/*
 * aiqna db for web service (QnA Log Table)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */




/*
 ***********************************************************************************************
 * TABLE: qna_log
 *  - 질문과 답변 로그 (AI 응답 분석용)
 ***********************************************************************************************
 */
CREATE TABLE public.qna_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- 질문/답변 내용
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  
  -- 사용자 피드백
  user_feedback VARCHAR(20) NULL,
  user_rating INTEGER NULL,
  user_comment TEXT NULL,
  
  -- 메타 정보
  question_lang VARCHAR(10) NULL,
  answer_lang VARCHAR(10) NULL,
  
  -- AI 정보
  ai_model VARCHAR(50) NULL,
  ai_confidence NUMERIC(3, 2) NULL,
  response_time_ms INTEGER NULL,
  token_count INTEGER NULL,
  
  -- 사용자 정보 (익명화)
  user_id VARCHAR(255) NULL,
  session_id VARCHAR(255) NULL,
  ip_hash VARCHAR(64) NULL,
  
  -- 컨텍스트 정보
  context_type VARCHAR(50) NULL,  -- 'city', 'category', 'place', 'general'
  context_id VARCHAR(255) NULL,
  
  -- 참조된 소스
  referenced_sources JSONB NULL,
  
  -- 시스템 정보
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 플래그
  is_helpful BOOLEAN NULL,
  is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
  flagged_reason VARCHAR(255) NULL,
  is_reviewed BOOLEAN NOT NULL DEFAULT FALSE,
  reviewed_at TIMESTAMP WITH TIME ZONE NULL,
  reviewed_by VARCHAR(255) NULL,

  -- 제약조건
  CONSTRAINT qna_log_user_feedback_check 
    CHECK (user_feedback IN ('like', 'dislike', 'neutral', 'report')),
  
  CONSTRAINT qna_log_user_rating_check 
    CHECK (user_rating IS NULL OR (user_rating BETWEEN 1 AND 5)),
  
  CONSTRAINT qna_log_ai_confidence_check 
    CHECK (ai_confidence IS NULL OR (ai_confidence BETWEEN 0 AND 1)),
  
  CONSTRAINT qna_log_response_time_check 
    CHECK (response_time_ms IS NULL OR response_time_ms > 0),
  
  CONSTRAINT qna_log_token_count_check 
    CHECK (token_count IS NULL OR token_count > 0),
  
  CONSTRAINT qna_log_question_not_empty_check 
    CHECK (LENGTH(TRIM(question)) > 0),
  
  CONSTRAINT qna_log_answer_not_empty_check 
    CHECK (LENGTH(TRIM(answer)) > 0)
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 시간순 조회
CREATE INDEX IF NOT EXISTS qna_log_created_at_idx
  ON public.qna_log (created_at DESC);

-- 사용자별 조회
CREATE INDEX IF NOT EXISTS qna_log_user_id_idx
  ON public.qna_log (user_id, created_at DESC)
  WHERE user_id IS NOT NULL;

-- 세션별 조회
CREATE INDEX IF NOT EXISTS qna_log_session_id_idx
  ON public.qna_log (session_id, created_at DESC)
  WHERE session_id IS NOT NULL;

-- 피드백 분석
CREATE INDEX IF NOT EXISTS qna_log_user_feedback_idx
  ON public.qna_log (user_feedback, created_at DESC)
  WHERE user_feedback IS NOT NULL;

CREATE INDEX IF NOT EXISTS qna_log_user_rating_idx
  ON public.qna_log (user_rating DESC, created_at DESC)
  WHERE user_rating IS NOT NULL;

-- 플래그된 항목
CREATE INDEX IF NOT EXISTS qna_log_flagged_idx
  ON public.qna_log (is_flagged, created_at DESC)
  WHERE is_flagged = TRUE;

-- 리뷰 대기 항목
CREATE INDEX IF NOT EXISTS qna_log_pending_review_idx
  ON public.qna_log (is_reviewed, is_flagged, created_at)
  WHERE is_reviewed = FALSE;

-- 컨텍스트별 조회
CREATE INDEX IF NOT EXISTS qna_log_context_idx
  ON public.qna_log (context_type, context_id, created_at DESC)
  WHERE context_type IS NOT NULL;

-- AI 모델별 분석
CREATE INDEX IF NOT EXISTS qna_log_ai_model_idx
  ON public.qna_log (ai_model, created_at DESC)
  WHERE ai_model IS NOT NULL;

-- 질문 전체 텍스트 검색
CREATE INDEX IF NOT EXISTS qna_log_question_gin_idx
  ON public.qna_log USING gin(to_tsvector('simple', question));

-- 답변 전체 텍스트 검색
CREATE INDEX IF NOT EXISTS qna_log_answer_gin_idx
  ON public.qna_log USING gin(to_tsvector('simple', answer));

