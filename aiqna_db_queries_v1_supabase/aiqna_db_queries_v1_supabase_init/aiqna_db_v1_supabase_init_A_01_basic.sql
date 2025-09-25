/*
 * aiqna db for web service (INIT)
 * Database Name 'aiqna'
 *
 * Created 2025-09-24
 * Updated 2025-09-24
 */

-- 1) 별도 스키마
CREATE SCHEMA IF NOT EXISTS gis;

-- 2) 확장 설치(대부분 이미 설치됨; 재실행 안전)
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- gen_random_uuid() 사용하려면 필요

-- 3) 권한: public(포스트GIS가 위치) + gis(내가 만드는 것)
-- PostGIS가 있는 public 스키마도 같이 열어두기
GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated, service_role;

-- gis 스키마 자체 접근
GRANT USAGE ON SCHEMA gis TO authenticated, anon, service_role;
-- (옵션) 현재 gis에 있는 함수들 실행권한 (지금은 없더라도 무해)
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA gis TO authenticated, anon, service_role;

-- 앞으로 gis에 생성될 객체 기본권한
ALTER DEFAULT PRIVILEGES IN SCHEMA gis
  GRANT EXECUTE ON FUNCTIONS TO authenticated, anon, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA gis
  GRANT USAGE ON TYPES TO authenticated, anon, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA gis
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated, anon, service_role;

-- 4) (권장) 기본 search_path에 extensions 포함
ALTER ROLE anon          SET search_path = pg_catalog, public, extensions, gis;
ALTER ROLE authenticated SET search_path = pg_catalog, public, extensions, gis;
ALTER ROLE service_role  SET search_path = pg_catalog, public, extensions, gis;




-- ##############################################################################################
-- Function: update_updated_at_column
-- ##############################################################################################
CREATE OR REPLACE FUNCTION update_updated_at_column() 
RETURNS trigger 
LANGUAGE plpgsql
SECURITY DEFINER  -- 함수 소유자(보통 관리자) 권한으로 실행
SET search_path = pg_catalog, public  -- 경로 고정으로 일관성 보장
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END; 
$$;

