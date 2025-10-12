/*
 * aiqna db for web service (Google Places and Mapping Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */



/*
 ***********************************************************************************************
 * TABLE: google_places
 ***********************************************************************************************
 */
CREATE TABLE public.google_places (
  google_place_id      VARCHAR(63)   PRIMARY KEY,
  
  -- 지역 연결
  country_code         VARCHAR(2)    NOT NULL DEFAULT 'AA',
  city_code            VARCHAR(96)   NULL,
  street_code          VARCHAR(96)   NULL,

  -- 기본 정보
  display_name         VARCHAR(127)  NOT NULL,
  name_en              VARCHAR(127)  NULL,
  name_native          VARCHAR(127)  NULL,
  name_ko              VARCHAR(127)  NULL,
  editorial_summary    VARCHAR(2047) NULL,

  -- 분류 정보
  types                JSONB         NULL,
  primary_type         VARCHAR(127)  NULL,
  
  -- 연락처 및 주소
  phone                VARCHAR(45)   NULL,
  address              VARCHAR(255)  NULL,
  plus_code_global     VARCHAR(45)   NULL,
  plus_code_compound   VARCHAR(45)   NULL,

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
  low_latitude         NUMERIC(10,8) NULL,
  low_longitude        NUMERIC(11,8) NULL,
  high_latitude        NUMERIC(10,8) NULL,
  high_longitude       NUMERIC(11,8) NULL,

  -- 평점 및 리뷰
  rating               REAL          NULL,
  user_rating_count    INTEGER       NULL,

  -- 영업 시간
  periods              JSONB         NULL,
  weekday_descriptions JSONB         NULL,
  business_status      VARCHAR(63)   NULL,

  -- 시간대
  utc_offset_minutes   SMALLINT      NULL,
  timezone             VARCHAR(63)   NULL,

  -- 미디어 및 링크
  photos               JSONB         NULL,
  directions_uri       VARCHAR(255)  NULL,
  place_uri            VARCHAR(255)  NULL,
  reviews_uri          VARCHAR(255)  NULL,
  photos_uri           VARCHAR(255)  NULL,

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

  -- 음식점 특성
  is_vegetarian_available BOOLEAN NULL,
  is_breakfast            BOOLEAN NULL,
  is_brunch               BOOLEAN NULL,
  is_lunch                BOOLEAN NULL,
  is_dinner               BOOLEAN NULL,
  is_bar                  BOOLEAN NULL,
  is_club                 BOOLEAN NULL,

  -- 운영 기간
  is_open_always          BOOLEAN NOT NULL DEFAULT TRUE,
  period_start            DATE NULL,
  period_end              DATE NULL,

  -- 시스템 정보
  fetched_at              TIMESTAMP WITH TIME ZONE NULL,
  created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  is_display              BOOLEAN NOT NULL DEFAULT TRUE,

  -- 외래키
  CONSTRAINT google_places_country_code_fkey
    FOREIGN KEY (country_code)
    REFERENCES public.countries (country_code)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT google_places_city_code_fkey
    FOREIGN KEY (city_code)
    REFERENCES public.cities (city_code)
    ON UPDATE CASCADE ON DELETE SET NULL,

  CONSTRAINT google_places_street_code_fkey
    FOREIGN KEY (street_code)
    REFERENCES public.streets (street_code)
    ON UPDATE CASCADE ON DELETE SET NULL,

  -- 제약조건
  CONSTRAINT google_places_rating_check 
    CHECK (rating IS NULL OR (rating >= 0 AND rating <= 5)),
  
  CONSTRAINT google_places_user_rating_count_check 
    CHECK (user_rating_count IS NULL OR user_rating_count >= 0),

  CONSTRAINT google_places_latitude_check 
    CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
  
  CONSTRAINT google_places_longitude_check 
    CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),

  -- 경계 박스 검증
  CONSTRAINT google_places_bbox_check CHECK (
    (low_latitude IS NULL AND low_longitude IS NULL AND high_latitude IS NULL AND high_longitude IS NULL)
    OR
    (
      low_latitude IS NOT NULL AND low_longitude IS NOT NULL
      AND high_latitude IS NOT NULL AND high_longitude IS NOT NULL
      AND low_latitude <= high_latitude
      AND low_longitude <= high_longitude
      AND low_latitude BETWEEN -90 AND 90
      AND high_latitude BETWEEN -90 AND 90
      AND low_longitude BETWEEN -180 AND 180
      AND high_longitude BETWEEN -180 AND 180
    )
  ),

  -- UTC 오프셋 검증
  CONSTRAINT google_places_utc_offset_check 
    CHECK (utc_offset_minutes IS NULL OR (utc_offset_minutes BETWEEN -720 AND 840)),

  -- 소요 시간 검증
  CONSTRAINT google_places_taking_minutes_check 
    CHECK (
      (taking_minutes_start IS NULL AND taking_minutes_end IS NULL)
      OR
      (taking_minutes_start IS NOT NULL AND taking_minutes_end IS NOT NULL 
      AND taking_minutes_start > 0 AND taking_minutes_end > 0
      AND taking_minutes_start <= taking_minutes_end)
    ),

  -- 가격 검증
  CONSTRAINT google_places_price_check 
    CHECK (
      (price_start IS NULL AND price_end IS NULL)
      OR
      (price_start IS NOT NULL AND price_end IS NOT NULL 
      AND price_start >= 0 AND price_end >= 0
      AND price_start <= price_end)
    ),

  -- 운영 기간 검증
  CONSTRAINT google_places_period_check 
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

