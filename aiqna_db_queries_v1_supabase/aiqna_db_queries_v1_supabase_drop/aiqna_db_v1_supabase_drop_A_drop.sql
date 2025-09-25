/*
 * dplus db for web service (RESET)
 * Drop all objects in strict reverse dependency (reverse of create)
 *
 * Created 2025-09-05
 */

DROP TABLE IF EXISTS public.pinecone_processing_logs;

DROP TABLE IF EXISTS public.youtube_video_transcripts;
DROP FUNCTION IF EXISTS update_youtube_video_transcript_status();

DROP FUNCTION IF EXISTS update_pinecone_status();
DROP FUNCTION IF EXISTS upsert_youtube_video_api_data(jsonb);
DROP FUNCTION IF EXISTS iso8601_duration_to_seconds(text);
DROP TABLE IF EXISTS public.youtube_videos;
DROP TABLE IF EXISTS public.youtube_video_processing_logs;




DROP TABLE IF EXISTS public.map_country_languages;
DROP FUNCTION IF EXISTS change_countries_video_count();
DROP FUNCTION IF EXISTS decrease_countries_video_count();
DROP FUNCTION IF EXISTS increase_countries_video_count();
DROP TABLE IF EXISTS public.countries;
DROP FUNCTION IF EXISTS change_languages_user_count();
DROP FUNCTION IF EXISTS decrease_languages_user_count();
DROP FUNCTION IF EXISTS increase_languages_user_count();
DROP TABLE IF EXISTS public.languages;



DROP FUNCTION IF EXISTS update_updated_at_column();


-- 관련 확장부터 순서대로 제거 (있을 때만)
DROP EXTENSION IF EXISTS pgcrypto CASCADE;
DROP EXTENSION IF EXISTS pg_trgm CASCADE;
DROP EXTENSION IF EXISTS postgis CASCADE;
