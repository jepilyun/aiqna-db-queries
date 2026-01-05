/*
 * aiqna db for web service (YouTube Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-09-24
 * Updated 2025-12-01
 * 
 * 테이블 구조:
 *   1. youtube_video              - YouTube 비디오 메타데이터 (YouTube Data API v3)
 *   2. youtube_video_transcript   - 비디오별 언어별 자막 데이터
 * 
 * 관계:
 *   youtube_video (1) : youtube_video_transcript (N)
 * 
 * 뷰:
 *   youtube_video_places          - 장소별 비디오 검색용 (ai_places JSONB 펼침)
 */

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║                         1. YOUTUBE_VIDEO 테이블                            ║
-- ║                                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

/*
 ***********************************************************************************************
 * TABLE: youtube_video
 ***********************************************************************************************
 * 설명: YouTube 비디오 메타데이터 저장
 * 데이터 소스: YouTube Data API v3
 * 
 * 섹션:
 *   - 기본 정보 (snippet)
 *   - 통계 정보 (statistics)  
 *   - 콘텐츠 세부사항 (contentDetails)
 *   - 상태 정보 (status)
 *   - 주제 정보 (topicDetails)
 *   - 썸네일 정보 (thumbnails)
 *   - AI 분석 결과 (ai_*)
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS youtube_video (
    -- ========================================
    -- 기본 키 및 API 메타
    -- ========================================
    video_id VARCHAR(20) PRIMARY KEY,
    etag VARCHAR(100) NULL,
    kind VARCHAR(50) NOT NULL DEFAULT 'youtube#video',
    
    -- ========================================
    -- 기본 정보 (snippet)
    -- ========================================
    title TEXT NOT NULL,
    description TEXT NULL,
    published_date TIMESTAMPTZ NULL,
    is_shorts BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- ========================================
    -- 채널 정보 (snippet)
    -- ========================================
    channel_id VARCHAR(50) NULL,
    channel_name VARCHAR(255) NULL,
    channel_url TEXT NULL,
    
    -- ========================================
    -- AI 분석 결과 - 비디오 전체 요약 (description, transcript)
    -- ========================================
    ai_description_summary TEXT NULL,                     -- 비디오 description을 기반으로 한 요약
    ai_description_key_points TEXT[] NULL,                -- 핵심 키포인트 배열 (description을 기반으로 한 핵심 키포인트)

    ai_meta_category TEXT[] NULL,                  -- 카테고리 ['맛집', '관광', '카페']
    ai_meta_influencer TEXT[] NULL,                -- 출연 인플루언서
    ai_meta_season TEXT[] NULL,                    -- 적합한 계절 ['봄', '가을']
    ai_meta_time_of_day TEXT[] NULL,               -- 적합한 시간대 ['아침', '저녁']
    ai_meta_activity_type TEXT[] NULL,             -- 활동 유형 ['데이트', '가족여행', '혼행']
    ai_meta_special_tag TEXT[] NULL,               -- 특수 태그 ['브이로그', '먹방', 'ASMR']
    ai_meta_kpop TEXT[] NULL,                      -- K-POP 관련 태그 ['BTS', 'BLACKPINK', 'EXO']
    ai_meta_target_age TEXT[] NULL,                -- 타겟 연령 ['20대', '30대', '40대', '50대', '60대 이상']
    ai_meta_target_audience TEXT[] NULL,           -- 타겟 ['20대', '커플', '외국인']
    ai_meta_landmark TEXT[] NULL,                  -- 랜드마크 ['광화문', '경복궁', '창덕궁']
    ai_meta_city TEXT[] NULL,                      -- 도시 ['서울', '부산', '인천']
    ai_meta_country TEXT[] NULL,                   -- 국가 ['대한민국', '미국', '일본']
    ai_meta_district TEXT[] NULL,                  -- 구 ['종로구', '강남구', '서초구']
    ai_meta_neighborhood TEXT[] NULL,              -- 동 ['세종로', '강남동', '서초동']
    ai_meta_place TEXT[] NULL,                     -- 장소 ['경복궁', '창덕궁', '창덕궁']
    
    ai_places JSONB NULL,                          -- 장소 상세 정보
    ai_places_count SMALLINT NULL,                 -- 장소 개수 (쿼리 최적화용)
    
    -- ========================================
    -- AI 분석 결과 - 장소별 상세 정보
    -- ========================================
    /*
    ai_places 구조:
    [
        {
            "place_name": "경복궁",
            "place_name_en": "Gyeongbokgung Palace",
            "place_name_native": "景福宮",
            "place_type": "attraction",  -- restaurant, cafe, hotel, shop, event, other
            "country": "KR",
            "city": "서울",
            "district": "종로구",
            "neighborhood": "세종로",
            "landmark": "광화문 근처",
            "address": "서울특별시 종로구 사직로 161",
            "period": "조선시대",
            "start_date": null,
            "end_date": null,
            "operation_hours": "09:00-18:00 (월 휴무)",
            "prices": {"adult": 3000, "child": 1500, "free_entry": "한복 착용 시 무료", "currency": "KRW"},
            "recommend_menu": null,
            "travel_tips": ["한복 대여소가 근처에 많음", "수문장 교대식 10:00, 14:00"],
            "notice": "월요일 휴궁",
            "review_summary": "서울 대표 고궁",
            "reservation_required": false,
            "order_in_video": 1,
            "timestamp_start": "00:01:30",
            "timestamp_end": "00:05:45"
        }
    ]
    */
    
    -- ========================================
    -- AI 분석 메타
    -- ========================================
    ai_analyzed_at TIMESTAMPTZ NULL,
    ai_model VARCHAR(50) NULL,
    ai_confidence NUMERIC(3,2) NULL,       -- 0.00 ~ 1.00

    -- ========================================
    -- 카테고리 및 언어 (snippet)
    -- ========================================
    category_id VARCHAR(10) NULL,
    language VARCHAR(10) NULL,
    default_audio_language VARCHAR(10) NULL,
    
    -- ========================================
    -- 현지화 정보 (snippet.localized)
    -- ========================================
    localized_title TEXT NULL,
    localized_description TEXT NULL,
    
    -- ========================================
    -- 라이브 방송 관련 (snippet)
    -- ========================================
    live_broadcast_content VARCHAR(20) NULL,
    
    -- ========================================
    -- 태그 (snippet)
    -- ========================================
    tags TEXT[] NULL,
    
    -- ========================================
    -- 통계 정보 (statistics)
    -- ========================================
    view_count BIGINT NOT NULL DEFAULT 0,
    like_count BIGINT NOT NULL DEFAULT 0,
    favorite_count BIGINT NOT NULL DEFAULT 0,
    comment_count BIGINT NOT NULL DEFAULT 0,
    
    -- ========================================
    -- 콘텐츠 세부사항 (contentDetails)
    -- ========================================
    duration_text VARCHAR(20) NULL,             -- "PT1H2M30S" (ISO 8601)
    duration_seconds INTEGER NULL,              -- 3750 (초 단위 변환)
    dimension VARCHAR(10) NULL,                 -- "2d", "3d"
    definition VARCHAR(10) NULL,                -- "hd", "sd"
    caption BOOLEAN NULL,                       -- 자막 존재 여부
    licensed_content BOOLEAN NULL,
    projection VARCHAR(20) NULL,                -- "rectangular", "360"
    
    -- ========================================
    -- 상태 정보 (status)
    -- ========================================
    upload_status VARCHAR(50) NULL,             -- "processed", "uploaded", "failed"
    privacy_status VARCHAR(20) NULL,            -- "public", "private", "unlisted"
    license VARCHAR(50) NULL,                   -- "youtube", "creativeCommon"
    embeddable BOOLEAN NULL,
    public_stats_viewable BOOLEAN NULL,
    
    -- ========================================
    -- 주제 정보 (topicDetails)
    -- ========================================
    topic_ids TEXT[] NULL,
    relevant_topic_ids TEXT[] NULL,
    
    -- ========================================
    -- 썸네일 정보 - default (120x90)
    -- ========================================
    thumbnail_default_url TEXT NULL,
    thumbnail_default_width INTEGER NULL,
    thumbnail_default_height INTEGER NULL,
    
    -- ========================================
    -- 썸네일 정보 - medium (320x180)
    -- ========================================
    thumbnail_medium_url TEXT NULL,
    thumbnail_medium_width INTEGER NULL,
    thumbnail_medium_height INTEGER NULL,
    
    -- ========================================
    -- 썸네일 정보 - high (480x360)
    -- ========================================
    thumbnail_high_url TEXT NULL,
    thumbnail_high_width INTEGER NULL,
    thumbnail_high_height INTEGER NULL,
    
    -- ========================================
    -- 썸네일 정보 - standard (640x480)
    -- ========================================
    thumbnail_standard_url TEXT NULL,
    thumbnail_standard_width INTEGER NULL,
    thumbnail_standard_height INTEGER NULL,
    
    -- ========================================
    -- 썸네일 정보 - maxres (1280x720)
    -- ========================================
    thumbnail_maxres_url TEXT NULL,
    thumbnail_maxres_width INTEGER NULL,
    thumbnail_maxres_height INTEGER NULL,
    
    -- ========================================
    -- 기존 호환성 필드 (deprecated, 향후 제거 예정)
    -- ========================================
    thumbnail_url TEXT NULL,
    thumbnail_width INTEGER NULL,
    thumbnail_height INTEGER NULL,
    upload_date DATE NULL,
    category VARCHAR(100) NULL,
    
    -- ========================================
    -- 불린 플래그
    -- ========================================
    is_live BOOLEAN NOT NULL DEFAULT FALSE,
    is_upcoming BOOLEAN NOT NULL DEFAULT FALSE,
    is_private BOOLEAN NOT NULL DEFAULT FALSE,
    age_restricted BOOLEAN NOT NULL DEFAULT FALSE,
    family_safe BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- ========================================
    -- 자막 정보 (트리거로 자동 동기화)
    -- ========================================
    available_transcript_langs VARCHAR(12)[] NULL,  -- ['ko', 'en', 'zh-Hans']
    
    -- ========================================
    -- 시스템 관리
    -- ========================================
    metadata_json JSONB NULL,                   -- 원본 API 응답 저장 (디버깅용)
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
    CONSTRAINT yv_duration_seconds_check 
        CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
    CONSTRAINT yv_view_count_check 
        CHECK (view_count >= 0),
    CONSTRAINT yv_like_count_check 
        CHECK (like_count >= 0),
    CONSTRAINT yv_comment_count_check 
        CHECK (comment_count >= 0),
    CONSTRAINT yv_favorite_count_check 
        CHECK (favorite_count >= 0),
    CONSTRAINT yv_ai_places_count_check
        CHECK (ai_places_count IS NULL OR ai_places_count >= 0),
    CONSTRAINT yv_ai_confidence_check
        CHECK (ai_confidence IS NULL OR (ai_confidence >= 0 AND ai_confidence <= 1)),
    CONSTRAINT yv_deleted_logic_check
        CHECK (
            (is_deleted = FALSE AND deleted_at IS NULL) 
            OR (is_deleted = TRUE AND deleted_at IS NOT NULL)
        )
);

