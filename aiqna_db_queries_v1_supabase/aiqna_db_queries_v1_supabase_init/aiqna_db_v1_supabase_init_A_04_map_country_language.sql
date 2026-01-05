/*
 * aiqna db for web service (INIT)
 * Database Name 'aiqna'
 *
 * Created 2024-09-24
 * Updated 2025-11-30
 */


-- ============================================================================
-- TABLE: map_country_language
-- ============================================================================
-- 설명: 국가-언어 매핑 (국가별 지원 언어)
-- ============================================================================
CREATE TABLE public.map_country_language (
    country_lang_code VARCHAR(12) NOT NULL,
    country_code VARCHAR(2) NOT NULL,
    lang_code VARCHAR(12) NOT NULL,
    CONSTRAINT map_country_language_pkey PRIMARY KEY (country_lang_code),
    CONSTRAINT map_country_language_unique UNIQUE (country_code, lang_code),
    CONSTRAINT map_country_language_country_code_fkey 
        FOREIGN KEY (country_code) 
        REFERENCES public.country (country_code) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,
    CONSTRAINT map_country_language_lang_code_fkey 
        FOREIGN KEY (lang_code) 
        REFERENCES public.language (lang_code) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE
) TABLESPACE pg_default;

-- 인덱스
-- 특정 국가에서 지원하는 모든 언어 조회 (예: "KR"의 지원 언어 목록)
CREATE INDEX IF NOT EXISTS idx_mcl_country_code
    ON public.map_country_language (country_code);

-- 특정 언어를 사용하는 모든 국가 조회 (예: "ko"를 지원하는 국가 목록)
CREATE INDEX IF NOT EXISTS idx_mcl_lang_code
    ON public.map_country_language (lang_code);

-- Enable RLS
ALTER TABLE public.map_country_language ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "map_country_language is visible to everyone" 
    ON public.map_country_language FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

CREATE POLICY "Service role can manage map_country_language" 
    ON public.map_country_language FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);
