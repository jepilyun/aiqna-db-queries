/*
 * aiqna db for web service (Categories and Mapping Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */




/*
 ***********************************************************************************************
 * TABLE: categories
 ***********************************************************************************************
 */
CREATE TABLE public.categories (
  category_code        VARCHAR(96)   PRIMARY KEY,
  target_country_code  VARCHAR(2)    NOT NULL DEFAULT 'AA',
  upper_category_code  VARCHAR(96)   NULL,
  
  order_num            SMALLINT      NOT NULL DEFAULT 0,
  name_en              VARCHAR(63)   NOT NULL,
  name_ko              VARCHAR(63)   NULL,
  description_en       VARCHAR(1023) NULL,
  description_ko       VARCHAR(1023) NULL,
  
  -- 계절성/기간
  is_open_always       BOOLEAN       NOT NULL DEFAULT TRUE,
  start_month          SMALLINT      NOT NULL DEFAULT 1,
  start_day            SMALLINT      NOT NULL DEFAULT 1,
  end_month            SMALLINT      NOT NULL DEFAULT 12,
  end_day              SMALLINT      NOT NULL DEFAULT 31,
  
  -- 미디어
  icon_url             VARCHAR(255)  NULL,
  img_url              VARCHAR(255)  NULL,

  -- 시스템 정보
  created_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_by           VARCHAR(511)  NULL,
  updated_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  is_active            BOOLEAN       NOT NULL DEFAULT TRUE,
  deactivated_at       TIMESTAMP WITH TIME ZONE NULL,
  deactivated_by       VARCHAR(511)  NULL,
  is_display           BOOLEAN       NOT NULL DEFAULT TRUE,

  -- 썸네일
  thumbnail_main_1     VARCHAR(1023) NULL,
  thumbnail_main_2     VARCHAR(1023) NULL,
  thumbnail_main_3     VARCHAR(1023) NULL,
  thumbnail_main_4     VARCHAR(1023) NULL,
  thumbnail_main_5     VARCHAR(1023) NULL,

  thumbnail_1          VARCHAR(1023) NULL,
  thumbnail_2          VARCHAR(1023) NULL,
  thumbnail_3          VARCHAR(1023) NULL,
  thumbnail_4          VARCHAR(1023) NULL,
  thumbnail_5          VARCHAR(1023) NULL,
  
  thumbnail_vertical_1 VARCHAR(1023) NULL,
  thumbnail_vertical_2 VARCHAR(1023) NULL,
  thumbnail_vertical_3 VARCHAR(1023) NULL,
  thumbnail_vertical_4 VARCHAR(1023) NULL,
  thumbnail_vertical_5 VARCHAR(1023) NULL,

  -- 외래키
  CONSTRAINT categories_target_country_code_fkey
    FOREIGN KEY (target_country_code)
    REFERENCES public.countries (country_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT categories_upper_category_code_fkey
    FOREIGN KEY (upper_category_code)
    REFERENCES public.categories (category_code)
    ON UPDATE CASCADE ON DELETE SET NULL,

  -- 제약조건
  CONSTRAINT categories_order_num_check CHECK (order_num >= 0),
  CONSTRAINT categories_start_month_check CHECK (start_month BETWEEN 1 AND 12),
  CONSTRAINT categories_start_day_check CHECK (start_day BETWEEN 1 AND 31),
  CONSTRAINT categories_end_month_check CHECK (end_month BETWEEN 1 AND 12),
  CONSTRAINT categories_end_day_check CHECK (end_day BETWEEN 1 AND 31),
  
  -- 순환 참조 방지
  CONSTRAINT categories_no_self_reference_check 
    CHECK (category_code != upper_category_code),
  
  -- 기간 논리 검증
  CONSTRAINT categories_period_check 
    CHECK (
      is_open_always = TRUE
      OR
      (
        (start_month < end_month)
        OR
        (start_month = end_month AND start_day <= end_day)
        OR
        (start_month > end_month)  -- 연말-연초 걸치는 경우 (예: 12월-2월)
      )
    )
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 상위 카테고리별 정렬
CREATE INDEX IF NOT EXISTS categories_upper_order_idx
  ON public.categories (upper_category_code, order_num, category_code);

-- 최상위 카테고리 조회
CREATE INDEX IF NOT EXISTS categories_top_level_idx
  ON public.categories (order_num, category_code)
  WHERE upper_category_code IS NULL;

-- 가시성 필터
CREATE INDEX IF NOT EXISTS categories_visible_idx
  ON public.categories (is_active, is_display, order_num)
  WHERE is_active = TRUE AND is_display = TRUE;

-- 국가별 카테고리
CREATE INDEX IF NOT EXISTS categories_country_idx
  ON public.categories (target_country_code, order_num);

-- 이름 검색 최적화
CREATE INDEX IF NOT EXISTS categories_name_en_trgm_idx
  ON public.categories USING gin (name_en gin_trgm_ops);

CREATE INDEX IF NOT EXISTS categories_name_ko_trgm_idx
  ON public.categories USING gin (name_ko gin_trgm_ops)
  WHERE name_ko IS NOT NULL;

-- 설명 검색 (선택적)
CREATE INDEX IF NOT EXISTS categories_desc_en_trgm_idx
  ON public.categories USING gin (description_en gin_trgm_ops)
  WHERE description_en IS NOT NULL;

CREATE INDEX IF NOT EXISTS categories_desc_ko_trgm_idx
  ON public.categories USING gin (description_ko gin_trgm_ops)
  WHERE description_ko IS NOT NULL;

-- 계절성 카테고리 조회
CREATE INDEX IF NOT EXISTS categories_seasonal_idx
  ON public.categories (is_open_always, start_month, end_month)
  WHERE is_open_always = FALSE;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "categories are visible to everyone"
  ON public.categories FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage categories"
  ON public.categories FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: get_sub_categories (개선)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_sub_categories(
    p_upper_category_code TEXT,
    p_only_display BOOLEAN DEFAULT FALSE,
    p_only_active BOOLEAN DEFAULT FALSE,
    p_limit INTEGER DEFAULT 100
)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT COALESCE(
        jsonb_agg(to_jsonb(s.*) ORDER BY s.order_num DESC, s.name_en),
        '[]'::jsonb
    )
    FROM (
        SELECT c.*
        FROM public.categories c
        WHERE c.upper_category_code = p_upper_category_code
          AND (NOT p_only_display OR c.is_display = TRUE)
          AND (NOT p_only_active OR c.is_active = TRUE)
        ORDER BY c.order_num DESC, c.name_en
        LIMIT p_limit
    ) AS s
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: get_category_tree (전체 계층 조회)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_category_tree(
    p_root_category_code TEXT DEFAULT NULL,
    p_max_depth INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    WITH RECURSIVE category_tree AS (
        -- 루트 레벨
        SELECT 
            c.category_code,
            c.upper_category_code,
            c.name_en,
            c.name_ko,
            c.order_num,
            c.is_active,
            c.is_display,
            1 AS depth,
            ARRAY[c.category_code::text]::text[] AS path
        FROM public.categories c
        WHERE (p_root_category_code IS NULL AND c.upper_category_code IS NULL)
          OR (c.category_code = p_root_category_code)
        
        UNION ALL
        
        -- 하위 카테고리
        SELECT 
            c.category_code,
            c.upper_category_code,
            c.name_en,
            c.name_ko,
            c.order_num,
            c.is_active,
            c.is_display,
            ct.depth + 1,
            (ct.path || c.category_code::text)::text[] AS path
        FROM public.categories c
        JOIN category_tree ct ON c.upper_category_code = ct.category_code
        WHERE ct.depth < p_max_depth
          AND NOT (c.category_code::text = ANY(ct.path))  -- 순환 방지
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'category_code', category_code,
            'upper_category_code', upper_category_code,
            'name_en', name_en,
            'name_ko', name_ko,
            'order_num', order_num,
            'depth', depth
        ) ORDER BY depth, order_num DESC, name_en
    )
    FROM category_tree
    WHERE is_active = TRUE AND is_display = TRUE;
$$;





-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: get_category_path (특정 카테고리의 경로)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_category_path(
    p_category_code TEXT
)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    WITH RECURSIVE category_path AS (
        -- 시작 카테고리
        SELECT 
            c.category_code,
            c.upper_category_code,
            c.name_en,
            c.name_ko,
            1 AS level
        FROM public.categories c
        WHERE c.category_code = p_category_code
        
        UNION ALL
        
        -- 상위 카테고리
        SELECT 
            c.category_code,
            c.upper_category_code,
            c.name_en,
            c.name_ko,
            cp.level + 1
        FROM public.categories c
        JOIN category_path cp ON c.category_code = cp.upper_category_code
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'category_code', category_code,
            'name_en', name_en,
            'name_ko', name_ko,
            'level', level
        ) ORDER BY level DESC
    )
    FROM category_path;
$$;






/*
 ***********************************************************************************************
 * TABLE: category_i18n
 ***********************************************************************************************
 */
CREATE TABLE public.category_i18n (
  category_code    VARCHAR(96)  NOT NULL,
  lang_code        VARCHAR(8)   NOT NULL,
  name_i18n        VARCHAR(63)  NOT NULL,
  description_i18n VARCHAR(511) NULL,
  
  created_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CONSTRAINT category_i18n_pkey PRIMARY KEY (category_code, lang_code),

  CONSTRAINT category_i18n_category_code_fkey
    FOREIGN KEY (category_code)
    REFERENCES public.categories (category_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT category_i18n_lang_code_fkey
    FOREIGN KEY (lang_code)
    REFERENCES public.languages (lang_code)
    ON UPDATE CASCADE ON DELETE CASCADE
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 부분/유사 검색 최적화
CREATE INDEX IF NOT EXISTS category_i18n_name_trgm_idx
  ON public.category_i18n USING gin (name_i18n gin_trgm_ops);

-- 언어별 조회
CREATE INDEX IF NOT EXISTS category_i18n_lang_idx
  ON public.category_i18n (lang_code);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.category_i18n ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "category_i18n are visible to everyone"
  ON public.category_i18n FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage category_i18n"
  ON public.category_i18n FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_category_i18n_updated_at
  BEFORE UPDATE ON public.category_i18n
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();









/*
 ***********************************************************************************************
 * TABLE: map_category
 *  - AI로 추출된 카테고리와 콘텐츠 매핑
 ***********************************************************************************************
 */
CREATE TABLE public.map_category (
  category_code VARCHAR(96) NOT NULL,
  source_type VARCHAR(50) NOT NULL,
  source_id VARCHAR(1023) NOT NULL,

  -- AI 추출 정보
  confidence_score NUMERIC(3, 2) NULL,
  extracted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  extraction_method VARCHAR(50) NULL,
  
  -- 관리 정보
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  verified_at TIMESTAMP WITH TIME ZONE NULL,
  verified_by VARCHAR(511) NULL,
  
  is_selected BOOLEAN NOT NULL DEFAULT FALSE,
  order_num INTEGER NOT NULL DEFAULT 0,
  added_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CONSTRAINT map_category_pkey
    PRIMARY KEY (category_code, source_type, source_id),

  CONSTRAINT map_category_category_code_fkey
    FOREIGN KEY (category_code) 
    REFERENCES public.categories (category_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT map_category_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT map_category_order_num_check CHECK (order_num >= 0),
  
  CONSTRAINT map_category_confidence_check 
    CHECK (confidence_score IS NULL OR (confidence_score BETWEEN 0 AND 1))
) TABLESPACE pg_default;

-- =============================================================================================
-- Indexes
-- =============================================================================================

-- 카테고리별 콘텐츠 목록 조회
CREATE INDEX IF NOT EXISTS map_category_code_order_idx
  ON public.map_category (category_code, order_num, source_id);

-- 최신 등록순 조회
CREATE INDEX IF NOT EXISTS map_category_code_added_idx
  ON public.map_category (category_code, added_at DESC, source_id);

-- 선택된 항목 빠른 조회
CREATE INDEX IF NOT EXISTS map_category_selected_idx
  ON public.map_category (category_code, order_num, added_at DESC)
  WHERE is_selected = TRUE;

-- 검증된 항목 조회
CREATE INDEX IF NOT EXISTS map_category_verified_idx
  ON public.map_category (category_code, confidence_score DESC)
  WHERE is_verified = TRUE;

-- 역방향 탐색
CREATE INDEX IF NOT EXISTS map_category_source_idx
  ON public.map_category (source_type, source_id, category_code);

-- 소스 타입별 조회
CREATE INDEX IF NOT EXISTS map_category_source_type_idx
  ON public.map_category (source_type, added_at DESC);

-- 신뢰도 높은 항목 조회
CREATE INDEX IF NOT EXISTS map_category_confidence_idx
  ON public.map_category (confidence_score DESC)
  WHERE confidence_score >= 0.8;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.map_category ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "map_category are visible to everyone"
  ON public.map_category FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage map_category"
  ON public.map_category FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_map_category_updated_at
  BEFORE UPDATE ON public.map_category
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: AI 추출 카테고리 매핑 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.upsert_category_mapping(
    p_category_code VARCHAR(96),
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(1023),
    p_confidence_score NUMERIC(3, 2) DEFAULT NULL,
    p_extraction_method VARCHAR(50) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    INSERT INTO public.map_category (
        category_code,
        source_type,
        source_id,
        confidence_score,
        extraction_method,
        extracted_at
    ) VALUES (
        p_category_code,
        p_source_type,
        p_source_id,
        p_confidence_score,
        p_extraction_method,
        NOW()
    )
    ON CONFLICT (category_code, source_type, source_id) DO UPDATE SET
        confidence_score = EXCLUDED.confidence_score,
        extraction_method = EXCLUDED.extraction_method,
        extracted_at = NOW(),
        updated_at = NOW();
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 콘텐츠의 카테고리 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_categories_for_content(
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(1023)
)
RETURNS TABLE (
    category_code VARCHAR(96),
    name_en VARCHAR(63),
    name_ko VARCHAR(63),
    upper_category_code VARCHAR(96),
    confidence_score NUMERIC(3, 2),
    is_verified BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        c.category_code,
        c.name_en,
        c.name_ko,
        c.upper_category_code,
        mc.confidence_score,
        mc.is_verified
    FROM public.map_category mc
    JOIN public.categories c ON mc.category_code = c.category_code
    WHERE mc.source_type = p_source_type
      AND mc.source_id = p_source_id
    ORDER BY mc.confidence_score DESC NULLS LAST, mc.order_num;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 카테고리의 콘텐츠 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_content_for_category(
    p_category_code VARCHAR(96),
    p_source_type VARCHAR(50) DEFAULT NULL,
    p_verified_only BOOLEAN DEFAULT FALSE,
    p_include_subcategories BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    source_type VARCHAR(50),
    source_id VARCHAR(1023),
    category_code VARCHAR(96),
    confidence_score NUMERIC(3, 2),
    is_verified BOOLEAN,
    added_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        mc.source_type,
        mc.source_id,
        mc.category_code,
        mc.confidence_score,
        mc.is_verified,
        mc.added_at
    FROM public.map_category mc
    WHERE (
        mc.category_code = p_category_code
        OR (
            p_include_subcategories = TRUE
            AND mc.category_code IN (
                SELECT c.category_code
                FROM public.categories c
                WHERE c.upper_category_code = p_category_code
            )
        )
    )
      AND (p_source_type IS NULL OR mc.source_type = p_source_type)
      AND (NOT p_verified_only OR mc.is_verified = TRUE)
    ORDER BY mc.order_num, mc.added_at DESC;
$$;