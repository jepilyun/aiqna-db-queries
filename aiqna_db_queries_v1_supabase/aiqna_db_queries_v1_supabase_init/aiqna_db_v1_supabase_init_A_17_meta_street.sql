/*
 * aiqna db for web service (Meta Streets Table)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */




/*
 ***********************************************************************************************
 * TABLE: meta_streets
 *  - AI로 추출된 거리명 임시 저장 (street_code 매핑 전)
 ***********************************************************************************************
 */
CREATE TABLE public.meta_streets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- 추출된 거리 정보
  street_name VARCHAR(255) NOT NULL,
  city_name VARCHAR(255) NULL,  -- 참고용 (어느 도시의 거리인지)
  
  -- 소스 정보
  source_type VARCHAR(50) NOT NULL,
  source_id VARCHAR(1023) NOT NULL,

  -- 매핑 정보
  street_code VARCHAR(96) NULL,
  
  -- 관리 정보
  admin_message VARCHAR(1023) NULL,
  is_processed BOOLEAN NOT NULL DEFAULT FALSE,
  processed_at TIMESTAMP WITH TIME ZONE NULL,
  
  -- 시스템 정보
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  -- 외래키
  CONSTRAINT meta_streets_street_code_fkey
    FOREIGN KEY (street_code)
    REFERENCES public.streets (street_code)
    ON UPDATE CASCADE ON DELETE SET NULL,

  -- 제약조건
  CONSTRAINT meta_streets_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT meta_streets_street_name_not_empty_check 
    CHECK (LENGTH(TRIM(street_name)) > 0),
  
  -- 중복 방지: 같은 소스에서 같은 거리명은 한 번만
  CONSTRAINT meta_streets_unique_source_street
    UNIQUE (source_type, source_id, street_name)
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 미처리 항목 조회 (가장 중요)
CREATE INDEX IF NOT EXISTS meta_streets_unprocessed_idx
  ON public.meta_streets (is_processed, created_at)
  WHERE is_processed = FALSE;

-- 거리명 검색
CREATE INDEX IF NOT EXISTS meta_streets_street_name_idx
  ON public.meta_streets (street_name, created_at DESC);

-- 거리명 전체 텍스트 검색
CREATE INDEX IF NOT EXISTS meta_streets_street_name_trgm_idx
  ON public.meta_streets USING gin (street_name gin_trgm_ops);

-- 도시명으로 필터링
CREATE INDEX IF NOT EXISTS meta_streets_city_name_idx
  ON public.meta_streets (city_name, created_at DESC)
  WHERE city_name IS NOT NULL;

-- 소스별 조회
CREATE INDEX IF NOT EXISTS meta_streets_source_idx
  ON public.meta_streets (source_type, source_id, created_at DESC);

-- street_code 매핑된 항목 조회
CREATE INDEX IF NOT EXISTS meta_streets_street_code_idx
  ON public.meta_streets (street_code, created_at DESC)
  WHERE street_code IS NOT NULL;

-- 처리된 항목 조회
CREATE INDEX IF NOT EXISTS meta_streets_processed_idx
  ON public.meta_streets (is_processed, processed_at DESC)
  WHERE is_processed = TRUE;

-- 최신 추가순
CREATE INDEX IF NOT EXISTS meta_streets_created_at_idx
  ON public.meta_streets (created_at DESC);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.meta_streets ENABLE ROW LEVEL SECURITY;

-- 읽기 전용 (모든 사용자)
CREATE POLICY "meta_streets are visible to everyone"
  ON public.meta_streets FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업 (service_role만)
CREATE POLICY "Service role can manage meta_streets"
  ON public.meta_streets FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_meta_streets_updated_at
  BEFORE UPDATE ON public.meta_streets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- street_code가 설정되면 자동으로 is_processed = TRUE로 변경
