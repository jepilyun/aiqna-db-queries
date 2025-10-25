/*
 * aiqna db for web service (INIT)
 * Database Name 'aiqna'
 *
 * Created 2024-09-24
 * Updated 2025-10-12
 */



/*
 ***********************************************************************************************
 * TABLE: languages
 ***********************************************************************************************
 */
CREATE TABLE public.languages (
    lang_code VARCHAR(8) NOT NULL,
    lang_name VARCHAR(48) NOT NULL,
    native_name VARCHAR(48) NOT NULL,
    user_count INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT languages_pkey PRIMARY KEY (lang_code),
    CONSTRAINT languages_check_lang_code_pattern CHECK (
        lang_code = lower(lang_code) -- 소문자 정규화 강제
        AND lang_code ~ '^[a-z]{2,3}(?:-[a-z0-9]{2,8})*$'
    ),
    CONSTRAINT languages_user_count_check CHECK ((user_count >= 0))
) TABLESPACE pg_default;

ALTER TABLE public.languages ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 SELECT 가능
CREATE POLICY "languages are visible to everyone" 
    ON languages FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- ⚠️ 관리 작업은 service_role만 가능하도록 제한 (보안 강화)
CREATE POLICY "Service role can manage languages" 
    ON languages FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);



-- ##############################################################################################
-- Function: Increase user_count on languages (INSERT)
-- ##############################################################################################
CREATE OR REPLACE FUNCTION increase_languages_user_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF NEW.lang_code IS NOT NULL THEN
        UPDATE public.languages
        SET user_count = user_count + 1
        WHERE lang_code = NEW.lang_code;
    END IF;
    RETURN NEW;
END;
$$;


-- ##############################################################################################
-- Function: Decrease user_count on languages (DELETE)
-- ##############################################################################################
CREATE OR REPLACE FUNCTION decrease_languages_user_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF OLD.lang_code IS NOT NULL THEN
        UPDATE public.languages
        SET user_count = user_count - 1
        WHERE lang_code = OLD.lang_code
        AND user_count > 0;  -- 음수 방지
    END IF;
    RETURN OLD;
END;
$$;



-- ##############################################################################################
-- Function: Change user_count on languages (UPDATE)
-- ##############################################################################################
CREATE OR REPLACE FUNCTION change_languages_user_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    -- lang_code가 실제로 변경된 경우만 처리
    IF OLD.lang_code IS DISTINCT FROM NEW.lang_code THEN
        IF OLD.lang_code IS NOT NULL THEN
            UPDATE public.languages
            SET user_count = user_count - 1
            WHERE lang_code = OLD.lang_code
            AND user_count > 0;  -- 음수 방지
        END IF;

        IF NEW.lang_code IS NOT NULL THEN
            UPDATE public.languages
            SET user_count = user_count + 1
            WHERE lang_code = NEW.lang_code;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;



/*
 ***********************************************************************************************
 * TABLE: countries
 ***********************************************************************************************
 */
CREATE TABLE public.countries (
    country_code VARCHAR(2) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    native_name VARCHAR(100) NOT NULL,
    CONSTRAINT countries_pkey PRIMARY KEY (country_code),
    CONSTRAINT check_country_code_length CHECK (country_code ~ '^[A-Z]{2}$')
) TABLESPACE pg_default;

ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 SELECT 가능
CREATE POLICY "countries are visible to everyone" 
    ON countries FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업은 service_role만 가능
CREATE POLICY "Service role can manage countries" 
    ON countries FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);




/*
 ***********************************************************************************************
 * TABLE: map_country_search_keywords
 ***********************************************************************************************
 */
CREATE TABLE public.map_country_search_keywords (
    country_code VARCHAR(2) NOT NULL,
    search_keyword VARCHAR(100) NOT NULL,
    CONSTRAINT map_country_search_keywords_pkey PRIMARY KEY (country_code, search_keyword),
    CONSTRAINT map_country_search_keywords_country_code_fkey 
        FOREIGN KEY (country_code) 
        REFERENCES public.countries (country_code) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE
) TABLESPACE pg_default;

ALTER TABLE public.map_country_search_keywords ENABLE ROW LEVEL SECURITY;

-- map_country_search_keywords
CREATE INDEX IF NOT EXISTS idx_mcsq_country_code
    ON public.map_country_search_keywords (country_code);
CREATE INDEX IF NOT EXISTS idx_mcsq_search_keyword
    ON public.map_country_search_keywords (search_keyword);

-- 모든 사용자가 SELECT 가능
CREATE POLICY "map_country_search_keywords are visible to everyone" 
    ON map_country_search_keywords FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업은 service_role만 가능
CREATE POLICY "Service role can manage map_country_search_keywords" 
    ON map_country_search_keywords FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);





/*
 ***********************************************************************************************
 * TABLE: map_country_languages
 ***********************************************************************************************
 */
CREATE TABLE public.map_country_languages (
    country_lang_code VARCHAR(12) NOT NULL,
    country_code VARCHAR(2) NOT NULL,
    lang_code VARCHAR(8) NOT NULL,
    CONSTRAINT map_country_languages_pkey PRIMARY KEY (country_lang_code),
    CONSTRAINT map_country_languages_unique UNIQUE (country_code, lang_code),
    CONSTRAINT map_country_languages_country_code_fkey 
        FOREIGN KEY (country_code) 
        REFERENCES public.countries (country_code) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,
    CONSTRAINT map_country_languages_lang_code_fkey 
        FOREIGN KEY (lang_code) 
        REFERENCES public.languages (lang_code) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE
) TABLESPACE pg_default;

ALTER TABLE public.map_country_languages ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_mcl_country_code
    ON public.map_country_languages (country_code);
CREATE INDEX IF NOT EXISTS idx_mcl_lang_code
    ON public.map_country_languages (lang_code);

-- 모든 사용자가 SELECT 가능
CREATE POLICY "map_country_languages are visible to everyone" 
    ON map_country_languages FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

-- 관리 작업은 service_role만 가능
CREATE POLICY "Service role can manage map_country_languages" 
    ON map_country_languages FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);