-- ========================================
-- 인덱스: youtube_video
-- ========================================
-- 기본 검색 인덱스
CREATE INDEX IF NOT EXISTS idx_yv_channel_id 
    ON public.youtube_video (channel_id);
CREATE INDEX IF NOT EXISTS idx_yv_published_date 
    ON public.youtube_video (published_date);
CREATE INDEX IF NOT EXISTS idx_yv_category_id 
    ON public.youtube_video (category_id);
CREATE INDEX IF NOT EXISTS idx_yv_live_broadcast_content 
    ON public.youtube_video (live_broadcast_content);
CREATE INDEX IF NOT EXISTS idx_yv_privacy_status 
    ON public.youtube_video (privacy_status);

-- 조건부 인덱스 (Partial Index)
CREATE INDEX IF NOT EXISTS idx_yv_is_active 
    ON public.youtube_video (is_active) 
    WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_yv_is_deleted 
    ON public.youtube_video (is_deleted) 
    WHERE is_deleted = FALSE;
CREATE INDEX IF NOT EXISTS idx_yv_is_shorts 
    ON public.youtube_video (is_shorts) 
    WHERE is_shorts = TRUE;
CREATE INDEX IF NOT EXISTS idx_yv_ai_analyzed_at
    ON public.youtube_video (ai_analyzed_at)
    WHERE ai_analyzed_at IS NOT NULL;

-- 배열 컬럼 GIN 인덱스
CREATE INDEX IF NOT EXISTS idx_yv_tags_gin 
    ON public.youtube_video USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_yv_topic_ids_gin 
    ON public.youtube_video USING GIN (topic_ids);
CREATE INDEX IF NOT EXISTS idx_yv_relevant_topic_ids_gin 
    ON public.youtube_video USING GIN (relevant_topic_ids);
CREATE INDEX IF NOT EXISTS idx_yv_available_transcript_langs_gin 
    ON public.youtube_video USING GIN (available_transcript_langs);
CREATE INDEX IF NOT EXISTS idx_yv_ai_meta_category_gin
    ON public.youtube_video USING GIN (ai_meta_category);
CREATE INDEX IF NOT EXISTS idx_yv_ai_meta_activity_type_gin
    ON public.youtube_video USING GIN (ai_meta_activity_type);
CREATE INDEX IF NOT EXISTS idx_yv_ai_meta_special_tag_gin
    ON public.youtube_video USING GIN (ai_meta_special_tag);
CREATE INDEX IF NOT EXISTS idx_yv_ai_meta_city_gin
    ON public.youtube_video USING GIN (ai_meta_city);
CREATE INDEX IF NOT EXISTS idx_yv_ai_meta_landmark_gin
    ON public.youtube_video USING GIN (ai_meta_landmark);

-- JSONB GIN 인덱스 (장소 검색용)
CREATE INDEX IF NOT EXISTS idx_yv_ai_places_gin 
    ON public.youtube_video USING GIN (ai_places);

-- 전체 텍스트 검색 인덱스
CREATE INDEX IF NOT EXISTS idx_yv_title_description_gin 
    ON public.youtube_video USING GIN (
        to_tsvector('simple', COALESCE(title, '') || ' ' || COALESCE(description, ''))
    );

-- ========================================
-- RLS: youtube_video
-- ========================================
ALTER TABLE public.youtube_video ENABLE ROW LEVEL SECURITY;

CREATE POLICY "youtube_video is visible to everyone" 
    ON public.youtube_video FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

CREATE POLICY "Service role can manage youtube_video" 
    ON public.youtube_video FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- ========================================
-- 트리거: youtube_video updated_at 자동 갱신
-- ========================================
CREATE OR REPLACE FUNCTION update_youtube_video_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_yv_updated_at
    BEFORE UPDATE ON public.youtube_video
    FOR EACH ROW
    EXECUTE FUNCTION update_youtube_video_updated_at();






-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║                    2. YOUTUBE_VIDEO_TRANSCRIPT 테이블                      ║
-- ║                                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

