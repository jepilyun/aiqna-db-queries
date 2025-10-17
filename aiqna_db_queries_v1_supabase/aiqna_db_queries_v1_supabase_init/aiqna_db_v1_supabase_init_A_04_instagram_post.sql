/*
 * aiqna db for web service (Instagram Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-09-24
 * Updated 2025-10-12
 */



/*
 ***********************************************************************************************
 * TABLE: instagram_post_processing_logs (Instagram Post Processing Logs)
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS instagram_post_processing_logs (
    -- 기본 키
    instagram_post_url VARCHAR(1023) PRIMARY KEY,
    
    -- 메타데이터
    processing_status VARCHAR(20) DEFAULT 'pending',
    index_name VARCHAR(255),
    
    -- 불린 플래그들
    is_data_fetched BOOLEAN DEFAULT FALSE,
    is_pinecone_processed BOOLEAN DEFAULT FALSE,
    
    -- ERROR
    is_error_occurred BOOLEAN DEFAULT FALSE,
    error_message TEXT,

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
    CONSTRAINT chk_instagram_processing_status 
        CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),

    -- 시간 로직 검증
    CONSTRAINT chk_instagram_processing_times 
        CHECK (processing_started IS NULL OR processing_completed IS NULL 
        OR processing_completed >= processing_started),

    -- 우선순위 검증
    CONSTRAINT chk_instagram_priority CHECK (priority BETWEEN 1 AND 10)
);

CREATE INDEX IF NOT EXISTS idx_instagram_post_processing_logs_status 
    ON instagram_post_processing_logs(processing_status);

CREATE INDEX IF NOT EXISTS idx_instagram_post_processing_logs_priority 
    ON instagram_post_processing_logs(priority) 
    WHERE processing_status = 'pending';

CREATE INDEX IF NOT EXISTS idx_instagram_post_processing_logs_error_flag
    ON instagram_post_processing_logs(is_error_occurred)
    WHERE is_error_occurred = TRUE;

ALTER TABLE public.instagram_post_processing_logs ENABLE ROW LEVEL SECURITY;

-- 읽기 전용 (모든 사용자)
CREATE POLICY "instagram_post_processing_logs are visible to everyone" 
    ON instagram_post_processing_logs FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업 (service_role만)
CREATE POLICY "Service role can manage instagram_post_processing_logs" 
    ON instagram_post_processing_logs FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER trigger_update_instagram_post_processing_logs_updated_at
    BEFORE UPDATE ON instagram_post_processing_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();





/*
 ***********************************************************************************************
 * TABLE: instagram_posts (Instagram Posts)
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS instagram_posts (
    -- 기본 키
    instagram_post_url VARCHAR(1023) PRIMARY KEY,
    
    -- 포스트 메타데이터
    post_type VARCHAR(20),
    media_count INTEGER DEFAULT 1,
    media_urls TEXT[],
    og_title VARCHAR(1023),
    og_description VARCHAR(1023),
    og_image VARCHAR(2048),
    og_url VARCHAR(1023),
    og_ios_url VARCHAR(1023),
    og_android_package VARCHAR(1023),
    og_android_url VARCHAR(1023),

    -- 통계
    like_count BIGINT DEFAULT 0,
    comment_count BIGINT DEFAULT 0,
    view_count BIGINT DEFAULT 0,

    description VARCHAR(2047),
    tags TEXT[],

    user_id VARCHAR(50),
    user_name VARCHAR(255),
    user_profile_url TEXT,

    published_date TIMESTAMP WITH TIME ZONE,

    local_image_url VARCHAR(511),

    -- 위치 정보
    location_name VARCHAR(255),
    location_id VARCHAR(100),
    latitude NUMERIC(10,8),
    longitude NUMERIC(11,8),

    -- 시스템 타임스탬프
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_processed_at TIMESTAMP WITH TIME ZONE,

    metadata_json JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- 제약조건
    CONSTRAINT chk_instagram_post_type 
        CHECK (post_type IN ('image', 'video', 'carousel', 'reel', 'story')),
    CONSTRAINT chk_instagram_media_count CHECK (media_count >= 1),
    CONSTRAINT chk_instagram_like_count CHECK (like_count >= 0),
    CONSTRAINT chk_instagram_comment_count CHECK (comment_count >= 0),
    CONSTRAINT chk_instagram_view_count CHECK (view_count >= 0),
    CONSTRAINT chk_instagram_latitude CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
    CONSTRAINT chk_instagram_longitude CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180))
);

-- 기본 인덱스
CREATE INDEX IF NOT EXISTS idx_instagram_posts_published_date 
    ON instagram_posts(published_date);
CREATE INDEX IF NOT EXISTS idx_instagram_posts_user_id 
    ON instagram_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_instagram_posts_user_name 
    ON instagram_posts(user_name);
CREATE INDEX IF NOT EXISTS idx_instagram_posts_post_type 
    ON instagram_posts(post_type);
CREATE INDEX IF NOT EXISTS idx_instagram_posts_location_name 
    ON instagram_posts(location_name);
CREATE INDEX IF NOT EXISTS idx_instagram_posts_location_id 
    ON instagram_posts(location_id);
CREATE INDEX IF NOT EXISTS idx_instagram_posts_is_active 
    ON instagram_posts(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_instagram_posts_is_deleted 
    ON instagram_posts(is_deleted) WHERE is_deleted = FALSE;

-- 배열 컬럼 GIN 인덱스
CREATE INDEX IF NOT EXISTS idx_instagram_posts_tags_gin 
    ON instagram_posts USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_instagram_posts_media_urls_gin 
    ON instagram_posts USING gin(media_urls);

-- 전체 텍스트 검색 인덱스
CREATE INDEX IF NOT EXISTS idx_instagram_posts_text_search_gin 
    ON instagram_posts USING gin(to_tsvector('simple', 
    COALESCE(og_title, '') || ' ' || 
    COALESCE(description, '') || ' ' || 
    COALESCE(user_name, '')));

-- 위치 기반 검색을 위한 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_instagram_posts_location_coords 
    ON instagram_posts(latitude, longitude) 
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- JSONB 인덱스
CREATE INDEX IF NOT EXISTS idx_instagram_posts_metadata_json_gin 
    ON instagram_posts USING gin(metadata_json);

ALTER TABLE public.instagram_posts ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "instagram_posts are visible to everyone" 
    ON instagram_posts FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage instagram_posts" 
    ON instagram_posts FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER trigger_update_instagram_posts_updated_at
    BEFORE UPDATE ON instagram_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


