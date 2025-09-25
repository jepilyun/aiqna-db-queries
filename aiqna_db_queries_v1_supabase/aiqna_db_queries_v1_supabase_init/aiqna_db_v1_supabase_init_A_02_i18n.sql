/*
 * aiqna db for web service (INIT)
 * Database Name 'aiqna'
 *
 * Created 2025-09-24
 * Updated 2025-09-24
 */




/*
 ***********************************************************************************************
 * TABLE: languages
 ***********************************************************************************************
 */
create table public.languages (
    lang_code character varying(8) not null,
    lang_name character varying(48) not null,
    "native" character varying(48) not null,
    user_count integer not null default 0,
    constraint languages_pkey primary key (lang_code),
    constraint languages_user_count_check check ((user_count >= 0))
) TABLESPACE pg_default;

alter table public.languages enable row level security;

-- 모든 사용자가 SELECT 가능
create policy "languages are visible to everyone" on languages for select to authenticated, anon using (TRUE);
-- 모든 사용자가 INSERT 가능
create policy "Everyone can insert languages" on languages for insert to authenticated with check (TRUE);
-- 모든 사용자가 UPDATE 가능
create policy "Everyone can update languages" on languages for update to authenticated using (TRUE);
-- 모든 사용자가 DELETE 가능
create policy "Everyone can delete languages" on languages for delete to authenticated using (TRUE);



-- ##############################################################################################
-- Function: Increase user_count on languages (INSERT)
-- ##############################################################################################
CREATE OR REPLACE FUNCTION increase_languages_user_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  -- 함수 소유자(보통 관리자) 권한으로 실행
SET search_path = pg_catalog, public  -- 경로 고정으로 일관성 보장
AS $$
BEGIN
    IF NEW.lang_code IS NOT NULL THEN
        UPDATE languages
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
SECURITY DEFINER  -- 함수 소유자(보통 관리자) 권한으로 실행
SET search_path = pg_catalog, public  -- 경로 고정으로 일관성 보장
AS $$
BEGIN
    IF OLD.lang_code IS NOT NULL THEN
        UPDATE languages
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
SECURITY DEFINER  -- 함수 소유자(보통 관리자) 권한으로 실행
SET search_path = pg_catalog, public  -- 경로 고정으로 일관성 보장
AS $$
BEGIN
    IF OLD.lang_code IS NOT NULL THEN
        UPDATE languages
        SET user_count = user_count - 1
        WHERE lang_code = OLD.lang_code
        AND user_count > 0;  -- ✅ 음수 방지 추가
    END IF;

    IF NEW.lang_code IS NOT NULL THEN
        UPDATE languages
        SET user_count = user_count + 1
        WHERE lang_code = NEW.lang_code;
    END IF;

    RETURN NEW;
END;
$$;



/*
 ***********************************************************************************************
 * TABLE: countries
 ***********************************************************************************************
 */
create table public.countries (
    country_code character varying(2) not null,
    country_name character varying(100) not null,
    "native" character varying(100) not null,
    video_count integer not null default 0,
    constraint countries_pkey primary key (country_code),
    constraint countries_video_count_check check ((video_count >= 0))
) TABLESPACE pg_default;

alter table public.countries enable row level security;

-- 모든 사용자가 SELECT 가능
create policy "countries are visible to everyone" on countries for select to authenticated, anon using (TRUE);
-- 모든 사용자가 INSERT 가능
create policy "Everyone can insert countries" on countries for insert to authenticated with check (TRUE);
-- 모든 사용자가 UPDATE 가능
create policy "Everyone can update countries" on countries for update to authenticated using (TRUE);
-- 모든 사용자가 DELETE 가능
create policy "Everyone can delete countries" on countries for delete to authenticated using (TRUE);


-- ##############################################################################################
-- Function: Increase video_count on countries (INSERT)
-- ##############################################################################################
CREATE OR REPLACE FUNCTION increase_countries_video_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  -- 함수 소유자(보통 관리자) 권한으로 실행
SET search_path = pg_catalog, public  -- 경로 고정으로 일관성 보장
AS $$
BEGIN
    IF NEW.country_code IS NOT NULL THEN
        UPDATE public.countries
        SET video_count = video_count + 1
        WHERE country_code = NEW.country_code;
    END IF;
    RETURN NEW;
END;
$$;


-- ##############################################################################################
-- Function: Decrease video_count on countries (DELETE)
-- ##############################################################################################
CREATE OR REPLACE FUNCTION decrease_countries_video_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  -- 함수 소유자(보통 관리자) 권한으로 실행
SET search_path = pg_catalog, public  -- 경로 고정으로 일관성 보장
AS $$
BEGIN
    IF OLD.country_code IS NOT NULL THEN
        UPDATE public.countries
        SET video_count = video_count - 1
        WHERE country_code = OLD.country_code
        AND video_count > 0;  -- 음수 방지
    END IF;
    RETURN OLD;
END;
$$;


-- ##############################################################################################
-- Function: Change video_count on countries (UPDATE)
-- ##############################################################################################
CREATE OR REPLACE FUNCTION change_countries_video_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  -- 함수 소유자(보통 관리자) 권한으로 실행
SET search_path = pg_catalog, public  -- 경로 고정으로 일관성 보장
AS $$
BEGIN
    IF OLD.country_code IS DISTINCT FROM NEW.country_code THEN
        IF OLD.country_code IS NOT NULL THEN
        UPDATE public.countries
        SET video_count = video_count - 1
        WHERE country_code = OLD.country_code
            AND video_count > 0;  -- 음수 방지
        END IF;

        IF NEW.country_code IS NOT NULL THEN
        UPDATE public.countries
        SET video_count = video_count + 1
        WHERE country_code = NEW.country_code;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;




/*
 ***********************************************************************************************
 * TABLE: map_country_languages
 ***********************************************************************************************
 */
create table public.map_country_languages (
    country_lang_code character varying(12) not null,
    country_code character varying(2) not null,
    lang_code character varying(8) not null,
    constraint map_country_languages_pkey primary key (country_lang_code),
    constraint map_country_languages_country_code_fkey foreign KEY (country_code) references countries (country_code) on update CASCADE on delete CASCADE,
    constraint map_country_languages_lang_code_fkey foreign KEY (lang_code) references languages (lang_code) on update CASCADE on delete CASCADE
) TABLESPACE pg_default;

alter table public.map_country_languages enable row level security;

-- 모든 사용자가 SELECT 가능
create policy "map_country_languages are visible to everyone" on map_country_languages for select to authenticated, anon using (TRUE);
-- 모든 사용자가 INSERT 가능
create policy "Everyone can insert map_country_languages" on map_country_languages for insert to authenticated with check (TRUE);
-- 모든 사용자가 UPDATE 가능
create policy "Everyone can update map_country_languages" on map_country_languages for update to authenticated using (TRUE);
-- 모든 사용자가 DELETE 가능
create policy "Everyone can delete map_country_languages" on map_country_languages for delete to authenticated using (TRUE);

