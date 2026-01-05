/*
 * aiqna db for web service (Instagram Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-09-24
 * Updated 2025-12-07
 * 
 * 테이블:
 *   1. instagram_post              - Instagram 포스트 메타데이터
 * 
 * 함수:
 *   - upsert_instagram_post_data()        - 포스트 데이터 저장
 *   - upsert_instagram_post_ai_analysis() - AI 분석 결과 저장
 * 
 * 주요 변경사항 (2025-12-07):
 *   - post_id를 PRIMARY KEY로 변경 (YouTube 테이블과 동일한 패턴)
 *   - 불필요한 id 컬럼 제거
 *   - map_google_place FK와의 일관성 확보
 */


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║                         1. INSTAGRAM_POST 테이블                           ║
-- ║                                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

/*
 ***********************************************************************************************
 * TABLE: instagram_post
 ***********************************************************************************************
 * 설명: Instagram 포스트 메타데이터 저장
 * 데이터 소스: Instagram 크롤링 / API
 * 
 * 섹션:
 *   - 기본 정보 (포스트 ID, URL)
 *   - 미디어 정보 (이미지, 비디오)
 *   - 사용자 정보 (작성자)
 *   - 통계 정보 (좋아요, 댓글, 조회수)
 *   - 위치 정보 (좌표, 장소명)
 *   - Open Graph 메타데이터
 *   - AI 분석 결과 (ai_*)
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS public.instagram_post (
    -- ========================================
    -- 기본 키 (YouTube와 동일한 패턴)
    -- ========================================
    post_id VARCHAR(50) PRIMARY KEY,            -- Instagram shortcode (자연키)
    post_url TEXT NOT NULL UNIQUE,              -- 전체 URL
    
    -- ========================================
    -- 포스트 기본 정보
    -- ========================================
    post_type VARCHAR(20) NOT NULL DEFAULT 'image',  -- image, video, carousel, reel, story
    caption TEXT NULL,                          -- 포스트 캡션/설명
    hashtags TEXT[] NULL,                       -- 해시태그 배열
    mentions TEXT[] NULL,                       -- 멘션된 사용자 배열
    published_date TIMESTAMPTZ NULL,            -- 게시 일시
    
    -- ========================================
    -- 미디어 정보
    -- ========================================
    media_count INTEGER NOT NULL DEFAULT 1,     -- 미디어 개수 (carousel의 경우 여러 개)
    media_urls TEXT[] NULL,                     -- 미디어 URL 배열
    thumbnail_url TEXT NULL,                    -- 대표 썸네일
    video_duration_seconds INTEGER NULL,        -- 비디오 길이 (초)
    is_video BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- ========================================
    -- 사용자 정보
    -- ========================================
    user_id VARCHAR(50) NULL,                   -- Instagram 사용자 ID
    username VARCHAR(100) NULL,                 -- 사용자명 (@username)
    user_full_name VARCHAR(255) NULL,           -- 표시 이름
    user_profile_url TEXT NULL,                 -- 프로필 URL
    user_profile_pic_url TEXT NULL,             -- 프로필 사진 URL
    user_is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    user_follower_count BIGINT NULL,            -- 팔로워 수 (스냅샷)
    
    -- ========================================
    -- 통계 정보
    -- ========================================
    like_count BIGINT NOT NULL DEFAULT 0,
    comment_count BIGINT NOT NULL DEFAULT 0,
    view_count BIGINT NOT NULL DEFAULT 0,       -- 비디오/릴스 조회수
    share_count BIGINT NOT NULL DEFAULT 0,
    save_count BIGINT NOT NULL DEFAULT 0,
    
    -- ========================================
    -- 위치 정보
    -- ========================================
    location_id VARCHAR(100) NULL,              -- Instagram 위치 ID
    location_name VARCHAR(255) NULL,            -- 위치명
    location_slug VARCHAR(255) NULL,            -- 위치 slug
    latitude NUMERIC(10,8) NULL,
    longitude NUMERIC(11,8) NULL,
    address TEXT NULL,                          -- 주소
    city VARCHAR(100) NULL,
    country VARCHAR(100) NULL,
    country_code VARCHAR(10) NULL,
    
    -- ========================================
    -- Open Graph 메타데이터
    -- ========================================
    og_title TEXT NULL,
    og_description TEXT NULL,
    og_image TEXT NULL,
    og_url TEXT NULL,
    
    -- ========================================
    -- AI 분석 결과 - 콘텐츠 요약
    -- ========================================
    ai_summary TEXT NULL,                       -- 포스트 전체 요약 (caption + 이미지 분석 기반)
    ai_key_points TEXT[] NULL,                  -- 핵심 포인트 배열
    
    ai_meta_category TEXT[] NULL,               -- 카테고리 ['맛집', '관광', '카페']
    ai_meta_influencer TEXT[] NULL,             -- 출연 인플루언서
    ai_meta_season TEXT[] NULL,                 -- 적합한 계절 ['봄', '가을']
    ai_meta_time_of_day TEXT[] NULL,            -- 적합한 시간대 ['아침', '저녁']
    ai_meta_activity_type TEXT[] NULL,          -- 활동 유형 ['데이트', '가족여행', '혼행']
    ai_meta_special_tag TEXT[] NULL,            -- 특수 태그 ['OOTD', '먹방', '일상']
    ai_meta_kpop TEXT[] NULL,                   -- K-POP 관련 태그 ['BTS', 'BLACKPINK', 'EXO']
    ai_meta_target_age TEXT[] NULL,             -- 타겟 연령 ['20대', '30대', '40대', '50대', '60대 이상']
    ai_meta_target_audience TEXT[] NULL,        -- 타겟 ['20대', '커플', '외국인']
    ai_meta_landmark TEXT[] NULL,               -- 랜드마크 ['광화문', '경복궁', '창덕궁']
    ai_meta_city TEXT[] NULL,                   -- 도시 ['서울', '부산', '인천']
    ai_meta_country TEXT[] NULL,                -- 국가 ['대한민국', '미국', '일본']
    ai_meta_district TEXT[] NULL,               -- 구 ['종로구', '강남구', '서초구']
    ai_meta_neighborhood TEXT[] NULL,           -- 동 ['세종로', '강남동', '서초동']
    ai_meta_place TEXT[] NULL,                  -- 장소 ['경복궁', '창덕궁', '카페 온마']
    
    -- ========================================
    -- AI 분석 결과 - 장소별 상세 정보
    -- ========================================
    ai_places JSONB NULL,                       -- 장소 상세 정보
    ai_places_count SMALLINT NULL,              -- 장소 개수 (쿼리 최적화용)
    /*
    ai_places 구조: (youtube_video와 동일)
    [
        {
            "place_name": "카페 온마",
            "place_name_en": "Cafe Onma",
            "place_name_native": null,
            "place_type": "cafe",
            "country": "KR",
            "city": "서울",
            "district": "마포구",
            "neighborhood": "연남동",
            "landmark": "홍대입구역 근처",
            "address": "서울특별시 마포구 연남로 123",
            "latitude": 37.5665,
            "longitude": 126.9780,
            "period": null,
            "start_date": null,
            "end_date": null,
            "operation_hours": "10:00-22:00",
            "prices": {"americano": 4500, "latte": 5000, "currency": "KRW"},
            "recommend_menu": ["티라미수", "아인슈페너"],
            "travel_tips": ["창가 자리 추천", "주차 어려움"],
            "notice": "월요일 휴무",
            "review_summary": "연남동 분위기 좋은 카페",
            "reservation_required": false,
            "order_in_post": 1
        }
    ]
    */
    
    -- ========================================
    -- AI 분석 메타
    -- ========================================
    ai_analyzed_at TIMESTAMPTZ NULL,
    ai_model VARCHAR(50) NULL,
    ai_confidence NUMERIC(3,2) NULL,            -- 0.00 ~ 1.00
    
    -- ========================================
    -- 로컬 저장 정보 (선택적)
    -- ========================================
    local_thumbnail_path TEXT NULL,             -- 로컬 저장된 썸네일 경로
    local_media_paths TEXT[] NULL,              -- 로컬 저장된 미디어 경로들
    
    -- ========================================
    -- 시스템 관리
    -- ========================================
    metadata_json JSONB NULL,                   -- 원본 크롤링 데이터 (디버깅용)
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ NULL,
    
    -- ========================================
    -- 시스템 타임스탬프
    -- ========================================
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_processed_at TIMESTAMPTZ NULL,

    -- ========================================
    -- 제약조건
    -- ========================================
    CONSTRAINT ip_post_type_check 
        CHECK (post_type IN ('image', 'video', 'carousel', 'reel', 'story')),
    CONSTRAINT ip_media_count_check 
        CHECK (media_count >= 1),
    CONSTRAINT ip_like_count_check 
        CHECK (like_count >= 0),
    CONSTRAINT ip_comment_count_check 
        CHECK (comment_count >= 0),
    CONSTRAINT ip_view_count_check 
        CHECK (view_count >= 0),
    CONSTRAINT ip_share_count_check 
        CHECK (share_count >= 0),
    CONSTRAINT ip_save_count_check 
        CHECK (save_count >= 0),
    CONSTRAINT ip_video_duration_check 
        CHECK (video_duration_seconds IS NULL OR video_duration_seconds >= 0),
    CONSTRAINT ip_latitude_check 
        CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
    CONSTRAINT ip_longitude_check 
        CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
    CONSTRAINT ip_ai_places_count_check
        CHECK (ai_places_count IS NULL OR ai_places_count >= 0),
    CONSTRAINT ip_ai_confidence_check
        CHECK (ai_confidence IS NULL OR (ai_confidence >= 0 AND ai_confidence <= 1)),
    CONSTRAINT ip_deleted_logic_check
        CHECK (
            (is_deleted = FALSE AND deleted_at IS NULL) 
            OR (is_deleted = TRUE AND deleted_at IS NOT NULL)
        )
);

