-- ============================================
-- Czyści i tworzy schemę analytics od zera
-- ============================================

DROP SCHEMA IF EXISTS analytics CASCADE;
CREATE SCHEMA analytics;

SET search_path TO clean, analytics, public;