/*
 ***********************************************************************************************
 * TABLE: youtube_video_transcript
 ***********************************************************************************************
 * 설명: YouTube 비디오의 언어별 자막 저장 및 처리 상태 추적
 * 관계: youtube_video (1) : youtube_video_transcript (N)
 * 
 * 처리 흐름:
 *   1. Fetch     - 자막 원본 가져오기 (YouTube Transcript API)
 *   2. Analyze   - AI 분석 (핵심정보, 메타데이터 추출)
 *   3. Save DB   - 분석 결과 DB 저장
 *   4. Pinecone  - 벡터 저장소에 임베딩 저장
 * 
 * 자막 저장 전략:
 *   - 소용량 (< 100KB): transcript_text, transcript_segments에 직접 저장
 *   - 대용량 (>= 100KB): Supabase Storage에 저장, segments_storage_path에 경로 기록
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS youtube_video_transcript (
    -- ========================================
    -- 기본 키
    -- ========================================
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    video_id VARCHAR(20) NOT NULL,
    lang_code VARCHAR(12) NOT NULL,             -- ko, en, zh-Hans, zh-Hant 등
    
    -- ========================================
    -- 자막 메타 정보
    -- ========================================
    transcript_type VARCHAR(20) NOT NULL DEFAULT 'auto',  -- auto, manual, asr
    is_translatable BOOLEAN NOT NULL DEFAULT FALSE,       -- 번역 가능 여부
    is_auto_generated BOOLEAN NOT NULL DEFAULT FALSE,     -- 자동 생성 여부
    
    -- ========================================
    -- 자막 원본 데이터 (소용량용)
    -- ========================================
    transcript_text TEXT NULL,                  -- 전체 자막 텍스트
    transcript_segments JSONB NULL,             -- [{start, duration, text}, ...]
    
    -- ========================================
    -- 자막 통계
    -- ========================================
    word_count INTEGER NULL,                    -- 단어 수
    char_count INTEGER NULL,                    -- 문자 수
    segment_count INTEGER NULL,                 -- 세그먼트 개수
    duration_covered_seconds INTEGER NULL,      -- 자막이 커버하는 시간 (초)
    
    -- ========================================
    -- Storage 파일 정보 (대용량 자막용)
    -- ========================================
    segments_storage_path TEXT NULL,            -- "transcripts/raw/{video_id}_{lang_code}.json"
    segments_file_size BIGINT NULL,             -- 파일 크기 (bytes)
    is_stored_in_storage BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- ========================================
    -- AI 분석 결과 - 자막 기반 요약
    -- ========================================
    ai_transcript_summary TEXT NULL,            -- 자막 기반 요약
    ai_transcript_key_points TEXT[] NULL,       -- 자막 기반 핵심 키포인트 배열
    
    -- ========================================
    -- AI 분석 결과 - 메타데이터
    -- ========================================
    ai_meta_category TEXT[] NULL,               -- 카테고리 ['맛집', '관광', '카페']
    ai_meta_influencer TEXT[] NULL,             -- 출연 인플루언서
    ai_meta_season TEXT[] NULL,                 -- 적합한 계절 ['봄', '가을']
    ai_meta_time_of_day TEXT[] NULL,            -- 적합한 시간대 ['아침', '저녁']
    ai_meta_activity_type TEXT[] NULL,          -- 활동 유형 ['데이트', '가족여행', '혼행']
    ai_meta_special_tag TEXT[] NULL,            -- 특수 태그 ['브이로그', '먹방', 'ASMR']
    ai_meta_kpop TEXT[] NULL,                   -- K-POP 관련 태그 ['BTS', 'BLACKPINK', 'EXO']
    ai_meta_target_age TEXT[] NULL,             -- 타겟 연령 ['20대', '30대', '40대', '50대', '60대 이상']
    ai_meta_target_audience TEXT[] NULL,        -- 타겟 ['20대', '커플', '외국인']
    ai_meta_landmark TEXT[] NULL,               -- 랜드마크 ['광화문', '경복궁', '창덕궁']
    ai_meta_city TEXT[] NULL,                   -- 도시 ['서울', '부산', '인천']
    ai_meta_country TEXT[] NULL,                -- 국가 ['대한민국', '미국', '일본']
    ai_meta_district TEXT[] NULL,               -- 구 ['종로구', '강남구', '서초구']
    ai_meta_neighborhood TEXT[] NULL,           -- 동 ['세종로', '강남동', '서초동']
    ai_meta_place TEXT[] NULL,                  -- 장소 ['경복궁', '창덕궁', '창덕궁']
    
    -- ========================================
    -- AI 분석 결과 - 장소별 상세 정보
    -- ========================================
    ai_places JSONB NULL,                       -- 장소 상세 정보
    ai_places_count SMALLINT NULL,              -- 장소 개수 (쿼리 최적화용)
    /*
    ai_places 구조:
    [
        {
            "place_name": "경복궁",
            "place_name_en": "Gyeongbokgung Palace",
            "place_name_native": "景福宮",
            "place_type": "attraction",  -- restaurant, cafe, hotel, shop, event, other
            "country": "KR",
            "city": "서울",
            "district": "종로구",
            "neighborhood": "세종로",
            "landmark": "광화문 근처",
            "address": "서울특별시 종로구 사직로 161",
            "period": "조선시대",
            "start_date": null,
            "end_date": null,
            "operation_hours": "09:00-18:00 (월 휴무)",
            "prices": {"adult": 3000, "child": 1500, "free_entry": "한복 착용 시 무료", "currency": "KRW"},
            "recommend_menu": null,
            "travel_tips": ["한복 대여소가 근처에 많음", "수문장 교대식 10:00, 14:00"],
            "notice": "월요일 휴궁",
            "review_summary": "서울 대표 고궁",
            "reservation_required": false,
            "order_in_video": 1,
            "timestamp_start": "00:01:30",
            "timestamp_end": "00:05:45"
        }
    ]
    */
    
    -- ========================================
    -- AI 분석 메타 (기존 필드 유지)
    -- ========================================
    ai_summary TEXT NULL,                       -- [DEPRECATED] ai_transcript_summary로 대체됨
    ai_key_points JSONB NULL,                   -- [DEPRECATED] ai_transcript_key_points로 대체됨
    ai_topics JSONB NULL,                       -- 주제 추출 결과
    ai_metadata JSONB NULL,                     -- 추출된 메타데이터 (자유 형식)
    ai_model_used VARCHAR(50) NULL,             -- 사용된 AI 모델
    ai_analyzed_at TIMESTAMPTZ NULL,            -- AI 분석 완료 시간
    ai_token_count INTEGER NULL,                -- AI 분석에 사용된 토큰 수
    
    -- ========================================
    -- 처리 상태: Fetch (자막 가져오기)
    -- ========================================
    is_fetched BOOLEAN NOT NULL DEFAULT FALSE,
    is_error_fetched BOOLEAN NOT NULL DEFAULT FALSE,
    error_fetched_message TEXT NULL,
    fetched_at TIMESTAMPTZ NULL,
    
    -- ========================================
    -- 처리 상태: AI Analyze (분석)
    -- ========================================
    is_analyzed BOOLEAN NOT NULL DEFAULT FALSE,
    is_error_analyzed BOOLEAN NOT NULL DEFAULT FALSE,
    error_analyzed_message TEXT NULL,
    analyzed_at TIMESTAMPTZ NULL,
    
    -- ========================================
    -- 처리 상태: Save to DB
    -- ========================================
    is_saved_to_db BOOLEAN NOT NULL DEFAULT FALSE,
    is_error_saved_to_db BOOLEAN NOT NULL DEFAULT FALSE,
    error_saved_to_db_message TEXT NULL,
    saved_to_db_at TIMESTAMPTZ NULL,
    
    -- ========================================
    -- 처리 상태: Save to Pinecone (벡터 저장)
    -- ========================================
    is_saved_to_pinecone BOOLEAN NOT NULL DEFAULT FALSE,
    is_error_saved_to_pinecone BOOLEAN NOT NULL DEFAULT FALSE,
    error_saved_to_pinecone_message TEXT NULL,
    saved_to_pinecone_at TIMESTAMPTZ NULL,
    pinecone_vector_count INTEGER NULL,         -- 저장된 벡터 개수
    pinecone_namespace VARCHAR(100) NULL,       -- Pinecone 네임스페이스
    pinecone_index_name VARCHAR(100) NULL,      -- Pinecone 인덱스명
    
    -- ========================================
    -- 전체 처리 상태
    -- ========================================
    processing_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- pending: 대기, processing: 처리중, completed: 완료, 
    -- failed: 실패, partial: 부분완료, skipped: 건너뜀
    is_error_occurred BOOLEAN NOT NULL DEFAULT FALSE,
    retry_count INTEGER NOT NULL DEFAULT 0,
    max_retry_count INTEGER NOT NULL DEFAULT 3,
    
    -- ========================================
    -- 시스템 타임스탬프
    -- ========================================
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- ========================================
    -- 제약조건
    -- ========================================
    CONSTRAINT yvt_video_lang_unique 
        UNIQUE (video_id, lang_code),
    CONSTRAINT yvt_video_id_fkey 
        FOREIGN KEY (video_id) 
        REFERENCES public.youtube_video (video_id) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,
    CONSTRAINT yvt_transcript_type_check 
        CHECK (transcript_type IN ('auto', 'manual', 'asr')),
    CONSTRAINT yvt_processing_status_check 
        CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed', 'partial', 'skipped')),
    CONSTRAINT yvt_word_count_check 
        CHECK (word_count IS NULL OR word_count >= 0),
    CONSTRAINT yvt_char_count_check 
        CHECK (char_count IS NULL OR char_count >= 0),
    CONSTRAINT yvt_segment_count_check 
        CHECK (segment_count IS NULL OR segment_count >= 0),
    CONSTRAINT yvt_duration_covered_check 
        CHECK (duration_covered_seconds IS NULL OR duration_covered_seconds >= 0),
    CONSTRAINT yvt_segments_file_size_check 
        CHECK (segments_file_size IS NULL OR segments_file_size >= 0),
    CONSTRAINT yvt_pinecone_vector_count_check 
        CHECK (pinecone_vector_count IS NULL OR pinecone_vector_count >= 0),
    CONSTRAINT yvt_ai_token_count_check 
        CHECK (ai_token_count IS NULL OR ai_token_count >= 0),
    CONSTRAINT yvt_retry_count_check 
        CHECK (retry_count >= 0 AND retry_count <= max_retry_count),
    CONSTRAINT yvt_ai_places_count_check
        CHECK (ai_places_count IS NULL OR ai_places_count >= 0),
    -- Storage 저장 시 경로 필수
    CONSTRAINT yvt_storage_path_check 
        CHECK (
            (is_stored_in_storage = FALSE) 
            OR (is_stored_in_storage = TRUE AND segments_storage_path IS NOT NULL)
        )
);

