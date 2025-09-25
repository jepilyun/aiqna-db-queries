/*
 * aiqna db for web service (INIT)
 * Database Name 'aiqna'
 *
 * Created 2025-09-24
 * Updated 2025-09-24
 */


/*
 ***********************************************************************************************
 * TABLE: youtube_video_processing_logs (YouTube Data API v3 대응)
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS youtube_video_processing_logs (
    -- 기본 키
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    video_id VARCHAR(20) NOT NULL UNIQUE,
    
    -- 메타데이터
    processing_status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, failed
    error_message TEXT,
    
    -- 불린 플래그들
    is_api_data_fetched BOOLEAN DEFAULT FALSE,
    is_transcript_fetched BOOLEAN DEFAULT FALSE,
    is_pinecone_processed BOOLEAN DEFAULT FALSE,
    
    -- 일시 정보
    processing_started TIMESTAMP WITH TIME ZONE,
    processing_completed TIMESTAMP WITH TIME ZONE,
    
    -- 시스템 타임스탬프
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_processed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_youtube_video_processing_logs_processing_status ON youtube_video_processing_logs(processing_status);


/*
 ***********************************************************************************************
 * TABLE: youtube_videos (YouTube Data API v3 완전 대응)
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS youtube_videos (
    -- 기본 키
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    video_id VARCHAR(20) NOT NULL UNIQUE,
    
    -- YouTube API 메타데이터
    etag VARCHAR(100),
    kind VARCHAR(50) DEFAULT 'youtube#video',
    
    -- 기본 정보 (snippet)
    title TEXT NOT NULL,
    description TEXT,
    published_date TIMESTAMP WITH TIME ZONE,
    
    -- 채널 정보 (snippet)
    channel_id VARCHAR(50),
    channel_name VARCHAR(255),
    channel_url TEXT,
    
    -- 카테고리 및 언어 (snippet)
    category_id VARCHAR(10),
    language VARCHAR(10), -- "ko", "en" 등
    default_audio_language VARCHAR(10),
    
    -- 현지화 정보 (snippet.localized)
    localized_title TEXT,
    localized_description TEXT,
    
    -- 라이브 방송 관련 (snippet)
    live_broadcast_content VARCHAR(20), -- "none", "live", "upcoming"
    
    -- 태그 (snippet)
    tags TEXT[], -- PostgreSQL 배열 타입
    
    -- 통계 정보 (statistics) - 문자열에서 숫자로 변환
    view_count BIGINT DEFAULT 0,
    like_count BIGINT DEFAULT 0,
    favorite_count BIGINT DEFAULT 0,
    comment_count BIGINT DEFAULT 0,
    
    -- 콘텐츠 세부사항 (contentDetails)
    duration_text VARCHAR(20), -- ISO 8601 형식 "PT4M32S"
    duration_seconds INTEGER, -- 별도 계산 필드
    dimension VARCHAR(10), -- "2d", "3d"
    definition VARCHAR(10), -- "sd", "hd"
    caption BOOLEAN,
    licensed_content BOOLEAN,
    projection VARCHAR(20), -- "rectangular", "360"
    
    -- 상태 정보 (status)
    upload_status VARCHAR(50),
    privacy_status VARCHAR(20), -- "public", "unlisted", "private"
    license VARCHAR(50),
    embeddable BOOLEAN,
    public_stats_viewable BOOLEAN,
    
    -- 주제 정보 (topicDetails)
    topic_ids TEXT[],
    relevant_topic_ids TEXT[],
    
    -- 썸네일 정보 - default
    thumbnail_default_url TEXT,
    thumbnail_default_width INTEGER,
    thumbnail_default_height INTEGER,
    
    -- 썸네일 정보 - medium
    thumbnail_medium_url TEXT,
    thumbnail_medium_width INTEGER,
    thumbnail_medium_height INTEGER,
    
    -- 썸네일 정보 - high
    thumbnail_high_url TEXT,
    thumbnail_high_width INTEGER,
    thumbnail_high_height INTEGER,
    
    -- 썸네일 정보 - standard (선택적)
    thumbnail_standard_url TEXT,
    thumbnail_standard_width INTEGER,
    thumbnail_standard_height INTEGER,
    
    -- 썸네일 정보 - maxres (선택적)
    thumbnail_maxres_url TEXT,
    thumbnail_maxres_width INTEGER,
    thumbnail_maxres_height INTEGER,
    
    -- 기존 호환성 필드들
    thumbnail_url TEXT, -- 대표 썸네일 (high 또는 medium)
    thumbnail_width INTEGER,
    thumbnail_height INTEGER,
    upload_date DATE,
    category VARCHAR(100), -- category_id와 별도
    keywords TEXT[],
    
    -- 불린 플래그들 (기존 호환성)
    is_live BOOLEAN DEFAULT FALSE,
    is_upcoming BOOLEAN DEFAULT FALSE,
    is_private BOOLEAN DEFAULT FALSE,
    age_restricted BOOLEAN DEFAULT FALSE,
    family_safe BOOLEAN DEFAULT TRUE,
    
    -- 처리 상태 플래그들
    is_info_fetched BOOLEAN DEFAULT FALSE,
    is_transcript_fetched BOOLEAN DEFAULT FALSE,
    is_pinecone_processed BOOLEAN DEFAULT FALSE,
    
    -- 시스템 타임스탬프
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_processed_at TIMESTAMP WITH TIME ZONE
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_youtube_videos_channel_id ON youtube_videos(channel_id);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_upload_date ON youtube_videos(upload_date);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_published_date ON youtube_videos(published_date);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_category_id ON youtube_videos(category_id);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_live_broadcast_content ON youtube_videos(live_broadcast_content);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_privacy_status ON youtube_videos(privacy_status);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_processing_status ON youtube_videos(is_info_fetched, is_transcript_fetched, is_pinecone_processed);








/*
 ***********************************************************************************************
 * FUNCTION: ISO 8601 "PT#H#M#S" → seconds
 ***********************************************************************************************
 */
