/*
 * aiqna db for web service (INIT)
 * Database Name 'aiqna'
 *
 * Created 2024-09-24
 * Updated 2025-11-30
 */


-- ============================================================================
-- TABLE: language
-- ============================================================================
-- 설명: 지원 언어 목록
-- ============================================================================
CREATE TABLE public.language (
    lang_code VARCHAR(12) NOT NULL,
    lang_name VARCHAR(48) NOT NULL,
    lang_native_name VARCHAR(48) NOT NULL,
    user_count INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT language_pkey PRIMARY KEY (lang_code),
    CONSTRAINT language_check_lang_code_pattern CHECK (
        lang_code = lower(lang_code)
        AND lang_code ~ '^[a-z]{2,3}(?:-[a-z0-9]{2,8})*$'
    ),
    CONSTRAINT language_user_count_check CHECK ((user_count >= 0))
) TABLESPACE pg_default;

ALTER TABLE public.language ENABLE ROW LEVEL SECURITY;

CREATE POLICY "language is visible to everyone" 
    ON public.language FOR SELECT 
    TO authenticated, anon 
    USING (TRUE);

CREATE POLICY "Service role can manage language" 
    ON public.language FOR ALL 
    TO service_role 
    USING (TRUE) 
    WITH CHECK (TRUE);


-- ============================================================================
-- Function: increase_language_user_count
-- ============================================================================
-- 설명: 사용자 추가 시 해당 언어의 user_count 증가
-- 용도: user 테이블의 AFTER INSERT 트리거에서 호출
-- ============================================================================
CREATE OR REPLACE FUNCTION increase_language_user_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF NEW.lang_code IS NOT NULL THEN
        UPDATE public.language
        SET user_count = user_count + 1
        WHERE lang_code = NEW.lang_code;
    END IF;
    RETURN NEW;
END;
$$;


-- ============================================================================
-- Function: decrease_language_user_count
-- ============================================================================
-- 설명: 사용자 삭제 시 해당 언어의 user_count 감소
-- 용도: user 테이블의 AFTER DELETE 트리거에서 호출
-- ============================================================================
CREATE OR REPLACE FUNCTION decrease_language_user_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF OLD.lang_code IS NOT NULL THEN
        UPDATE public.language
        SET user_count = user_count - 1
        WHERE lang_code = OLD.lang_code
        AND user_count > 0;
    END IF;
    RETURN OLD;
END;
$$;


-- ============================================================================
-- Function: change_language_user_count
-- ============================================================================
-- 설명: 사용자 언어 변경 시 기존 언어 감소, 새 언어 증가
-- 용도: user 테이블의 AFTER UPDATE 트리거에서 호출
-- ============================================================================
CREATE OR REPLACE FUNCTION change_language_user_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF OLD.lang_code IS DISTINCT FROM NEW.lang_code THEN
        IF OLD.lang_code IS NOT NULL THEN
            UPDATE public.language
            SET user_count = user_count - 1
            WHERE lang_code = OLD.lang_code
            AND user_count > 0;
        END IF;

        IF NEW.lang_code IS NOT NULL THEN
            UPDATE public.language
            SET user_count = user_count + 1
            WHERE lang_code = NEW.lang_code;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