CREATE OR REPLACE FUNCTION auto_mark_processed_on_street_code()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.street_code IS NOT NULL AND OLD.street_code IS NULL THEN
        NEW.is_processed = TRUE;
        NEW.processed_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_auto_mark_processed_street
  BEFORE UPDATE ON public.meta_streets
  FOR EACH ROW
  WHEN (NEW.street_code IS NOT NULL AND OLD.street_code IS NULL)
  EXECUTE FUNCTION auto_mark_processed_on_street_code();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 추출된 거리명 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.add_meta_street(
    p_street_name VARCHAR(255),
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
    INSERT INTO public.meta_streets (
        street_name,
        source_type,
        source_id,
        city_name
    ) VALUES (
        TRIM(p_street_name),
        p_source_type,
        p_source_id,
        TRIM(p_city_name)
    )
    ON CONFLICT (source_type, source_id, street_name) DO NOTHING
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: street_code 매핑 및 자동 처리
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.map_meta_street_to_street_code(
    p_meta_street_id UUID,
    p_street_code VARCHAR(96),
    p_admin_message VARCHAR(1023) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    UPDATE public.meta_streets
    SET street_code = p_street_code,
        admin_message = p_admin_message,
        is_processed = TRUE,
        processed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_meta_street_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 미처리 거리명 목록 조회 (관리자용)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_unprocessed_meta_streets(
    p_city_name VARCHAR(255) DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    street_name VARCHAR(255),
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
        street_name,
        city_name,
        source_type,
        source_id,
        COUNT(*) AS occurrence_count,
        MIN(created_at) AS first_seen,
        MAX(created_at) AS last_seen
    FROM public.meta_streets
    WHERE is_processed = FALSE
      AND (p_city_name IS NULL OR city_name = p_city_name)
    GROUP BY street_name, city_name, source_type, source_id
    ORDER BY occurrence_count DESC, last_seen DESC
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 거리명 검색 (유사 매칭)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.search_similar_street_names(
    p_street_name VARCHAR(255),
    p_city_name VARCHAR(255) DEFAULT NULL,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    street_name VARCHAR(255),
    city_name VARCHAR(255),
    street_code VARCHAR(96),
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
        ms.street_name,
        ms.city_name,
        ms.street_code,
        COUNT(*) AS occurrence_count,
        ms.is_processed,
        similarity(ms.street_name, p_street_name) AS similarity_score
    FROM public.meta_streets ms
    WHERE ms.street_name % p_street_name
      AND (p_city_name IS NULL OR ms.city_name = p_city_name)
    GROUP BY ms.street_name, ms.city_name, ms.street_code, ms.is_processed
    ORDER BY similarity_score DESC, occurrence_count DESC
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 거리명 일괄 매핑 (같은 이름을 한 번에)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.batch_map_street_name_to_code(
    p_street_name VARCHAR(255),
    p_street_code VARCHAR(96),
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
    UPDATE public.meta_streets
    SET street_code = p_street_code,
        admin_message = p_admin_message,
        is_processed = TRUE,
        processed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE street_name = p_street_name
      AND (p_city_name IS NULL OR city_name = p_city_name)
      AND is_processed = FALSE;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    RETURN v_updated_count;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 통계 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_meta_streets_statistics()
RETURNS TABLE (
    total_count BIGINT,
    processed_count BIGINT,
    unprocessed_count BIGINT,
    unique_street_names BIGINT,
    mapped_street_codes BIGINT,
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
        COUNT(DISTINCT street_name) AS unique_street_names,
        COUNT(DISTINCT street_code) FILTER (WHERE street_code IS NOT NULL) AS mapped_street_codes,
        COUNT(DISTINCT city_name) FILTER (WHERE city_name IS NOT NULL) AS unique_city_names
    FROM public.meta_streets;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 도시별 거리명 통계
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_streets_by_city_statistics()
RETURNS TABLE (
    city_name VARCHAR(255),
    total_streets BIGINT,
    processed_streets BIGINT,
    unprocessed_streets BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        COALESCE(city_name, 'Unknown') AS city_name,
        COUNT(*) AS total_streets,
        COUNT(*) FILTER (WHERE is_processed = TRUE) AS processed_streets,
        COUNT(*) FILTER (WHERE is_processed = FALSE) AS unprocessed_streets
    FROM public.meta_streets
    GROUP BY city_name
    ORDER BY total_streets DESC;
$$;