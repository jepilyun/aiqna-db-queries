/*
 * aiqna db for web service (Text Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-09-24
 * Updated 2025-10-12
 */



/*
 ***********************************************************************************************
 * TABLE: text_processing_logs (Text Processing Logs)
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS text_processing_logs (
    -- 기본 키
    hash_key VARCHAR(64) PRIMARY KEY,  -- SHA256 해시는 64자
    
    -- 메타데이터
    processing_status VARCHAR(20) DEFAULT 'pending',
    index_name VARCHAR(255),

    -- 불린 플래그들
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
    CONSTRAINT chk_text_processing_status 
        CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),

    -- 시간 로직 검증
    CONSTRAINT chk_text_processing_times 
        CHECK (processing_started IS NULL OR processing_completed IS NULL 
        OR processing_completed >= processing_started),

    -- 우선순위 검증
    CONSTRAINT chk_text_priority CHECK (priority BETWEEN 1 AND 10),
    
    -- 해시 형식 검증 (16진수 문자열)
    CONSTRAINT chk_text_hash_format CHECK (hash_key ~ '^[a-f0-9]{32,64}$')
);

CREATE INDEX IF NOT EXISTS idx_text_processing_logs_status 
    ON text_processing_logs(processing_status);

CREATE INDEX IF NOT EXISTS idx_text_processing_logs_priority 
    ON text_processing_logs(priority) 
    WHERE processing_status = 'pending';

CREATE INDEX IF NOT EXISTS idx_text_processing_logs_error_flag
    ON text_processing_logs(is_error_occurred)
    WHERE is_error_occurred = TRUE;

ALTER TABLE public.text_processing_logs ENABLE ROW LEVEL SECURITY;

-- 읽기 전용 (모든 사용자)
CREATE POLICY "text_processing_logs are visible to everyone" 
    ON text_processing_logs FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업 (service_role만)
CREATE POLICY "Service role can manage text_processing_logs" 
    ON text_processing_logs FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER trigger_update_text_processing_logs_updated_at
    BEFORE UPDATE ON text_processing_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();





/*
 ***********************************************************************************************
 * TABLE: texts (Texts)
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS texts (
    -- 기본 키
    hash_key VARCHAR(64) PRIMARY KEY,  -- SHA256 해시는 64자
    
    title VARCHAR(1023),
    content TEXT NOT NULL,  -- 텍스트 내용은 필수

    -- 시스템 타임스탬프
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_processed_at TIMESTAMP WITH TIME ZONE,

    metadata_json JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- 제약조건
    CONSTRAINT chk_text_hash_format CHECK (hash_key ~ '^[a-f0-9]{32,64}$'),
    CONSTRAINT chk_text_content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

-- 기본 인덱스
CREATE INDEX IF NOT EXISTS idx_texts_created_at 
    ON texts(created_at);
CREATE INDEX IF NOT EXISTS idx_texts_is_active 
    ON texts(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_texts_is_deleted 
    ON texts(is_deleted) WHERE is_deleted = FALSE;

-- 전체 텍스트 검색 인덱스
CREATE INDEX IF NOT EXISTS idx_texts_text_search_gin 
    ON texts USING gin(to_tsvector('simple', 
    COALESCE(title, '') || ' ' || COALESCE(content, '')));

-- JSONB 인덱스
CREATE INDEX IF NOT EXISTS idx_texts_metadata_json_gin 
    ON texts USING gin(metadata_json);

ALTER TABLE public.texts ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "texts are visible to everyone" 
    ON texts FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage texts" 
    ON texts FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER trigger_update_texts_updated_at
    BEFORE UPDATE ON texts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();