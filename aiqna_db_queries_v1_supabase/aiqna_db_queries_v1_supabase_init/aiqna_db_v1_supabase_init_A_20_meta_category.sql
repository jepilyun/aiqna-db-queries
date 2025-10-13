/*
 * aiqna db for web service (Meta Categories Table)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */




/*
 ***********************************************************************************************
 * TABLE: meta_categories
 *  - AI로 추출된 카테고리 임시 저장 (category_code 매핑 전)
 ***********************************************************************************************
 */
CREATE TABLE public.meta_categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- 추출된 카테고리 정보
  category_name VARCHAR(255) NOT NULL,
  
  -- 소스 정보
  source_type VARCHAR(50) NOT NULL,
  source_id VARCHAR(1023) NOT NULL,

  -- 매핑 정보
  category_code TEXT NULL,
  
  -- 관리 정보
  admin_message VARCHAR(1023) NULL,
  is_processed BOOLEAN NOT NULL DEFAULT FALSE,
  processed_at TIMESTAMP WITH TIME ZONE NULL,
  
  -- 시스템 정보
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  -- 외래키
  CONSTRAINT meta_categories_category_code_fkey
    FOREIGN KEY (category_code)
    REFERENCES public.categories (category_code)
    ON UPDATE CASCADE ON DELETE SET NULL,

  -- 제약조건
  CONSTRAINT meta_categories_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text', 'ai_extraction')),
  
  CONSTRAINT meta_categories_category_name_not_empty_check 
    CHECK (LENGTH(TRIM(category_name)) > 0),
  
  -- 중복 방지: 같은 소스에서 같은 카테고리명은 한 번만
  CONSTRAINT meta_categories_unique_source_category
    UNIQUE (source_type, source_id, category_name)
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 미처리 항목 조회 (가장 중요)
CREATE INDEX IF NOT EXISTS meta_categories_unprocessed_idx
  ON public.meta_categories (is_processed, created_at)
  WHERE is_processed = FALSE;

-- 카테고리명 검색
CREATE INDEX IF NOT EXISTS meta_categories_category_name_idx
  ON public.meta_categories (category_name, created_at DESC);

-- 카테고리명 전체 텍스트 검색
CREATE INDEX IF NOT EXISTS meta_categories_category_name_trgm_idx
  ON public.meta_categories USING gin (category_name gin_trgm_ops);

-- 소스별 조회
CREATE INDEX IF NOT EXISTS meta_categories_source_idx
  ON public.meta_categories (source_type, source_id, created_at DESC);

-- category_code 매핑된 항목 조회
CREATE INDEX IF NOT EXISTS meta_categories_category_code_idx
  ON public.meta_categories (category_code, created_at DESC)
  WHERE category_code IS NOT NULL;

-- 처리된 항목 조회
CREATE INDEX IF NOT EXISTS meta_categories_processed_idx
  ON public.meta_categories (is_processed, processed_at DESC)
  WHERE is_processed = TRUE;

-- 최신 추가순
CREATE INDEX IF NOT EXISTS meta_categories_created_at_idx
  ON public.meta_categories (created_at DESC);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.meta_categories ENABLE ROW LEVEL SECURITY;

-- 읽기 전용 (모든 사용자)
CREATE POLICY "meta_categories are visible to everyone"
  ON public.meta_categories FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업 (service_role만)
CREATE POLICY "Service role can manage meta_categories"
  ON public.meta_categories FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_meta_categories_updated_at
  BEFORE UPDATE ON public.meta_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- category_code가 설정되면 자동으로 is_processed = TRUE로 변경
CREATE OR REPLACE FUNCTION auto_mark_processed_on_category_code()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.category_code IS NOT NULL AND OLD.category_code IS NULL THEN
        NEW.is_processed = TRUE;
        NEW.processed_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_auto_mark_processed_category
  BEFORE UPDATE ON public.meta_categories
  FOR EACH ROW
  WHEN (NEW.category_code IS NOT NULL AND OLD.category_code IS NULL)
  EXECUTE FUNCTION auto_mark_processed_on_category_code();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 추출된 카테고리명 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.add_meta_category(
    p_category_name VARCHAR(255),
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
    INSERT INTO public.meta_categories (
        category_name,
        source_type,
        source_id
    ) VALUES (
        TRIM(p_category_name),
        p_source_type,
        p_source_id
    )
    ON CONFLICT (source_type, source_id, category_name) DO NOTHING
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: category_code 매핑 및 자동 처리
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.map_meta_category_to_category_code(
    p_meta_category_id UUID,
    p_category_code TEXT,
    p_admin_message VARCHAR(1023) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    UPDATE public.meta_categories
    SET category_code = p_category_code,
        admin_message = p_admin_message,
        is_processed = TRUE,
        processed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_meta_category_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 미처리 카테고리명 목록 조회 (관리자용)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_unprocessed_meta_categories(
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    category_name VARCHAR(255),
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
        category_name,
        source_type,
        source_id,
        COUNT(*) AS occurrence_count,
        MIN(created_at) AS first_seen,
        MAX(created_at) AS last_seen
    FROM public.meta_categories
    WHERE is_processed = FALSE
    GROUP BY category_name, source_type, source_id
    ORDER BY occurrence_count DESC, last_seen DESC
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 카테고리명 검색 (유사 매칭)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.search_similar_category_names(
    p_category_name VARCHAR(255),
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    category_name VARCHAR(255),
    category_code TEXT,
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
        mc.category_name,
        mc.category_code,
        COUNT(*) AS occurrence_count,
        mc.is_processed,
        similarity(mc.category_name, p_category_name) AS similarity_score
    FROM public.meta_categories mc
    WHERE mc.category_name % p_category_name
    GROUP BY mc.category_name, mc.category_code, mc.is_processed
    ORDER BY similarity_score DESC, occurrence_count DESC
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 카테고리명 일괄 매핑 (같은 이름을 한 번에)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.batch_map_category_name_to_code(
    p_category_name VARCHAR(255),
    p_category_code TEXT,
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
    UPDATE public.meta_categories
    SET category_code = p_category_code,
        admin_message = p_admin_message,
        is_processed = TRUE,
        processed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE category_name = p_category_name
      AND is_processed = FALSE;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    RETURN v_updated_count;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 통계 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_meta_categories_statistics()
RETURNS TABLE (
    total_count BIGINT,
    processed_count BIGINT,
    unprocessed_count BIGINT,
    unique_category_names BIGINT,
    mapped_category_codes BIGINT
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
        COUNT(DISTINCT category_name) AS unique_category_names,
        COUNT(DISTINCT category_code) FILTER (WHERE category_code IS NOT NULL) AS mapped_category_codes
    FROM public.meta_categories;
$$;