/*
 * aiqna db for web service (Meta Stags Table)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */




/*
 ***********************************************************************************************
 * TABLE: meta_stags
 *  - AI로 추출된 스태그 임시 저장 (stag_code 매핑 전)
 ***********************************************************************************************
 */
CREATE TABLE public.meta_stags (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- 추출된 스태그 정보
  stag_name VARCHAR(255) NOT NULL,
  
  -- 소스 정보
  source_type VARCHAR(50) NOT NULL,
  source_id VARCHAR(1023) NOT NULL,

  -- 매핑 정보
  stag_code VARCHAR(96) NULL,
  
  -- 관리 정보
  admin_message VARCHAR(1023) NULL,
  is_processed BOOLEAN NOT NULL DEFAULT FALSE,
  processed_at TIMESTAMP WITH TIME ZONE NULL,
  
  -- 시스템 정보
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  -- 외래키
  CONSTRAINT meta_stags_stag_code_fkey
    FOREIGN KEY (stag_code)
    REFERENCES public.stags (stag_code)
    ON UPDATE CASCADE ON DELETE SET NULL,

  -- 제약조건
  CONSTRAINT meta_stags_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT meta_stags_stag_name_not_empty_check 
    CHECK (LENGTH(TRIM(stag_name)) > 0),
  
  -- 중복 방지: 같은 소스에서 같은 스태그명은 한 번만
  CONSTRAINT meta_stags_unique_source_stag
    UNIQUE (source_type, source_id, stag_name)
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 미처리 항목 조회 (가장 중요)
CREATE INDEX IF NOT EXISTS meta_stags_unprocessed_idx
  ON public.meta_stags (is_processed, created_at)
  WHERE is_processed = FALSE;

-- 스태그명 검색
CREATE INDEX IF NOT EXISTS meta_stags_stag_name_idx
  ON public.meta_stags (stag_name, created_at DESC);

-- 스태그명 전체 텍스트 검색
CREATE INDEX IF NOT EXISTS meta_stags_stag_name_trgm_idx
  ON public.meta_stags USING gin (stag_name gin_trgm_ops);

-- 소스별 조회
CREATE INDEX IF NOT EXISTS meta_stags_source_idx
  ON public.meta_stags (source_type, source_id, created_at DESC);

-- stag_code 매핑된 항목 조회
CREATE INDEX IF NOT EXISTS meta_stags_stag_code_idx
  ON public.meta_stags (stag_code, created_at DESC)
  WHERE stag_code IS NOT NULL;

-- 처리된 항목 조회
CREATE INDEX IF NOT EXISTS meta_stags_processed_idx
  ON public.meta_stags (is_processed, processed_at DESC)
  WHERE is_processed = TRUE;

-- 최신 추가순
CREATE INDEX IF NOT EXISTS meta_stags_created_at_idx
  ON public.meta_stags (created_at DESC);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.meta_stags ENABLE ROW LEVEL SECURITY;

-- 읽기 전용 (모든 사용자)
CREATE POLICY "meta_stags are visible to everyone"
  ON public.meta_stags FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업 (service_role만)
CREATE POLICY "Service role can manage meta_stags"
  ON public.meta_stags FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_meta_stags_updated_at
  BEFORE UPDATE ON public.meta_stags
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- stag_code가 설정되면 자동으로 is_processed = TRUE로 변경
CREATE OR REPLACE FUNCTION auto_mark_processed_on_stag_code()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.stag_code IS NOT NULL AND OLD.stag_code IS NULL THEN
        NEW.is_processed = TRUE;
        NEW.processed_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_auto_mark_processed_stag
  BEFORE UPDATE ON public.meta_stags
  FOR EACH ROW
  WHEN (NEW.stag_code IS NOT NULL AND OLD.stag_code IS NULL)
  EXECUTE FUNCTION auto_mark_processed_on_stag_code();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 추출된 스태그명 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.add_meta_stag(
    p_stag_name VARCHAR(255),
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
    INSERT INTO public.meta_stags (
        stag_name,
        source_type,
        source_id
    ) VALUES (
        TRIM(p_stag_name),
        p_source_type,
        p_source_id
    )
    ON CONFLICT (source_type, source_id, stag_name) DO NOTHING
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: stag_code 매핑 및 자동 처리
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.map_meta_stag_to_stag_code(
    p_meta_stag_id UUID,
    p_stag_code VARCHAR(96),
    p_admin_message VARCHAR(1023) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    UPDATE public.meta_stags
    SET stag_code = p_stag_code,
        admin_message = p_admin_message,
        is_processed = TRUE,
        processed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_meta_stag_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 미처리 스태그명 목록 조회 (관리자용)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_unprocessed_meta_stags(
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    stag_name VARCHAR(255),
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
        stag_name,
        source_type,
        source_id,
        COUNT(*) AS occurrence_count,
        MIN(created_at) AS first_seen,
        MAX(created_at) AS last_seen
    FROM public.meta_stags
    WHERE is_processed = FALSE
    GROUP BY stag_name, source_type, source_id
    ORDER BY occurrence_count DESC, last_seen DESC
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 스태그명 검색 (유사 매칭)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.search_similar_stag_names(
    p_stag_name VARCHAR(255),
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    stag_name VARCHAR(255),
    stag_code VARCHAR(96),
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
        ms.stag_name,
        ms.stag_code,
        COUNT(*) AS occurrence_count,
        ms.is_processed,
        similarity(ms.stag_name, p_stag_name) AS similarity_score
    FROM public.meta_stags ms
    WHERE ms.stag_name % p_stag_name
    GROUP BY ms.stag_name, ms.stag_code, ms.is_processed
    ORDER BY similarity_score DESC, occurrence_count DESC
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 스태그명 일괄 매핑 (같은 이름을 한 번에)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.batch_map_stag_name_to_code(
    p_stag_name VARCHAR(255),
    p_stag_code VARCHAR(96),
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
    UPDATE public.meta_stags
    SET stag_code = p_stag_code,
        admin_message = p_admin_message,
        is_processed = TRUE,
        processed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE stag_name = p_stag_name
      AND is_processed = FALSE;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    RETURN v_updated_count;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 통계 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_meta_stags_statistics()
RETURNS TABLE (
    total_count BIGINT,
    processed_count BIGINT,
    unprocessed_count BIGINT,
    unique_stag_names BIGINT,
    mapped_stag_codes BIGINT
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
        COUNT(DISTINCT stag_name) AS unique_stag_names,
        COUNT(DISTINCT stag_code) FILTER (WHERE stag_code IS NOT NULL) AS mapped_stag_codes
    FROM public.meta_stags;
$$;