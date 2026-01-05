/*
 * aiqna db for web service (Cities and Mapping Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */



/*
 ***********************************************************************************************
 * TABLE: cities (개선된 버전)
 ***********************************************************************************************
 */
CREATE TABLE public.cities (
  country_code VARCHAR(2) NULL,
  city_code VARCHAR(96) NOT NULL,
  name_en VARCHAR(255) NOT NULL,
  name_native VARCHAR(255) NULL,
  name_ko VARCHAR(255) NULL,
  order_num SMALLINT NOT NULL DEFAULT 0,
  description_en VARCHAR(1023) NULL,
  description_native VARCHAR(1023) NULL,
  google_place_id VARCHAR(63) NULL,
  official_web VARCHAR(255) NULL,
  official_web_tour VARCHAR(255) NULL,
  youtube_official_id VARCHAR(48) NULL,
  youtube_tour_id VARCHAR(48) NULL,
  tiktok_official_id VARCHAR(48) NULL,
  tiktok_tour_id VARCHAR(48) NULL,
  instagram_official_id VARCHAR(48) NULL,
  instagram_tour_id VARCHAR(48) NULL,
  instagram_tags VARCHAR(31)[] NULL,
  
  -- 위도/경도 (기본 컬럼)
  latitude NUMERIC(10, 8) NULL,
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

  radius_m INTEGER NULL,
  address_en VARCHAR(255) NULL,
  address_native VARCHAR(255) NULL,
  google_map_url VARCHAR(255) NULL,
  naver_map_url VARCHAR(255) NULL,
  etc TEXT NULL,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_by VARCHAR(511) NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  is_active BOOLEAN NOT NULL DEFAULT FALSE,
  deactivated_at TIMESTAMP WITH TIME ZONE NULL,
  deactivated_by VARCHAR(511) NULL,
  is_display BOOLEAN NOT NULL DEFAULT TRUE,

  thumbnail_main_1 VARCHAR(1023) NULL,
  thumbnail_main_2 VARCHAR(1023) NULL,
  thumbnail_main_3 VARCHAR(1023) NULL,
  thumbnail_main_4 VARCHAR(1023) NULL,
  thumbnail_main_5 VARCHAR(1023) NULL,

  thumbnail_1 VARCHAR(1023) NULL,
  thumbnail_2 VARCHAR(1023) NULL,
  thumbnail_3 VARCHAR(1023) NULL,
  thumbnail_4 VARCHAR(1023) NULL,
  thumbnail_5 VARCHAR(1023) NULL,

  thumbnail_vertical_1 VARCHAR(1023) NULL,
  thumbnail_vertical_2 VARCHAR(1023) NULL,
  thumbnail_vertical_3 VARCHAR(1023) NULL,
  thumbnail_vertical_4 VARCHAR(1023) NULL,
  thumbnail_vertical_5 VARCHAR(1023) NULL,

  CONSTRAINT cities_pkey PRIMARY KEY (city_code),
  CONSTRAINT cities_country_code_fkey 
    FOREIGN KEY (country_code) 
    REFERENCES countries (country_code) 
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT cities_radius_m_check CHECK (radius_m IS NULL OR radius_m >= 0),
  CONSTRAINT cities_latitude_check CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
  CONSTRAINT cities_longitude_check CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
  CONSTRAINT cities_order_num_check CHECK (order_num >= 0)
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 이름 검색 최적화
CREATE INDEX IF NOT EXISTS cities_name_en_trgm_idx
  ON public.cities USING gin (name_en gin_trgm_ops);

CREATE INDEX IF NOT EXISTS cities_name_ko_trgm_idx
  ON public.cities USING gin (name_ko gin_trgm_ops);

CREATE INDEX IF NOT EXISTS cities_name_native_trgm_idx
  ON public.cities USING gin (name_native gin_trgm_ops);

-- 지리 검색 최적화
CREATE INDEX IF NOT EXISTS cities_location_gist_idx 
  ON public.cities USING GIST (location)
  WHERE location IS NOT NULL;

-- 좌표 복합 인덱스
CREATE INDEX IF NOT EXISTS cities_lat_lng_idx 
  ON public.cities (latitude, longitude)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- 국가별 도시 조회
CREATE INDEX IF NOT EXISTS cities_country_code_idx
  ON public.cities (country_code);

-- 활성 도시 필터링
CREATE INDEX IF NOT EXISTS cities_is_active_idx
  ON public.cities (is_active, order_num)
  WHERE is_active = TRUE;

-- 표시 가능한 도시
CREATE INDEX IF NOT EXISTS cities_is_display_idx
  ON public.cities (is_display, order_num)
  WHERE is_display = TRUE;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "cities are visible to everyone" 
  ON cities FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage cities" 
  ON cities FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_cities_updated_at
  BEFORE UPDATE ON public.cities
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: get_city_name
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_city_name(p_city_code VARCHAR(96))
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT COALESCE(
        (
        SELECT jsonb_build_object(
            'city_code',   c.city_code,
            'name_en',     c.name_en,
            'name_native', c.name_native,
            'name_ko',     c.name_ko
        )
        FROM public.cities AS c
        WHERE c.city_code = p_city_code
        ),
        '{}'::jsonb
    );
$$;






/*
 ***********************************************************************************************
 * TABLE: city_i18n
 ***********************************************************************************************
 */
CREATE TABLE public.city_i18n (
  city_code VARCHAR(96) NOT NULL,
  lang_code VARCHAR(8) NOT NULL,
  name_i18n VARCHAR(255) NOT NULL,
  description_i18n VARCHAR(1023) NULL,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT city_i18n_pkey PRIMARY KEY (city_code, lang_code),
  CONSTRAINT city_i18n_city_code_fkey
    FOREIGN KEY (city_code) 
    REFERENCES public.cities (city_code)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT city_i18n_lang_code_fkey
    FOREIGN KEY (lang_code) 
    REFERENCES public.languages (lang_code)
    ON UPDATE CASCADE ON DELETE CASCADE
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 부분/유사 검색 최적화
CREATE INDEX IF NOT EXISTS city_i18n_name_trgm_idx
  ON public.city_i18n USING gin (name_i18n gin_trgm_ops);

-- 언어별 역방향 조회
CREATE INDEX IF NOT EXISTS city_i18n_lang_idx
  ON public.city_i18n (lang_code);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.city_i18n ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "city_i18n are visible to everyone"
  ON public.city_i18n FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage city_i18n"
  ON public.city_i18n FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_city_i18n_updated_at
  BEFORE UPDATE ON public.city_i18n
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();






-- ============================================================================
-- TABLE: map_city_search_keywords
-- ============================================================================
-- 설명: 도시별 검색 키워드 매핑 (내부 검색용)
-- 용도: "Seoul", "서울", "서울시" → "KR-11" 매핑
-- 접근: authenticated, anon 모두 조회 가능, service_role만 관리 가능
-- ============================================================================
CREATE TABLE public.map_city_search_keywords (
    city_code VARCHAR(96) NOT NULL,
    search_keyword VARCHAR(100) NOT NULL,
    
    -- 추가 필드
    lang_code VARCHAR(12) NULL,                    -- 키워드 언어 (ko, en, zh 등)
    keyword_type VARCHAR(20) NOT NULL DEFAULT 'name',  -- 키워드 유형
    is_primary BOOLEAN NOT NULL DEFAULT false,     -- 대표 키워드 여부 (검색 결과 표시용)
    priority SMALLINT NOT NULL DEFAULT 0,          -- 우선순위 (높을수록 먼저 매칭)
    
    -- 메타 필드
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    added_by VARCHAR(45) NULL,
    
    CONSTRAINT map_city_search_keywords_pkey 
        PRIMARY KEY (city_code, search_keyword),
    CONSTRAINT map_city_search_keywords_city_code_fkey 
        FOREIGN KEY (city_code) 
        REFERENCES public.cities (city_code) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,
    CONSTRAINT map_city_search_keywords_type_check 
        CHECK (keyword_type IN ('name', 'native', 'alias', 'code', 'abbreviation', 'district', 'old_name')),
    CONSTRAINT map_city_search_keywords_priority_check
        CHECK (priority >= 0)
) TABLESPACE pg_default;

ALTER TABLE public.map_city_search_keywords ENABLE ROW LEVEL SECURITY;

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_mcsq_city_code
    ON public.map_city_search_keywords (city_code);
CREATE INDEX IF NOT EXISTS idx_mcsq_search_keyword
    ON public.map_city_search_keywords (search_keyword);
CREATE INDEX IF NOT EXISTS idx_mcsq_search_keyword_lower
    ON public.map_city_search_keywords (LOWER(search_keyword));  -- 대소문자 무시 검색용
CREATE INDEX IF NOT EXISTS idx_mcsq_lang_code
    ON public.map_city_search_keywords (lang_code) WHERE lang_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_mcsq_is_primary
    ON public.map_city_search_keywords (is_primary) WHERE is_primary = true;

-- RLS 정책
CREATE POLICY "map_city_search_keywords are visible to everyone" 
    ON public.map_city_search_keywords FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

CREATE POLICY "Service role can manage map_city_search_keywords" 
    ON public.map_city_search_keywords FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);






-- ============================================================================
-- TABLE: map_city
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.map_city (
    -- ========================================
    -- 기본 키
    -- ========================================
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- ========================================
    -- 매핑 정보
    -- ========================================
    city_code VARCHAR(96) NOT NULL,
    source_type VARCHAR(50) NOT NULL,
    
    -- 타입별 ID (source_type에 따라 하나만 NOT NULL)
    youtube_video_id VARCHAR(20) NULL,
    instagram_post_id VARCHAR(50) NULL,
    blog_post_id BIGINT NULL,
    text_content_id BIGINT NULL,
    
    -- ========================================
    -- AI 추출 정보
    -- ========================================
    confidence_score NUMERIC(3,2) NULL,
    extraction_method VARCHAR(50) NULL,
    extracted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- ========================================
    -- 검증 정보
    -- ========================================
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at TIMESTAMPTZ NULL,
    verified_by VARCHAR(255) NULL,
    
    -- ========================================
    -- 표시 순서
    -- ========================================
    is_selected BOOLEAN NOT NULL DEFAULT FALSE,
    order_num INTEGER NOT NULL DEFAULT 0,
    
    -- ========================================
    -- 시스템 타임스탬프
    -- ========================================
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- ========================================
    -- 제약조건
    -- ========================================
    CONSTRAINT mc_city_code_fkey
        FOREIGN KEY (city_code) 
        REFERENCES public.cities (city_code)
        ON UPDATE CASCADE ON DELETE CASCADE,
    
    CONSTRAINT mc_youtube_video_id_fkey
        FOREIGN KEY (youtube_video_id) 
        REFERENCES public.youtube_video (video_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    
    CONSTRAINT mc_instagram_post_id_fkey
        FOREIGN KEY (instagram_post_id) 
        REFERENCES public.instagram_post (post_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    
    CONSTRAINT mc_blog_post_id_fkey
        FOREIGN KEY (blog_post_id) 
        REFERENCES public.blog_post (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    
    CONSTRAINT mc_text_content_id_fkey
        FOREIGN KEY (text_content_id) 
        REFERENCES public.text_content (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    
    CONSTRAINT mc_source_type_check 
        CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text_content')),
    
    CONSTRAINT mc_one_source_id_check 
        CHECK (
            (source_type = 'youtube_video' 
            AND youtube_video_id IS NOT NULL 
            AND instagram_post_id IS NULL 
            AND blog_post_id IS NULL 
            AND text_content_id IS NULL)
            OR
            (source_type = 'instagram_post' 
            AND instagram_post_id IS NOT NULL 
            AND youtube_video_id IS NULL 
            AND blog_post_id IS NULL 
            AND text_content_id IS NULL)
            OR
            (source_type = 'blog_post' 
            AND blog_post_id IS NOT NULL 
            AND youtube_video_id IS NULL 
            AND instagram_post_id IS NULL 
            AND text_content_id IS NULL)
            OR
            (source_type = 'text_content' 
            AND text_content_id IS NOT NULL 
            AND youtube_video_id IS NULL 
            AND instagram_post_id IS NULL 
            AND blog_post_id IS NULL)
        ),
    
    CONSTRAINT mc_mapping_unique 
        UNIQUE (city_code, source_type, 
                COALESCE(youtube_video_id, 
                        instagram_post_id, 
                        blog_post_id::TEXT, 
                        text_content_id::TEXT)),
    
    CONSTRAINT mc_order_num_check 
        CHECK (order_num >= 0),
    
    CONSTRAINT mc_confidence_check 
        CHECK (confidence_score IS NULL OR (confidence_score >= 0 AND confidence_score <= 1)),
    
    CONSTRAINT mc_verified_logic_check
        CHECK (
            (is_verified = FALSE AND verified_at IS NULL AND verified_by IS NULL)
            OR
            (is_verified = TRUE AND verified_at IS NOT NULL)
        )
) TABLESPACE pg_default;

-- ========================================
-- 인덱스: map_city
-- ========================================
-- 기본 매핑 인덱스
CREATE INDEX IF NOT EXISTS idx_mc_city_order 
    ON public.map_city (city_code, order_num);

CREATE INDEX IF NOT EXISTS idx_mc_city_added 
    ON public.map_city (city_code, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_mc_selected 
    ON public.map_city (city_code, order_num) 
    WHERE is_selected = TRUE;

CREATE INDEX IF NOT EXISTS idx_mc_verified 
    ON public.map_city (city_code, confidence_score DESC) 
    WHERE is_verified = TRUE;

-- 소스별 역방향 인덱스
CREATE INDEX IF NOT EXISTS idx_mc_youtube_video 
    ON public.map_city (youtube_video_id, city_code) 
    WHERE youtube_video_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_mc_instagram_post 
    ON public.map_city (instagram_post_id, city_code) 
    WHERE instagram_post_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_mc_blog_post 
    ON public.map_city (blog_post_id, city_code) 
    WHERE blog_post_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_mc_text_content 
    ON public.map_city (text_content_id, city_code) 
    WHERE text_content_id IS NOT NULL;

-- 소스 타입별 인덱스
CREATE INDEX IF NOT EXISTS idx_mc_source_type 
    ON public.map_city (source_type, created_at DESC);

-- 신뢰도 인덱스
CREATE INDEX IF NOT EXISTS idx_mc_high_confidence 
    ON public.map_city (city_code, confidence_score DESC) 
    WHERE confidence_score >= 0.8;

CREATE INDEX IF NOT EXISTS idx_mc_low_confidence 
    ON public.map_city (city_code, confidence_score ASC) 
    WHERE confidence_score < 0.7 AND is_verified = FALSE;

-- 검증자별 조회
CREATE INDEX IF NOT EXISTS idx_mc_verified_by 
    ON public.map_city (verified_by, verified_at DESC) 
    WHERE verified_by IS NOT NULL;

-- 추출 방법별 통계/분석용
CREATE INDEX IF NOT EXISTS idx_mc_extraction_method 
    ON public.map_city (extraction_method, extracted_at DESC) 
    WHERE extraction_method IS NOT NULL;

-- 최근 추출 인덱스
CREATE INDEX IF NOT EXISTS idx_mc_recently_extracted 
    ON public.map_city (extracted_at DESC) 
    WHERE extracted_at > NOW() - INTERVAL '7 days';

-- ========================================
-- RLS: map_city
-- ========================================
ALTER TABLE public.map_city ENABLE ROW LEVEL SECURITY;

CREATE POLICY "map_city is visible to everyone"
    ON public.map_city FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

CREATE POLICY "Service role can manage map_city"
    ON public.map_city FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- ========================================
-- 트리거: map_city updated_at
-- ========================================
CREATE OR REPLACE FUNCTION public.update_map_city_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_mc_updated_at
    BEFORE UPDATE ON public.map_city
    FOR EACH ROW
    EXECUTE FUNCTION public.update_map_city_updated_at();






-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: AI 추출 도시 정보 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.upsert_city_mapping(
    p_city_code VARCHAR(96),
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
    INSERT INTO public.map_city (
        city_code,
        source_type,
        source_id,
        confidence_score,
        extraction_method,
        extracted_at
    ) VALUES (
        p_city_code,
        p_source_type,
        p_source_id,
        p_confidence_score,
        p_extraction_method,
        NOW()
    )
    ON CONFLICT (city_code, source_type, source_id) DO UPDATE SET
        confidence_score = EXCLUDED.confidence_score,
        extraction_method = EXCLUDED.extraction_method,
        extracted_at = NOW(),
        updated_at = NOW();
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 콘텐츠의 도시 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_cities_for_content(
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(1023)
)
RETURNS TABLE (
    city_code VARCHAR(96),
    name_en VARCHAR(255),
    name_ko VARCHAR(255),
    confidence_score NUMERIC(3, 2),
    is_verified BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        c.city_code,
        c.name_en,
        c.name_ko,
        mc.confidence_score,
        mc.is_verified
    FROM public.map_city mc
    JOIN public.cities c ON mc.city_code = c.city_code
    WHERE mc.source_type = p_source_type
      AND mc.source_id = p_source_id
    ORDER BY mc.confidence_score DESC NULLS LAST, mc.order_num;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 도시의 콘텐츠 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_content_for_city(
    p_city_code VARCHAR(96),
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
        mc.source_type,
        mc.source_id,
        mc.confidence_score,
        mc.is_verified,
        mc.added_at
    FROM public.map_city mc
    WHERE mc.city_code = p_city_code
      AND (p_source_type IS NULL OR mc.source_type = p_source_type)
      AND (NOT p_verified_only OR mc.is_verified = TRUE)
    ORDER BY mc.order_num, mc.added_at DESC;
$$;