-- JSONB 인덱스
CREATE INDEX IF NOT EXISTS qna_log_referenced_sources_gin_idx
  ON public.qna_log USING gin(referenced_sources)
  WHERE referenced_sources IS NOT NULL;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.qna_log ENABLE ROW LEVEL SECURITY;

-- 읽기 전용 (모든 사용자)
CREATE POLICY "qna_log are visible to everyone"
  ON public.qna_log FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업 (service_role만)
CREATE POLICY "Service role can manage qna_log"
  ON public.qna_log FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_qna_log_updated_at
  BEFORE UPDATE ON public.qna_log
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: QnA 로그 저장
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.log_qna(
    p_question TEXT,
    p_answer TEXT,
    p_user_id VARCHAR(255) DEFAULT NULL,
    p_session_id VARCHAR(255) DEFAULT NULL,
    p_ai_model VARCHAR(50) DEFAULT NULL,
    p_response_time_ms INTEGER DEFAULT NULL,
    p_context_type VARCHAR(50) DEFAULT NULL,
    p_context_id VARCHAR(255) DEFAULT NULL,
    p_referenced_sources JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO public.qna_log (
        question,
        answer,
        user_id,
        session_id,
        ai_model,
        response_time_ms,
        context_type,
        context_id,
        referenced_sources
    ) VALUES (
        p_question,
        p_answer,
        p_user_id,
        p_session_id,
        p_ai_model,
        p_response_time_ms,
        p_context_type,
        p_context_id,
        p_referenced_sources
    )
    RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 사용자 피드백 업데이트
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.update_qna_feedback(
    p_log_id UUID,
    p_user_feedback VARCHAR(20),
    p_user_rating INTEGER DEFAULT NULL,
    p_user_comment TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    UPDATE public.qna_log
    SET user_feedback = p_user_feedback,
        user_rating = p_user_rating,
        user_comment = p_user_comment,
        is_helpful = CASE 
            WHEN p_user_feedback = 'like' THEN TRUE
            WHEN p_user_feedback = 'dislike' THEN FALSE
            ELSE NULL
        END,
        is_flagged = CASE 
            WHEN p_user_feedback = 'report' THEN TRUE
            ELSE is_flagged
        END,
        updated_at = NOW()
    WHERE id = p_log_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 인기 질문 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_popular_questions(
    p_context_type VARCHAR(50) DEFAULT NULL,
    p_days INTEGER DEFAULT 30,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    question TEXT,
    question_count BIGINT,
    avg_rating NUMERIC(3, 2),
    helpful_count BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        question,
        COUNT(*) AS question_count,
        ROUND(AVG(user_rating), 2) AS avg_rating,
        COUNT(*) FILTER (WHERE is_helpful = TRUE) AS helpful_count
    FROM public.qna_log
    WHERE (p_context_type IS NULL OR context_type = p_context_type)
      AND created_at >= NOW() - (p_days || ' days')::INTERVAL
    GROUP BY question
    ORDER BY question_count DESC, avg_rating DESC NULLS LAST
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: AI 모델 성능 분석
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.analyze_ai_performance(
    p_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    ai_model VARCHAR(50),
    total_responses BIGINT,
    avg_response_time_ms NUMERIC(10, 2),
    avg_rating NUMERIC(3, 2),
    like_count BIGINT,
    dislike_count BIGINT,
    report_count BIGINT,
    satisfaction_rate NUMERIC(5, 2)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        ai_model,
        COUNT(*) AS total_responses,
        ROUND(AVG(response_time_ms), 2) AS avg_response_time_ms,
        ROUND(AVG(user_rating), 2) AS avg_rating,
        COUNT(*) FILTER (WHERE user_feedback = 'like') AS like_count,
        COUNT(*) FILTER (WHERE user_feedback = 'dislike') AS dislike_count,
        COUNT(*) FILTER (WHERE user_feedback = 'report') AS report_count,
        ROUND(
            (COUNT(*) FILTER (WHERE user_feedback = 'like')::NUMERIC / 
             NULLIF(COUNT(*) FILTER (WHERE user_feedback IN ('like', 'dislike')), 0)) * 100,
            2
        ) AS satisfaction_rate
    FROM public.qna_log
    WHERE ai_model IS NOT NULL
      AND created_at >= NOW() - (p_days || ' days')::INTERVAL
    GROUP BY ai_model
    ORDER BY total_responses DESC;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 유사 질문 찾기
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.find_similar_questions(
    p_question TEXT,
    p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
    log_id UUID,
    question TEXT,
    answer TEXT,
    similarity REAL,
    avg_rating NUMERIC(3, 2)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        id AS log_id,
        question,
        answer,
        similarity(question, p_question) AS similarity,
        user_rating AS avg_rating
    FROM public.qna_log
    WHERE question % p_question  -- % 연산자는 유사도 기반 매칭
      AND is_helpful = TRUE
    ORDER BY similarity DESC, user_rating DESC NULLS LAST
    LIMIT p_limit;
$$;