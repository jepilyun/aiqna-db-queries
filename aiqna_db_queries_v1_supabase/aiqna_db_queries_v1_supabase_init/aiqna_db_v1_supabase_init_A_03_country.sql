/*
 * aiqna db for web service (INIT)
 * Database Name 'aiqna'
 *
 * Created 2024-09-24
 * Updated 2025-11-30
 */


-- ============================================================================
-- TABLE: country
-- ============================================================================
-- 설명: 지원 국가 목록
-- ============================================================================
CREATE TABLE public.country (
    country_code VARCHAR(2) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    country_native_name VARCHAR(100) NOT NULL,
    user_count INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT country_pkey PRIMARY KEY (country_code),
    CONSTRAINT country_check_country_code_pattern CHECK (country_code ~ '^[A-Z]{2}$'),
    CONSTRAINT country_user_count_check CHECK ((user_count >= 0))
) TABLESPACE pg_default;

ALTER TABLE public.country ENABLE ROW LEVEL SECURITY;

CREATE POLICY "country is visible to everyone" 
    ON public.country FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

CREATE POLICY "Service role can manage country" 
    ON public.country FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);


-- ============================================================================
-- Function: increase_country_user_count
-- ============================================================================
-- 설명: 사용자 추가 시 해당 국가의 user_count 증가
-- 용도: user 테이블의 AFTER INSERT 트리거에서 호출
-- ============================================================================
CREATE OR REPLACE FUNCTION increase_country_user_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF NEW.country_code IS NOT NULL THEN
        UPDATE public.country
        SET user_count = user_count + 1
        WHERE country_code = NEW.country_code;
    END IF;
    RETURN NEW;
END;
$$;


-- ============================================================================
-- Function: decrease_country_user_count
-- ============================================================================
-- 설명: 사용자 삭제 시 해당 국가의 user_count 감소
-- 용도: user 테이블의 AFTER DELETE 트리거에서 호출
-- ============================================================================
CREATE OR REPLACE FUNCTION decrease_country_user_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF OLD.country_code IS NOT NULL THEN
        UPDATE public.country
        SET user_count = user_count - 1
        WHERE country_code = OLD.country_code
        AND user_count > 0;
    END IF;
    RETURN OLD;
END;
$$;


-- ============================================================================
-- Function: change_country_user_count
-- ============================================================================
-- 설명: 사용자 국가 변경 시 기존 국가 감소, 새 국가 증가
-- 용도: user 테이블의 AFTER UPDATE 트리거에서 호출
-- ============================================================================
CREATE OR REPLACE FUNCTION change_country_user_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF OLD.country_code IS DISTINCT FROM NEW.country_code THEN
        IF OLD.country_code IS NOT NULL THEN
            UPDATE public.country
            SET user_count = user_count - 1
            WHERE country_code = OLD.country_code
            AND user_count > 0;
        END IF;

        IF NEW.country_code IS NOT NULL THEN
            UPDATE public.country
            SET user_count = user_count + 1
            WHERE country_code = NEW.country_code;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;



-- ============================================================================
-- TABLE: search_country_code_by_keyword
-- ============================================================================
-- 설명: 국가별 검색 키워드 매핑 (내부 검색용)
-- 용도: "Korea", "한국", "대한민국" → "KR" 매핑
-- 접근: authenticated, service_role만 허용
-- ============================================================================
CREATE TABLE public.search_country_code_by_keyword (
    country_code VARCHAR(2) NOT NULL,
    search_keyword VARCHAR(100) NOT NULL,
    
    -- 추가 필드
    lang_code VARCHAR(12) NULL,                    -- 키워드 언어 (ko, en, zh 등)
    keyword_type VARCHAR(20) NOT NULL DEFAULT 'name',  -- 키워드 유형
    is_primary BOOLEAN NOT NULL DEFAULT false,   -- 대표 키워드 여부 (검색 결과 표시용)
    "priority" SMALLINT NOT NULL DEFAULT 0,        -- 우선순위 (높을수록 먼저 매칭)
    
    -- 메타 필드
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    added_by VARCHAR(45) NULL,
    
    CONSTRAINT search_country_code_by_keyword_pkey 
        PRIMARY KEY (country_code, search_keyword),
    CONSTRAINT search_country_code_by_keyword_country_code_fkey 
        FOREIGN KEY (country_code) 
        REFERENCES public.country (country_code) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,
    CONSTRAINT search_country_code_by_keyword_type_check 
        CHECK (keyword_type IN ('name', 'native', 'alias', 'code', 'abbreviation', 'demonym')),
    CONSTRAINT search_country_code_by_keyword_priority_check
        CHECK (priority >= 0)
) TABLESPACE pg_default;

-- 인덱스
-- 특정 국가의 모든 키워드 조회 (예: "KR"의 모든 검색어)
CREATE INDEX IF NOT EXISTS idx_sccbk_country_code
    ON public.search_country_code_by_keyword (country_code);

-- 키워드로 국가 코드 검색 (예: "Korea" → "KR")
-- 대소문자 구분 검색용
CREATE INDEX IF NOT EXISTS idx_sccbk_search_keyword
    ON public.search_country_code_by_keyword (search_keyword);

-- 키워드 대소문자 무시 검색 (예: "korea", "KOREA", "Korea" 모두 매칭)
-- WHERE LOWER(search_keyword) = LOWER('korea') 쿼리 최적화
CREATE INDEX IF NOT EXISTS idx_sccbk_search_keyword_lower
    ON public.search_country_code_by_keyword (LOWER(search_keyword));

-- 특정 언어의 키워드 필터링 (예: lang_code = 'ko'인 키워드만 검색)
-- 부분 인덱스로 NULL 제외하여 효율성 향상
CREATE INDEX IF NOT EXISTS idx_sccbk_lang_code
    ON public.search_country_code_by_keyword (lang_code) WHERE lang_code IS NOT NULL;


-- Enable RLS
ALTER TABLE public.search_country_code_by_keyword ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "search_country_code_by_keyword is visible to authenticated" 
    ON public.search_country_code_by_keyword FOR SELECT 
    TO authenticated 
    USING (TRUE);

CREATE POLICY "Service role can manage search_country_code_by_keyword" 
    ON public.search_country_code_by_keyword FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);
