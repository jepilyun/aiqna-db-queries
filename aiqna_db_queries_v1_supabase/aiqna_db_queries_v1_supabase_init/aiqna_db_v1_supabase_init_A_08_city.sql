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
  etc VARCHAR(1023) NULL,
  
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









/*
 ***********************************************************************************************
 * TABLE: map_city
 *  - AI로 추출된 도시 정보와 콘텐츠 매핑
 *  - 수동 정렬(order_num) 및 등록시각(added_at) 포함
 ***********************************************************************************************
 */
CREATE TABLE public.map_city (
  city_code VARCHAR(96) NOT NULL,
  source_type VARCHAR(50) NOT NULL,
  source_id VARCHAR(1023) NOT NULL,

  -- AI 추출 정보
  confidence_score NUMERIC(3, 2) NULL,  -- 0.00 ~ 1.00
  extracted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  extraction_method VARCHAR(50) NULL,  -- 'gpt-4', 'claude', 'manual' 등
  
  -- 관리 정보
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,  -- 수동 검증 여부
  verified_at TIMESTAMP WITH TIME ZONE NULL,
  verified_by VARCHAR(511) NULL,
  
  is_selected BOOLEAN NOT NULL DEFAULT FALSE,
  order_num INTEGER NOT NULL DEFAULT 0,
  added_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CONSTRAINT map_city_pkey
    PRIMARY KEY (city_code, source_type, source_id),

  CONSTRAINT map_city_city_code_fkey
    FOREIGN KEY (city_code) 
    REFERENCES public.cities (city_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT map_city_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT map_city_order_num_check CHECK (order_num >= 0),
  
  CONSTRAINT map_city_confidence_check 
    CHECK (confidence_score IS NULL OR (confidence_score BETWEEN 0 AND 1))
) TABLESPACE pg_default;

-- =============================================================================================
-- Indexes
-- =============================================================================================

-- 도시별 콘텐츠 목록 조회 (순서 정렬)
CREATE INDEX IF NOT EXISTS map_city_code_order_idx
  ON public.map_city (city_code, order_num, source_id);

-- 최신 등록순 조회
CREATE INDEX IF NOT EXISTS map_city_code_added_idx
  ON public.map_city (city_code, added_at DESC, source_id);

-- 선택된 항목 빠른 조회
CREATE INDEX IF NOT EXISTS map_city_selected_idx
  ON public.map_city (city_code, order_num, added_at DESC)
  WHERE is_selected = TRUE;

-- 검증된 항목 조회
CREATE INDEX IF NOT EXISTS map_city_verified_idx
  ON public.map_city (city_code, confidence_score DESC)
  WHERE is_verified = TRUE;

-- 역방향 탐색 (특정 콘텐츠가 매핑된 도시들)
CREATE INDEX IF NOT EXISTS map_city_source_idx
  ON public.map_city (source_type, source_id, city_code);

-- 소스 타입별 조회
CREATE INDEX IF NOT EXISTS map_city_source_type_idx
  ON public.map_city (source_type, added_at DESC);

-- 신뢰도 높은 항목 조회
CREATE INDEX IF NOT EXISTS map_city_confidence_idx
  ON public.map_city (confidence_score DESC)
  WHERE confidence_score >= 0.8;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.map_city ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "map_city are visible to everyone"
  ON public.map_city FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage map_city"
  ON public.map_city FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_map_city_updated_at
  BEFORE UPDATE ON public.map_city
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




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