-- ISO 8601 "PT#H#M#S" → seconds
CREATE OR REPLACE FUNCTION iso8601_duration_to_seconds(p text)
RETURNS int LANGUAGE plpgsql AS $$
DECLARE
  v_hours int := 0; 
  v_minutes int := 0; 
  v_seconds int := 0;
  v_match_h text[];
  v_match_m text[];
  v_match_s text[];
BEGIN
  IF p IS NULL OR p = '' OR p !~ '^PT' THEN RETURN NULL; END IF;

  v_match_h := regexp_match(p, '([0-9]+)H');
  v_match_m := regexp_match(p, '([0-9]+)M');
  v_match_s := regexp_match(p, '([0-9]+)S');

  v_hours := COALESCE(v_match_h[1], '0')::int;
  v_minutes := COALESCE(v_match_m[1], '0')::int;
  v_seconds := COALESCE(v_match_s[1], '0')::int;

  RETURN v_hours * 3600 + v_minutes * 60 + v_seconds;
END;
$$;


/*
 ***********************************************************************************************
 * FUNCTION: YouTube Data API 데이터 Upsert
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION upsert_youtube_video_api_data(
    p_video_data jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_video_uuid uuid;
    v_snippet jsonb;
    v_statistics jsonb;
    v_content_details jsonb;
    v_status jsonb;
    v_topic_details jsonb;
    v_thumbnails jsonb;
BEGIN
    -- JSON 데이터에서 각 섹션 추출
    v_snippet := p_video_data->'snippet';
    v_statistics := p_video_data->'statistics';
    v_content_details := p_video_data->'contentDetails';
    v_status := p_video_data->'status';
    v_topic_details := p_video_data->'topicDetails';
    v_thumbnails := v_snippet->'thumbnails';

    -- YouTube 비디오 데이터 Upsert (테이블 컬럼 순서대로)
    INSERT INTO youtube_videos (
        -- 기본 키 (id는 자동생성이므로 제외)
        video_id,
        
        -- YouTube API 메타데이터
        etag,
        kind,
        
        -- 기본 정보 (snippet)
        title,
        description,
        published_date,
        
        -- 채널 정보 (snippet)
        channel_id,
        channel_name,
        channel_url,
        
        -- 카테고리 및 언어 (snippet)
        category_id,
        language,
        default_audio_language,
        
        -- 현지화 정보 (snippet.localized)
        localized_title,
        localized_description,
        
        -- 라이브 방송 관련 (snippet)
        live_broadcast_content,
        
        -- 태그 (snippet)
        tags,
        
        -- 통계 정보 (statistics)
        view_count,
        like_count,
        favorite_count,
        comment_count,
        
        -- 콘텐츠 세부사항 (contentDetails)
        duration_text,
        duration_seconds,
        dimension,
        definition,
        caption,
        licensed_content,
        projection,
        
        -- 상태 정보 (status)
        upload_status,
        privacy_status,
        license,
        embeddable,
        public_stats_viewable,
        
        -- 주제 정보 (topicDetails)
        topic_ids,
        relevant_topic_ids,
        
        -- 썸네일 정보 - default
        thumbnail_default_url,
        thumbnail_default_width,
        thumbnail_default_height,
        
        -- 썸네일 정보 - medium
        thumbnail_medium_url,
        thumbnail_medium_width,
        thumbnail_medium_height,
        
        -- 썸네일 정보 - high
        thumbnail_high_url,
        thumbnail_high_width,
        thumbnail_high_height,
        
        -- 썸네일 정보 - standard
        thumbnail_standard_url,
        thumbnail_standard_width,
        thumbnail_standard_height,
        
        -- 썸네일 정보 - maxres
        thumbnail_maxres_url,
        thumbnail_maxres_width,
        thumbnail_maxres_height,
        
        -- 기존 호환성 필드들
        thumbnail_url,
        thumbnail_width,
        thumbnail_height,
        upload_date,
        category,
        keywords,
        
        -- 불린 플래그들 (기존 호환성)
        is_live,
        is_upcoming,
        is_private,
        age_restricted,
        family_safe,
        
        -- 처리 상태 플래그들
        is_info_fetched,
        is_transcript_fetched,
        is_pinecone_processed,
        
        -- 시스템 타임스탬프 (created_at은 자동생성)
        updated_at,
        last_processed_at
    ) VALUES (
        -- 기본 키
        p_video_data->>'id',
        
        -- YouTube API 메타데이터
        p_video_data->>'etag',
        COALESCE(p_video_data->>'kind', 'youtube#video'),
        
        -- 기본 정보 (snippet)
        v_snippet->>'title',
        v_snippet->>'description',
        (v_snippet->>'publishedAt')::timestamptz,
        
        -- 채널 정보 (snippet)
        v_snippet->>'channelId',
        v_snippet->>'channelTitle',
        CASE WHEN v_snippet->>'channelId' IS NOT NULL
            THEN 'https://www.youtube.com/channel/' || (v_snippet->>'channelId')
            ELSE NULL END,
        
        -- 카테고리 및 언어 (snippet)
        v_snippet->>'categoryId',
        COALESCE(NULLIF(v_snippet->>'defaultLanguage',''), NULLIF(v_snippet->>'defaultAudioLanguage','')),
        v_snippet->>'defaultAudioLanguage',
        
        -- 현지화 정보 (snippet.localized)
        v_snippet->'localized'->>'title',
        v_snippet->'localized'->>'description',
        
        -- 라이브 방송 관련 (snippet)
        v_snippet->>'liveBroadcastContent',
        
        -- 태그 (snippet)
        CASE WHEN v_snippet->'tags' IS NOT NULL
            THEN ARRAY(SELECT jsonb_array_elements_text(v_snippet->'tags'))
            ELSE NULL END,
        
        -- 통계 정보 (statistics)
        COALESCE(NULLIF(v_statistics->>'viewCount','')::bigint, 0),
        COALESCE(NULLIF(v_statistics->>'likeCount','')::bigint, 0),
        COALESCE(NULLIF(v_statistics->>'favoriteCount','')::bigint, 0),
        COALESCE(NULLIF(v_statistics->>'commentCount','')::bigint, 0),
        
        -- 콘텐츠 세부사항 (contentDetails)
        v_content_details->>'duration',
        iso8601_duration_to_seconds(v_content_details->>'duration'),
        v_content_details->>'dimension',
        v_content_details->>'definition',
        CASE WHEN lower(NULLIF(v_content_details->>'caption','')) = 'true' THEN TRUE
            WHEN lower(NULLIF(v_content_details->>'caption','')) = 'false' THEN FALSE
            ELSE NULL END,
        (v_content_details->>'licensedContent')::boolean,
        v_content_details->>'projection',
        
        -- 상태 정보 (status)
        v_status->>'uploadStatus',
        v_status->>'privacyStatus',
        v_status->>'license',
        (v_status->>'embeddable')::boolean,
        (v_status->>'publicStatsViewable')::boolean,
        
        -- 주제 정보 (topicDetails)
        CASE WHEN v_topic_details->'topicIds' IS NOT NULL
            THEN ARRAY(SELECT jsonb_array_elements_text(v_topic_details->'topicIds'))
            ELSE NULL END,
        CASE WHEN v_topic_details->'relevantTopicIds' IS NOT NULL
            THEN ARRAY(SELECT jsonb_array_elements_text(v_topic_details->'relevantTopicIds'))
            ELSE NULL END,
        
        -- 썸네일 정보 - default
        v_thumbnails->'default'->>'url',
        (v_thumbnails->'default'->>'width')::int,
        (v_thumbnails->'default'->>'height')::int,
        
        -- 썸네일 정보 - medium
        v_thumbnails->'medium'->>'url',
        (v_thumbnails->'medium'->>'width')::int,
        (v_thumbnails->'medium'->>'height')::int,
        
        -- 썸네일 정보 - high
        v_thumbnails->'high'->>'url',
        (v_thumbnails->'high'->>'width')::int,
        (v_thumbnails->'high'->>'height')::int,
        
        -- 썸네일 정보 - standard
        v_thumbnails->'standard'->>'url',
        (v_thumbnails->'standard'->>'width')::int,
        (v_thumbnails->'standard'->>'height')::int,
        
        -- 썸네일 정보 - maxres
        v_thumbnails->'maxres'->>'url',
        (v_thumbnails->'maxres'->>'width')::int,
        (v_thumbnails->'maxres'->>'height')::int,
        
        -- 기존 호환성 필드들
        COALESCE(v_thumbnails->'high'->>'url', v_thumbnails->'medium'->>'url'),
        COALESCE((v_thumbnails->'high'->>'width')::int, (v_thumbnails->'medium'->>'width')::int),
        COALESCE((v_thumbnails->'high'->>'height')::int, (v_thumbnails->'medium'->>'height')::int),
        (v_snippet->>'publishedAt')::date,
        NULL, -- category는 별도 매핑 필요하면 추후 추가
        NULL, -- keywords는 별도 로직 필요하면 추후 추가
        
        -- 불린 플래그들 (기존 호환성)
        (v_snippet->>'liveBroadcastContent' = 'live'),
        (v_snippet->>'liveBroadcastContent' = 'upcoming'),
        (v_status->>'privacyStatus' = 'private'),
        FALSE, -- age_restricted는 별도 로직 필요
        TRUE,  -- family_safe 기본값
        
        -- 처리 상태 플래그들
        TRUE,  -- is_info_fetched
        FALSE, -- is_transcript_fetched (기본값 유지)
        FALSE, -- is_pinecone_processed (기본값 유지)
        
        -- 시스템 타임스탬프
        NOW(),
        NOW()
    )
    ON CONFLICT (video_id) DO UPDATE SET
        -- YouTube API 메타데이터
        etag = EXCLUDED.etag,
        kind = EXCLUDED.kind,
        
        -- 기본 정보 (snippet)
        title = EXCLUDED.title,
        description = EXCLUDED.description,
        published_date = EXCLUDED.published_date,
        
        -- 채널 정보 (snippet)
        channel_id = EXCLUDED.channel_id,
        channel_name = EXCLUDED.channel_name,
        channel_url = EXCLUDED.channel_url,
        
        -- 카테고리 및 언어 (snippet)
        category_id = EXCLUDED.category_id,
        language = EXCLUDED.language,
        default_audio_language = EXCLUDED.default_audio_language,
        
        -- 현지화 정보
        localized_title = EXCLUDED.localized_title,
        localized_description = EXCLUDED.localized_description,
        
        -- 라이브 방송 관련
        live_broadcast_content = EXCLUDED.live_broadcast_content,
        
        -- 태그
        tags = EXCLUDED.tags,
        
        -- 통계 정보
        view_count = EXCLUDED.view_count,
        like_count = EXCLUDED.like_count,
        favorite_count = EXCLUDED.favorite_count,
        comment_count = EXCLUDED.comment_count,
        
        -- 콘텐츠 세부사항
        duration_text = EXCLUDED.duration_text,
        duration_seconds = EXCLUDED.duration_seconds,
        dimension = EXCLUDED.dimension,
        definition = EXCLUDED.definition,
        caption = EXCLUDED.caption,
        licensed_content = EXCLUDED.licensed_content,
        projection = EXCLUDED.projection,
        
        -- 상태 정보
        upload_status = EXCLUDED.upload_status,
        privacy_status = EXCLUDED.privacy_status,
        license = EXCLUDED.license,
        embeddable = EXCLUDED.embeddable,
        public_stats_viewable = EXCLUDED.public_stats_viewable,
        
        -- 주제 정보
        topic_ids = EXCLUDED.topic_ids,
        relevant_topic_ids = EXCLUDED.relevant_topic_ids,
        
        -- 썸네일 정보 업데이트
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
        
        -- 기존 호환성 필드들
        thumbnail_url = EXCLUDED.thumbnail_url,
        thumbnail_width = EXCLUDED.thumbnail_width,
        thumbnail_height = EXCLUDED.thumbnail_height,
        upload_date = EXCLUDED.upload_date,
        
        -- 불린 플래그들
        is_live = EXCLUDED.is_live,
        is_upcoming = EXCLUDED.is_upcoming,
        is_private = EXCLUDED.is_private,
        
        -- 처리 상태 플래그들
        is_info_fetched = TRUE,
        
        -- 시스템 타임스탬프
        updated_at = NOW(),
        last_processed_at = NOW()
    RETURNING id INTO v_video_uuid;

    -- 처리 로그도 업데이트
    INSERT INTO youtube_video_processing_logs (
        video_id,
        processing_status,
        is_api_data_fetched,
        updated_at
    )
    VALUES (
        p_video_data->>'id',
        'completed',
        TRUE,
        NOW()
    )
    ON CONFLICT (video_id) DO UPDATE SET
        is_api_data_fetched = TRUE,
        processing_status = CASE 
            WHEN youtube_video_processing_logs.processing_status = 'failed' THEN 'completed'
            ELSE youtube_video_processing_logs.processing_status
        END,
        updated_at = NOW();

    RETURN v_video_uuid;
END;
$$;







/*
 ***********************************************************************************************
 * TABLE: youtube_transcripts
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS youtube_transcripts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    video_id VARCHAR(20) NOT NULL REFERENCES youtube_videos(video_id) ON DELETE CASCADE,
    
    -- 트랜스크립트 메타 정보
    language VARCHAR(10) NOT NULL DEFAULT 'ko',
    total_duration NUMERIC(12,2), -- 전체 길이 (초) - 더 긴 동영상 대응
    segment_count INTEGER DEFAULT 0,
    
    -- 전체 트랜스크립트 JSON 데이터
    segments_json JSONB NOT NULL DEFAULT '[]'::jsonb, -- 기본값 추가
    
    -- 전체 텍스트 (검색용)
    full_text TEXT,
    
    -- 시스템 정보
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    UNIQUE(video_id, language),
    CHECK (segment_count >= 0),
    CHECK (total_duration IS NULL OR total_duration >= 0)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_youtube_transcripts_video_id ON youtube_transcripts(video_id);
CREATE INDEX IF NOT EXISTS idx_youtube_transcripts_language ON youtube_transcripts(language);

-- 전문 검색을 위한 GIN 인덱스 (선택사항)
-- CREATE INDEX IF NOT EXISTS idx_youtube_transcripts_full_text_gin 
-- ON youtube_transcripts USING gin(to_tsvector('korean', full_text));


/*
 ***********************************************************************************************
 * 트리거 함수: 처리 상태 자동 업데이트 (선택사항)
 ***********************************************************************************************
 */