-- ========================================
-- 인덱스: instagram_post
-- ========================================
-- 기본 검색 인덱스
CREATE INDEX IF NOT EXISTS idx_ip_published_date 
    ON public.instagram_post (published_date DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_ip_user_id 
    ON public.instagram_post (user_id) 
    WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ip_username 
    ON public.instagram_post (username) 
    WHERE username IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ip_post_type 
    ON public.instagram_post (post_type);

CREATE INDEX IF NOT EXISTS idx_ip_location_id 
    ON public.instagram_post (location_id) 
    WHERE location_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ip_location_name 
    ON public.instagram_post (location_name) 
    WHERE location_name IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ip_city 
    ON public.instagram_post (city) 
    WHERE city IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ip_country_code 
    ON public.instagram_post (country_code) 
    WHERE country_code IS NOT NULL;

-- 조건부 인덱스 (Partial Index)
CREATE INDEX IF NOT EXISTS idx_ip_is_active 
    ON public.instagram_post (is_active) 
    WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_ip_is_deleted 
    ON public.instagram_post (is_deleted) 
    WHERE is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_ip_is_video 
    ON public.instagram_post (is_video) 
    WHERE is_video = TRUE;

CREATE INDEX IF NOT EXISTS idx_ip_ai_analyzed_at
    ON public.instagram_post (ai_analyzed_at DESC)
    WHERE ai_analyzed_at IS NOT NULL;

-- 위치 기반 검색 인덱스
CREATE INDEX IF NOT EXISTS idx_ip_location_coords 
    ON public.instagram_post (latitude, longitude) 
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- 통계 기반 인덱스
CREATE INDEX IF NOT EXISTS idx_ip_popular 
    ON public.instagram_post (like_count DESC, comment_count DESC) 
    WHERE like_count > 100;

CREATE INDEX IF NOT EXISTS idx_ip_viral_videos 
    ON public.instagram_post (view_count DESC) 
    WHERE is_video = TRUE AND view_count > 1000;

-- 배열 컬럼 GIN 인덱스
CREATE INDEX IF NOT EXISTS idx_ip_hashtags_gin 
    ON public.instagram_post USING GIN (hashtags);

CREATE INDEX IF NOT EXISTS idx_ip_mentions_gin 
    ON public.instagram_post USING GIN (mentions);

CREATE INDEX IF NOT EXISTS idx_ip_media_urls_gin 
    ON public.instagram_post USING GIN (media_urls);

CREATE INDEX IF NOT EXISTS idx_ip_ai_meta_category_gin
    ON public.instagram_post USING GIN (ai_meta_category);

CREATE INDEX IF NOT EXISTS idx_ip_ai_meta_activity_type_gin
    ON public.instagram_post USING GIN (ai_meta_activity_type);

CREATE INDEX IF NOT EXISTS idx_ip_ai_meta_special_tag_gin
    ON public.instagram_post USING GIN (ai_meta_special_tag);

CREATE INDEX IF NOT EXISTS idx_ip_ai_meta_city_gin
    ON public.instagram_post USING GIN (ai_meta_city);

CREATE INDEX IF NOT EXISTS idx_ip_ai_meta_landmark_gin
    ON public.instagram_post USING GIN (ai_meta_landmark);

CREATE INDEX IF NOT EXISTS idx_ip_ai_meta_place_gin
    ON public.instagram_post USING GIN (ai_meta_place);

-- JSONB GIN 인덱스 (jsonb_path_ops로 최적화)
CREATE INDEX IF NOT EXISTS idx_ip_ai_places_gin 
    ON public.instagram_post USING GIN (ai_places jsonb_path_ops) 
    WHERE ai_places IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ip_metadata_json_gin 
    ON public.instagram_post USING GIN (metadata_json jsonb_path_ops) 
    WHERE metadata_json IS NOT NULL;

-- 전체 텍스트 검색 인덱스
CREATE INDEX IF NOT EXISTS idx_ip_text_search_gin 
    ON public.instagram_post USING GIN (
        to_tsvector('simple', 
            COALESCE(caption, '') || ' ' || 
            COALESCE(username, '') || ' ' ||
            COALESCE(location_name, '')
        )
    );

-- 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_ip_user_date 
    ON public.instagram_post (username, published_date DESC) 
    WHERE username IS NOT NULL AND published_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ip_location_date 
    ON public.instagram_post (location_id, published_date DESC) 
    WHERE location_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ip_city_type 
    ON public.instagram_post (city, post_type) 
    WHERE city IS NOT NULL;

-- ========================================
-- RLS: instagram_post
-- ========================================
ALTER TABLE public.instagram_post ENABLE ROW LEVEL SECURITY;

CREATE POLICY "instagram_post is visible to everyone" 
    ON public.instagram_post FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

CREATE POLICY "Service role can manage instagram_post" 
    ON public.instagram_post FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- ========================================
-- 트리거: instagram_post updated_at 자동 갱신
-- ========================================
CREATE OR REPLACE FUNCTION public.update_instagram_post_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_ip_updated_at
    BEFORE UPDATE ON public.instagram_post
    FOR EACH ROW
    EXECUTE FUNCTION public.update_instagram_post_updated_at();


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║                       2. INSTAGRAM_POST 관련 함수                          ║
-- ║                                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

/*
 ***********************************************************************************************
 * FUNCTION: Instagram 포스트 데이터 Upsert
 ***********************************************************************************************
 * 설명: 크롤링/API 데이터를 instagram_post 테이블에 저장
 * 용도: 데이터 fetch 후 호출
 * 
 * 반환: {success, post_id}
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION public.upsert_instagram_post_data(
    p_post_id VARCHAR(50),
    p_post_url TEXT,
    p_post_type VARCHAR(20) DEFAULT 'image',
    p_caption TEXT DEFAULT NULL,
    p_hashtags TEXT[] DEFAULT NULL,
    p_mentions TEXT[] DEFAULT NULL,
    p_published_date TIMESTAMPTZ DEFAULT NULL,
    p_media_count INTEGER DEFAULT 1,
    p_media_urls TEXT[] DEFAULT NULL,
    p_thumbnail_url TEXT DEFAULT NULL,
    p_video_duration_seconds INTEGER DEFAULT NULL,
    p_is_video BOOLEAN DEFAULT FALSE,
    p_user_id VARCHAR(50) DEFAULT NULL,
    p_username VARCHAR(100) DEFAULT NULL,
    p_user_full_name VARCHAR(255) DEFAULT NULL,
    p_user_profile_url TEXT DEFAULT NULL,
    p_user_profile_pic_url TEXT DEFAULT NULL,
    p_user_is_verified BOOLEAN DEFAULT FALSE,
    p_user_follower_count BIGINT DEFAULT NULL,
    p_like_count BIGINT DEFAULT 0,
    p_comment_count BIGINT DEFAULT 0,
    p_view_count BIGINT DEFAULT 0,
    p_share_count BIGINT DEFAULT 0,
    p_save_count BIGINT DEFAULT 0,
    p_location_id VARCHAR(100) DEFAULT NULL,
    p_location_name VARCHAR(255) DEFAULT NULL,
    p_location_slug VARCHAR(255) DEFAULT NULL,
    p_latitude NUMERIC(10,8) DEFAULT NULL,
    p_longitude NUMERIC(11,8) DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_city VARCHAR(100) DEFAULT NULL,
    p_country VARCHAR(100) DEFAULT NULL,
    p_country_code VARCHAR(10) DEFAULT NULL,
    p_og_title TEXT DEFAULT NULL,
    p_og_description TEXT DEFAULT NULL,
    p_og_image TEXT DEFAULT NULL,
    p_og_url TEXT DEFAULT NULL,
    p_metadata_json JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    -- post_id 필수 체크
    IF p_post_id IS NULL OR p_post_id = '' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'post_id is required'
        );
    END IF;
    
    -- post_url 필수 체크
    IF p_post_url IS NULL OR p_post_url = '' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'post_url is required'
        );
    END IF;

    -- Upsert
    INSERT INTO public.instagram_post (
        post_id,
        post_url,
        post_type,
        caption,
        hashtags,
        mentions,
        published_date,
        media_count,
        media_urls,
        thumbnail_url,
        video_duration_seconds,
        is_video,
        user_id,
        username,
        user_full_name,
        user_profile_url,
        user_profile_pic_url,
        user_is_verified,
        user_follower_count,
        like_count,
        comment_count,
        view_count,
        share_count,
        save_count,
        location_id,
        location_name,
        location_slug,
        latitude,
        longitude,
        address,
        city,
        country,
        country_code,
        og_title,
        og_description,
        og_image,
        og_url,
        metadata_json,
        last_processed_at
    ) VALUES (
        p_post_id,
        p_post_url,
        p_post_type,
        p_caption,
        p_hashtags,
        p_mentions,
        p_published_date,
        p_media_count,
        p_media_urls,
        p_thumbnail_url,
        p_video_duration_seconds,
        p_is_video,
        p_user_id,
        p_username,
        p_user_full_name,
        p_user_profile_url,
        p_user_profile_pic_url,
        p_user_is_verified,
        p_user_follower_count,
        p_like_count,
        p_comment_count,
        p_view_count,
        p_share_count,
        p_save_count,
        p_location_id,
        p_location_name,
        p_location_slug,
        p_latitude,
        p_longitude,
        p_address,
        p_city,
        p_country,
        p_country_code,
        p_og_title,
        p_og_description,
        p_og_image,
        p_og_url,
        p_metadata_json,
        NOW()
    )
    ON CONFLICT (post_id) DO UPDATE SET
        post_url = EXCLUDED.post_url,
        post_type = EXCLUDED.post_type,
        caption = COALESCE(EXCLUDED.caption, public.instagram_post.caption),
        hashtags = COALESCE(EXCLUDED.hashtags, public.instagram_post.hashtags),
        mentions = COALESCE(EXCLUDED.mentions, public.instagram_post.mentions),
        published_date = COALESCE(EXCLUDED.published_date, public.instagram_post.published_date),
        media_count = EXCLUDED.media_count,
        media_urls = COALESCE(EXCLUDED.media_urls, public.instagram_post.media_urls),
        thumbnail_url = COALESCE(EXCLUDED.thumbnail_url, public.instagram_post.thumbnail_url),
        video_duration_seconds = COALESCE(EXCLUDED.video_duration_seconds, public.instagram_post.video_duration_seconds),
        is_video = EXCLUDED.is_video,
        user_id = COALESCE(EXCLUDED.user_id, public.instagram_post.user_id),
        username = COALESCE(EXCLUDED.username, public.instagram_post.username),
        user_full_name = COALESCE(EXCLUDED.user_full_name, public.instagram_post.user_full_name),
        user_profile_url = COALESCE(EXCLUDED.user_profile_url, public.instagram_post.user_profile_url),
        user_profile_pic_url = COALESCE(EXCLUDED.user_profile_pic_url, public.instagram_post.user_profile_pic_url),
        user_is_verified = EXCLUDED.user_is_verified,
        user_follower_count = COALESCE(EXCLUDED.user_follower_count, public.instagram_post.user_follower_count),
        like_count = EXCLUDED.like_count,
        comment_count = EXCLUDED.comment_count,
        view_count = EXCLUDED.view_count,
        share_count = EXCLUDED.share_count,
        save_count = EXCLUDED.save_count,
        location_id = COALESCE(EXCLUDED.location_id, public.instagram_post.location_id),
        location_name = COALESCE(EXCLUDED.location_name, public.instagram_post.location_name),
        location_slug = COALESCE(EXCLUDED.location_slug, public.instagram_post.location_slug),
        latitude = COALESCE(EXCLUDED.latitude, public.instagram_post.latitude),
        longitude = COALESCE(EXCLUDED.longitude, public.instagram_post.longitude),
        address = COALESCE(EXCLUDED.address, public.instagram_post.address),
        city = COALESCE(EXCLUDED.city, public.instagram_post.city),
        country = COALESCE(EXCLUDED.country, public.instagram_post.country),
        country_code = COALESCE(EXCLUDED.country_code, public.instagram_post.country_code),
        og_title = COALESCE(EXCLUDED.og_title, public.instagram_post.og_title),
        og_description = COALESCE(EXCLUDED.og_description, public.instagram_post.og_description),
        og_image = COALESCE(EXCLUDED.og_image, public.instagram_post.og_image),
        og_url = COALESCE(EXCLUDED.og_url, public.instagram_post.og_url),
        metadata_json = COALESCE(EXCLUDED.metadata_json, public.instagram_post.metadata_json),
        last_processed_at = NOW();

    RETURN jsonb_build_object(
        'success', true,
        'post_id', p_post_id
    );
END;
$$;

COMMENT ON FUNCTION public.upsert_instagram_post_data IS 
'Instagram 포스트 데이터를 instagram_post 테이블에 저장 (post_id 기반)';


/*
 ***********************************************************************************************
 * FUNCTION: AI 분석 결과 저장
 ***********************************************************************************************
 * 설명: AI 분석 결과를 instagram_post 테이블의 ai_* 필드에 저장
 * 용도: AI 분석 완료 후 호출
 * 
 * 파라미터: 모든 파라미터는 선택적 (NULL이면 기존 값 유지)
 * 반환: {success, post_id, places_count} 또는 {success: false, error}
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION public.upsert_instagram_post_ai_analysis(
    p_post_id VARCHAR(50),
    p_ai_summary TEXT DEFAULT NULL,
    p_ai_key_points TEXT[] DEFAULT NULL,
    p_ai_meta_category TEXT[] DEFAULT NULL,
    p_ai_meta_influencer TEXT[] DEFAULT NULL,
    p_ai_meta_season TEXT[] DEFAULT NULL,
    p_ai_meta_time_of_day TEXT[] DEFAULT NULL,
    p_ai_meta_activity_type TEXT[] DEFAULT NULL,
    p_ai_meta_special_tag TEXT[] DEFAULT NULL,
    p_ai_meta_kpop TEXT[] DEFAULT NULL,
    p_ai_meta_target_age TEXT[] DEFAULT NULL,
    p_ai_meta_target_audience TEXT[] DEFAULT NULL,
    p_ai_meta_landmark TEXT[] DEFAULT NULL,
    p_ai_meta_city TEXT[] DEFAULT NULL,
    p_ai_meta_country TEXT[] DEFAULT NULL,
    p_ai_meta_district TEXT[] DEFAULT NULL,
    p_ai_meta_neighborhood TEXT[] DEFAULT NULL,
    p_ai_meta_place TEXT[] DEFAULT NULL,
    p_ai_places JSONB DEFAULT NULL,
    p_ai_model VARCHAR(50) DEFAULT NULL,
    p_ai_confidence NUMERIC(3,2) DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_places_count SMALLINT;
BEGIN
    -- post_id 존재 확인
    IF NOT EXISTS (SELECT 1 FROM public.instagram_post WHERE post_id = p_post_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'post_id not found'
        );
    END IF;
    
    -- 장소 개수 계산 (있는 경우)
    v_places_count := CASE 
        WHEN p_ai_places IS NOT NULL 
        THEN jsonb_array_length(p_ai_places)::SMALLINT
        ELSE NULL
    END;
    
    -- AI 분석 결과 업데이트 (COALESCE로 NULL이면 기존 값 유지)
    UPDATE public.instagram_post SET
        ai_summary = COALESCE(p_ai_summary, ai_summary),
        ai_key_points = COALESCE(p_ai_key_points, ai_key_points),
        ai_meta_category = COALESCE(p_ai_meta_category, ai_meta_category),
        ai_meta_influencer = COALESCE(p_ai_meta_influencer, ai_meta_influencer),
        ai_meta_season = COALESCE(p_ai_meta_season, ai_meta_season),
        ai_meta_time_of_day = COALESCE(p_ai_meta_time_of_day, ai_meta_time_of_day),
        ai_meta_activity_type = COALESCE(p_ai_meta_activity_type, ai_meta_activity_type),
        ai_meta_special_tag = COALESCE(p_ai_meta_special_tag, ai_meta_special_tag),
        ai_meta_kpop = COALESCE(p_ai_meta_kpop, ai_meta_kpop),
        ai_meta_target_age = COALESCE(p_ai_meta_target_age, ai_meta_target_age),
        ai_meta_target_audience = COALESCE(p_ai_meta_target_audience, ai_meta_target_audience),
        ai_meta_landmark = COALESCE(p_ai_meta_landmark, ai_meta_landmark),
        ai_meta_city = COALESCE(p_ai_meta_city, ai_meta_city),
        ai_meta_country = COALESCE(p_ai_meta_country, ai_meta_country),
        ai_meta_district = COALESCE(p_ai_meta_district, ai_meta_district),
        ai_meta_neighborhood = COALESCE(p_ai_meta_neighborhood, ai_meta_neighborhood),
        ai_meta_place = COALESCE(p_ai_meta_place, ai_meta_place),
        ai_places = COALESCE(p_ai_places, ai_places),
        ai_places_count = COALESCE(v_places_count, ai_places_count),
        ai_model = COALESCE(p_ai_model, ai_model),
        ai_confidence = COALESCE(p_ai_confidence, ai_confidence),
        ai_analyzed_at = NOW(),
        last_processed_at = NOW()
    WHERE post_id = p_post_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'post_id', p_post_id,
        'places_count', v_places_count
    );
END;
$$;

COMMENT ON FUNCTION public.upsert_instagram_post_ai_analysis IS 
'AI 분석 결과를 instagram_post 테이블의 ai_* 필드에 저장';


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║                               3. 뷰 (VIEW)                                ║
-- ║                                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

/*
 ***********************************************************************************************
 * VIEW: 장소 검색용 뷰
 ***********************************************************************************************
 * 설명: ai_places JSONB를 행으로 펼쳐서 장소별 검색 가능하게 함
 * 용도: 특정 장소가 포함된 포스트 검색
 * 
 * 쿼리 예시:
 *   SELECT * FROM instagram_post_places WHERE city = '서울';
 *   SELECT * FROM instagram_post_places WHERE place_name LIKE '%카페%';
 *   SELECT * FROM instagram_post_places WHERE place_type = 'restaurant';
 *   SELECT * FROM instagram_post_places WHERE country = 'KR' AND city = '부산';
 ***********************************************************************************************
 */
CREATE OR REPLACE VIEW public.instagram_post_places AS
SELECT 
    -- 포스트 정보
    ip.post_id,
    ip.post_url,
    ip.caption,
    ip.username,
    ip.user_id,
    ip.published_date,
    ip.post_type,
    ip.like_count,
    ip.comment_count,
    ip.thumbnail_url,
    
    -- 장소 기본 정보
    place.value->>'place_name' AS place_name,
    place.value->>'place_name_en' AS place_name_en,
    place.value->>'place_name_native' AS place_name_native,
    place.value->>'place_type' AS place_type,
    
    -- 위치 정보
    place.value->>'country' AS country,
    place.value->>'city' AS city,
    place.value->>'district' AS district,
    place.value->>'neighborhood' AS neighborhood,
    place.value->>'landmark' AS landmark,
    place.value->>'address' AS address,
    (place.value->>'latitude')::NUMERIC AS latitude,
    (place.value->>'longitude')::NUMERIC AS longitude,
    
    -- 시간 정보 (이벤트/축제용)
    place.value->>'period' AS period,
    place.value->>'start_date' AS start_date,
    place.value->>'end_date' AS end_date,
    place.value->>'operation_hours' AS operation_hours,
    
    -- 상세 정보
    place.value->'prices' AS prices,
    place.value->'recommend_menu' AS recommend_menu,
    place.value->'travel_tips' AS travel_tips,
    place.value->>'notice' AS notice,
    place.value->>'review_summary' AS review_summary,
    (place.value->>'reservation_required')::BOOLEAN AS reservation_required,
    
    -- 포스트 내 위치
    (place.value->>'order_in_post')::INTEGER AS order_in_post
    
FROM public.instagram_post ip
CROSS JOIN LATERAL jsonb_array_elements(ip.ai_places) AS place(value)
WHERE ip.ai_places IS NOT NULL 
    AND ip.is_active = TRUE 
    AND ip.is_deleted = FALSE;
