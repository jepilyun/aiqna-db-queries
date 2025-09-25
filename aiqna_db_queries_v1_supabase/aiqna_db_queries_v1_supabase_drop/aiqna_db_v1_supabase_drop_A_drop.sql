/*
 * dplus db for web service (RESET)
 * Drop all objects in strict reverse dependency (reverse of create)
 *
 * Created 2025-09-05
 */



DROP TABLE IF EXISTS public.map_country_languages;
DROP FUNCTION IF EXISTS update_countries_user_count();
DROP FUNCTION IF EXISTS decrease_countries_user_count();
DROP FUNCTION IF EXISTS increase_countries_user_count();
DROP FUNCTION IF EXISTS update_countries_event_count();
DROP FUNCTION IF EXISTS decrease_countries_event_count();
DROP FUNCTION IF EXISTS increase_countries_event_count();
DROP TABLE IF EXISTS public.countries;
DROP TABLE IF EXISTS public.languages;




DROP FUNCTION IF EXISTS update_updated_at_column();

-- 관련 확장부터 순서대로 제거 (있을 때만)
DROP EXTENSION IF EXISTS postgis_topology CASCADE;
DROP EXTENSION IF EXISTS postgis_raster   CASCADE;
DROP EXTENSION IF EXISTS postgis          CASCADE;