/*
 * aiqna db for web service (Pinecone Vectors Table)
 * Database Name 'aiqna'
 *
 * Created 2024-09-24
 * Updated 2025-10-12
 */



/*
 ***********************************************************************************************
 * TABLE: pinecone_vectors (Vector Storage Tracking)
 ***********************************************************************************************
 */
CREATE TABLE IF NOT EXISTS pinecone_vectors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- 소스 식별
    source_type VARCHAR(50) NOT NULL,
    source_id VARCHAR(1023) NOT NULL,
    
    -- Pinecone 정보
    vector_id VARCHAR(255) NOT NULL UNIQUE,
    namespace VARCHAR(255),
    index_name VARCHAR(255) NOT NULL,
    
    -- 메타데이터
    chunk_index INTEGER DEFAULT 0,
    total_chunks INTEGER DEFAULT 1,
    embedding_model VARCHAR(100),
    embedding_dimensions INTEGER,
    
    -- 원본 텍스트 정보 (선택적)
    chunk_text TEXT,
    chunk_tokens INTEGER,
    
    -- 상태
    status VARCHAR(20) DEFAULT 'active',
    
    -- 타임스탬프
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- 제약조건
    CONSTRAINT chk_pinecone_source_type 
        CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
    
    CONSTRAINT chk_pinecone_status 
        CHECK (status IN ('active', 'deleted', 'outdated', 'processing', 'failed')),
    
    CONSTRAINT chk_pinecone_chunk_index 
        CHECK (chunk_index >= 0),
    
    CONSTRAINT chk_pinecone_total_chunks 
        CHECK (total_chunks >= 1),
    
    CONSTRAINT chk_pinecone_chunk_relationship 
        CHECK (chunk_index < total_chunks),
    
    CONSTRAINT chk_pinecone_embedding_dimensions 
        CHECK (embedding_dimensions IS NULL OR embedding_dimensions > 0),
    
    CONSTRAINT chk_pinecone_chunk_tokens 
        CHECK (chunk_tokens IS NULL OR chunk_tokens > 0),
    
    -- 복합 UNIQUE 제약
    CONSTRAINT uq_pinecone_source_chunk 
        UNIQUE(source_type, source_id, chunk_index)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_pinecone_vectors_source_type_id 
    ON pinecone_vectors(source_type, source_id);

CREATE INDEX IF NOT EXISTS idx_pinecone_vectors_source_type 
    ON pinecone_vectors(source_type);

CREATE INDEX IF NOT EXISTS idx_pinecone_vectors_status 
    ON pinecone_vectors(status) WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_pinecone_vectors_index_name 
    ON pinecone_vectors(index_name);

CREATE INDEX IF NOT EXISTS idx_pinecone_vectors_namespace 
    ON pinecone_vectors(namespace) WHERE namespace IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_pinecone_vectors_created_at 
    ON pinecone_vectors(created_at);

-- 청크 텍스트 전체 검색 인덱스 (선택적)
CREATE INDEX IF NOT EXISTS idx_pinecone_vectors_chunk_text_gin 
    ON pinecone_vectors USING gin(to_tsvector('simple', COALESCE(chunk_text, '')))
    WHERE chunk_text IS NOT NULL;

ALTER TABLE public.pinecone_vectors ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "pinecone_vectors are visible to everyone" 
    ON pinecone_vectors FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage pinecone_vectors" 
    ON pinecone_vectors FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER trigger_update_pinecone_vectors_updated_at
    BEFORE UPDATE ON pinecone_vectors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();