-- youtube_transcripts 삽입/삭제 시 youtube_videos.is_transcript_fetched 업데이트
CREATE OR REPLACE FUNCTION update_transcript_status()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE youtube_videos 
        SET is_transcript_fetched = TRUE, updated_at = NOW()
        WHERE video_id = NEW.video_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- 해당 video_id의 다른 언어 트랜스크립트가 있는지 확인
        UPDATE youtube_videos 
        SET is_transcript_fetched = EXISTS (
            SELECT 1 FROM youtube_transcripts 
            WHERE video_id = OLD.video_id
        ), updated_at = NOW()
        WHERE video_id = OLD.video_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_transcript_status ON youtube_transcripts;
CREATE TRIGGER trigger_update_transcript_status
    AFTER INSERT OR DELETE ON youtube_transcripts
    FOR EACH ROW EXECUTE FUNCTION update_transcript_status();

-- pinecone_processing_logs 상태 변경 시 youtube_videos.is_pinecone_processed 업데이트
CREATE OR REPLACE FUNCTION update_pinecone_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.processing_status = 'completed' THEN
        UPDATE youtube_videos 
        SET is_pinecone_processed = TRUE, updated_at = NOW()
        WHERE video_id = NEW.video_id;
    ELSIF NEW.processing_status = 'failed' THEN
        UPDATE youtube_videos 
        SET is_pinecone_processed = FALSE, updated_at = NOW()
        WHERE video_id = NEW.video_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;