-- ========================================
-- 인덱스: youtube_video_transcript
-- ========================================
-- 기본 검색 인덱스
CREATE INDEX IF NOT EXISTS idx_yvt_video_id 
    ON public.youtube_video_transcript (video_id);
CREATE INDEX IF NOT EXISTS idx_yvt_lang_code 
    ON public.youtube_video_transcript (lang_code);
CREATE INDEX IF NOT EXISTS idx_yvt_video_lang 
    ON public.youtube_video_transcript (video_id, lang_code);
CREATE INDEX IF NOT EXISTS idx_yvt_processing_status 
    ON public.youtube_video_transcript (processing_status);

-- 워커용 조건부 인덱스 (Partial Index)
CREATE INDEX IF NOT EXISTS idx_yvt_pending 
    ON public.youtube_video_transcript (processing_status, created_at ASC) 
    WHERE processing_status = 'pending';
CREATE INDEX IF NOT EXISTS idx_yvt_error_occurred 
    ON public.youtube_video_transcript (is_error_occurred) 
    WHERE is_error_occurred = TRUE;
CREATE INDEX IF NOT EXISTS idx_yvt_is_fetched 
    ON public.youtube_video_transcript (is_fetched) 
    WHERE is_fetched = TRUE;
CREATE INDEX IF NOT EXISTS idx_yvt_is_analyzed 
    ON public.youtube_video_transcript (is_analyzed) 
    WHERE is_analyzed = TRUE;
CREATE INDEX IF NOT EXISTS idx_yvt_is_stored_in_storage 
    ON public.youtube_video_transcript (is_stored_in_storage) 
    WHERE is_stored_in_storage = TRUE;

-- 배열 컬럼 GIN 인덱스 (AI 메타데이터 검색용)
CREATE INDEX IF NOT EXISTS idx_yvt_ai_meta_category_gin
    ON public.youtube_video_transcript USING GIN (ai_meta_category);
CREATE INDEX IF NOT EXISTS idx_yvt_ai_meta_activity_type_gin
    ON public.youtube_video_transcript USING GIN (ai_meta_activity_type);
CREATE INDEX IF NOT EXISTS idx_yvt_ai_meta_special_tag_gin
    ON public.youtube_video_transcript USING GIN (ai_meta_special_tag);
CREATE INDEX IF NOT EXISTS idx_yvt_ai_meta_city_gin
    ON public.youtube_video_transcript USING GIN (ai_meta_city);
CREATE INDEX IF NOT EXISTS idx_yvt_ai_meta_landmark_gin
    ON public.youtube_video_transcript USING GIN (ai_meta_landmark);
CREATE INDEX IF NOT EXISTS idx_yvt_ai_meta_place_gin
    ON public.youtube_video_transcript USING GIN (ai_meta_place);

-- JSONB GIN 인덱스 (장소 검색용)
CREATE INDEX IF NOT EXISTS idx_yvt_ai_places_gin 
    ON public.youtube_video_transcript USING GIN (ai_places);

-- ========================================
-- RLS: youtube_video_transcript
-- ========================================
ALTER TABLE public.youtube_video_transcript ENABLE ROW LEVEL SECURITY;

CREATE POLICY "youtube_video_transcript is visible to everyone" 
    ON public.youtube_video_transcript FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

CREATE POLICY "Service role can manage youtube_video_transcript" 
    ON public.youtube_video_transcript FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- ========================================
-- 트리거: youtube_video_transcript updated_at 자동 갱신
-- ========================================
CREATE OR REPLACE FUNCTION update_yvt_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_yvt_updated_at
    BEFORE UPDATE ON public.youtube_video_transcript
    FOR EACH ROW
    EXECUTE FUNCTION update_yvt_updated_at();




-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║                         3. 테이블 간 동기화 트리거                          ║
-- ║                                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

