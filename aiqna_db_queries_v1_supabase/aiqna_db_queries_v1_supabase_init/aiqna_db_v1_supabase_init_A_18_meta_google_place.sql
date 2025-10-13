/*
 * aiqna db for web service (Meta Google Places Table)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */




/*
 ***********************************************************************************************
 * TABLE: meta_google_places
 *  - AI로 추출된 Google Place 임시 저장 (google_place_id 매핑 전)
 ***********************************************************************************************
 */
CREATE TABLE public.meta_google_places (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- 추출된 장소 정보
  place_name VARCHAR(255) NOT NULL,
  city_name VARCHAR(255) NULL,  -- 참고용 (어느 도시의 장소인지)
  
  -- 소스 정보
  source_type VARCHAR(50) NOT NULL,
  source_id VARCHAR(1023) NOT NULL,

  -- 매핑 정보
  google_place_id VARCHAR(63) NULL,
  
  -- 관리 정보
  admin_message VARCHAR(1023) NULL,
  is_processed BOOLEAN NOT NULL DEFAULT FALSE,
  processed_at TIMESTAMP WITH TIME ZONE NULL,
  
  -- 시스템 정보
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  -- 외래키
  CONSTRAINT meta_google_places_google_place_id_fkey
    FOREIGN KEY (google_place_id)
    REFERENCES public.google_places (google_place_id)
    ON UPDATE CASCADE ON DELETE SET NULL,

  -- 제약조건
  CONSTRAINT meta_google_places_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT meta_google_places_place_name_not_empty_check 
    CHECK (LENGTH(TRIM(place_name)) > 0),
  
  -- 중복 방지: 같은 소스에서 같은 장소명은 한 번만
  CONSTRAINT meta_google_places_unique_source_place
    UNIQUE (source_type, source_id, place_name)
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 미처리 항목 조회 (가장 중요)
CREATE INDEX IF NOT EXISTS meta_google_places_unprocessed_idx
  ON public.meta_google_places (is_processed, created_at)
  WHERE is_processed = FALSE;

-- 장소명 검색
CREATE INDEX IF NOT EXISTS meta_google_places_place_name_idx
  ON public.meta_google_places (place_name, created_at DESC);

-- 장소명 전체 텍스트 검색
CREATE INDEX IF NOT EXISTS meta_google_places_place_name_trgm_idx
  ON public.meta_google_places USING gin (place_name gin_trgm_ops);

-- 도시명으로 필터링
CREATE INDEX IF NOT EXISTS meta_google_places_city_name_idx
  ON public.meta_google_places (city_name, created_at DESC)
  WHERE city_name IS NOT NULL;

-- 소스별 조회
CREATE INDEX IF NOT EXISTS meta_google_places_source_idx
  ON public.meta_google_places (source_type, source_id, created_at DESC);

-- google_place_id 매핑된 항목 조회
CREATE INDEX IF NOT EXISTS meta_google_places_google_place_id_idx
  ON public.meta_google_places (google_place_id, created_at DESC)
  WHERE google_place_id IS NOT NULL;

-- 처리된 항목 조회
CREATE INDEX IF NOT EXISTS meta_google_places_processed_idx
  ON public.meta_google_places (is_processed, processed_at DESC)
  WHERE is_processed = TRUE;

-- 최신 추가순
CREATE INDEX IF NOT EXISTS meta_google_places_created_at_idx
  ON public.meta_google_places (created_at DESC);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.meta_google_places ENABLE ROW LEVEL SECURITY;

-- 읽기 전용 (모든 사용자)
CREATE POLICY "meta_google_places are visible to everyone"
  ON public.meta_google_places FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업 (service_role만)
CREATE POLICY "Service role can manage meta_google_places"
  ON public.meta_google_places FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_meta_google_places_updated_at
  BEFORE UPDATE ON public.meta_google_places
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- google_place_id가 설정되면 자동으로 is_processed = TRUE로 변경
CREATE OR REPLACE FUNCTION auto_mark_processed_on_google_place_id()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.google_place_id IS NOT NULL AND OLD.google_place_id IS NULL THEN
        NEW.is_processed = TRUE;
        NEW.processed_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_auto_mark_processed_google_place
  BEFORE UPDATE ON public.meta_google_places
  FOR EACH ROW
  WHEN (NEW.google_place_id IS NOT NULL AND OLD.google_place_id IS NULL)
  EXECUTE FUNCTION auto_mark_processed_on_google_place_id();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 추출된 장소명 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.add_meta_google_place(
    p_place_name VARCHAR(255),
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(1023),
    p_city_name VARCHAR(255) DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO public.meta_google_places (
        place_name,
        source_type,
        source_id,
        city_name
    ) VALUES (
        TRIM(p_place_name),
        p_source_type,
        p_source_id,
        TRIM(p_city_name)
    )
    ON CONFLICT (source_type, source_id, place_name) DO NOTHING
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: google_place_id 매핑 및 자동 처리
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.map_meta_google_place_to_google_place_id(
    p_meta_google_place_id UUID,
    p_google_place_id VARCHAR(63),
    p_admin_message VARCHAR(1023) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    UPDATE public.meta_google_places
    SET google_place_id = p_google_place_id,
        admin_message = p_admin_message,
        is_processed = TRUE,
        processed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_meta_google_place_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 미처리 장소명 목록 조회 (관리자용)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_unprocessed_meta_google_places(
    p_city_name VARCHAR(255) DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    place_name VARCHAR(255),
    city_name VARCHAR(255),
    source_type VARCHAR(50),
    source_id VARCHAR(1023),
    occurrence_count BIGINT,
    first_seen TIMESTAMP WITH TIME ZONE,
    last_seen TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        place_name,
        city_name,
        source_type,
        source_id,
        COUNT(*) AS occurrence_count,
        MIN(created_at) AS first_seen,
        MAX(created_at) AS last_seen
    FROM public.meta_google_places
    WHERE is_processed = FALSE
      AND (p_city_name IS NULL OR city_name = p_city_name)
    GROUP BY place_name, city_name, source_type, source_id
    ORDER BY occurrence_count DESC, last_seen DESC
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 장소명 검색 (유사 매칭)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.search_similar_google_place_names(
    p_place_name VARCHAR(255),
    p_city_name VARCHAR(255) DEFAULT NULL,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    place_name VARCHAR(255),
    city_name VARCHAR(255),
    google_place_id VARCHAR(63),
    occurrence_count BIGINT,
    is_processed BOOLEAN,
    similarity_score REAL
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        mgp.place_name,
        mgp.city_name,
        mgp.google_place_id,
        COUNT(*) AS occurrence_count,
        mgp.is_processed,
        similarity(mgp.place_name, p_place_name) AS similarity_score
    FROM public.meta_google_places mgp
    WHERE mgp.place_name % p_place_name
      AND (p_city_name IS NULL OR mgp.city_name = p_city_name)
    GROUP BY mgp.place_name, mgp.city_name, mgp.google_place_id, mgp.is_processed
    ORDER BY similarity_score DESC, occurrence_count DESC
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 장소명 일괄 매핑 (같은 이름을 한 번에)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.batch_map_google_place_name_to_id(
    p_place_name VARCHAR(255),
    p_google_place_id VARCHAR(63),
    p_city_name VARCHAR(255) DEFAULT NULL,
    p_admin_message VARCHAR(1023) DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE public.meta_google_places
    SET google_place_id = p_google_place_id,
        admin_message = p_admin_message,
        is_processed = TRUE,
        processed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE place_name = p_place_name
      AND (p_city_name IS NULL OR city_name = p_city_name)
      AND is_processed = FALSE;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    RETURN v_updated_count;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 통계 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_meta_google_places_statistics()
RETURNS TABLE (
    total_count BIGINT,
    processed_count BIGINT,
    unprocessed_count BIGINT,
    unique_place_names BIGINT,
    mapped_google_place_ids BIGINT,
    unique_city_names BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        COUNT(*) AS total_count,
        COUNT(*) FILTER (WHERE is_processed = TRUE) AS processed_count,
        COUNT(*) FILTER (WHERE is_processed = FALSE) AS unprocessed_count,
        COUNT(DISTINCT place_name) AS unique_place_names,
        COUNT(DISTINCT google_place_id) FILTER (WHERE google_place_id IS NOT NULL) AS mapped_google_place_ids,
        COUNT(DISTINCT city_name) FILTER (WHERE city_name IS NOT NULL) AS unique_city_names
    FROM public.meta_google_places;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 도시별 장소명 통계
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_google_places_by_city_statistics()
RETURNS TABLE (
    city_name VARCHAR(255),
    total_places BIGINT,
    processed_places BIGINT,
    unprocessed_places BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        COALESCE(city_name, 'Unknown') AS city_name,
        COUNT(*) AS total_places,
        COUNT(*) FILTER (WHERE is_processed = TRUE) AS processed_places,
        COUNT(*) FILTER (WHERE is_processed = FALSE) AS unprocessed_places
    FROM public.meta_google_places
    GROUP BY city_name
    ORDER BY total_places DESC;
$$;