/*
 ***********************************************************************************************
 * TABLE: pinecone_processing_logs
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS pinecone_processing_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    video_id VARCHAR(20) NOT NULL REFERENCES youtube_videos(video_id) ON DELETE CASCADE,
    
    -- Pinecone 정보
    index_name VARCHAR(100) NOT NULL,
    chunk_count INTEGER DEFAULT 0,
    
    -- 처리 정보
    embedding_model VARCHAR(100), -- "text-embedding-ada-002" 등
    processing_status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, failed
    error_message TEXT,
    
    -- 시간 정보
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    processing_duration_seconds INTEGER,
    
    -- 메타 정보
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건 추가
    CHECK (chunk_count >= 0),
    CHECK (processing_duration_seconds IS NULL OR processing_duration_seconds >= 0),
    CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed'))
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_pinecone_logs_video_id ON pinecone_processing_logs(video_id);
CREATE INDEX IF NOT EXISTS idx_pinecone_logs_status ON pinecone_processing_logs(processing_status);
CREATE INDEX IF NOT EXISTS idx_pinecone_logs_created_at ON pinecone_processing_logs(created_at);

-- 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_pinecone_status ON pinecone_processing_logs;
CREATE TRIGGER trigger_update_pinecone_status
    AFTER UPDATE ON pinecone_processing_logs
    FOR EACH ROW 
    WHEN (OLD.processing_status IS DISTINCT FROM NEW.processing_status)
    EXECUTE FUNCTION update_pinecone_status();

