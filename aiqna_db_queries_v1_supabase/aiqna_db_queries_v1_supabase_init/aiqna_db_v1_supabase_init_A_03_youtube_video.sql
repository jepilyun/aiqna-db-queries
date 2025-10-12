/*
 * aiqna db for web service (YouTube Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-09-24
 * Updated 2025-10-12
 */


/*
 ***********************************************************************************************
 * TABLE: youtube_video_processing_logs (YouTube Data API v3 대응)
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS youtube_video_processing_logs (
    -- 기본 키
    video_id VARCHAR(20) PRIMARY KEY,
    
    -- 메타데이터
    processing_status VARCHAR(20) DEFAULT 'pending',
    error_message TEXT,
    index_name VARCHAR(255),
    
    -- 불린 플래그들
    is_transcript_exist BOOLEAN DEFAULT FALSE,
    is_api_data_fetched BOOLEAN DEFAULT FALSE,
    is_transcript_fetched BOOLEAN DEFAULT FALSE,
    is_pinecone_processed BOOLEAN DEFAULT FALSE,

    -- 일시 정보
    processing_started TIMESTAMP WITH TIME ZONE,
    processing_completed TIMESTAMP WITH TIME ZONE,
    retry_count INTEGER DEFAULT 0,
    
    -- 시스템 타임스탬프
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_processed_at TIMESTAMP WITH TIME ZONE,

    source VARCHAR(50),
    priority INTEGER DEFAULT 5,
    assigned_worker VARCHAR(100),

    -- processing 상태 검증
    CONSTRAINT chk_processing_status 
        CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),

    -- 시간 로직 검증
    CONSTRAINT chk_processing_times 
        CHECK (processing_started IS NULL OR processing_completed IS NULL 
        OR processing_completed >= processing_started)
);

CREATE INDEX IF NOT EXISTS idx_youtube_video_processing_logs_status 
    ON youtube_video_processing_logs(processing_status);

CREATE INDEX IF NOT EXISTS idx_youtube_video_processing_logs_priority 
    ON youtube_video_processing_logs(priority) 
    WHERE processing_status = 'pending';

ALTER TABLE public.youtube_video_processing_logs ENABLE ROW LEVEL SECURITY;

-- 읽기 전용 (모든 사용자)
CREATE POLICY "youtube_video_processing_logs are visible to everyone" 
    ON youtube_video_processing_logs FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업 (service_role만)
CREATE POLICY "Service role can manage youtube_video_processing_logs" 
    ON youtube_video_processing_logs FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER trigger_update_youtube_video_processing_logs_updated_at
    BEFORE UPDATE ON youtube_video_processing_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();







/*
 ***********************************************************************************************
 * TABLE: youtube_videos (YouTube Data API v3 완전 대응)
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS youtube_videos (
    -- 기본 키
    video_id VARCHAR(20) PRIMARY KEY,
    
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
    
    -- Summary From AI 
    ai_summary TEXT,
    main_topics TEXT[],
    key_points TEXT[],
    keywords TEXT[],

    -- 카테고리 및 언어 (snippet)
    category_id VARCHAR(10),
    language VARCHAR(10),
    default_audio_language VARCHAR(10),
    
    -- 현지화 정보 (snippet.localized)
    localized_title TEXT,
    localized_description TEXT,
    
    -- 라이브 방송 관련 (snippet)
    live_broadcast_content VARCHAR(20),
    
    -- 태그 (snippet)
    tags TEXT[],
    
    -- 통계 정보 (statistics)
    view_count BIGINT DEFAULT 0,
    like_count BIGINT DEFAULT 0,
    favorite_count BIGINT DEFAULT 0,
    comment_count BIGINT DEFAULT 0,
    
    -- 콘텐츠 세부사항 (contentDetails)
    duration_text VARCHAR(20),
    duration_seconds INTEGER,
    dimension VARCHAR(10),
    definition VARCHAR(10),
    caption BOOLEAN,
    licensed_content BOOLEAN,
    projection VARCHAR(20),
    
    -- 상태 정보 (status)
    upload_status VARCHAR(50),
    privacy_status VARCHAR(20),
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
    
    -- 썸네일 정보 - standard
    thumbnail_standard_url TEXT,
    thumbnail_standard_width INTEGER,
    thumbnail_standard_height INTEGER,
    
    -- 썸네일 정보 - maxres
    thumbnail_maxres_url TEXT,
    thumbnail_maxres_width INTEGER,
    thumbnail_maxres_height INTEGER,
    
    -- 기존 호환성 필드들
    thumbnail_url TEXT,
    thumbnail_width INTEGER,
    thumbnail_height INTEGER,
    upload_date DATE,
    category VARCHAR(100),
    
    -- 불린 플래그들
    is_live BOOLEAN DEFAULT FALSE,
    is_upcoming BOOLEAN DEFAULT FALSE,
    is_private BOOLEAN DEFAULT FALSE,
    age_restricted BOOLEAN DEFAULT FALSE,
    family_safe BOOLEAN DEFAULT TRUE,
    
    -- 시스템 타임스탬프
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_processed_at TIMESTAMP WITH TIME ZONE,

    metadata_json JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- 제약조건
    CONSTRAINT chk_duration_seconds CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
    CONSTRAINT chk_view_count CHECK (view_count >= 0),
    CONSTRAINT chk_like_count CHECK (like_count >= 0),
    CONSTRAINT chk_comment_count CHECK (comment_count >= 0)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_youtube_videos_channel_id 
    ON youtube_videos(channel_id);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_upload_date 
    ON youtube_videos(upload_date);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_published_date 
    ON youtube_videos(published_date);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_category_id 
    ON youtube_videos(category_id);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_live_broadcast_content 
    ON youtube_videos(live_broadcast_content);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_privacy_status 
    ON youtube_videos(privacy_status);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_is_active 
    ON youtube_videos(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_youtube_videos_is_deleted 
    ON youtube_videos(is_deleted) WHERE is_deleted = FALSE;

-- 배열 컬럼 GIN 인덱스
CREATE INDEX IF NOT EXISTS idx_youtube_videos_tags_gin 
    ON youtube_videos USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_topic_ids_gin 
    ON youtube_videos USING gin(topic_ids);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_relevant_topic_ids_gin 
    ON youtube_videos USING gin(relevant_topic_ids);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_keywords_gin 
    ON youtube_videos USING gin(keywords);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_main_topics_gin 
    ON youtube_videos USING gin(main_topics);
CREATE INDEX IF NOT EXISTS idx_youtube_videos_key_points_gin 
    ON youtube_videos USING gin(key_points);

-- 전체 텍스트 검색 인덱스
CREATE INDEX IF NOT EXISTS idx_youtube_videos_title_description_gin 
    ON youtube_videos USING gin(to_tsvector('simple', 
    COALESCE(title, '') || ' ' || COALESCE(description, '')));

ALTER TABLE public.youtube_videos ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "youtube_videos are visible to everyone" 
    ON youtube_videos FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage youtube_videos" 
    ON youtube_videos FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER trigger_update_youtube_videos_updated_at
    BEFORE UPDATE ON youtube_videos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();







/*
 ***********************************************************************************************
 * FUNCTION: ISO 8601 "PT#H#M#S" → seconds
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
    IF p IS NULL OR p = '' OR p !~ '^PT' THEN 
        RETURN NULL; 
    END IF;

    v_match_h := regexp_match(p, '([0-9]+)H');
    v_match_m := regexp_match(p, '([0-9]+)M');
    v_match_s := regexp_match(p, '([0-9]+)S');

    v_hours := COALESCE(v_match_h[1], '0')::INTEGER;
    v_minutes := COALESCE(v_match_m[1], '0')::INTEGER;
    v_seconds := COALESCE(v_match_s[1], '0')::INTEGER;

    RETURN v_hours * 3600 + v_minutes * 60 + v_seconds;
END;
$$;





/*
 ***********************************************************************************************
 * FUNCTION: YouTube Data API 데이터 Upsert
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION upsert_youtube_video_api_data(
    p_video_data JSONB
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
    -- video_id 추출
    v_video_id := p_video_data->>'id';
    
    -- JSON 데이터에서 각 섹션 추출
    v_snippet := p_video_data->'snippet';
    v_statistics := p_video_data->'statistics';
    v_content_details := p_video_data->'contentDetails';
    v_status := p_video_data->'status';
    v_topic_details := p_video_data->'topicDetails';
    v_thumbnails := v_snippet->'thumbnails';

    -- YouTube 비디오 데이터 Upsert
    INSERT INTO youtube_videos (
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
        updated_at,
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
        CASE WHEN v_snippet->>'channelId' IS NOT NULL
            THEN 'https://www.youtube.com/channel/' || (v_snippet->>'channelId')
            ELSE NULL END,
        v_snippet->>'categoryId',
        COALESCE(NULLIF(v_snippet->>'defaultLanguage',''), NULLIF(v_snippet->>'defaultAudioLanguage','')),
        v_snippet->>'defaultAudioLanguage',
        v_snippet->'localized'->>'title',
        v_snippet->'localized'->>'description',
        v_snippet->>'liveBroadcastContent',
        CASE WHEN v_snippet->'tags' IS NOT NULL
            THEN ARRAY(SELECT jsonb_array_elements_text(v_snippet->'tags'))
            ELSE NULL END,
        COALESCE(NULLIF(v_statistics->>'viewCount','')::BIGINT, 0),
        COALESCE(NULLIF(v_statistics->>'likeCount','')::BIGINT, 0),
        COALESCE(NULLIF(v_statistics->>'favoriteCount','')::BIGINT, 0),
        COALESCE(NULLIF(v_statistics->>'commentCount','')::BIGINT, 0),
        v_content_details->>'duration',
        iso8601_duration_to_seconds(v_content_details->>'duration'),
        v_content_details->>'dimension',
        v_content_details->>'definition',
        CASE WHEN LOWER(NULLIF(v_content_details->>'caption','')) = 'true' THEN TRUE
            WHEN LOWER(NULLIF(v_content_details->>'caption','')) = 'false' THEN FALSE
            ELSE NULL END,
        CASE WHEN LOWER(NULLIF(v_content_details->>'licensedContent','')) = 'true' THEN TRUE
            WHEN LOWER(NULLIF(v_content_details->>'licensedContent','')) = 'false' THEN FALSE
            ELSE NULL END,
        v_content_details->>'projection',
        v_status->>'uploadStatus',
        v_status->>'privacyStatus',
        v_status->>'license',
        (v_status->>'embeddable')::BOOLEAN,
        (v_status->>'publicStatsViewable')::BOOLEAN,
        CASE WHEN v_topic_details->'topicIds' IS NOT NULL
            THEN ARRAY(SELECT jsonb_array_elements_text(v_topic_details->'topicIds'))
            ELSE NULL END,
        CASE WHEN v_topic_details->'relevantTopicIds' IS NOT NULL
            THEN ARRAY(SELECT jsonb_array_elements_text(v_topic_details->'relevantTopicIds'))
            ELSE NULL END,
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
        COALESCE(v_thumbnails->'high'->>'url', v_thumbnails->'medium'->>'url'),
        COALESCE((v_thumbnails->'high'->>'width')::INTEGER, (v_thumbnails->'medium'->>'width')::INTEGER),
        COALESCE((v_thumbnails->'high'->>'height')::INTEGER, (v_thumbnails->'medium'->>'height')::INTEGER),
        (v_snippet->>'publishedAt')::DATE,
        (v_snippet->>'liveBroadcastContent' = 'live'),
        (v_snippet->>'liveBroadcastContent' = 'upcoming'),
        (v_status->>'privacyStatus' = 'private'),
        NOW(),
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
        updated_at = NOW(),
        last_processed_at = NOW();

    -- 처리 로그도 업데이트
    INSERT INTO youtube_video_processing_logs (
        video_id,
        processing_status,
        is_api_data_fetched,
        updated_at
    )
    VALUES (
        v_video_id,
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

    RETURN v_video_id;
END;
$$;






/*
 ***********************************************************************************************
 * TABLE: youtube_video_transcripts
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS youtube_video_transcripts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    video_id VARCHAR(20) NOT NULL,
    
    -- 트랜스크립트 메타 정보
    "language" VARCHAR(10) NOT NULL DEFAULT 'ko',
    total_duration NUMERIC(12,2),
    segment_count INTEGER DEFAULT 0,
    
    -- 전체 트랜스크립트 JSON 데이터
    segments_json JSONB NOT NULL DEFAULT '[]'::JSONB,
    
    -- 전체 텍스트 (검색용)
    full_text TEXT,
    
    -- 시스템 정보
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    UNIQUE(video_id, language),
    CONSTRAINT chk_segment_count CHECK (segment_count >= 0),
    CONSTRAINT chk_total_duration CHECK (total_duration IS NULL OR total_duration >= 0),
    
    -- 외래키
    CONSTRAINT fk_youtube_video_transcripts_video_id 
        FOREIGN KEY (video_id) 
        REFERENCES youtube_videos(video_id) 
        ON DELETE CASCADE
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_youtube_transcripts_video_id 
    ON youtube_video_transcripts(video_id);
CREATE INDEX IF NOT EXISTS idx_youtube_transcripts_language 
    ON youtube_video_transcripts(language);

-- 트랜스크립트 전체 텍스트 검색
CREATE INDEX IF NOT EXISTS idx_youtube_transcripts_full_text_gin 
    ON youtube_video_transcripts USING gin(to_tsvector('simple', COALESCE(full_text, '')));

ALTER TABLE public.youtube_video_transcripts ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "youtube_video_transcripts are visible to everyone" 
    ON youtube_video_transcripts FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage youtube_video_transcripts" 
    ON youtube_video_transcripts FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER trigger_update_youtube_video_transcripts_updated_at
    BEFORE UPDATE ON youtube_video_transcripts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();





/*
 ***********************************************************************************************
 * FUNCTION: 트랜스크립트 상태 자동 업데이트
 ***********************************************************************************************
 */
CREATE OR REPLACE FUNCTION update_youtube_video_transcript_status()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE youtube_video_processing_logs 
        SET is_transcript_fetched = TRUE, 
            is_transcript_exist = TRUE,
            updated_at = NOW()
        WHERE video_id = NEW.video_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- 해당 video_id의 다른 언어 트랜스크립트가 있는지 확인
        UPDATE youtube_video_processing_logs 
        SET is_transcript_fetched = EXISTS (
                SELECT 1 FROM youtube_video_transcripts 
                WHERE video_id = OLD.video_id
            ),
            is_transcript_exist = EXISTS (
                SELECT 1 FROM youtube_video_transcripts 
                WHERE video_id = OLD.video_id
            ),
            updated_at = NOW()
        WHERE video_id = OLD.video_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

-- 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_youtube_video_transcript_status 
    ON youtube_video_transcripts;

CREATE TRIGGER trigger_update_youtube_video_transcript_status
    AFTER INSERT OR DELETE ON youtube_video_transcripts
    FOR EACH ROW 
    EXECUTE FUNCTION update_youtube_video_transcript_status();