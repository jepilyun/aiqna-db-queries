/*
 * aiqna db for web service (COMPLETE CLEANUP)
 * Drop all objects in strict reverse dependency order
 *
 * Created 2025-09-05
 * Updated 2025-10-13
 */

-- =============================================================================================
-- 1. META_STAGS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_meta_stags_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_stag_name_to_code(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_stag_names(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_meta_stags(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_meta_stag_to_stag_code(UUID, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_meta_stag(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_stag_code() CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_stag ON public.meta_stags;
DROP TRIGGER IF EXISTS trigger_update_meta_stags_updated_at ON public.meta_stags;
DROP TABLE IF EXISTS public.meta_stags CASCADE;


-- =============================================================================================
-- 2. META_CATEGORIES
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_meta_categories_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_category_name_to_code(VARCHAR, TEXT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_category_names(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_meta_categories(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_meta_category_to_category_code(UUID, TEXT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_meta_category(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_category_code() CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_category ON public.meta_categories;
DROP TRIGGER IF EXISTS trigger_update_meta_categories_updated_at ON public.meta_categories;
DROP TABLE IF EXISTS public.meta_categories CASCADE;


-- =============================================================================================
-- 3. META_CONTENTS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_contents_by_city_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.get_meta_contents_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_content_name_to_code(VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_content_names(VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_meta_contents(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_meta_content_to_content_code(UUID, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_meta_content(VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_content_code() CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_content ON public.meta_contents;
DROP TRIGGER IF EXISTS trigger_update_meta_contents_updated_at ON public.meta_contents;
DROP TABLE IF EXISTS public.meta_contents CASCADE;


-- =============================================================================================
-- 4. META_GOOGLE_PLACES
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_google_places_by_city_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.get_meta_google_places_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_google_place_name_to_id(VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_google_place_names(VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_meta_google_places(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_meta_google_place_to_google_place_id(UUID, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_meta_google_place(VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_google_place_id() CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_google_place ON public.meta_google_places;
DROP TRIGGER IF EXISTS trigger_update_meta_google_places_updated_at ON public.meta_google_places;
DROP TABLE IF EXISTS public.meta_google_places CASCADE;


-- =============================================================================================
-- 5. META_STREETS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_streets_by_city_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.get_meta_streets_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_street_name_to_code(VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_street_names(VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_meta_streets(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_meta_street_to_street_code(UUID, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_meta_street(VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_street_code() CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_street ON public.meta_streets;
DROP TRIGGER IF EXISTS trigger_update_meta_streets_updated_at ON public.meta_streets;
DROP TABLE IF EXISTS public.meta_streets CASCADE;


-- =============================================================================================
-- 6. META_CITIES
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_meta_cities_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_city_name_to_code(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_city_names(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_meta_cities(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_meta_city_to_city_code(UUID, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_meta_city(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_city_code() CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed ON public.meta_cities;
DROP TRIGGER IF EXISTS trigger_update_meta_cities_updated_at ON public.meta_cities;
DROP TABLE IF EXISTS public.meta_cities CASCADE;


-- =============================================================================================
-- 7. QNA_LOG
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_language_statistics(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.find_similar_questions(TEXT, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.analyze_ai_performance(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_popular_questions(VARCHAR, VARCHAR, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.update_qna_feedback(UUID, VARCHAR, INTEGER, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.log_qna(TEXT, TEXT, VARCHAR, TEXT, TEXT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, INTEGER, INTEGER, VARCHAR, VARCHAR, JSONB) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_qna_log_updated_at ON public.qna_log;
DROP TABLE IF EXISTS public.qna_log CASCADE;


-- =============================================================================================
-- 8. MAP_CONTENTS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_contents_by_location(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_sources_for_content(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_contents_for_source(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_content_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_contents_updated_at ON public.map_contents;
DROP TABLE IF EXISTS public.map_contents CASCADE;


-- =============================================================================================
-- 9. CONTENTS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_contents_i18n_updated_at ON public.contents_i18n;
DROP TABLE IF EXISTS public.contents_i18n CASCADE;
DROP TRIGGER IF EXISTS trigger_update_contents_updated_at ON public.contents;
DROP TABLE IF EXISTS public.contents CASCADE;


-- =============================================================================================
-- 10. TAGS
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
-- 11. STAGS
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
-- 12. CATEGORIES
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
-- 13. GOOGLE_PLACES
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
-- 14. STREETS
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
-- 15. CITIES
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
-- 16. PINECONE_VECTORS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_pinecone_vectors_updated_at ON public.pinecone_vectors;
DROP TABLE IF EXISTS public.pinecone_vectors CASCADE;


-- =============================================================================================
-- 17. TEXTS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_texts_updated_at ON public.texts;
DROP TABLE IF EXISTS public.texts CASCADE;
DROP TRIGGER IF EXISTS trigger_update_text_processing_logs_updated_at ON public.text_processing_logs;
DROP TABLE IF EXISTS public.text_processing_logs CASCADE;


-- =============================================================================================
-- 18. BLOG_POSTS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_blog_posts_updated_at ON public.blog_posts;
DROP TABLE IF EXISTS public.blog_posts CASCADE;
DROP TRIGGER IF EXISTS trigger_update_blog_post_processing_logs_updated_at ON public.blog_post_processing_logs;
DROP TABLE IF EXISTS public.blog_post_processing_logs CASCADE;


-- =============================================================================================
-- 19. INSTAGRAM_POSTS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_instagram_posts_updated_at ON public.instagram_posts;
DROP TABLE IF EXISTS public.instagram_posts CASCADE;
DROP TRIGGER IF EXISTS trigger_update_instagram_post_processing_logs_updated_at ON public.instagram_post_processing_logs;
DROP TABLE IF EXISTS public.instagram_post_processing_logs CASCADE;


-- =============================================================================================
-- 20. YOUTUBE_VIDEOS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.update_youtube_video_transcript_status() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_youtube_video_transcript_status ON public.youtube_video_transcripts;
DROP TRIGGER IF EXISTS trigger_update_youtube_video_transcripts_updated_at ON public.youtube_video_transcripts;
DROP TABLE IF EXISTS public.youtube_video_transcripts CASCADE;
DROP FUNCTION IF EXISTS public.upsert_youtube_video_api_data(JSONB, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.iso8601_duration_to_seconds(TEXT) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_youtube_videos_updated_at ON public.youtube_videos;
DROP TABLE IF EXISTS public.youtube_videos CASCADE;
DROP TRIGGER IF EXISTS trigger_update_youtube_video_processing_logs_updated_at ON public.youtube_video_processing_logs;
DROP TABLE IF EXISTS public.youtube_video_processing_logs CASCADE;


-- =============================================================================================
-- 21. COUNTRIES & LANGUAGES
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
-- 22. COMMON FUNCTIONS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;


-- =============================================================================================
-- 23. EXTENSIONS
-- =============================================================================================
-- PostGIS가 다른 확장보다 먼저 삭제되어야 함
DROP EXTENSION IF EXISTS postgis CASCADE;
DROP EXTENSION IF EXISTS pg_trgm CASCADE;
DROP EXTENSION IF EXISTS pgcrypto CASCADE;
DROP EXTENSION IF EXISTS pg_cron CASCADE;


-- =============================================================================================
-- VERIFICATION QUERY
-- =============================================================================================
-- 모든 객체가 삭제되었는지 확인
SELECT 
    'FUNCTION' AS object_type,
    routine_schema || '.' || routine_name AS object_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND (routine_name LIKE '%meta_%'
    OR routine_name LIKE '%qna_log%'
    OR routine_name LIKE '%content%'
    OR routine_name LIKE '%tag%'
    OR routine_name LIKE '%stag%'
    OR routine_name LIKE '%category%'
    OR routine_name LIKE '%google_place%'
    OR routine_name LIKE '%street%'
    OR routine_name LIKE '%city%')

UNION ALL

SELECT 
    'TABLE' AS object_type,
    table_schema || '.' || table_name AS object_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%meta_%'
    OR table_name IN ('qna_log', 'contents', 'map_contents', 
                    'tags', 'map_tag', 'stags', 'map_stag', 'stag_i18n',
                    'categories', 'map_category', 'category_i18n',
                    'google_places', 'map_google_place',
                    'streets', 'map_street', 'street_i18n',
                    'cities', 'map_city', 'city_i18n'))

UNION ALL

SELECT 
    'TRIGGER' AS object_type,
    trigger_schema || '.' || trigger_name AS object_name
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND (trigger_name LIKE '%meta_%'
    OR trigger_name LIKE '%qna_log%'
    OR trigger_name LIKE '%content%'
    OR trigger_name LIKE '%tag%'
    OR trigger_name LIKE '%category%')

ORDER BY object_type, object_name;