/*
 ***********************************************************************************************
 * TRIGGER FUNCTION: youtube_video.available_transcript_langs 자동 동기화
 ***********************************************************************************************
 * 설명: youtube_video_transcript에서 자막이 추가/삭제되면
 *       youtube_video.available_transcript_langs 자동 업데이트
 * 트리거 조건: INSERT, UPDATE OF is_fetched, DELETE
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION sync_youtube_video_transcript_langs()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_video_id VARCHAR(20);
    v_lang_codes VARCHAR(12)[];
BEGIN
    -- video_id 결정
    IF TG_OP = 'DELETE' THEN
        v_video_id := OLD.video_id;
    ELSE
        v_video_id := NEW.video_id;
    END IF;
    
    -- 해당 비디오의 모든 자막 언어 조회 (is_fetched = TRUE인 것만)
    SELECT ARRAY_AGG(lang_code ORDER BY lang_code)
    INTO v_lang_codes
    FROM public.youtube_video_transcript
    WHERE video_id = v_video_id
        AND is_fetched = TRUE;
    
    -- youtube_video 테이블 업데이트
    UPDATE public.youtube_video 
    SET available_transcript_langs = v_lang_codes,
        updated_at = NOW()
    WHERE video_id = v_video_id;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

CREATE TRIGGER trigger_sync_yvt_langs
    AFTER INSERT OR UPDATE OF is_fetched OR DELETE 
    ON public.youtube_video_transcript
    FOR EACH ROW 
    EXECUTE FUNCTION sync_youtube_video_transcript_langs();


/*
 ***********************************************************************************************
 * TRIGGER FUNCTION: processing_log_youtube_video 자막 요약 동기화
 ***********************************************************************************************
 * 설명: youtube_video_transcript의 processing_status가 변경되면
 *       processing_log_youtube_video의 자막 요약 필드 자동 업데이트
 * 
 * 동기화 필드:
 *   - transcript_total_lang_codes: 전체 자막 언어 배열
 *   - transcript_completed_lang_codes: 완료된 언어 배열
 *   - transcript_failed_lang_codes: 실패한 언어 배열
 *   - transcript_*_count: 각각의 카운트
 *   - is_all_transcripts_completed: 전체 완료 여부
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION sync_processing_log_transcript_summary()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_video_id VARCHAR(20);
    v_total_langs VARCHAR(12)[];
    v_completed_langs VARCHAR(12)[];
    v_failed_langs VARCHAR(12)[];
    v_total_count SMALLINT;
    v_completed_count SMALLINT;
    v_failed_count SMALLINT;
BEGIN
    -- video_id 결정
    IF TG_OP = 'DELETE' THEN
        v_video_id := OLD.video_id;
    ELSE
        v_video_id := NEW.video_id;
    END IF;
    
    -- 상태별 언어 집계
    SELECT 
        ARRAY_AGG(lang_code ORDER BY lang_code),
        ARRAY_AGG(lang_code ORDER BY lang_code) FILTER (WHERE processing_status = 'completed'),
        ARRAY_AGG(lang_code ORDER BY lang_code) FILTER (WHERE processing_status = 'failed')
    INTO v_total_langs, v_completed_langs, v_failed_langs
    FROM public.youtube_video_transcript
    WHERE video_id = v_video_id;
    
    -- 카운트 계산 (NULL 배열 처리)
    v_total_count := COALESCE(array_length(v_total_langs, 1), 0);
    v_completed_count := COALESCE(array_length(v_completed_langs, 1), 0);
    v_failed_count := COALESCE(array_length(v_failed_langs, 1), 0);
    
    -- processing_log 업데이트 (레코드가 있는 경우에만)
    UPDATE public.processing_log_youtube_video SET
        is_transcript_exist = (v_total_count > 0),
        transcript_total_lang_codes = v_total_langs,
        transcript_completed_lang_codes = v_completed_langs,
        transcript_failed_lang_codes = v_failed_langs,
        transcript_total_count = v_total_count,
        transcript_completed_count = v_completed_count,
        transcript_failed_count = v_failed_count,
        is_all_transcripts_completed = (v_total_count > 0 AND v_completed_count = v_total_count),
        updated_at = NOW()
    WHERE video_id = v_video_id;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

CREATE TRIGGER trigger_sync_transcript_summary
    AFTER INSERT OR UPDATE OF processing_status OR DELETE 
    ON public.youtube_video_transcript
    FOR EACH ROW 
    EXECUTE FUNCTION sync_processing_log_transcript_summary();


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║                              4. 유틸리티 함수                               ║
-- ║                                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

/*
 ***********************************************************************************************
 * FUNCTION: ISO 8601 Duration → Seconds 변환
 ***********************************************************************************************
 * 설명: YouTube API duration 형식을 초 단위로 변환
 * 입력: "PT1H2M30S" (ISO 8601 duration)
 * 출력: 3750 (초)
 * 
 * 예시:
 *   iso8601_duration_to_seconds('PT1H2M30S') → 3750
 *   iso8601_duration_to_seconds('PT5M')      → 300
 *   iso8601_duration_to_seconds('PT30S')     → 30
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION iso8601_duration_to_seconds(p TEXT)
RETURNS INTEGER 
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_hours INTEGER := 0; 
    v_minutes INTEGER := 0; 
    v_seconds INTEGER := 0;
    v_match_h TEXT[];
    v_match_m TEXT[];
    v_match_s TEXT[];
BEGIN
    -- NULL 또는 빈 문자열 또는 PT로 시작하지 않는 경우
    IF p IS NULL OR p = '' OR p !~ '^PT' THEN 
        RETURN NULL; 
    END IF;

    -- 정규식으로 시/분/초 추출
    v_match_h := regexp_match(p, '([0-9]+)H');
    v_match_m := regexp_match(p, '([0-9]+)M');
    v_match_s := regexp_match(p, '([0-9]+)S');

    v_hours := COALESCE(v_match_h[1], '0')::INTEGER;
    v_minutes := COALESCE(v_match_m[1], '0')::INTEGER;
    v_seconds := COALESCE(v_match_s[1], '0')::INTEGER;

    RETURN v_hours * 3600 + v_minutes * 60 + v_seconds;
END;
$$;

COMMENT ON FUNCTION iso8601_duration_to_seconds(TEXT) IS 
'YouTube API duration 형식(PT1H2M30S)을 초 단위로 변환';


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║                       5. YOUTUBE_VIDEO 관련 함수                           ║
-- ║                                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

/*
 ***********************************************************************************************
 * FUNCTION: YouTube Data API 데이터 Upsert
 ***********************************************************************************************
 * 설명: YouTube Data API v3 응답을 youtube_video 테이블에 저장
 * 용도: API 데이터 fetch 후 호출
 * 
 * 파라미터:
 *   p_video_data: YouTube API 응답 JSON (snippet, statistics, contentDetails, status, topicDetails 포함)
 *   p_is_shorts: Shorts 여부 (NULL이면 기존 값 유지)
 * 
 * 반환: 저장된 video_id
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION upsert_youtube_video_api_data(
    p_video_data JSONB,
    p_is_shorts BOOLEAN DEFAULT NULL
)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_video_id VARCHAR(20);
    v_snippet JSONB;
    v_statistics JSONB;
    v_content_details JSONB;
    v_status JSONB;
    v_topic_details JSONB;
    v_thumbnails JSONB;
BEGIN
    -- video_id 추출 및 검증
    v_video_id := p_video_data->>'id';
    
    IF v_video_id IS NULL OR v_video_id = '' THEN
        RAISE EXCEPTION 'video_id is required';
    END IF;
    
    -- JSON 데이터에서 각 섹션 추출
    v_snippet := p_video_data->'snippet';
    v_statistics := p_video_data->'statistics';
    v_content_details := p_video_data->'contentDetails';
    v_status := p_video_data->'status';
    v_topic_details := p_video_data->'topicDetails';
    v_thumbnails := v_snippet->'thumbnails';

    -- YouTube 비디오 데이터 Upsert
    INSERT INTO public.youtube_video (
        video_id,
        etag,
        kind,
        title,
        description,
        published_date,
        channel_id,
        channel_name,
        channel_url,
        category_id,
        language,
        default_audio_language,
        localized_title,
        localized_description,
        live_broadcast_content,
        tags,
        view_count,
        like_count,
        favorite_count,
        comment_count,
        duration_text,
        duration_seconds,
        dimension,
        definition,
        caption,
        licensed_content,
        projection,
        upload_status,
        privacy_status,
        license,
        embeddable,
        public_stats_viewable,
        topic_ids,
        relevant_topic_ids,
        thumbnail_default_url,
        thumbnail_default_width,
        thumbnail_default_height,
        thumbnail_medium_url,
        thumbnail_medium_width,
        thumbnail_medium_height,
        thumbnail_high_url,
        thumbnail_high_width,
        thumbnail_high_height,
        thumbnail_standard_url,
        thumbnail_standard_width,
        thumbnail_standard_height,
        thumbnail_maxres_url,
        thumbnail_maxres_width,
        thumbnail_maxres_height,
        thumbnail_url,
        thumbnail_width,
        thumbnail_height,
        upload_date,
        is_live,
        is_upcoming,
        is_private,
        is_shorts,
        last_processed_at
    ) VALUES (
        v_video_id,
        p_video_data->>'etag',
        COALESCE(p_video_data->>'kind', 'youtube#video'),
        v_snippet->>'title',
        v_snippet->>'description',
        (v_snippet->>'publishedAt')::TIMESTAMPTZ,
        v_snippet->>'channelId',
        v_snippet->>'channelTitle',
        CASE 
            WHEN v_snippet->>'channelId' IS NOT NULL
            THEN 'https://www.youtube.com/channel/' || (v_snippet->>'channelId')
            ELSE NULL 
        END,
        v_snippet->>'categoryId',
        COALESCE(
            NULLIF(v_snippet->>'defaultLanguage', ''), 
            NULLIF(v_snippet->>'defaultAudioLanguage', '')
        ),
        v_snippet->>'defaultAudioLanguage',
        v_snippet->'localized'->>'title',
        v_snippet->'localized'->>'description',
        v_snippet->>'liveBroadcastContent',
        CASE 
            WHEN v_snippet->'tags' IS NOT NULL
            THEN ARRAY(SELECT jsonb_array_elements_text(v_snippet->'tags'))
            ELSE NULL 
        END,
        COALESCE(NULLIF(v_statistics->>'viewCount', '')::BIGINT, 0),
        COALESCE(NULLIF(v_statistics->>'likeCount', '')::BIGINT, 0),
        COALESCE(NULLIF(v_statistics->>'favoriteCount', '')::BIGINT, 0),
        COALESCE(NULLIF(v_statistics->>'commentCount', '')::BIGINT, 0),
        v_content_details->>'duration',
        iso8601_duration_to_seconds(v_content_details->>'duration'),
        v_content_details->>'dimension',
        v_content_details->>'definition',
        CASE 
            WHEN LOWER(NULLIF(v_content_details->>'caption', '')) = 'true' THEN TRUE
            WHEN LOWER(NULLIF(v_content_details->>'caption', '')) = 'false' THEN FALSE
            ELSE NULL 
        END,
        CASE 
            WHEN LOWER(NULLIF(v_content_details->>'licensedContent', '')) = 'true' THEN TRUE
            WHEN LOWER(NULLIF(v_content_details->>'licensedContent', '')) = 'false' THEN FALSE
            ELSE NULL 
        END,
        v_content_details->>'projection',
        v_status->>'uploadStatus',
        v_status->>'privacyStatus',
        v_status->>'license',
        (v_status->>'embeddable')::BOOLEAN,
        (v_status->>'publicStatsViewable')::BOOLEAN,
        CASE 
            WHEN v_topic_details->'topicIds' IS NOT NULL
            THEN ARRAY(SELECT jsonb_array_elements_text(v_topic_details->'topicIds'))
            ELSE NULL 
        END,
        CASE 
            WHEN v_topic_details->'relevantTopicIds' IS NOT NULL
            THEN ARRAY(SELECT jsonb_array_elements_text(v_topic_details->'relevantTopicIds'))
            ELSE NULL 
        END,
        v_thumbnails->'default'->>'url',
        (v_thumbnails->'default'->>'width')::INTEGER,
        (v_thumbnails->'default'->>'height')::INTEGER,
        v_thumbnails->'medium'->>'url',
        (v_thumbnails->'medium'->>'width')::INTEGER,
        (v_thumbnails->'medium'->>'height')::INTEGER,
        v_thumbnails->'high'->>'url',
        (v_thumbnails->'high'->>'width')::INTEGER,
        (v_thumbnails->'high'->>'height')::INTEGER,
        v_thumbnails->'standard'->>'url',
        (v_thumbnails->'standard'->>'width')::INTEGER,
        (v_thumbnails->'standard'->>'height')::INTEGER,
        v_thumbnails->'maxres'->>'url',
        (v_thumbnails->'maxres'->>'width')::INTEGER,
        (v_thumbnails->'maxres'->>'height')::INTEGER,
        -- deprecated 필드 (호환성)
        COALESCE(
            v_thumbnails->'high'->>'url', 
            v_thumbnails->'medium'->>'url'
        ),
        COALESCE(
            (v_thumbnails->'high'->>'width')::INTEGER, 
            (v_thumbnails->'medium'->>'width')::INTEGER
        ),
        COALESCE(
            (v_thumbnails->'high'->>'height')::INTEGER, 
            (v_thumbnails->'medium'->>'height')::INTEGER
        ),
        (v_snippet->>'publishedAt')::DATE,
        (v_snippet->>'liveBroadcastContent' = 'live'),
        (v_snippet->>'liveBroadcastContent' = 'upcoming'),
        (v_status->>'privacyStatus' = 'private'),
        COALESCE(p_is_shorts, FALSE),
        NOW()
    )
    ON CONFLICT (video_id) DO UPDATE SET
        etag = EXCLUDED.etag,
        kind = EXCLUDED.kind,
        title = EXCLUDED.title,
        description = EXCLUDED.description,
        published_date = EXCLUDED.published_date,
        channel_id = EXCLUDED.channel_id,
        channel_name = EXCLUDED.channel_name,
        channel_url = EXCLUDED.channel_url,
        category_id = EXCLUDED.category_id,
        language = EXCLUDED.language,
        default_audio_language = EXCLUDED.default_audio_language,
        localized_title = EXCLUDED.localized_title,
        localized_description = EXCLUDED.localized_description,
        live_broadcast_content = EXCLUDED.live_broadcast_content,
        tags = EXCLUDED.tags,
        view_count = EXCLUDED.view_count,
        like_count = EXCLUDED.like_count,
        favorite_count = EXCLUDED.favorite_count,
        comment_count = EXCLUDED.comment_count,
        duration_text = EXCLUDED.duration_text,
        duration_seconds = EXCLUDED.duration_seconds,
        dimension = EXCLUDED.dimension,
        definition = EXCLUDED.definition,
        caption = EXCLUDED.caption,
        licensed_content = EXCLUDED.licensed_content,
        projection = EXCLUDED.projection,
        upload_status = EXCLUDED.upload_status,
        privacy_status = EXCLUDED.privacy_status,
        license = EXCLUDED.license,
        embeddable = EXCLUDED.embeddable,
        public_stats_viewable = EXCLUDED.public_stats_viewable,
        topic_ids = EXCLUDED.topic_ids,
        relevant_topic_ids = EXCLUDED.relevant_topic_ids,
        thumbnail_default_url = EXCLUDED.thumbnail_default_url,
        thumbnail_default_width = EXCLUDED.thumbnail_default_width,
        thumbnail_default_height = EXCLUDED.thumbnail_default_height,
        thumbnail_medium_url = EXCLUDED.thumbnail_medium_url,
        thumbnail_medium_width = EXCLUDED.thumbnail_medium_width,
        thumbnail_medium_height = EXCLUDED.thumbnail_medium_height,
        thumbnail_high_url = EXCLUDED.thumbnail_high_url,
        thumbnail_high_width = EXCLUDED.thumbnail_high_width,
        thumbnail_high_height = EXCLUDED.thumbnail_high_height,
        thumbnail_standard_url = EXCLUDED.thumbnail_standard_url,
        thumbnail_standard_width = EXCLUDED.thumbnail_standard_width,
        thumbnail_standard_height = EXCLUDED.thumbnail_standard_height,
        thumbnail_maxres_url = EXCLUDED.thumbnail_maxres_url,
        thumbnail_maxres_width = EXCLUDED.thumbnail_maxres_width,
        thumbnail_maxres_height = EXCLUDED.thumbnail_maxres_height,
        thumbnail_url = EXCLUDED.thumbnail_url,
        thumbnail_width = EXCLUDED.thumbnail_width,
        thumbnail_height = EXCLUDED.thumbnail_height,
        upload_date = EXCLUDED.upload_date,
        is_live = EXCLUDED.is_live,
        is_upcoming = EXCLUDED.is_upcoming,
        is_private = EXCLUDED.is_private,
        is_shorts = COALESCE(p_is_shorts, youtube_video.is_shorts),
        last_processed_at = NOW();

    RETURN v_video_id;
END;
$$;

COMMENT ON FUNCTION upsert_youtube_video_api_data(JSONB, BOOLEAN) IS 
'YouTube Data API v3 응답을 youtube_video 테이블에 저장';


/*
 ***********************************************************************************************
 * FUNCTION: AI 분석 결과 저장
 ***********************************************************************************************
 * 설명: AI 분석 결과를 youtube_video 테이블의 ai_* 필드에 저장
 * 용도: AI 분석 완료 후 호출
 * 
 * 파라미터: 모든 파라미터는 선택적 (NULL이면 기존 값 유지)
 * 반환: {success, video_id, places_count} 또는 {success: false, error}
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION upsert_youtube_video_ai_analysis(
    p_video_id VARCHAR(20),
    p_ai_description_summary TEXT DEFAULT NULL,
    p_ai_description_key_points TEXT[] DEFAULT NULL,
    p_ai_transcript_summary_default_language TEXT DEFAULT NULL,
    p_ai_transcript_key_points_default_language TEXT[] DEFAULT NULL,
    p_ai_transcript_summary_other_languages TEXT[] DEFAULT NULL,
    p_ai_transcript_key_points_other_languages TEXT[] DEFAULT NULL,
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
    -- video_id 존재 확인
    IF NOT EXISTS (SELECT 1 FROM public.youtube_video WHERE video_id = p_video_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'video_id not found'
        );
    END IF;
    
    -- 장소 개수 계산 (있는 경우)
    v_places_count := CASE 
        WHEN p_ai_places IS NOT NULL 
        THEN jsonb_array_length(p_ai_places)::SMALLINT
        ELSE NULL
    END;
    
    -- AI 분석 결과 업데이트 (COALESCE로 NULL이면 기존 값 유지)
    UPDATE public.youtube_video SET
        ai_description_summary = COALESCE(p_ai_description_summary, ai_description_summary),
        ai_description_key_points = COALESCE(p_ai_description_key_points, ai_description_key_points),
        ai_transcript_summary_default_language = COALESCE(p_ai_transcript_summary_default_language, ai_transcript_summary_default_language),
        ai_transcript_key_points_default_language = COALESCE(p_ai_transcript_key_points_default_language, ai_transcript_key_points_default_language),
        ai_transcript_summary_other_languages = COALESCE(p_ai_transcript_summary_other_languages, ai_transcript_summary_other_languages),
        ai_transcript_key_points_other_languages = COALESCE(p_ai_transcript_key_points_other_languages, ai_transcript_key_points_other_languages),
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
    WHERE video_id = p_video_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'video_id', p_video_id,
        'places_count', v_places_count
    );
END;
$$;

COMMENT ON FUNCTION upsert_youtube_video_ai_analysis IS 
'AI 분석 결과를 youtube_video 테이블의 ai_* 필드에 저장';


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║                  6. YOUTUBE_VIDEO_TRANSCRIPT 관련 함수                     ║
-- ║                                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

/*
 ***********************************************************************************************
 * FUNCTION: 자막 데이터 저장 (전체 버전)
 ***********************************************************************************************
 * 설명: 특정 언어의 자막 데이터를 저장 (Storage 지원 포함)
 * 용도: 자막 fetch 완료 후 호출
 * 
 * 저장 전략:
 *   - p_is_stored_in_storage = FALSE: transcript_text, transcript_segments에 직접 저장
 *   - p_is_stored_in_storage = TRUE: segments_storage_path에 Storage 경로 저장
 * 
 * 반환: {success, video_id, lang_code, word_count, char_count, segment_count, is_stored_in_storage}
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION upsert_youtube_video_transcript_data(
    p_video_id VARCHAR(20),
    p_lang_code VARCHAR(12),
    p_transcript_text TEXT DEFAULT NULL,
    p_transcript_segments JSONB DEFAULT NULL,
    p_word_count INTEGER DEFAULT NULL,
    p_char_count INTEGER DEFAULT NULL,
    p_segment_count INTEGER DEFAULT NULL,
    p_duration_covered_seconds INTEGER DEFAULT NULL,
    p_is_auto_generated BOOLEAN DEFAULT NULL,
    p_is_translatable BOOLEAN DEFAULT NULL,
    -- Storage 관련
    p_segments_storage_path TEXT DEFAULT NULL,
    p_segments_file_size BIGINT DEFAULT NULL,
    p_is_stored_in_storage BOOLEAN DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.youtube_video WHERE video_id = p_video_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'video_id not found in youtube_video'
        );
    END IF;

    -- 레코드 존재 확인 및 없으면 생성
    IF NOT EXISTS (
        SELECT 1 FROM public.youtube_video_transcript 
        WHERE video_id = p_video_id AND lang_code = p_lang_code
    ) THEN
        INSERT INTO public.youtube_video_transcript (video_id, lang_code)
        VALUES (p_video_id, p_lang_code);
    END IF;
    
    -- 자막 데이터 업데이트
    UPDATE public.youtube_video_transcript SET
        transcript_text = COALESCE(p_transcript_text, transcript_text),
        transcript_segments = COALESCE(p_transcript_segments, transcript_segments),
        word_count = COALESCE(p_word_count, word_count),
        char_count = COALESCE(p_char_count, char_count),
        segment_count = COALESCE(p_segment_count, segment_count),
        duration_covered_seconds = COALESCE(p_duration_covered_seconds, duration_covered_seconds),
        is_auto_generated = COALESCE(p_is_auto_generated, is_auto_generated),
        is_translatable = COALESCE(p_is_translatable, is_translatable),
        segments_storage_path = COALESCE(p_segments_storage_path, segments_storage_path),
        segments_file_size = COALESCE(p_segments_file_size, segments_file_size),
        is_stored_in_storage = COALESCE(p_is_stored_in_storage, is_stored_in_storage),
        is_fetched = TRUE,
        fetched_at = NOW(),
        updated_at = NOW()
    WHERE video_id = p_video_id AND lang_code = p_lang_code;
    
    RETURN jsonb_build_object(
        'success', true,
        'video_id', p_video_id,
        'lang_code', p_lang_code,
        'word_count', p_word_count,
        'char_count', p_char_count,
        'segment_count', p_segment_count,
        'is_stored_in_storage', p_is_stored_in_storage
    );
END;
$$;


/*
 ***********************************************************************************************
 * FUNCTION: 자막 AI 분석 결과 저장
 ***********************************************************************************************
 * 설명: 자막 AI 분석 결과를 youtube_video_transcript에 저장
 * 용도: AI 분석 완료 후 호출
 * 
 * 반환: {success, video_id, lang_code} 또는 {success: false, error}
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION upsert_youtube_video_transcript_ai_analysis(
    p_video_id VARCHAR(20),
    p_lang_code VARCHAR(12),
    -- 새로운 필드
    p_ai_transcript_summary TEXT DEFAULT NULL,
    p_ai_transcript_key_points TEXT[] DEFAULT NULL,
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
    -- 기존 필드 (deprecated, 호환성 유지)
    p_ai_summary TEXT DEFAULT NULL,
    p_ai_key_points JSONB DEFAULT NULL,
    p_ai_topics JSONB DEFAULT NULL,
    p_ai_metadata JSONB DEFAULT NULL,
    p_ai_model_used VARCHAR(50) DEFAULT NULL,
    p_ai_token_count INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_places_count SMALLINT;
BEGIN
    -- 레코드 존재 확인
    IF NOT EXISTS (
        SELECT 1 FROM public.youtube_video_transcript 
        WHERE video_id = p_video_id AND lang_code = p_lang_code
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'transcript record not found'
        );
    END IF;
    
    -- 장소 개수 계산
    v_places_count := CASE 
        WHEN p_ai_places IS NOT NULL 
        THEN jsonb_array_length(p_ai_places)::SMALLINT
        ELSE NULL
    END;
    
    -- AI 분석 결과 업데이트
    UPDATE public.youtube_video_transcript SET
        -- 새로운 필드
        ai_transcript_summary = COALESCE(p_ai_transcript_summary, ai_transcript_summary),
        ai_transcript_key_points = COALESCE(p_ai_transcript_key_points, ai_transcript_key_points),
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
        -- 기존 필드 (deprecated)
        ai_summary = COALESCE(p_ai_summary, ai_summary),
        ai_key_points = COALESCE(p_ai_key_points, ai_key_points),
        ai_topics = COALESCE(p_ai_topics, ai_topics),
        ai_metadata = COALESCE(p_ai_metadata, ai_metadata),
        ai_model_used = COALESCE(p_ai_model_used, ai_model_used),
        ai_token_count = COALESCE(p_ai_token_count, ai_token_count),
        ai_analyzed_at = NOW(),
        is_analyzed = TRUE,
        analyzed_at = NOW(),
        updated_at = NOW()
    WHERE video_id = p_video_id AND lang_code = p_lang_code;
    
    RETURN jsonb_build_object(
        'success', true,
        'video_id', p_video_id,
        'lang_code', p_lang_code,
        'places_count', v_places_count
    );
END;
$$;

COMMENT ON FUNCTION upsert_youtube_video_transcript_ai_analysis IS 
'자막 AI 분석 결과 저장 (새 필드 + deprecated 필드 호환)';


/*
 ***********************************************************************************************
 * FUNCTION: 자막 Pinecone 저장 상태 업데이트
 ***********************************************************************************************
 * 설명: Pinecone 저장 결과를 youtube_video_transcript에 업데이트
 * 용도: Pinecone 저장 완료/실패 후 호출
 * 
 * 동작:
 *   - 성공 시: is_saved_to_pinecone = TRUE, processing_status 자동 계산
 *   - 실패 시: is_error_saved_to_pinecone = TRUE, processing_status = 'failed'
 * 
 * 반환: {success, video_id, lang_code, vector_count}
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION update_youtube_video_transcript_pinecone_status(
    p_video_id VARCHAR(20),
    p_lang_code VARCHAR(12),
    p_pinecone_vector_count INTEGER,
    p_pinecone_namespace VARCHAR(100) DEFAULT NULL,
    p_pinecone_index_name VARCHAR(100) DEFAULT NULL,
    p_is_error BOOLEAN DEFAULT FALSE,
    p_error_message TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    -- 레코드 존재 확인
    IF NOT EXISTS (
        SELECT 1 FROM public.youtube_video_transcript 
        WHERE video_id = p_video_id AND lang_code = p_lang_code
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'transcript record not found'
        );
    END IF;

    UPDATE public.youtube_video_transcript SET
        is_saved_to_pinecone = NOT p_is_error,
        is_error_saved_to_pinecone = p_is_error,
        error_saved_to_pinecone_message = p_error_message,
        saved_to_pinecone_at = NOW(),
        pinecone_vector_count = CASE WHEN NOT p_is_error THEN p_pinecone_vector_count ELSE pinecone_vector_count END,
        pinecone_namespace = COALESCE(p_pinecone_namespace, pinecone_namespace),
        pinecone_index_name = COALESCE(p_pinecone_index_name, pinecone_index_name),
        is_error_occurred = CASE WHEN p_is_error THEN TRUE ELSE is_error_occurred END,
        processing_status = CASE 
            WHEN p_is_error THEN 'failed'
            WHEN is_fetched AND is_analyzed AND NOT p_is_error THEN 'completed'
            ELSE 'partial'
        END,
        updated_at = NOW()
    WHERE video_id = p_video_id AND lang_code = p_lang_code;
    
    RETURN jsonb_build_object(
        'success', true,
        'video_id', p_video_id,
        'lang_code', p_lang_code,
        'vector_count', p_pinecone_vector_count
    );
END;
$$;

COMMENT ON FUNCTION update_youtube_video_transcript_pinecone_status IS 
'Pinecone 저장 결과 업데이트 및 processing_status 자동 계산';


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║                     7. PROCESSING_LOG 관련 함수                            ║
-- ║                                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

/*
 ***********************************************************************************************
 * FUNCTION: 처리 로그 단계별 상태 업데이트
 ***********************************************************************************************
 * 설명: processing_log_youtube_video의 특정 단계 상태를 동적으로 업데이트
 * 용도: 각 처리 단계 완료 시 호출
 * 
 * 파라미터:
 *   p_step_name: 단계명 (api_data_fetched, api_data_analyzed, api_data_saved_to_db 등)
 *   p_is_success: 성공 여부
 *   p_error_message: 에러 메시지 (실패 시)
 * 
 * 동작:
 *   - is_{step_name} = p_is_success
 *   - is_error_{step_name} = NOT p_is_success
 *   - error_{step_name}_message = p_error_message
 * 
 * 반환: {success, video_id, step, is_success}
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION update_processing_log_youtube_video_step(
    p_video_id VARCHAR(20),
    p_step_name VARCHAR(50),
    p_is_success BOOLEAN,
    p_error_message TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_is_field TEXT;
    v_error_field TEXT;
    v_error_msg_field TEXT;
    v_sql TEXT;
    v_rows_affected INTEGER;
BEGIN
    -- 레코드 존재 확인
    IF NOT EXISTS (
        SELECT 1 FROM public.processing_log_youtube_video 
        WHERE video_id = p_video_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'processing_log record not found for video_id'
        );
    END IF;

    -- 동적 필드명 생성
    v_is_field := 'is_' || p_step_name;
    v_error_field := 'is_error_occurred_' || p_step_name;
    v_error_msg_field := 'error_msg_' || p_step_name;
    
    -- 동적 SQL 생성 및 실행
    v_sql := format(
        'UPDATE processing_log_youtube_video SET
            %I = %L,
            %I = %L,
            %I = %L,
            is_error_occurred = CASE WHEN %L THEN is_error_occurred ELSE TRUE END,
            last_processed_at = NOW(),
            updated_at = NOW()
        WHERE video_id = %L',
        v_is_field, p_is_success,
        v_error_field, NOT p_is_success,
        v_error_msg_field, p_error_message,
        p_is_success,
        p_video_id
    );
    
    EXECUTE v_sql;
    
    RETURN jsonb_build_object(
        'success', true,
        'video_id', p_video_id,
        'step', p_step_name,
        'is_success', p_is_success
    );
END;
$$;


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                                                                           ║
-- ║                               8. 뷰 (VIEW)                                ║
-- ║                                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

/*
 ***********************************************************************************************
 * VIEW: 장소 검색용 뷰
 ***********************************************************************************************
 * 설명: ai_places JSONB를 행으로 펼쳐서 장소별 검색 가능하게 함
 * 용도: 특정 장소가 포함된 비디오 검색
 * 
 * 쿼리 예시:
 *   SELECT * FROM youtube_video_places WHERE city = '서울';
 *   SELECT * FROM youtube_video_places WHERE place_name LIKE '%경복궁%';
 *   SELECT * FROM youtube_video_places WHERE place_type = 'restaurant';
 *   SELECT * FROM youtube_video_places WHERE country = 'KR' AND city = '부산';
 ***********************************************************************************************
 */
CREATE OR REPLACE VIEW youtube_video_places AS
SELECT 
    -- 비디오 정보
    yv.video_id,
    yv.title AS video_title,
    yv.channel_name,
    yv.channel_id,
    yv.published_date,
    yv.is_shorts,
    yv.view_count,
    yv.duration_seconds,
    yv.thumbnail_high_url,
    
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
    
    -- 비디오 내 위치
    (place.value->>'order_in_video')::INTEGER AS order_in_video,
    place.value->>'timestamp_start' AS timestamp_start,
    place.value->>'timestamp_end' AS timestamp_end
    
FROM youtube_video yv
CROSS JOIN LATERAL jsonb_array_elements(yv.ai_places) AS place(value)
WHERE yv.ai_places IS NOT NULL 
    AND yv.is_active = TRUE 
    AND yv.is_deleted = FALSE;
