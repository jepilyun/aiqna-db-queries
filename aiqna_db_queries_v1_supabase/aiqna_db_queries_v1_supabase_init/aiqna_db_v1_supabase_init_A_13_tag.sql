/*
 * aiqna db for web service (Tags and Mapping Tables)
 * Database Name 'aiqna'
 *
 * Created 2024-10-12
 * Updated 2025-10-12
 */




/*
 ***********************************************************************************************
 * TABLE: tags
 *  - 일반 태그 시스템 (stags와 다른 자유형식 태그)
 ***********************************************************************************************
 */
CREATE TABLE public.tags (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tag VARCHAR(63) NOT NULL UNIQUE,  -- 태그는 유일해야 함
  
  -- 통계
  content_count INTEGER NOT NULL DEFAULT 0,
  
  -- 시스템 정보
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,

  -- 제약조건
  CONSTRAINT tags_tag_trim_check CHECK (btrim(tag) = tag),
  CONSTRAINT tags_tag_not_empty_check CHECK (LENGTH(tag) > 0),
  CONSTRAINT tags_content_count_check CHECK (content_count >= 0)
) TABLESPACE pg_default;

-- =============================================================================================
-- INDEXES
-- =============================================================================================

-- 태그 부분/유사 검색 최적화
CREATE INDEX IF NOT EXISTS tags_tag_trgm_idx
  ON public.tags USING gin (tag gin_trgm_ops);

-- 소문자 변환 검색 (대소문자 구분 없이)
CREATE INDEX IF NOT EXISTS tags_tag_lower_idx
  ON public.tags (LOWER(tag));

-- 인기 태그 정렬
CREATE INDEX IF NOT EXISTS tags_content_count_idx
  ON public.tags (content_count DESC, tag)
  WHERE is_active = TRUE;

-- 활성 태그만
CREATE INDEX IF NOT EXISTS tags_is_active_idx
  ON public.tags (is_active)
  WHERE is_active = TRUE;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "tags are visible to everyone"
  ON public.tags FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage tags"
  ON public.tags FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- =============================================================================================
-- TRIGGER
-- =============================================================================================

CREATE TRIGGER trigger_update_tags_updated_at
  BEFORE UPDATE ON public.tags
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




/*
 ***********************************************************************************************
 * TABLE: map_tag
 *  - AI로 추출된 태그와 콘텐츠 매핑
 ***********************************************************************************************
 */
CREATE TABLE public.map_tag (
  tag_id UUID NOT NULL,
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

  CONSTRAINT map_tag_pkey
    PRIMARY KEY (tag_id, source_type, source_id),

  CONSTRAINT map_tag_tag_id_fkey
    FOREIGN KEY (tag_id) 
    REFERENCES public.tags (id)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT map_tag_source_type_check 
    CHECK (source_type IN ('youtube_video', 'instagram_post', 'blog_post', 'text')),
  
  CONSTRAINT map_tag_order_num_check CHECK (order_num >= 0),
  
  CONSTRAINT map_tag_confidence_check 
    CHECK (confidence_score IS NULL OR (confidence_score BETWEEN 0 AND 1))
) TABLESPACE pg_default;

-- =============================================================================================
-- Indexes
-- =============================================================================================

-- 태그별 콘텐츠 목록 조회
CREATE INDEX IF NOT EXISTS map_tag_id_order_idx
  ON public.map_tag (tag_id, order_num, source_id);

-- 최신 등록순 조회
CREATE INDEX IF NOT EXISTS map_tag_id_added_idx
  ON public.map_tag (tag_id, added_at DESC, source_id);

-- 선택된 항목 빠른 조회
CREATE INDEX IF NOT EXISTS map_tag_selected_idx
  ON public.map_tag (tag_id, order_num, added_at DESC)
  WHERE is_selected = TRUE;

-- 검증된 항목 조회
CREATE INDEX IF NOT EXISTS map_tag_verified_idx
  ON public.map_tag (tag_id, confidence_score DESC)
  WHERE is_verified = TRUE;

