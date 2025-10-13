/*
 * aiqna db for web service (STags and Mapping Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */



/*
 ***********************************************************************************************
 * TABLE: stags (Semantic Tags)
 ***********************************************************************************************
 */
CREATE TABLE public.stags (
  stag_code           VARCHAR(96)   PRIMARY KEY,
  target_country_code VARCHAR(2)    NOT NULL DEFAULT 'AA',
  
  name_en             VARCHAR(63)   NOT NULL,
  name_native         VARCHAR(63)   NULL,
  order_num           INTEGER       NOT NULL DEFAULT 0,
  
  description_en      VARCHAR(1023) NULL,
  url_en              VARCHAR(511)  NULL,
  img_url             VARCHAR(255)  NULL,
  
  -- 소셜 미디어
  youtube_ch_id       VARCHAR(48)   NULL,
  instagram_id        VARCHAR(48)   NULL,
  tiktok_id           VARCHAR(48)   NULL,

  -- 위도/경도
  latitude  NUMERIC(10, 8) NULL,
  longitude NUMERIC(11, 8) NULL,

  -- 자동 생성되는 지리 객체 컬럼
  location GEOGRAPHY(POINT, 4326)
    GENERATED ALWAYS AS (
      CASE 
        WHEN latitude IS NOT NULL AND longitude IS NOT NULL 
        THEN geography(ST_SetSRID(ST_MakePoint(longitude, latitude), 4326))
        ELSE NULL
      END
    ) STORED,

  radius_m       INTEGER       NULL,

  address_en        VARCHAR(255)  NULL,
  address_native    VARCHAR(255)  NULL,
  google_map_url    VARCHAR(255)  NULL,

  -- 시스템 정보
  created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_by          VARCHAR(511)  NULL,
  updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
  deactivated_at      TIMESTAMP WITH TIME ZONE NULL,
  deactivated_by      VARCHAR(511)  NULL,
  is_display          BOOLEAN       NOT NULL DEFAULT TRUE,

  -- 썸네일
  thumbnail_main_1    VARCHAR(1023) NULL,
  thumbnail_main_2    VARCHAR(1023) NULL,
  thumbnail_main_3    VARCHAR(1023) NULL,
  thumbnail_main_4    VARCHAR(1023) NULL,
  thumbnail_main_5    VARCHAR(1023) NULL,

  thumbnail_1         VARCHAR(1023) NULL,
  thumbnail_2         VARCHAR(1023) NULL,
  thumbnail_3         VARCHAR(1023) NULL,
  thumbnail_4         VARCHAR(1023) NULL,
  thumbnail_5         VARCHAR(1023) NULL,

  thumbnail_vertical_1 VARCHAR(1023) NULL,
  thumbnail_vertical_2 VARCHAR(1023) NULL,
  thumbnail_vertical_3 VARCHAR(1023) NULL,
  thumbnail_vertical_4 VARCHAR(1023) NULL,
  thumbnail_vertical_5 VARCHAR(1023) NULL,

  -- 외래키
  CONSTRAINT stags_target_country_code_fkey
    FOREIGN KEY (target_country_code)
    REFERENCES public.countries (country_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  -- 제약조건
  CONSTRAINT stags_order_num_check CHECK (order_num >= 0)
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 이름 검색 최적화
CREATE INDEX IF NOT EXISTS stags_name_en_trgm_idx
  ON public.stags USING gin (name_en gin_trgm_ops);

CREATE INDEX IF NOT EXISTS stags_name_native_trgm_idx
  ON public.stags USING gin (name_native gin_trgm_ops)
  WHERE name_native IS NOT NULL;

-- 설명 검색
CREATE INDEX IF NOT EXISTS stags_desc_en_trgm_idx
  ON public.stags USING gin (description_en gin_trgm_ops)
  WHERE description_en IS NOT NULL;

-- 국가별 태그
CREATE INDEX IF NOT EXISTS stags_country_order_idx
  ON public.stags (target_country_code, order_num, stag_code);

-- 활성/표시 필터
CREATE INDEX IF NOT EXISTS stags_active_display_idx
  ON public.stags (is_active, is_display, order_num)
  WHERE is_active = TRUE AND is_display = TRUE;

-- 정렬 순서
CREATE INDEX IF NOT EXISTS stags_order_idx
  ON public.stags (order_num, stag_code);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.stags ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "stags are visible to everyone"
  ON public.stags FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage stags"
  ON public.stags FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_stags_updated_at
  BEFORE UPDATE ON public.stags
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




/*
 ***********************************************************************************************
 * TABLE: stag_i18n
 ***********************************************************************************************
 */
CREATE TABLE public.stag_i18n (
  stag_code        VARCHAR(96)   NOT NULL,
  lang_code        VARCHAR(8)    NOT NULL,
  name_i18n        VARCHAR(255)  NOT NULL,
  description_i18n VARCHAR(1023) NULL,
  
  created_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CONSTRAINT stag_i18n_pkey PRIMARY KEY (stag_code, lang_code),
  
  CONSTRAINT stag_i18n_stag_code_fkey
    FOREIGN KEY (stag_code) 
    REFERENCES public.stags (stag_code)
    ON UPDATE CASCADE ON DELETE CASCADE,
    
  CONSTRAINT stag_i18n_lang_code_fkey
    FOREIGN KEY (lang_code) 
    REFERENCES public.languages (lang_code)
    ON UPDATE CASCADE ON DELETE CASCADE
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 부분/유사 검색 최적화
CREATE INDEX IF NOT EXISTS stag_i18n_name_trgm_idx
  ON public.stag_i18n USING gin (name_i18n gin_trgm_ops);

-- 언어별 역방향 조회
CREATE INDEX IF NOT EXISTS stag_i18n_lang_idx
  ON public.stag_i18n (lang_code);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.stag_i18n ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "stag_i18n are visible to everyone"
  ON public.stag_i18n FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage stag_i18n"
  ON public.stag_i18n FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_stag_i18n_updated_at
  BEFORE UPDATE ON public.stag_i18n
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();







/*
 ***********************************************************************************************
 * TABLE: map_stag
 *  - AI로 추출된 의미론적 태그와 콘텐츠 매핑
 ***********************************************************************************************
 */
CREATE TABLE public.map_stag (
  stag_code VARCHAR(96) NOT NULL,
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

  CONSTRAINT map_stag_pkey
    PRIMARY KEY (stag_code, source_type, source_id),

  CONSTRAINT map_stag_stag_code_fkey
    FOREIGN KEY (stag_code) 
    REFERENCES public.stags (stag_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT map_stag_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT map_stag_order_num_check CHECK (order_num >= 0),
  
  CONSTRAINT map_stag_confidence_check 
    CHECK (confidence_score IS NULL OR (confidence_score BETWEEN 0 AND 1))
) TABLESPACE pg_default;

-- =============================================================================================
-- Indexes
-- =============================================================================================

-- 태그별 콘텐츠 목록 조회
CREATE INDEX IF NOT EXISTS map_stag_code_order_idx
  ON public.map_stag (stag_code, order_num, source_id);

-- 최신 등록순 조회
CREATE INDEX IF NOT EXISTS map_stag_code_added_idx
  ON public.map_stag (stag_code, added_at DESC, source_id);

-- 선택된 항목 빠른 조회
CREATE INDEX IF NOT EXISTS map_stag_selected_idx
  ON public.map_stag (stag_code, order_num, added_at DESC)
  WHERE is_selected = TRUE;

-- 검증된 항목 조회
CREATE INDEX IF NOT EXISTS map_stag_verified_idx
  ON public.map_stag (stag_code, confidence_score DESC)
  WHERE is_verified = TRUE;

-- 역방향 탐색 (특정 콘텐츠가 매핑된 태그들)
CREATE INDEX IF NOT EXISTS map_stag_source_idx
  ON public.map_stag (source_type, source_id, stag_code);

-- 소스 타입별 조회
CREATE INDEX IF NOT EXISTS map_stag_source_type_idx
  ON public.map_stag (source_type, added_at DESC);

-- 신뢰도 높은 항목 조회
CREATE INDEX IF NOT EXISTS map_stag_confidence_idx
  ON public.map_stag (confidence_score DESC)
  WHERE confidence_score >= 0.8;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.map_stag ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "map_stag are visible to everyone"
  ON public.map_stag FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage map_stag"
  ON public.map_stag FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_map_stag_updated_at
  BEFORE UPDATE ON public.map_stag
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: AI 추출 태그 매핑 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.upsert_stag_mapping(
    p_stag_code VARCHAR(96),
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
    INSERT INTO public.map_stag (
        stag_code,
        source_type,
        source_id,
        confidence_score,
        extraction_method,
        extracted_at
    ) VALUES (
        p_stag_code,
        p_source_type,
        p_source_id,
        p_confidence_score,
        p_extraction_method,
        NOW()
    )
    ON CONFLICT (stag_code, source_type, source_id) DO UPDATE SET
        confidence_score = EXCLUDED.confidence_score,
        extraction_method = EXCLUDED.extraction_method,
        extracted_at = NOW(),
        updated_at = NOW();
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 콘텐츠의 태그 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_stags_for_content(
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(1023),
    p_min_confidence NUMERIC(3, 2) DEFAULT 0.5
)
RETURNS TABLE (
    stag_code VARCHAR(96),
    name_en VARCHAR(63),
    name_native VARCHAR(63),
    confidence_score NUMERIC(3, 2),
    is_verified BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        s.stag_code,
        s.name_en,
        s.name_native,
        ms.confidence_score,
        ms.is_verified
    FROM public.map_stag ms
    JOIN public.stags s ON ms.stag_code = s.stag_code
    WHERE ms.source_type = p_source_type
      AND ms.source_id = p_source_id
      AND (ms.confidence_score IS NULL OR ms.confidence_score >= p_min_confidence)
    ORDER BY ms.confidence_score DESC NULLS LAST, ms.order_num;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 태그의 콘텐츠 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_content_for_stag(
    p_stag_code VARCHAR(96),
    p_source_type VARCHAR(50) DEFAULT NULL,
    p_verified_only BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    source_type VARCHAR(50),
    source_id VARCHAR(1023),
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
        ms.source_type,
        ms.source_id,
        ms.confidence_score,
        ms.is_verified,
        ms.added_at
    FROM public.map_stag ms
    WHERE ms.stag_code = p_stag_code
      AND (p_source_type IS NULL OR ms.source_type = p_source_type)
      AND (NOT p_verified_only OR ms.is_verified = TRUE)
    ORDER BY ms.order_num, ms.added_at DESC;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 태그 클라우드 생성 (인기 태그)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_popular_stags(
    p_source_type VARCHAR(50) DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_min_count INTEGER DEFAULT 1
)
RETURNS TABLE (
    stag_code VARCHAR(96),
    name_en VARCHAR(63),
    name_native VARCHAR(63),
    content_count BIGINT,
    avg_confidence NUMERIC(5, 2)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        s.stag_code,
        s.name_en,
        s.name_native,
        COUNT(ms.source_id) AS content_count,
        ROUND(AVG(ms.confidence_score), 2) AS avg_confidence
    FROM public.stags s
    JOIN public.map_stag ms ON s.stag_code = ms.stag_code
    WHERE (p_source_type IS NULL OR ms.source_type = p_source_type)
      AND s.is_active = TRUE
      AND s.is_display = TRUE
    GROUP BY s.stag_code, s.name_en, s.name_native
    HAVING COUNT(ms.source_id) >= p_min_count
    ORDER BY content_count DESC, avg_confidence DESC NULLS LAST
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 관련 태그 찾기 (동시 출현 기반)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_related_stags(
    p_stag_code VARCHAR(96),
    p_source_type VARCHAR(50) DEFAULT NULL,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    related_stag_code VARCHAR(96),
    name_en VARCHAR(63),
    co_occurrence_count BIGINT,
    relevance_score NUMERIC(5, 2)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    WITH target_content AS (
        -- 기준 태그가 있는 콘텐츠들
        SELECT source_type, source_id
        FROM public.map_stag
        WHERE stag_code = p_stag_code
          AND (p_source_type IS NULL OR source_type = p_source_type)
    ),
    co_occurring_tags AS (
        -- 같은 콘텐츠에 함께 나타나는 다른 태그들
        SELECT 
            ms.stag_code,
            COUNT(*) AS co_count
        FROM public.map_stag ms
        JOIN target_content tc 
          ON ms.source_type = tc.source_type 
          AND ms.source_id = tc.source_id
        WHERE ms.stag_code != p_stag_code
        GROUP BY ms.stag_code
    )
    SELECT 
        s.stag_code AS related_stag_code,
        s.name_en,
        cot.co_count AS co_occurrence_count,
        ROUND(
            (cot.co_count::NUMERIC / NULLIF(total_target.cnt, 0)) * 100, 
            2
        ) AS relevance_score
    FROM co_occurring_tags cot
    JOIN public.stags s ON cot.stag_code = s.stag_code
    CROSS JOIN (
        SELECT COUNT(*) AS cnt FROM target_content
    ) AS total_target
    WHERE s.is_active = TRUE AND s.is_display = TRUE
    ORDER BY co_occurrence_count DESC
    LIMIT p_limit;
$$;