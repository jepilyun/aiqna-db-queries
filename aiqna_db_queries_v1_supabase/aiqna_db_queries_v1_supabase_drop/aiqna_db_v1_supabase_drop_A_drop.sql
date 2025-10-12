/*
 * aiqna db for web service (COMPLETE CLEANUP)
 * Drop all objects in strict reverse dependency order
 *
 * Created 2025-09-05
 * Updated 2025-10-12
 */

-- =============================================================================================
-- 1. QNA_LOG
-- =============================================================================================
DROP FUNCTION IF EXISTS public.find_similar_questions(TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.analyze_ai_performance(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_popular_questions(VARCHAR, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.update_qna_feedback(UUID, VARCHAR, INTEGER, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.log_qna(TEXT, TEXT, VARCHAR, VARCHAR, VARCHAR, INTEGER, VARCHAR, VARCHAR, JSONB) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_qna_log_updated_at ON public.qna_log;
DROP TABLE IF EXISTS public.qna_log CASCADE;


-- =============================================================================================
-- 2. TAGS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_related_tags(VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.search_tags(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_popular_tags(VARCHAR, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_content_for_tag(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_tags_for_content(VARCHAR, VARCHAR, NUMERIC) CASCADE;
DROP FUNCTION IF EXISTS public.decrease_tag_content_count() CASCADE;
DROP FUNCTION IF EXISTS public.increase_tag_content_count() CASCADE;
DROP FUNCTION IF EXISTS public.upsert_tag_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.get_or_create_tag(VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_decrease_tag_content_count ON public.map_tag;
DROP TRIGGER IF EXISTS trigger_increase_tag_content_count ON public.map_tag;
DROP TRIGGER IF EXISTS trigger_update_map_tag_updated_at ON public.map_tag;
DROP TABLE IF EXISTS public.map_tag CASCADE;
DROP TRIGGER IF EXISTS trigger_update_tags_updated_at ON public.tags;
DROP TABLE IF EXISTS public.tags CASCADE;


-- =============================================================================================
-- 3. STAGS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_related_stags(VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_popular_stags(VARCHAR, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_content_for_stag(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_stags_for_content(VARCHAR, VARCHAR, NUMERIC) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_stag_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_stag_updated_at ON public.map_stag;
DROP TABLE IF EXISTS public.map_stag CASCADE;
DROP TRIGGER IF EXISTS trigger_update_stag_i18n_updated_at ON public.stag_i18n;
DROP TABLE IF EXISTS public.stag_i18n CASCADE;
DROP TRIGGER IF EXISTS trigger_update_stags_updated_at ON public.stags;
DROP TABLE IF EXISTS public.stags CASCADE;


-- =============================================================================================
-- 4. CATEGORIES
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_content_for_category(VARCHAR, VARCHAR, BOOLEAN, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_categories_for_content(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_category_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_category_updated_at ON public.map_category;
DROP TABLE IF EXISTS public.map_category CASCADE;
DROP TRIGGER IF EXISTS trigger_update_category_i18n_updated_at ON public.category_i18n;
DROP TABLE IF EXISTS public.category_i18n CASCADE;
DROP FUNCTION IF EXISTS public.get_category_path(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.get_category_tree(TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_sub_categories(TEXT, BOOLEAN, BOOLEAN, INTEGER) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_categories_updated_at ON public.categories;
DROP TABLE IF EXISTS public.categories CASCADE;


-- =============================================================================================
-- 5. GOOGLE_PLACES
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_google_places_by_location(VARCHAR, VARCHAR, VARCHAR, REAL) CASCADE;
DROP FUNCTION IF EXISTS public.get_content_for_google_place(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_google_places_for_content(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_google_place_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_google_place_updated_at ON public.map_google_place;
DROP TABLE IF EXISTS public.map_google_place CASCADE;
DROP TRIGGER IF EXISTS trigger_update_google_places_updated_at ON public.google_places;
DROP TABLE IF EXISTS public.google_places CASCADE;


-- =============================================================================================
-- 6. STREETS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_streets_by_city(VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_content_for_street(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_streets_for_content(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_street_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_street_updated_at ON public.map_street;
DROP TABLE IF EXISTS public.map_street CASCADE;
DROP TRIGGER IF EXISTS trigger_update_street_i18n_updated_at ON public.street_i18n;
DROP TABLE IF EXISTS public.street_i18n CASCADE;
DROP TRIGGER IF EXISTS trigger_update_streets_updated_at ON public.streets;
DROP TABLE IF EXISTS public.streets CASCADE;


-- =============================================================================================
-- 7. CITIES
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_content_for_city(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_cities_for_content(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_city_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_city_updated_at ON public.map_city;
DROP TABLE IF EXISTS public.map_city CASCADE;
DROP TRIGGER IF EXISTS trigger_update_city_i18n_updated_at ON public.city_i18n;
DROP TABLE IF EXISTS public.city_i18n CASCADE;
DROP FUNCTION IF EXISTS public.get_city_name(VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_cities_updated_at ON public.cities;
DROP TABLE IF EXISTS public.cities CASCADE;


-- =============================================================================================
-- 8. PINECONE_VECTORS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_pinecone_vectors_updated_at ON public.pinecone_vectors;
DROP TABLE IF EXISTS public.pinecone_vectors CASCADE;


-- =============================================================================================
-- 9. TEXTS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_texts_updated_at ON public.texts;
DROP TABLE IF EXISTS public.texts CASCADE;
DROP TRIGGER IF EXISTS trigger_update_text_processing_logs_updated_at ON public.text_processing_logs;
DROP TABLE IF EXISTS public.text_processing_logs CASCADE;


-- =============================================================================================
-- 10. BLOG_POSTS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_blog_posts_updated_at ON public.blog_posts;
DROP TABLE IF EXISTS public.blog_posts CASCADE;
DROP TRIGGER IF EXISTS trigger_update_blog_post_processing_logs_updated_at ON public.blog_post_processing_logs;
DROP TABLE IF EXISTS public.blog_post_processing_logs CASCADE;


-- =============================================================================================
-- 11. INSTAGRAM_POSTS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_instagram_posts_updated_at ON public.instagram_posts;
DROP TABLE IF EXISTS public.instagram_posts CASCADE;
DROP TRIGGER IF EXISTS trigger_update_instagram_post_processing_logs_updated_at ON public.instagram_post_processing_logs;
DROP TABLE IF EXISTS public.instagram_post_processing_logs CASCADE;


-- =============================================================================================
-- 12. YOUTUBE_VIDEOS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.update_youtube_video_transcript_status() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_youtube_video_transcript_status ON public.youtube_video_transcripts;
DROP TRIGGER IF EXISTS trigger_update_youtube_video_transcripts_updated_at ON public.youtube_video_transcripts;
DROP TABLE IF EXISTS public.youtube_video_transcripts CASCADE;
DROP FUNCTION IF EXISTS public.upsert_youtube_video_api_data(JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.iso8601_duration_to_seconds(TEXT) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_youtube_videos_updated_at ON public.youtube_videos;
DROP TABLE IF EXISTS public.youtube_videos CASCADE;
DROP TRIGGER IF EXISTS trigger_update_youtube_video_processing_logs_updated_at ON public.youtube_video_processing_logs;
DROP TABLE IF EXISTS public.youtube_video_processing_logs CASCADE;


-- =============================================================================================
-- 13. COUNTRIES & LANGUAGES
-- =============================================================================================
DROP TABLE IF EXISTS public.map_country_languages CASCADE;
DROP FUNCTION IF EXISTS public.change_countries_video_count() CASCADE;
DROP FUNCTION IF EXISTS public.decrease_countries_video_count() CASCADE;
DROP FUNCTION IF EXISTS public.increase_countries_video_count() CASCADE;
DROP TABLE IF EXISTS public.countries CASCADE;
DROP FUNCTION IF EXISTS public.change_languages_user_count() CASCADE;
DROP FUNCTION IF EXISTS public.decrease_languages_user_count() CASCADE;
DROP FUNCTION IF EXISTS public.increase_languages_user_count() CASCADE;
DROP TABLE IF EXISTS public.languages CASCADE;


-- =============================================================================================
-- 14. COMMON FUNCTIONS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;


-- =============================================================================================
-- 15. EXTENSIONS
-- =============================================================================================
-- PostGIS가 다른 확장보다 먼저 삭제되어야 함
DROP EXTENSION IF EXISTS postgis CASCADE;
DROP EXTENSION IF EXISTS pg_trgm CASCADE;
DROP EXTENSION IF EXISTS pgcrypto CASCADE;
DROP EXTENSION IF EXISTS pg_cron CASCADE;  -- 추가된 확장


-- =============================================================================================
-- 16. SCHEMAS (선택적)
-- =============================================================================================
-- gis 스키마 삭제 (필요한 경우)
-- DROP SCHEMA IF EXISTS gis CASCADE;


-- =============================================================================================
-- 17. 확인 쿼리 (실행 후 검증용)
-- =============================================================================================
-- 남아있는 테이블 확인
-- SELECT schemaname, tablename 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
-- ORDER BY tablename;

-- 남아있는 함수 확인
-- SELECT n.nspname AS schema, p.proname AS function
-- FROM pg_proc p
-- JOIN pg_namespace n ON p.pronamespace = n.oid
-- WHERE n.nspname = 'public'
-- ORDER BY p.proname;

-- 남아있는 트리거 확인
-- SELECT trigger_schema, trigger_name, event_object_table
-- FROM information_schema.triggers
-- WHERE trigger_schema = 'public'
-- ORDER BY event_object_table, trigger_name;