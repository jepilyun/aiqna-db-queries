/*
 * aiqna db for web service (Contents and Mapping Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */



/*
 ***********************************************************************************************
 * TABLE: contents
 ***********************************************************************************************
 */
CREATE TABLE public.contents (
  content_code           VARCHAR(96)   PRIMARY KEY,
  
  -- 지역 연결
  country_code         VARCHAR(2)    NOT NULL DEFAULT 'AA',
  city_code            VARCHAR(96)   NULL,
  street_code          VARCHAR(96)   NULL,

  -- 기본 정보
  name_en              VARCHAR(127)  NULL,
  name_native          VARCHAR(127)  NULL,
  name_ko              VARCHAR(127)  NULL,
  description_en       VARCHAR(1023) NULL,
  description_native   VARCHAR(1023) NULL,

  -- 연락처 및 주소
  phone                VARCHAR(45)   NULL,
  address_en           VARCHAR(255)  NULL,
  address_native       VARCHAR(255)  NULL,

  -- 위치 정보
  latitude             NUMERIC(10,8) NULL,
  longitude            NUMERIC(11,8) NULL,

  -- 자동 생성되는 지리 객체 컬럼
  location GEOGRAPHY(POINT, 4326)
    GENERATED ALWAYS AS (
      CASE 
        WHEN latitude IS NOT NULL AND longitude IS NOT NULL 
        THEN geography(ST_SetSRID(ST_MakePoint(longitude, latitude), 4326))
        ELSE NULL
      END
    ) STORED,

  -- 경계 박스
  radius_m             INTEGER       NULL,

  -- 시간대
  utc_offset_minutes   SMALLINT      NULL,
  timezone             VARCHAR(63)   NULL,

  -- 외부 링크
  naver_map_url        VARCHAR(255)  NULL,
  instagram_id         VARCHAR(48)   NULL,
  youtube_ch_id        VARCHAR(48)   NULL,
  google_place_url     VARCHAR(1023) NULL,
  trip_advisor_url     VARCHAR(1023) NULL,
  facebook             VARCHAR(255)  NULL,

  -- 타겟 그룹
  is_target_for_family    BOOLEAN NOT NULL DEFAULT FALSE,
  is_target_for_children  BOOLEAN NOT NULL DEFAULT FALSE,
  is_target_for_couple    BOOLEAN NOT NULL DEFAULT FALSE,
  is_target_for_friends   BOOLEAN NOT NULL DEFAULT FALSE,
  is_target_for_solo      BOOLEAN NOT NULL DEFAULT FALSE,

  -- 소요 시간
  taking_minutes_start    SMALLINT NULL,
  taking_minutes_end      SMALLINT NULL,

  -- 가격 정보
  is_free_available       BOOLEAN NOT NULL DEFAULT FALSE,
  price_symbol            VARCHAR(4) NULL,
  price_start             NUMERIC(18,2) NULL,
  price_end               NUMERIC(18,2) NULL,

  -- 운영 기간
  is_open_always          BOOLEAN NOT NULL DEFAULT TRUE,
  period_start            DATE NULL,
  period_end              DATE NULL,

  -- 시스템 정보
  created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  is_display              BOOLEAN NOT NULL DEFAULT TRUE,

  -- 썸네일
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

  -- 외래키
  CONSTRAINT contents_country_code_fkey
    FOREIGN KEY (country_code)
    REFERENCES public.countries (country_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT contents_city_code_fkey
    FOREIGN KEY (city_code)
    REFERENCES public.cities (city_code)
    ON UPDATE CASCADE ON DELETE SET NULL,

  CONSTRAINT contents_street_code_fkey
    FOREIGN KEY (street_code)
    REFERENCES public.streets (street_code)
    ON UPDATE CASCADE ON DELETE SET NULL,

  -- 제약조건
  CONSTRAINT contents_latitude_check 
    CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
  
  CONSTRAINT contents_longitude_check 
    CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),

  -- UTC 오프셋 검증
  CONSTRAINT contents_utc_offset_check 
    CHECK (utc_offset_minutes IS NULL OR (utc_offset_minutes BETWEEN -720 AND 840)),

  -- 소요 시간 검증
  CONSTRAINT contents_taking_minutes_check 
    CHECK (
      (taking_minutes_start IS NULL AND taking_minutes_end IS NULL)
      OR
      (taking_minutes_start IS NOT NULL AND taking_minutes_end IS NOT NULL 
      AND taking_minutes_start > 0 AND taking_minutes_end > 0
      AND taking_minutes_start <= taking_minutes_end)
    ),

  -- 가격 검증
  CONSTRAINT contents_price_check 
    CHECK (
      (price_start IS NULL AND price_end IS NULL)
      OR
      (price_start IS NOT NULL AND price_end IS NOT NULL 
      AND price_start >= 0 AND price_end >= 0
      AND price_start <= price_end)
    ),

  -- 운영 기간 검증
  CONSTRAINT contents_period_check 
    CHECK (
      is_open_always = TRUE
      OR
      (period_start IS NOT NULL AND period_end IS NOT NULL 
      AND period_start <= period_end)
    )
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 제목 검색 최적화 (다국어)
CREATE INDEX IF NOT EXISTS contents_name_en_trgm_idx
  ON public.contents USING gin (name_en gin_trgm_ops)
  WHERE name_en IS NOT NULL;

CREATE INDEX IF NOT EXISTS contents_name_native_trgm_idx
  ON public.contents USING gin (name_native gin_trgm_ops)
  WHERE name_native IS NOT NULL;

CREATE INDEX IF NOT EXISTS contents_name_ko_trgm_idx
  ON public.contents USING gin (name_ko gin_trgm_ops)
  WHERE name_ko IS NOT NULL;

-- 지역별 조회
CREATE INDEX IF NOT EXISTS contents_country_idx
  ON public.contents (country_code);

CREATE INDEX IF NOT EXISTS contents_city_idx
  ON public.contents (city_code)
  WHERE city_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS contents_street_idx
  ON public.contents (street_code)
  WHERE street_code IS NOT NULL;

-- 지오 검색
CREATE INDEX IF NOT EXISTS contents_location_gist_idx
  ON public.contents USING gist (location)
  WHERE location IS NOT NULL;

-- 좌표 복합 인덱스
CREATE INDEX IF NOT EXISTS contents_lat_lng_idx
  ON public.contents (latitude, longitude)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- 활성 콘텐츠
CREATE INDEX IF NOT EXISTS contents_is_active_idx
  ON public.contents (is_active, is_display)
  WHERE is_active = TRUE AND is_display = TRUE;

-- 타겟 그룹별 조회
CREATE INDEX IF NOT EXISTS contents_target_family_idx
  ON public.contents (is_target_for_family)
  WHERE is_target_for_family = TRUE;

CREATE INDEX IF NOT EXISTS contents_target_children_idx
  ON public.contents (is_target_for_children)
  WHERE is_target_for_children = TRUE;

CREATE INDEX IF NOT EXISTS contents_target_couple_idx
  ON public.contents (is_target_for_couple)
  WHERE is_target_for_couple = TRUE;

CREATE INDEX IF NOT EXISTS contents_target_friends_idx
  ON public.contents (is_target_for_friends)
  WHERE is_target_for_friends = TRUE;

CREATE INDEX IF NOT EXISTS contents_target_solo_idx
  ON public.contents (is_target_for_solo)
  WHERE is_target_for_solo = TRUE;

-- 무료 콘텐츠
CREATE INDEX IF NOT EXISTS contents_free_idx
  ON public.contents (is_free_available)
  WHERE is_free_available = TRUE;

-- 가격대별 조회
CREATE INDEX IF NOT EXISTS contents_price_idx
  ON public.contents (price_start, price_end)
  WHERE price_start IS NOT NULL AND price_end IS NOT NULL;

-- 운영 기간별 조회
CREATE INDEX IF NOT EXISTS contents_period_idx
  ON public.contents (period_start, period_end)
  WHERE is_open_always = FALSE;

-- 최신순 조회
CREATE INDEX IF NOT EXISTS contents_created_at_idx
  ON public.contents (created_at DESC);

CREATE INDEX IF NOT EXISTS contents_updated_at_idx
  ON public.contents (updated_at DESC);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "contents are visible to everyone"
  ON public.contents FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage contents"
  ON public.contents FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_contents_updated_at
  BEFORE UPDATE ON public.contents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();







/*
 ***********************************************************************************************
 * TABLE: contents_i18n
 ***********************************************************************************************
 */
CREATE TABLE public.contents_i18n (
  content_code     VARCHAR(96)   NOT NULL,
  lang_code        VARCHAR(8)    NOT NULL,
  name_i18n        VARCHAR(255)  NOT NULL,
  description_i18n VARCHAR(1023) NULL,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT contents_i18n_pkey PRIMARY KEY (content_code, lang_code),
  CONSTRAINT contents_i18n_content_code_fkey
    FOREIGN KEY (content_code) 
    REFERENCES public.contents (content_code)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT contents_i18n_lang_code_fkey
    FOREIGN KEY (lang_code) 
    REFERENCES public.languages (lang_code)
    ON UPDATE CASCADE ON DELETE CASCADE
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 부분/유사 검색 최적화
CREATE INDEX IF NOT EXISTS contents_i18n_name_trgm_idx
  ON public.contents_i18n USING gin (name_i18n gin_trgm_ops);

-- 언어별 역방향 조회
CREATE INDEX IF NOT EXISTS contents_i18n_lang_idx
  ON public.contents_i18n (lang_code);

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.contents_i18n ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "contents_i18n are visible to everyone"
  ON public.contents_i18n FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage contents_i18n"
  ON public.contents_i18n FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_contents_i18n_updated_at
  BEFORE UPDATE ON public.contents_i18n
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();








/*
 ***********************************************************************************************
 * TABLE: map_contents
 *  - AI로 추출된 콘텐츠와 소스 매핑
 ***********************************************************************************************
 */
CREATE TABLE public.map_contents (
  content_code VARCHAR(96) NOT NULL,
  source_type VARCHAR(50) NOT NULL,
  source_id VARCHAR(1023) NOT NULL,

  -- AI 추출 정보
  confidence_score NUMERIC(3, 2) NULL,
  extracted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  extraction_method VARCHAR(50) NULL,
  
  -- 관리 정보
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  verified_at TIMESTAMP WITH TIME ZONE NULL,
  verified_by VARCHAR(511) NULL,
  
  is_selected BOOLEAN NOT NULL DEFAULT FALSE,
  order_num INTEGER NOT NULL DEFAULT 0,
  added_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT map_contents_pkey
    PRIMARY KEY (content_code, source_type, source_id),

  CONSTRAINT map_contents_content_code_fkey
    FOREIGN KEY (content_code) 
    REFERENCES public.contents (content_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT map_contents_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT map_contents_order_num_check 
    CHECK (order_num >= 0),
  
  CONSTRAINT map_contents_confidence_check 
    CHECK (confidence_score IS NULL OR (confidence_score BETWEEN 0 AND 1))
) TABLESPACE pg_default;

-- =============================================================================================
-- Indexes
-- =============================================================================================

-- 콘텐츠별 소스 목록 조회 (순서 정렬)
CREATE INDEX IF NOT EXISTS map_contents_id_order_idx
  ON public.map_contents (content_code, order_num, source_id);

-- 최신 등록순 조회
CREATE INDEX IF NOT EXISTS map_contents_id_added_idx
  ON public.map_contents (content_code, added_at DESC, source_id);

-- 선택된 항목 빠른 조회
CREATE INDEX IF NOT EXISTS map_contents_selected_idx
  ON public.map_contents (content_code, order_num, added_at DESC)
  WHERE is_selected = TRUE;

-- 검증된 항목 조회
CREATE INDEX IF NOT EXISTS map_contents_verified_idx
  ON public.map_contents (content_code, confidence_score DESC)
  WHERE is_verified = TRUE;

-- 역방향 탐색 (특정 소스가 매핑된 콘텐츠들)
CREATE INDEX IF NOT EXISTS map_contents_source_idx
  ON public.map_contents (source_type, source_id, content_code);

-- 소스 타입별 조회
CREATE INDEX IF NOT EXISTS map_contents_source_type_idx
  ON public.map_contents (source_type, added_at DESC);

-- 신뢰도 높은 항목 조회
CREATE INDEX IF NOT EXISTS map_contents_confidence_idx
  ON public.map_contents (confidence_score DESC)
  WHERE confidence_score >= 0.8;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.map_contents ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "map_contents are visible to everyone"
  ON public.map_contents FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage map_contents"
  ON public.map_contents FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_map_contents_updated_at
  BEFORE UPDATE ON public.map_contents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: AI 추출 콘텐츠 매핑 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.upsert_content_mapping(
    p_content_code VARCHAR(96),
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
    INSERT INTO public.map_contents (
        content_code,
        source_type,
        source_id,
        confidence_score,
        extraction_method,
        extracted_at
    ) VALUES (
        p_content_code,
        p_source_type,
        p_source_id,
        p_confidence_score,
        p_extraction_method,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (content_code, source_type, source_id) DO UPDATE SET
        confidence_score = EXCLUDED.confidence_score,
        extraction_method = EXCLUDED.extraction_method,
        extracted_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 소스의 콘텐츠 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_contents_for_source(
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(1023)
)
RETURNS TABLE (
    content_code VARCHAR(96),
    name_en VARCHAR(127),
    name_native VARCHAR(127),
    name_ko VARCHAR(127),
    confidence_score NUMERIC(3, 2),
    is_verified BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        c.content_code,
        c.name_en,
        c.name_native,
        c.name_ko,
        mc.confidence_score,
        mc.is_verified
    FROM public.map_contents mc
    JOIN public.contents c ON mc.content_code = c.content_code
    WHERE mc.source_type = p_source_type
      AND mc.source_id = p_source_id
    ORDER BY mc.confidence_score DESC NULLS LAST, mc.order_num;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 콘텐츠의 소스 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_sources_for_content(
    p_content_code VARCHAR(96),
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
    FROM public.map_contents mc
    WHERE mc.content_code = p_content_code
      AND (p_source_type IS NULL OR mc.source_type = p_source_type)
      AND (NOT p_verified_only OR mc.is_verified = TRUE)
    ORDER BY mc.order_num, mc.added_at DESC;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 지역의 콘텐츠 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_contents_by_location(
    p_city_code VARCHAR(96) DEFAULT NULL,
    p_street_code VARCHAR(96) DEFAULT NULL,
    p_is_free BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    content_code VARCHAR(96),
    name_en VARCHAR(127),
    name_native VARCHAR(127),
    name_ko VARCHAR(127),
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    is_free_available BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        c.content_code,
        c.name_en,
        c.name_native,
        c.name_ko,
        c.latitude,
        c.longitude,
        c.is_free_available
    FROM public.contents c
    WHERE (p_city_code IS NULL OR c.city_code = p_city_code)
      AND (p_street_code IS NULL OR c.street_code = p_street_code)
      AND (p_is_free IS NULL OR c.is_free_available = p_is_free)
      AND c.is_active = TRUE
      AND c.is_display = TRUE
    ORDER BY c.created_at DESC;
$$;