/*
 * aiqna db for web service (Meta Cities Table)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */




/*
 ***********************************************************************************************
 * TABLE: meta_cities
 *  - AI로 추출된 도시명 임시 저장 (city_code 매핑 전)
 ***********************************************************************************************
 */
CREATE TABLE public.meta_cities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- 추출된 도시 정보
  city_name VARCHAR(255) NOT NULL,
  
  -- 소스 정보
  source_type VARCHAR(50) NOT NULL,
  source_id VARCHAR(1023) NOT NULL,

  -- 매핑 정보
  city_code VARCHAR(96) NULL,
  
  -- 관리 정보
  admin_message VARCHAR(1023) NULL,
  is_processed BOOLEAN NOT NULL DEFAULT FALSE,
  processed_at TIMESTAMP WITH TIME ZONE NULL,
  
  -- 시스템 정보
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  -- 외래키
  CONSTRAINT meta_cities_city_code_fkey
    FOREIGN KEY (city_code)
    REFERENCES public.cities (city_code)
    ON UPDATE CASCADE ON DELETE SET NULL,

  -- 제약조건
  CONSTRAINT meta_cities_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT meta_cities_city_name_not_empty_check 
    CHECK (LENGTH(TRIM(city_name)) > 0),
  
  -- 중복 방지: 같은 소스에서 같은 도시명은 한 번만
  CONSTRAINT meta_cities_unique_source_city
    UNIQUE (source_type, source_id, city_name)
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 미처리 항목 조회 (가장 중요)
CREATE INDEX IF NOT EXISTS meta_cities_unprocessed_idx
  ON public.meta_cities (is_processed, created_at)
  WHERE is_processed = FALSE;

-- 도시명 검색
CREATE INDEX IF NOT EXISTS meta_cities_city_name_idx
  ON public.meta_cities (city_name, created_at DESC);

-- 도시명 전체 텍스트 검색
CREATE INDEX IF NOT EXISTS meta_cities_city_name_trgm_idx
  ON public.meta_cities USING gin (city_name gin_trgm_ops);

-- 소스별 조회
CREATE INDEX IF NOT EXISTS meta_cities_source_idx
  ON public.meta_cities (source_type, source_id, created_at DESC);

-- city_code 매핑된 항목 조회
CREATE INDEX IF NOT EXISTS meta_cities_city_code_idx
  ON public.meta_cities (city_code, created_at DESC)
  WHERE city_code IS NOT NULL;

-- 처리된 항목 조회
CREATE INDEX IF NOT EXISTS meta_cities_processed_idx
  ON public.meta_cities (is_processed, processed_at DESC)
  WHERE is_processed = TRUE;

-- 최신 추가순
CREATE INDEX IF NOT EXISTS meta_cities_created_at_idx
  ON public.meta_cities (created_at DESC);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.meta_cities ENABLE ROW LEVEL SECURITY;

-- 읽기 전용 (모든 사용자)
CREATE POLICY "meta_cities are visible to everyone"
  ON public.meta_cities FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업 (service_role만)
CREATE POLICY "Service role can manage meta_cities"
  ON public.meta_cities FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_meta_cities_updated_at
  BEFORE UPDATE ON public.meta_cities
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- city_code가 설정되면 자동으로 is_processed = TRUE로 변경
CREATE OR REPLACE FUNCTION auto_mark_processed_on_city_code()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.city_code IS NOT NULL AND OLD.city_code IS NULL THEN
        NEW.is_processed = TRUE;
        NEW.processed_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_auto_mark_processed
  BEFORE UPDATE ON public.meta_cities
  FOR EACH ROW
  WHEN (NEW.city_code IS NOT NULL AND OLD.city_code IS NULL)
  EXECUTE FUNCTION auto_mark_processed_on_city_code();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 추출된 도시명 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.add_meta_city(
    p_city_name VARCHAR(255),
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(1023)
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO public.meta_cities (
        city_name,
        source_type,
        source_id
    ) VALUES (
        TRIM(p_city_name),
        p_source_type,
        p_source_id
    )
    ON CONFLICT (source_type, source_id, city_name) DO NOTHING
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: city_code 매핑 및 자동 처리
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.map_meta_city_to_city_code(
    p_meta_city_id UUID,
    p_city_code VARCHAR(96),
    p_admin_message VARCHAR(1023) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    UPDATE public.meta_cities
    SET city_code = p_city_code,
        admin_message = p_admin_message,
        is_processed = TRUE,
        processed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_meta_city_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 미처리 도시명 목록 조회 (관리자용)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_unprocessed_meta_cities(
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
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
        city_name,
        source_type,
        source_id,
        COUNT(*) AS occurrence_count,
        MIN(created_at) AS first_seen,
        MAX(created_at) AS last_seen
    FROM public.meta_cities
    WHERE is_processed = FALSE
    GROUP BY city_name, source_type, source_id
    ORDER BY occurrence_count DESC, last_seen DESC
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 도시명 검색 (유사 매칭)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.search_similar_city_names(
    p_city_name VARCHAR(255),
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    city_name VARCHAR(255),
    city_code VARCHAR(96),
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
        mc.city_name,
        mc.city_code,
        COUNT(*) AS occurrence_count,
        mc.is_processed,
        similarity(mc.city_name, p_city_name) AS similarity_score
    FROM public.meta_cities mc
    WHERE mc.city_name % p_city_name
    GROUP BY mc.city_name, mc.city_code, mc.is_processed
    ORDER BY similarity_score DESC, occurrence_count DESC
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 도시명 일괄 매핑 (같은 이름을 한 번에)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.batch_map_city_name_to_code(
    p_city_name VARCHAR(255),
    p_city_code VARCHAR(96),
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
    UPDATE public.meta_cities
    SET city_code = p_city_code,
        admin_message = p_admin_message,
        is_processed = TRUE,
        processed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE city_name = p_city_name
      AND is_processed = FALSE;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    RETURN v_updated_count;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 통계 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_meta_cities_statistics()
RETURNS TABLE (
    total_count BIGINT,
    processed_count BIGINT,
    unprocessed_count BIGINT,
    unique_city_names BIGINT,
    mapped_city_codes BIGINT
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
        COUNT(DISTINCT city_name) AS unique_city_names,
        COUNT(DISTINCT city_code) FILTER (WHERE city_code IS NOT NULL) AS mapped_city_codes
    FROM public.meta_cities;
$$;