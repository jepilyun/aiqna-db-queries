/*
 * aiqna db for web service (Streets and Mapping Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */



/*
 ***********************************************************************************************
 * TABLE: streets
 ***********************************************************************************************
 */
CREATE TABLE public.streets (
  country_code   VARCHAR(2)    NULL,
  city_code      VARCHAR(96)   NULL,
  street_code    VARCHAR(96)   NOT NULL,
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

  CONSTRAINT streets_pkey PRIMARY KEY (street_code),

  CONSTRAINT streets_country_code_fkey
    FOREIGN KEY (country_code)
    REFERENCES public.countries (country_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT streets_city_code_fkey
    FOREIGN KEY (city_code)
    REFERENCES public.cities (city_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  -- 값 검증
  CONSTRAINT streets_radius_m_check CHECK (radius_m IS NULL OR radius_m >= 0),
  CONSTRAINT streets_latitude_check CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
  CONSTRAINT streets_longitude_check CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
  CONSTRAINT streets_order_num_check CHECK (order_num >= 0)
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 도시별 거리 목록 정렬
CREATE INDEX IF NOT EXISTS streets_city_order_idx
  ON public.streets (city_code, order_num, street_code);

-- 국가별 거리 목록
CREATE INDEX IF NOT EXISTS streets_country_idx
  ON public.streets (country_code);

-- 활성/노출 필터
CREATE INDEX IF NOT EXISTS streets_city_active_display_idx
  ON public.streets (city_code, is_active, is_display)
  WHERE is_active = TRUE AND is_display = TRUE;

-- 활성 거리만
CREATE INDEX IF NOT EXISTS streets_is_active_idx
  ON public.streets (is_active, order_num)
  WHERE is_active = TRUE;

-- 지오 검색
CREATE INDEX IF NOT EXISTS streets_location_gist_idx
  ON public.streets USING GIST (location)
  WHERE location IS NOT NULL;

-- 위/경도 복합 인덱스
CREATE INDEX IF NOT EXISTS streets_lat_lng_idx
  ON public.streets (latitude, longitude)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- 이름 검색 최적화 (다국어)
CREATE INDEX IF NOT EXISTS streets_name_en_trgm_idx
  ON public.streets USING gin (name_en gin_trgm_ops);

CREATE INDEX IF NOT EXISTS streets_name_ko_trgm_idx
  ON public.streets USING gin (name_ko gin_trgm_ops)
  WHERE name_ko IS NOT NULL;

CREATE INDEX IF NOT EXISTS streets_name_native_trgm_idx
  ON public.streets USING gin (name_native gin_trgm_ops)
  WHERE name_native IS NOT NULL;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.streets ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "streets are visible to everyone"
  ON public.streets FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage streets"
  ON public.streets FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_streets_updated_at
  BEFORE UPDATE ON public.streets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();






/*
 ***********************************************************************************************
 * TABLE: street_i18n
 ***********************************************************************************************
 */
CREATE TABLE public.street_i18n (
  street_code      VARCHAR(96)   NOT NULL,
  lang_code        VARCHAR(8)    NOT NULL,
  name_i18n        VARCHAR(255)  NOT NULL,
  description_i18n VARCHAR(1023) NULL,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT street_i18n_pkey PRIMARY KEY (street_code, lang_code),
  CONSTRAINT street_i18n_street_code_fkey
    FOREIGN KEY (street_code) 
    REFERENCES public.streets (street_code)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT street_i18n_lang_code_fkey
    FOREIGN KEY (lang_code) 
    REFERENCES public.languages (lang_code)
    ON UPDATE CASCADE ON DELETE CASCADE
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 부분/유사 검색 최적화
CREATE INDEX IF NOT EXISTS street_i18n_name_trgm_idx
  ON public.street_i18n USING gin (name_i18n gin_trgm_ops);

-- 언어별 역방향 조회
CREATE INDEX IF NOT EXISTS street_i18n_lang_idx
  ON public.street_i18n (lang_code);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.street_i18n ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "street_i18n are visible to everyone"
  ON public.street_i18n FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage street_i18n"
  ON public.street_i18n FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_street_i18n_updated_at
  BEFORE UPDATE ON public.street_i18n
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();





/*
 ***********************************************************************************************
 * TABLE: map_street
 *  - AI로 추출된 거리 정보와 콘텐츠 매핑
 *  - 수동 정렬(order_num) 및 등록시각(added_at) 포함
 ***********************************************************************************************
 */
CREATE TABLE public.map_street (
  street_code VARCHAR(96) NOT NULL,
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

  CONSTRAINT map_street_pkey
    PRIMARY KEY (street_code, source_type, source_id),

  CONSTRAINT map_street_street_code_fkey
    FOREIGN KEY (street_code) 
    REFERENCES public.streets (street_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT map_street_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT map_street_order_num_check CHECK (order_num >= 0),
  
  CONSTRAINT map_street_confidence_check 
    CHECK (confidence_score IS NULL OR (confidence_score BETWEEN 0 AND 1))
) TABLESPACE pg_default;

-- =============================================================================================
-- Indexes
-- =============================================================================================

-- 거리별 콘텐츠 목록 조회 (순서 정렬)
CREATE INDEX IF NOT EXISTS map_street_code_order_idx
  ON public.map_street (street_code, order_num, source_id);

-- 최신 등록순 조회
CREATE INDEX IF NOT EXISTS map_street_code_added_idx
  ON public.map_street (street_code, added_at DESC, source_id);

-- 선택된 항목 빠른 조회
CREATE INDEX IF NOT EXISTS map_street_selected_idx
  ON public.map_street (street_code, order_num, added_at DESC)
  WHERE is_selected = TRUE;

-- 검증된 항목 조회
CREATE INDEX IF NOT EXISTS map_street_verified_idx
  ON public.map_street (street_code, confidence_score DESC)
  WHERE is_verified = TRUE;

-- 역방향 탐색 (특정 콘텐츠가 매핑된 거리들)
CREATE INDEX IF NOT EXISTS map_street_source_idx
  ON public.map_street (source_type, source_id, street_code);

-- 소스 타입별 조회
CREATE INDEX IF NOT EXISTS map_street_source_type_idx
  ON public.map_street (source_type, added_at DESC);

-- 신뢰도 높은 항목 조회
CREATE INDEX IF NOT EXISTS map_street_confidence_idx
  ON public.map_street (confidence_score DESC)
  WHERE confidence_score >= 0.8;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.map_street ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "map_street are visible to everyone"
  ON public.map_street FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage map_street"
  ON public.map_street FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_map_street_updated_at
  BEFORE UPDATE ON public.map_street
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: AI 추출 거리 정보 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.upsert_street_mapping(
    p_street_code VARCHAR(96),
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
    INSERT INTO public.map_street (
        street_code,
        source_type,
        source_id,
        confidence_score,
        extraction_method,
        extracted_at
    ) VALUES (
        p_street_code,
        p_source_type,
        p_source_id,
        p_confidence_score,
        p_extraction_method,
        NOW()
    )
    ON CONFLICT (street_code, source_type, source_id) DO UPDATE SET
        confidence_score = EXCLUDED.confidence_score,
        extraction_method = EXCLUDED.extraction_method,
        extracted_at = NOW(),
        updated_at = NOW();
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 콘텐츠의 거리 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_streets_for_content(
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(1023)
)
RETURNS TABLE (
    street_code VARCHAR(96),
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
        s.street_code,
        s.name_en,
        s.name_ko,
        s.city_code,
        ms.confidence_score,
        ms.is_verified
    FROM public.map_street ms
    JOIN public.streets s ON ms.street_code = s.street_code
    WHERE ms.source_type = p_source_type
      AND ms.source_id = p_source_id
    ORDER BY ms.confidence_score DESC NULLS LAST, ms.order_num;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 거리의 콘텐츠 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_content_for_street(
    p_street_code VARCHAR(96),
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
    FROM public.map_street ms
    WHERE ms.street_code = p_street_code
      AND (p_source_type IS NULL OR ms.source_type = p_source_type)
      AND (NOT p_verified_only OR ms.is_verified = TRUE)
    ORDER BY ms.order_num, ms.added_at DESC;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 도시의 모든 거리 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_streets_by_city(
    p_city_code VARCHAR(96),
    p_active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    street_code VARCHAR(96),
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
        s.street_code,
        s.name_en,
        s.name_ko,
        s.name_native,
        s.latitude,
        s.longitude,
        s.order_num
    FROM public.streets s
    WHERE s.city_code = p_city_code
      AND (NOT p_active_only OR (s.is_active = TRUE AND s.is_display = TRUE))
    ORDER BY s.order_num, s.street_code;
$$;