/*
 * aiqna db for web service (COMPLETE CLEANUP)
 * Drop all objects in strict reverse dependency order
 *
 * Created 2025-09-05
 * Updated 2025-10-25
 */


-- =============================================================================================
-- 1. QNA_LOG
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
-- 2. TEMP_CONTENT_DATA
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_temp_content_data_by_city_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.get_temp_content_data_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_temp_content_name_to_code(VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_temp_content_names(VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_temp_content_data(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_temp_content_data_to_content_code(BIGINT, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_temp_content_data(VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_temp_content ON public.temp_content_data;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_temp_content_code() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_temp_content_data_updated_at ON public.temp_content_data;
DROP TABLE IF EXISTS public.temp_content_data CASCADE;





-- =============================================================================================
-- 3. TEMP_GOOGLE_PLACE_DATA
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_temp_google_place_data_by_city_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.get_temp_google_place_data_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_temp_google_place_name_to_id(VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_temp_google_place_names(VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_temp_google_place_data(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_temp_google_place_data_to_google_place_id(BIGINT, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_temp_google_place_data(VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_temp_google_place ON public.temp_google_place_data;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_temp_google_place_id() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_temp_google_place_data_updated_at ON public.temp_google_place_data;
DROP TABLE IF EXISTS public.temp_google_place_data CASCADE;






-- =============================================================================================
-- 4. TEMP_CATEGORY_DATA
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_temp_category_data_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_temp_category_name_to_code(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_temp_category_names(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_temp_category_data(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_temp_category_data_to_category_code(BIGINT, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_temp_category_data(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_temp_category ON public.temp_category_data;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_temp_category_code() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_temp_category_data_updated_at ON public.temp_category_data;
DROP TABLE IF EXISTS public.temp_category_data CASCADE;





-- =============================================================================================
-- 5. TEMP_INFLUENCER_DATA
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_temp_influencer_data_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_temp_influencer_name_to_id(VARCHAR, BIGINT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_temp_influencer_names(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_temp_influencer_data(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_temp_influencer_data_to_influencer_id(BIGINT, BIGINT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_temp_influencer_data(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_temp_influencer ON public.temp_influencer_data;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_temp_influencer_id() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_temp_influencer_data_updated_at ON public.temp_influencer_data;
DROP TABLE IF EXISTS public.temp_influencer_data CASCADE;




-- =============================================================================================
-- 6. TEMP_STAG_DATA
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_temp_stag_data_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_temp_stag_name_to_code(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_temp_stag_names(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_temp_stag_data(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_temp_stag_data_to_stag_code(BIGINT, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_temp_stag_data(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_stag ON public.temp_stag_data;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_temp_stag_code() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_temp_stag_data_updated_at ON public.temp_stag_data;
DROP TABLE IF EXISTS public.temp_stag_data CASCADE;



-- =============================================================================================
-- 7. TEMP_LANDMARK_DATA
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_temp_landmark_data_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_temp_landmark_name_to_id(VARCHAR, BIGINT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_temp_landmark_names(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_temp_landmark_data(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_temp_landmark_data_to_landmark_id(BIGINT, BIGINT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_temp_landmark_data(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_temp_landmark ON public.temp_landmark_data;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_temp_landmark_id() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_temp_landmark_data_updated_at ON public.temp_landmark_data;
DROP TABLE IF EXISTS public.temp_landmark_data CASCADE;



-- =============================================================================================
-- 8. TEMP_NEIGHBORHOOD_DATA
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_temp_neighborhood_data_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_temp_neighborhood_name_to_id(VARCHAR, BIGINT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_temp_neighborhood_names(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_temp_neighborhood_data(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_temp_neighborhood_data_to_neighborhood_id(BIGINT, BIGINT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_temp_neighborhood_data(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed_temp_neighborhood ON public.temp_neighborhood_data;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_temp_neighborhood_id() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_temp_neighborhood_data_updated_at ON public.temp_neighborhood_data;
DROP TABLE IF EXISTS public.temp_neighborhood_data CASCADE;



-- =============================================================================================
-- 9. TEMP_DISTRICT_DATA
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_temp_district_data_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_temp_district_name_to_code(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_temp_district_names(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_temp_district_data(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_temp_district_data_to_district_code(BIGINT, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_temp_district_data(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed ON public.temp_district_data;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_temp_district_code() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_temp_district_data_updated_at ON public.temp_district_data;
DROP TABLE IF EXISTS public.temp_district_data CASCADE;



-- =============================================================================================
-- 10. TEMP_CITY_DATA
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_temp_city_data_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_temp_city_name_to_code(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_temp_city_names(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_temp_city_data(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_temp_city_data_to_city_code(BIGINT, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_temp_city_data(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed ON public.temp_city_data;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_temp_city_code() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_temp_city_data_updated_at ON public.temp_city_data;
DROP TABLE IF EXISTS public.temp_city_data CASCADE;



-- =============================================================================================
-- 11. TEMP_COUNTRY_DATA
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_temp_country_data_statistics() CASCADE;
DROP FUNCTION IF EXISTS public.batch_map_country_name_to_code(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.search_similar_country_names(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_unprocessed_temp_country_data(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.map_temp_country_data_to_country_code(BIGINT, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.add_temp_country_data(VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_auto_mark_processed ON public.temp_country_data;
DROP FUNCTION IF EXISTS public.auto_mark_processed_on_country_code() CASCADE;
DROP TRIGGER IF EXISTS trigger_update_temp_country_data_updated_at ON public.temp_country_data;
DROP TABLE IF EXISTS public.temp_country_data CASCADE;




-- =============================================================================================
-- 12. TAGS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_related_tags(VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.search_tags(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_popular_tags(VARCHAR, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_content_for_tag(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_tags_for_content(VARCHAR, VARCHAR, NUMERIC) CASCADE;
DROP TRIGGER IF EXISTS trigger_decrease_tag_content_count ON public.map_tag;
DROP FUNCTION IF EXISTS public.decrease_tag_content_count() CASCADE;
DROP TRIGGER IF EXISTS trigger_increase_tag_content_count ON public.map_tag;
DROP FUNCTION IF EXISTS public.increase_tag_content_count() CASCADE;
DROP FUNCTION IF EXISTS public.upsert_tag_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.get_or_create_tag(VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_tag_updated_at ON public.map_tag;
DROP TABLE IF EXISTS public.map_tag CASCADE;
DROP TRIGGER IF EXISTS trigger_update_tags_updated_at ON public.tags;
DROP TABLE IF EXISTS public.tags CASCADE;



-- =============================================================================================
-- 13. CONTENTS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_contents_by_location(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_sources_for_content(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_contents_for_source(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_content_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_contents_updated_at ON public.map_contents;
DROP TABLE IF EXISTS public.map_contents CASCADE;
DROP TRIGGER IF EXISTS trigger_update_contents_i18n_updated_at ON public.contents_i18n;
DROP TABLE IF EXISTS public.contents_i18n CASCADE;
DROP TRIGGER IF EXISTS trigger_update_contents_updated_at ON public.contents;
DROP TABLE IF EXISTS public.contents CASCADE;



-- =============================================================================================
-- 14. GOOGLE_PLACES
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
-- 15. CATEGORIES
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_content_for_category(VARCHAR, VARCHAR, BOOLEAN, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_categories_for_content(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_category_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_category_updated_at ON public.map_category;
DROP TABLE IF EXISTS public.map_category CASCADE;
DROP TABLE IF EXISTS public.map_category_search_keywords CASCADE;
DROP TRIGGER IF EXISTS trigger_update_category_i18n_updated_at ON public.category_i18n;
DROP TABLE IF EXISTS public.category_i18n CASCADE;
DROP FUNCTION IF EXISTS public.get_category_path(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.get_category_tree(TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_sub_categories(TEXT, BOOLEAN, BOOLEAN, INTEGER) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_categories_updated_at ON public.categories;
DROP TABLE IF EXISTS public.categories CASCADE;




-- =============================================================================================
-- 16. INFLUENCERS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_influencers_by_city(VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_content_for_influencer(BIGINT, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_influencers_for_content(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_influencer_mapping(BIGINT, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_influencer_updated_at ON public.map_influencer;
DROP TABLE IF EXISTS public.map_influencer CASCADE;
DROP TABLE IF EXISTS public.map_influencer_search_keywords CASCADE;
DROP TRIGGER IF EXISTS trigger_update_influencer_i18n_updated_at ON public.influencer_i18n;
DROP TABLE IF EXISTS public.influencer_i18n CASCADE;
DROP TRIGGER IF EXISTS trigger_update_influencers_updated_at ON public.influencers;
DROP TABLE IF EXISTS public.influencers CASCADE;




-- =============================================================================================
-- 17. STAGS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_related_stags(VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_popular_stags(VARCHAR, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_content_for_stag(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_stags_for_content(VARCHAR, VARCHAR, NUMERIC) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_stag_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_stag_updated_at ON public.map_stag;
DROP TABLE IF EXISTS public.map_stag CASCADE;
DROP TABLE IF EXISTS public.map_stag_search_keywords CASCADE;
DROP TRIGGER IF EXISTS trigger_update_stag_i18n_updated_at ON public.stag_i18n;
DROP TABLE IF EXISTS public.stag_i18n CASCADE;
DROP TRIGGER IF EXISTS trigger_update_stags_updated_at ON public.stags;
DROP TABLE IF EXISTS public.stags CASCADE;




-- =============================================================================================
-- 18. LANDMARKS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_landmarks_by_city(VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_content_for_landmark(BIGINT, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_landmarks_for_content(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_landmark_mapping(BIGINT, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_landmark_updated_at ON public.map_landmark;
DROP TABLE IF EXISTS public.map_landmark CASCADE;
DROP TABLE IF EXISTS public.map_landmark_search_keywords CASCADE;
DROP TRIGGER IF EXISTS trigger_update_landmark_i18n_updated_at ON public.landmark_i18n;
DROP TABLE IF EXISTS public.landmark_i18n CASCADE;
DROP TRIGGER IF EXISTS trigger_update_landmarks_updated_at ON public.landmarks;
DROP TABLE IF EXISTS public.landmarks CASCADE;




-- =============================================================================================
-- 19. NEIGHBORHOODS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_neighborhoods_by_city(VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_content_for_neighborhood(BIGINT, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_neighborhoods_for_content(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_neighborhood_mapping(BIGINT, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_neighborhood_updated_at ON public.map_neighborhood;
DROP TABLE IF EXISTS public.map_neighborhood CASCADE;
DROP TABLE IF EXISTS public.map_neighborhood_search_keywords CASCADE;
DROP TRIGGER IF EXISTS trigger_update_neighborhood_i18n_updated_at ON public.neighborhood_i18n;
DROP TABLE IF EXISTS public.neighborhood_i18n CASCADE;
DROP TRIGGER IF EXISTS trigger_update_neighborhoods_updated_at ON public.neighborhoods;
DROP TABLE IF EXISTS public.neighborhoods CASCADE;



-- =============================================================================================
-- 20. DISTRICTS
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_districts_by_city(VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_content_for_district(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_districts_for_content(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_district_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_district_updated_at ON public.map_district;
DROP TABLE IF EXISTS public.map_district CASCADE;
DROP TABLE IF EXISTS public.map_district_search_keywords CASCADE;
DROP TRIGGER IF EXISTS trigger_update_district_i18n_updated_at ON public.district_i18n;
DROP TABLE IF EXISTS public.district_i18n CASCADE;
DROP TRIGGER IF EXISTS trigger_update_districts_updated_at ON public.districts;
DROP TABLE IF EXISTS public.districts CASCADE;


-- =============================================================================================
-- 21. CITIES
-- =============================================================================================
DROP FUNCTION IF EXISTS public.get_content_for_city(VARCHAR, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_cities_for_content(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS public.upsert_city_mapping(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_map_city_updated_at ON public.map_city;
DROP TABLE IF EXISTS public.map_city CASCADE;
DROP TABLE IF EXISTS public.map_city_search_keywords CASCADE;
DROP TRIGGER IF EXISTS trigger_update_city_i18n_updated_at ON public.city_i18n;
DROP TABLE IF EXISTS public.city_i18n CASCADE;
DROP FUNCTION IF EXISTS public.get_city_name(VARCHAR) CASCADE;
DROP TRIGGER IF EXISTS trigger_update_cities_updated_at ON public.cities;
DROP TABLE IF EXISTS public.cities CASCADE;


-- =============================================================================================
-- 22. PINECONE_VECTORS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_pinecone_vectors_updated_at ON public.pinecone_vectors;
DROP TABLE IF EXISTS public.pinecone_vectors CASCADE;


-- =============================================================================================
-- 23. TEXTS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_texts_updated_at ON public.texts;
DROP TABLE IF EXISTS public.texts CASCADE;
DROP TRIGGER IF EXISTS trigger_update_text_processing_logs_updated_at ON public.text_processing_logs;
DROP TABLE IF EXISTS public.text_processing_logs CASCADE;


-- =============================================================================================
-- 24. BLOG_POSTS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_blog_posts_updated_at ON public.blog_posts;
DROP TABLE IF EXISTS public.blog_posts CASCADE;
DROP TRIGGER IF EXISTS trigger_update_blog_post_processing_logs_updated_at ON public.blog_post_processing_logs;
DROP TABLE IF EXISTS public.blog_post_processing_logs CASCADE;


-- =============================================================================================
-- 25. INSTAGRAM_POSTS
-- =============================================================================================
DROP TRIGGER IF EXISTS trigger_update_instagram_posts_updated_at ON public.instagram_posts;
DROP TABLE IF EXISTS public.instagram_posts CASCADE;
DROP TRIGGER IF EXISTS trigger_update_instagram_post_processing_logs_updated_at ON public.instagram_post_processing_logs;
DROP TABLE IF EXISTS public.instagram_post_processing_logs CASCADE;


-- =============================================================================================
-- 26. YOUTUBE_VIDEOS
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
-- 27. COUNTRIES & LANGUAGES
-- =============================================================================================

DROP FUNCTION IF EXISTS public.change_countries_video_count() CASCADE;
DROP FUNCTION IF EXISTS public.decrease_countries_video_count() CASCADE;
DROP FUNCTION IF EXISTS public.increase_countries_video_count() CASCADE;
DROP TABLE IF EXISTS public.map_country_languages CASCADE;
DROP TABLE IF EXISTS public.search_map_country_by_keyword CASCADE;
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