-- 역방향 탐색 (특정 콘텐츠가 매핑된 태그들)
CREATE INDEX IF NOT EXISTS map_tag_source_idx
  ON public.map_tag (source_type, source_id, tag_id);

-- 소스 타입별 조회
CREATE INDEX IF NOT EXISTS map_tag_source_type_idx
  ON public.map_tag (source_type, added_at DESC);

-- 신뢰도 높은 항목 조회
CREATE INDEX IF NOT EXISTS map_tag_confidence_idx
  ON public.map_tag (confidence_score DESC)
  WHERE confidence_score >= 0.8;

-- =============================================================================================
-- RLS
-- =============================================================================================

ALTER TABLE public.map_tag ENABLE ROW LEVEL SECURITY;

-- 읽기 전용
CREATE POLICY "map_tag are visible to everyone"
  ON public.map_tag FOR SELECT 
  TO authenticated, anon 
  USING (TRUE);

-- 관리 작업
CREATE POLICY "Service role can manage map_tag"
  ON public.map_tag FOR ALL 
  TO service_role 
  USING (TRUE) 
  WITH CHECK (TRUE);

-- 트리거
CREATE TRIGGER trigger_update_map_tag_updated_at
  BEFORE UPDATE ON public.map_tag
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 태그 찾기 또는 생성
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_or_create_tag(
    p_tag VARCHAR(63)
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_tag_id UUID;
    v_normalized_tag VARCHAR(63);
BEGIN
    -- 태그 정규화 (소문자, 공백 제거)
    v_normalized_tag := LOWER(TRIM(p_tag));
    
    -- 기존 태그 찾기
    SELECT id INTO v_tag_id
    FROM public.tags
    WHERE LOWER(tag) = v_normalized_tag;
    
    -- 없으면 생성
    IF v_tag_id IS NULL THEN
        INSERT INTO public.tags (tag)
        VALUES (v_normalized_tag)
        RETURNING id INTO v_tag_id;
    END IF;
    
    RETURN v_tag_id;
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: AI 추출 태그 매핑 저장 (자동 태그 생성)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.upsert_tag_mapping(
    p_tag VARCHAR(63),
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
DECLARE
    v_tag_id UUID;
BEGIN
    -- 태그 찾기 또는 생성
    v_tag_id := get_or_create_tag(p_tag);
    
    -- 매핑 저장
    INSERT INTO public.map_tag (
        tag_id,
        source_type,
        source_id,
        confidence_score,
        extraction_method,
        extracted_at
    ) VALUES (
        v_tag_id,
        p_source_type,
        p_source_id,
        p_confidence_score,
        p_extraction_method,
        NOW()
    )
    ON CONFLICT (tag_id, source_type, source_id) DO UPDATE SET
        confidence_score = EXCLUDED.confidence_score,
        extraction_method = EXCLUDED.extraction_method,
        extracted_at = NOW(),
        updated_at = NOW();
END;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 태그 카운트 증가
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION increase_tag_content_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    UPDATE public.tags
    SET content_count = content_count + 1
    WHERE id = NEW.tag_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_increase_tag_content_count
    AFTER INSERT ON public.map_tag
    FOR EACH ROW
    EXECUTE FUNCTION increase_tag_content_count();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 태그 카운트 감소
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION decrease_tag_content_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    UPDATE public.tags
    SET content_count = content_count - 1
    WHERE id = OLD.tag_id
    AND content_count > 0;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trigger_decrease_tag_content_count
    AFTER DELETE ON public.map_tag
    FOR EACH ROW
    EXECUTE FUNCTION decrease_tag_content_count();




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 콘텐츠의 태그 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_tags_for_content(
    p_source_type VARCHAR(50),
    p_source_id VARCHAR(1023),
    p_min_confidence NUMERIC(3, 2) DEFAULT 0.5
)
RETURNS TABLE (
    tag_id UUID,
    tag VARCHAR(63),
    content_count INTEGER,
    confidence_score NUMERIC(3, 2),
    is_verified BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        t.id AS tag_id,
        t.tag,
        t.content_count,
        mt.confidence_score,
        mt.is_verified
    FROM public.map_tag mt
    JOIN public.tags t ON mt.tag_id = t.id
    WHERE mt.source_type = p_source_type
      AND mt.source_id = p_source_id
      AND (mt.confidence_score IS NULL OR mt.confidence_score >= p_min_confidence)
    ORDER BY mt.confidence_score DESC NULLS LAST, mt.order_num;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 특정 태그의 콘텐츠 목록 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_content_for_tag(
    p_tag VARCHAR(63),
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
        mt.source_type,
        mt.source_id,
        mt.confidence_score,
        mt.is_verified,
        mt.added_at
    FROM public.map_tag mt
    JOIN public.tags t ON mt.tag_id = t.id
    WHERE LOWER(t.tag) = LOWER(p_tag)
      AND (p_source_type IS NULL OR mt.source_type = p_source_type)
      AND (NOT p_verified_only OR mt.is_verified = TRUE)
    ORDER BY mt.order_num, mt.added_at DESC;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 인기 태그 조회
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_popular_tags(
    p_source_type VARCHAR(50) DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_min_count INTEGER DEFAULT 1
)
RETURNS TABLE (
    tag_id UUID,
    tag VARCHAR(63),
    content_count BIGINT,
    avg_confidence NUMERIC(5, 2)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        t.id AS tag_id,
        t.tag,
        COUNT(mt.source_id) AS content_count,
        ROUND(AVG(mt.confidence_score), 2) AS avg_confidence
    FROM public.tags t
    JOIN public.map_tag mt ON t.id = mt.tag_id
    WHERE (p_source_type IS NULL OR mt.source_type = p_source_type)
      AND t.is_active = TRUE
    GROUP BY t.id, t.tag
    HAVING COUNT(mt.source_id) >= p_min_count
    ORDER BY content_count DESC, avg_confidence DESC NULLS LAST
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 태그 검색 (자동완성용)
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.search_tags(
    p_query VARCHAR(63),
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    tag_id UUID,
    tag VARCHAR(63),
    content_count INTEGER,
    similarity REAL
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT 
        id AS tag_id,
        tag,
        content_count,
        similarity(tag, p_query) AS similarity
    FROM public.tags
    WHERE tag ILIKE '%' || p_query || '%'
      AND is_active = TRUE
    ORDER BY 
        similarity DESC,
        content_count DESC,
        tag
    LIMIT p_limit;
$$;




-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- Function: 관련 태그 찾기
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
CREATE OR REPLACE FUNCTION public.get_related_tags(
    p_tag VARCHAR(63),
    p_source_type VARCHAR(50) DEFAULT NULL,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    related_tag VARCHAR(63),
    co_occurrence_count BIGINT,
    relevance_score NUMERIC(5, 2)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    WITH target_tag AS (
        SELECT id FROM public.tags WHERE LOWER(tag) = LOWER(p_tag)
    ),
    target_content AS (
        SELECT source_type, source_id
        FROM public.map_tag
        WHERE tag_id = (SELECT id FROM target_tag)
          AND (p_source_type IS NULL OR source_type = p_source_type)
    ),
    co_occurring_tags AS (
        SELECT 
            mt.tag_id,
            COUNT(*) AS co_count
        FROM public.map_tag mt
        JOIN target_content tc 
          ON mt.source_type = tc.source_type 
          AND mt.source_id = tc.source_id
        WHERE mt.tag_id != (SELECT id FROM target_tag)
        GROUP BY mt.tag_id
    )
    SELECT 
        t.tag AS related_tag,
        cot.co_count AS co_occurrence_count,
        ROUND(
            (cot.co_count::NUMERIC / NULLIF((SELECT COUNT(*) FROM target_content), 0)) * 100, 
            2
        ) AS relevance_score
    FROM co_occurring_tags cot
    JOIN public.tags t ON cot.tag_id = t.id
    WHERE t.is_active = TRUE
    ORDER BY co_occurrence_count DESC
    LIMIT p_limit;
$$;