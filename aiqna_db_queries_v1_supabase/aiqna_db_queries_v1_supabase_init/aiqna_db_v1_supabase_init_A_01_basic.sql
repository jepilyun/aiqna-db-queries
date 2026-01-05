/*
 * aiqna db for web service (INIT)
 * Database Name 'aiqna'
 *
 * Created 2024-09-24
 * Updated 2025-11-30
 *
 * 보안 정책:
 * - anon: 최소 권한 원칙 적용, 필요한 함수만 개별 GRANT
 * - authenticated: 인증된 사용자용 기본 권한
 * - service_role: 서버 사이드 전체 권한
 */

-- ============================================================================
-- 1) 스키마 생성
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS gis;

-- ============================================================================
-- 2) 확장 설치
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS postgis;      -- 위치 정보 처리
CREATE EXTENSION IF NOT EXISTS pg_trgm;      -- 텍스트 유사도 검색
CREATE EXTENSION IF NOT EXISTS pgcrypto;     -- gen_random_uuid() 등 암호화 함수

-- ============================================================================
-- 3) PUBLIC 스키마 권한
-- ============================================================================

-- 스키마 접근 권한
GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;

-- authenticated: 함수 실행 권한
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated, service_role;

-- 앞으로 생성될 함수: authenticated, service_role만 기본 실행 권한
-- (anon은 개별 함수에 명시적으로 GRANT 필요)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT EXECUTE ON FUNCTIONS TO authenticated, service_role;

-- ============================================================================
-- 4) GIS 스키마 권한
-- ============================================================================

-- 스키마 접근 권한
GRANT USAGE ON SCHEMA gis TO authenticated, anon, service_role;

-- authenticated, service_role: 전체 권한
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA gis TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA gis 
  TO authenticated, service_role;

-- anon: GIS 테이블 직접 접근 불가 (함수 통해서만 접근)
-- 개별 위치 검색 함수에만 GRANT EXECUTE 부여할 것

-- 앞으로 생성될 객체 기본 권한 (authenticated, service_role만)
ALTER DEFAULT PRIVILEGES IN SCHEMA gis
  GRANT EXECUTE ON FUNCTIONS TO authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA gis
  GRANT USAGE ON TYPES TO authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA gis
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA gis
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated, service_role;

-- ============================================================================
-- 5) SEARCH PATH 설정
-- ============================================================================
ALTER ROLE anon          SET search_path = pg_catalog, public, extensions, gis;
ALTER ROLE authenticated SET search_path = pg_catalog, public, extensions, gis;
ALTER ROLE service_role  SET search_path = pg_catalog, public, extensions, gis;

-- ============================================================================
-- 6) anon 권한 부여 예시 (위치 검색 함수)
-- ============================================================================
-- 위치 검색 관련 함수 생성 후 개별적으로 권한 부여:
--
-- GRANT EXECUTE ON FUNCTION gis.search_nearby_places(geography, integer) TO anon;
-- GRANT EXECUTE ON FUNCTION public.get_city_locations(text) TO anon;
--
-- 패턴:
-- 1. SECURITY DEFINER로 함수 생성 (함수 소유자 권한으로 실행)
-- 2. 필요한 함수에만 anon GRANT EXECUTE 부여
-- 3. RLS 정책으로 추가 보안 적용



-- ============================================================================
-- Function: update_updated_at_column
-- ============================================================================
-- 설명: 레코드 수정 시 updated_at 컬럼을 현재 시간으로 자동 갱신
-- 용도: 각 테이블의 BEFORE UPDATE 트리거에서 호출
--
-- 사용 예시:
--   CREATE TRIGGER trg_users_updated_at
--     BEFORE UPDATE ON users
--     FOR EACH ROW
--     EXECUTE FUNCTION update_updated_at_column();
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column() 
RETURNS trigger 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END; 
$$;