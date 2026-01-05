/*
 * aiqna db for web service (Streets and Mapping Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */



/*
 ***********************************************************************************************
 * TABLE: districts
 ***********************************************************************************************
 */
CREATE TABLE public.districts (
  country_code   VARCHAR(2)    NULL,
  city_code      VARCHAR(96)   NULL,
  district_code  VARCHAR(96)   NOT NULL,
  name_en        VARCHAR(100)  NOT NULL,
  name_native    VARCHAR(100)  NULL,
  name_ko        VARCHAR(100)  NULL,
  order_num      SMALLINT      NOT NULL DEFAULT 0,
  url_en         VARCHAR(511)  NULL,
  url_native     VARCHAR(511)  NULL,
  description_en VARCHAR(1023) NULL,
  description_native VARCHAR(1023) NULL,
  google_place_id VARCHAR(63) NULL,
  youtube_ch_id  VARCHAR(48)   NULL,
  instagram_id   VARCHAR(48)   NULL,

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
  address_en     VARCHAR(255)  NULL,
  address_native VARCHAR(255)  NULL,
  google_map_url VARCHAR(255)  NULL,
  naver_map_url  VARCHAR(255)  NULL,

  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_by VARCHAR(511) NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  is_active  BOOLEAN NOT NULL DEFAULT TRUE,
  deactivated_at TIMESTAMP WITH TIME ZONE NULL,
  deactivated_by VARCHAR(511) NULL,
  is_display BOOLEAN NOT NULL DEFAULT TRUE,

  thumbnail_main_1 VARCHAR(1023) NULL,
  thumbnail_main_2 VARCHAR(1023) NULL,
  thumbnail_main_3 VARCHAR(1023) NULL,
  thumbnail_main_4 VARCHAR(1023) NULL,
  thumbnail_main_5 VARCHAR(1023) NULL,

  thumbnail_1      VARCHAR(1023) NULL,
  thumbnail_2      VARCHAR(1023) NULL,
  thumbnail_3      VARCHAR(1023) NULL,
  thumbnail_4      VARCHAR(1023) NULL,
  thumbnail_5      VARCHAR(1023) NULL,

  thumbnail_vertical_1 VARCHAR(1023) NULL,
  thumbnail_vertical_2 VARCHAR(1023) NULL,
  thumbnail_vertical_3 VARCHAR(1023) NULL,
  thumbnail_vertical_4 VARCHAR(1023) NULL,
  thumbnail_vertical_5 VARCHAR(1023) NULL,

  CONSTRAINT districts_pkey PRIMARY KEY (district_code),

  CONSTRAINT districts_country_code_fkey
    FOREIGN KEY (country_code)
    REFERENCES public.countries (country_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT districts_city_code_fkey
    FOREIGN KEY (city_code)
    REFERENCES public.cities (city_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  -- 값 검증
  CONSTRAINT districts_radius_m_check CHECK (radius_m IS NULL OR radius_m >= 0),
  CONSTRAINT districts_latitude_check CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
  CONSTRAINT districts_longitude_check CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
  CONSTRAINT districts_order_num_check CHECK (order_num >= 0)
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 도시별 거리 목록 정렬
CREATE INDEX IF NOT EXISTS districts_city_order_idx
  ON public.districts (city_code, order_num, district_code);

-- 국가별 거리 목록
CREATE INDEX IF NOT EXISTS districts_country_idx
  ON public.districts (country_code);

-- 활성/노출 필터
CREATE INDEX IF NOT EXISTS districts_city_active_display_idx
  ON public.districts (city_code, is_active, is_display)
  WHERE is_active = TRUE AND is_display = TRUE;

-- 활성 거리만
CREATE INDEX IF NOT EXISTS districts_is_active_idx
  ON public.districts (is_active, order_num)
  WHERE is_active = TRUE;

-- 지오 검색
CREATE INDEX IF NOT EXISTS districts_location_gist_idx
  ON public.districts USING GIST (location)
  WHERE location IS NOT NULL;

-- 위/경도 복합 인덱스
CREATE INDEX IF NOT EXISTS districts_lat_lng_idx
  ON public.districts (latitude, longitude)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- 이름 검색 최적화 (다국어)
CREATE INDEX IF NOT EXISTS districts_name_en_trgm_idx
  ON public.districts USING gin (name_en gin_trgm_ops);

CREATE INDEX IF NOT EXISTS districts_name_ko_trgm_idx
  ON public.districts USING gin (name_ko gin_trgm_ops)
  WHERE name_ko IS NOT NULL;

CREATE INDEX IF NOT EXISTS districts_name_native_trgm_idx
  ON public.districts USING gin (name_native gin_trgm_ops)
  WHERE name_native IS NOT NULL;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.districts ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "districts are visible to everyone"
  ON public.districts FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage districts"
  ON public.districts FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_districts_updated_at
  BEFORE UPDATE ON public.districts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();






/*
 ***********************************************************************************************
 * TABLE: district_i18n
 ***********************************************************************************************
 */
CREATE TABLE public.district_i18n (
  district_code    VARCHAR(96)   NOT NULL,
  lang_code        VARCHAR(8)    NOT NULL,
  name_i18n        VARCHAR(255)  NOT NULL,
  description_i18n VARCHAR(1023) NULL,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT district_i18n_pkey PRIMARY KEY (district_code, lang_code),
  CONSTRAINT district_i18n_district_code_fkey
    FOREIGN KEY (district_code) 
    REFERENCES public.districts (district_code)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT district_i18n_lang_code_fkey
    FOREIGN KEY (lang_code) 
    REFERENCES public.languages (lang_code)
    ON UPDATE CASCADE ON DELETE CASCADE
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 부분/유사 검색 최적화
CREATE INDEX IF NOT EXISTS district_i18n_name_trgm_idx
  ON public.district_i18n USING gin (name_i18n gin_trgm_ops);

-- 언어별 역방향 조회
CREATE INDEX IF NOT EXISTS district_i18n_lang_idx
  ON public.district_i18n (lang_code);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.district_i18n ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "district_i18n are visible to everyone"
  ON public.district_i18n FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage district_i18n"
  ON public.district_i18n FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_district_i18n_updated_at
  BEFORE UPDATE ON public.district_i18n
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();





/*
 ***********************************************************************************************
 * TABLE: map_district_search_keywords
 ***********************************************************************************************
 */
CREATE TABLE public.map_district_search_keywords (
    district_code VARCHAR(96) NOT NULL,
    search_keyword VARCHAR(100) NOT NULL,
    CONSTRAINT map_district_search_keywords_pkey PRIMARY KEY (district_code, search_keyword),
    CONSTRAINT map_district_search_keywords_district_code_fkey 
        FOREIGN KEY (district_code) 
        REFERENCES public.districts (district_code) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE
) TABLESPACE pg_default;

ALTER TABLE public.map_district_search_keywords ENABLE ROW LEVEL SECURITY;

-- map_district_search_keywords
CREATE INDEX IF NOT EXISTS idx_mdsq_district_code
    ON public.map_district_search_keywords (district_code);

-- 모든 사용자가 SELECT 가능
CREATE POLICY "map_district_search_keywords are visible to everyone" 
    ON map_district_search_keywords FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업은 service_role만 가능
CREATE POLICY "Service role can manage map_district_search_keywords" 
    ON map_district_search_keywords FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);






/*
 ***********************************************************************************************
 * TABLE: map_district
 *  - AI로 추출된 거리 정보와 콘텐츠 매핑
 *  - 수동 정렬(order_num) 및 등록시각(added_at) 포함
 ***********************************************************************************************
 */
CREATE TABLE public.map_district (
  district_code VARCHAR(96) NOT NULL,
  source_type VARCHAR(50) NOT NULL,
  source_id VARCHAR(1023) NOT NULL,

  -- AI 추출 정보
  confidence_score NUMERIC(3, 2) NULL,  -- 0.00 ~ 1.00
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

  CONSTRAINT map_district_pkey
    PRIMARY KEY (district_code, source_type, source_id),

  CONSTRAINT map_district_district_code_fkey
    FOREIGN KEY (district_code) 
    REFERENCES public.districts (district_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT map_district_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT map_district_order_num_check CHECK (order_num >= 0),
  
  CONSTRAINT map_district_confidence_check 
    CHECK (confidence_score IS NULL OR (confidence_score BETWEEN 0 AND 1))
) TABLESPACE pg_default;

-- =============================================================================================
-- Indexes
-- =============================================================================================

-- 거리별 콘텐츠 목록 조회 (순서 정렬)
CREATE INDEX IF NOT EXISTS map_district_code_order_idx
  ON public.map_district (district_code, order_num, source_id);

-- 최신 등록순 조회
CREATE INDEX IF NOT EXISTS map_district_code_added_idx
  ON public.map_district (district_code, added_at DESC, source_id);

-- 선택된 항목 빠른 조회
CREATE INDEX IF NOT EXISTS map_district_selected_idx
  ON public.map_district (district_code, order_num, added_at DESC)
  WHERE is_selected = TRUE;

-- 검증된 항목 조회
CREATE INDEX IF NOT EXISTS map_district_verified_idx
  ON public.map_district (district_code, confidence_score DESC)
  WHERE is_verified = TRUE;

-- 역방향 탐색 (특정 콘텐츠가 매핑된 거리들)
CREATE INDEX IF NOT EXISTS map_district_source_idx
  ON public.map_district (source_type, source_id, district_code);

-- 소스 타입별 조회
CREATE INDEX IF NOT EXISTS map_district_source_type_idx
  ON public.map_district (source_type, added_at DESC);

-- 신뢰도 높은 항목 조회
CREATE INDEX IF NOT EXISTS map_district_confidence_idx
  ON public.map_district (confidence_score DESC)
  WHERE confidence_score >= 0.8;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.map_district ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "map_district are visible to everyone"
  ON public.map_district FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage map_district"
  ON public.map_district FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_map_district_updated_at
  BEFORE UPDATE ON public.map_district
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: AI 추출 거리 정보 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.upsert_district_mapping(
    p_district_code VARCHAR(96),
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
    INSERT INTO public.map_district (
        district_code,
        source_type,
        source_id,
        confidence_score,
        extraction_method,
        extracted_at
    ) VALUES (
        p_district_code,
        p_source_type,
        p_source_id,
        p_confidence_score,
        p_extraction_method,
        NOW()
    )
    ON CONFLICT (district_code, source_type, source_id) DO UPDATE SET
        confidence_score = EXCLUDED.confidence_score,
        extraction_method = EXCLUDED.extraction_method,
        extracted_at = NOW(),
        updated_at = NOW();
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 콘텐츠의 거리 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_districts_for_content(
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(1023)
)
RETURNS TABLE (
    district_code VARCHAR(96),
    name_en VARCHAR(100),
    name_ko VARCHAR(100),
    city_code VARCHAR(96),
    confidence_score NUMERIC(3, 2),
    is_verified BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        d.district_code,
        d.name_en,
        d.name_ko,
        d.city_code,
        ms.confidence_score,
        ms.is_verified
    FROM public.map_district ms
    JOIN public.districts d ON ms.district_code = d.district_code
    WHERE ms.source_type = p_source_type
      AND ms.source_id = p_source_id
    ORDER BY ms.confidence_score DESC NULLS LAST, ms.order_num;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 거리의 콘텐츠 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_content_for_district(
    p_district_code VARCHAR(96),
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
    FROM public.map_district ms
    WHERE ms.district_code = p_district_code
      AND (p_source_type IS NULL OR ms.source_type = p_source_type)
      AND (NOT p_verified_only OR ms.is_verified = TRUE)
    ORDER BY ms.order_num, ms.added_at DESC;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 도시의 모든 거리 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_districts_by_city(
    p_city_code VARCHAR(96),
    p_active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    district_code VARCHAR(96),
    name_en VARCHAR(100),
    name_ko VARCHAR(100),
    name_native VARCHAR(100),
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    order_num SMALLINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        d.district_code,
        d.name_en,
        d.name_ko,
        d.name_native,
        d.latitude,
        d.longitude,
        d.order_num
    FROM public.districts d
    WHERE d.city_code = p_city_code
      AND (NOT p_active_only OR (d.is_active = TRUE AND d.is_display = TRUE))
    ORDER BY d.order_num, d.district_code;
$$;