-- 이름 검색 최적화
CREATE INDEX IF NOT EXISTS google_places_display_name_trgm_idx
  ON public.google_places USING gin (display_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS google_places_name_ko_trgm_idx
  ON public.google_places USING gin (name_ko gin_trgm_ops)
  WHERE name_ko IS NOT NULL;

CREATE INDEX IF NOT EXISTS google_places_editorial_summary_trgm_idx
  ON public.google_places USING gin (editorial_summary gin_trgm_ops)
  WHERE editorial_summary IS NOT NULL;

-- JSONB 조회
CREATE INDEX IF NOT EXISTS google_places_types_gin_idx
  ON public.google_places USING gin (types);

-- 지역별 조회
CREATE INDEX IF NOT EXISTS google_places_country_idx
  ON public.google_places (country_code);

CREATE INDEX IF NOT EXISTS google_places_city_idx
  ON public.google_places (city_code)
  WHERE city_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS google_places_street_idx
  ON public.google_places (street_code)
  WHERE street_code IS NOT NULL;

-- 타입별 조회
CREATE INDEX IF NOT EXISTS google_places_primary_type_idx
  ON public.google_places (primary_type)
  WHERE primary_type IS NOT NULL;

-- 평점 순 조회
CREATE INDEX IF NOT EXISTS google_places_rating_idx
  ON public.google_places (rating DESC, user_rating_count DESC)
  WHERE rating IS NOT NULL;

-- 지오 검색
CREATE INDEX IF NOT EXISTS google_places_location_gist_idx
  ON public.google_places USING gist (location)
  WHERE location IS NOT NULL;

-- 좌표 복합 인덱스
CREATE INDEX IF NOT EXISTS google_places_lat_lng_idx
  ON public.google_places (latitude, longitude)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- 다음 갱신 대상 선별
CREATE INDEX IF NOT EXISTS google_places_fetched_at_idx
  ON public.google_places (fetched_at NULLS FIRST);

-- 활성 장소
CREATE INDEX IF NOT EXISTS google_places_is_active_idx
  ON public.google_places (is_active, is_display)
  WHERE is_active = TRUE AND is_display = TRUE;

-- 타겟 그룹별 조회
CREATE INDEX IF NOT EXISTS google_places_target_family_idx
  ON public.google_places (is_target_for_family)
  WHERE is_target_for_family = TRUE;

CREATE INDEX IF NOT EXISTS google_places_target_couple_idx
  ON public.google_places (is_target_for_couple)
  WHERE is_target_for_couple = TRUE;

-- 무료 장소
CREATE INDEX IF NOT EXISTS google_places_free_idx
  ON public.google_places (is_free_available)
  WHERE is_free_available = TRUE;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.google_places ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "google_places are visible to everyone"
  ON public.google_places FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage google_places"
  ON public.google_places FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_google_places_updated_at
  BEFORE UPDATE ON public.google_places
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();







/*
 ***********************************************************************************************
 * TABLE: map_google_place
 *  - AI로 추출된 Google Place와 콘텐츠 매핑
 ***********************************************************************************************
 */
CREATE TABLE public.map_google_place (
  google_place_id VARCHAR(63) NOT NULL,
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

  CONSTRAINT map_google_place_pkey
    PRIMARY KEY (google_place_id, source_type, source_id),

  CONSTRAINT map_google_place_google_place_id_fkey
    FOREIGN KEY (google_place_id) 
    REFERENCES public.google_places (google_place_id)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT map_google_place_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT map_google_place_order_num_check CHECK (order_num >= 0),
  
  CONSTRAINT map_google_place_confidence_check 
    CHECK (confidence_score IS NULL OR (confidence_score BETWEEN 0 AND 1))
) TABLESPACE pg_default;

-- =============================================================================================
-- Indexes
-- =============================================================================================

-- 장소별 콘텐츠 목록 조회 (순서 정렬)
CREATE INDEX IF NOT EXISTS map_google_place_id_order_idx
  ON public.map_google_place (google_place_id, order_num, source_id);

-- 최신 등록순 조회
CREATE INDEX IF NOT EXISTS map_google_place_id_added_idx
  ON public.map_google_place (google_place_id, added_at DESC, source_id);

-- 선택된 항목 빠른 조회
CREATE INDEX IF NOT EXISTS map_google_place_selected_idx
  ON public.map_google_place (google_place_id, order_num, added_at DESC)
  WHERE is_selected = TRUE;

-- 검증된 항목 조회
CREATE INDEX IF NOT EXISTS map_google_place_verified_idx
  ON public.map_google_place (google_place_id, confidence_score DESC)
  WHERE is_verified = TRUE;

-- 역방향 탐색 (특정 콘텐츠가 매핑된 장소들)
CREATE INDEX IF NOT EXISTS map_google_place_source_idx
  ON public.map_google_place (source_type, source_id, google_place_id);

-- 소스 타입별 조회
CREATE INDEX IF NOT EXISTS map_google_place_source_type_idx
  ON public.map_google_place (source_type, added_at DESC);

-- 신뢰도 높은 항목 조회
CREATE INDEX IF NOT EXISTS map_google_place_confidence_idx
  ON public.map_google_place (confidence_score DESC)
  WHERE confidence_score >= 0.8;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.map_google_place ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "map_google_place are visible to everyone"
  ON public.map_google_place FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage map_google_place"
  ON public.map_google_place FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_map_google_place_updated_at
  BEFORE UPDATE ON public.map_google_place
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: AI 추출 Google Place 매핑 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.upsert_google_place_mapping(
    p_google_place_id VARCHAR(63),
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
    INSERT INTO public.map_google_place (
        google_place_id,
        source_type,
        source_id,
        confidence_score,
        extraction_method,
        extracted_at
    ) VALUES (
        p_google_place_id,
        p_source_type,
        p_source_id,
        p_confidence_score,
        p_extraction_method,
        NOW()
    )
    ON CONFLICT (google_place_id, source_type, source_id) DO UPDATE SET
        confidence_score = EXCLUDED.confidence_score,
        extraction_method = EXCLUDED.extraction_method,
        extracted_at = NOW(),
        updated_at = NOW();
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 콘텐츠의 Google Place 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_google_places_for_content(
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(1023)
)
RETURNS TABLE (
    google_place_id VARCHAR(63),
    display_name VARCHAR(127),
    name_ko VARCHAR(127),
    primary_type VARCHAR(127),
    rating REAL,
    confidence_score NUMERIC(3, 2),
    is_verified BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        gp.google_place_id,
        gp.display_name,
        gp.name_ko,
        gp.primary_type,
        gp.rating,
        mgp.confidence_score,
        mgp.is_verified
    FROM public.map_google_place mgp
    JOIN public.google_places gp ON mgp.google_place_id = gp.google_place_id
    WHERE mgp.source_type = p_source_type
      AND mgp.source_id = p_source_id
    ORDER BY mgp.confidence_score DESC NULLS LAST, mgp.order_num;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 Google Place의 콘텐츠 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_content_for_google_place(
    p_google_place_id VARCHAR(63),
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
        mgp.source_type,
        mgp.source_id,
        mgp.confidence_score,
        mgp.is_verified,
        mgp.added_at
    FROM public.map_google_place mgp
    WHERE mgp.google_place_id = p_google_place_id
      AND (p_source_type IS NULL OR mgp.source_type = p_source_type)
      AND (NOT p_verified_only OR mgp.is_verified = TRUE)
    ORDER BY mgp.order_num, mgp.added_at DESC;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 지역의 Google Place 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_google_places_by_location(
    p_city_code VARCHAR(96) DEFAULT NULL,
    p_street_code VARCHAR(96) DEFAULT NULL,
    p_primary_type VARCHAR(127) DEFAULT NULL,
    p_min_rating REAL DEFAULT NULL
)
RETURNS TABLE (
    google_place_id VARCHAR(63),
    display_name VARCHAR(127),
    name_ko VARCHAR(127),
    primary_type VARCHAR(127),
    rating REAL,
    user_rating_count INTEGER,
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        gp.google_place_id,
        gp.display_name,
        gp.name_ko,
        gp.primary_type,
        gp.rating,
        gp.user_rating_count,
        gp.latitude,
        gp.longitude
    FROM public.google_places gp
    WHERE (p_city_code IS NULL OR gp.city_code = p_city_code)
      AND (p_street_code IS NULL OR gp.street_code = p_street_code)
      AND (p_primary_type IS NULL OR gp.primary_type = p_primary_type)
      AND (p_min_rating IS NULL OR gp.rating >= p_min_rating)
      AND gp.is_active = TRUE
      AND gp.is_display = TRUE
    ORDER BY gp.rating DESC NULLS LAST, gp.user_rating_count DESC NULLS LAST;
$$;