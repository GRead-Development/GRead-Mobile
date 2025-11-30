-- GRead - Populate Book Cover URLs from ISBN
--
-- This SQL script updates the books table with cover URLs from Open Library
--
-- IMPORTANT:
-- 1. Adjust the table name (wp_books or your actual table name)
-- 2. Adjust column names based on your database schema
-- 3. This generates URLs but doesn't verify they exist - you may want to
--    use the PHP script instead for validation
--
-- Usage:
--   mysql -u your_username -p your_database < populate_cover_urls.sql

-- Backup your table first!
-- CREATE TABLE wp_books_backup AS SELECT * FROM wp_books;

-- Update books with ISBN to have Open Library cover URLs
-- Replace 'wp_books' with your actual table name
UPDATE wp_books
SET cover_url = CONCAT(
    'https://covers.openlibrary.org/b/isbn/',
    REPLACE(isbn, '-', ''),
    '-M.jpg'
)
WHERE isbn IS NOT NULL
  AND isbn != ''
  AND (cover_url IS NULL OR cover_url = '');

-- Check the results
SELECT
    id,
    title,
    isbn,
    cover_url
FROM wp_books
WHERE cover_url LIKE '%openlibrary.org%'
LIMIT 10;

-- Get summary statistics
SELECT
    COUNT(*) as total_books,
    SUM(CASE WHEN cover_url IS NOT NULL AND cover_url != '' THEN 1 ELSE 0 END) as books_with_covers,
    SUM(CASE WHEN cover_url IS NULL OR cover_url = '' THEN 1 ELSE 0 END) as books_without_covers,
    SUM(CASE WHEN isbn IS NULL OR isbn = '' THEN 1 ELSE 0 END) as books_without_isbn
FROM wp_books;
