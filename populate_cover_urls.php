<?php
/**
 * GRead - Populate Book Cover URLs from Open Library
 *
 * This script updates the books table with cover URLs from Open Library
 * based on ISBN numbers.
 *
 * IMPORTANT: Run this on your WordPress server where GRead is installed
 *
 * Usage:
 *   1. Upload this file to your WordPress root directory
 *   2. Run via command line: php populate_cover_urls.php
 *   OR
 *   2. Access via browser: https://gread.fun/populate_cover_urls.php
 *      (Make sure to delete the file after running!)
 */

// Load WordPress
require_once(__DIR__ . '/wp-load.php');

// Only allow admin access if running via web
if (!defined('WP_CLI') && !is_super_admin()) {
    die('Unauthorized access');
}

global $wpdb;

// Get the books table name (adjust based on your setup)
// Assuming you have a custom books table or using a custom post type
// You'll need to adjust this based on your actual database structure

echo "Starting cover URL population...\n\n";

// Example 1: If books are stored as a custom post type
$args = array(
    'post_type' => 'book', // Adjust based on your setup
    'posts_per_page' => -1,
    'post_status' => 'publish'
);

$books = get_posts($args);
$updated_count = 0;
$skipped_count = 0;

foreach ($books as $book) {
    $book_id = $book->ID;
    $title = get_the_title($book_id);

    // Get ISBN from meta field (adjust meta key based on your setup)
    $isbn = get_post_meta($book_id, 'isbn', true);

    // Check if cover URL already exists
    $existing_cover = get_post_meta($book_id, 'cover_url', true);

    if (empty($isbn)) {
        echo "⚠️  Skipping '$title' - No ISBN found\n";
        $skipped_count++;
        continue;
    }

    if (!empty($existing_cover)) {
        echo "⏭️  Skipping '$title' - Cover URL already exists\n";
        $skipped_count++;
        continue;
    }

    // Clean ISBN (remove hyphens)
    $clean_isbn = str_replace('-', '', $isbn);

    // Generate Open Library cover URL
    $cover_url = "https://covers.openlibrary.org/b/isbn/{$clean_isbn}-M.jpg";

    // Verify the cover exists by making a HEAD request
    $headers = @get_headers($cover_url);
    $cover_exists = $headers && strpos($headers[0], '200') !== false;

    if ($cover_exists) {
        // Update the cover URL
        update_post_meta($book_id, 'cover_url', $cover_url);
        echo "✅ Updated '$title' - Cover URL: $cover_url\n";
        $updated_count++;
    } else {
        echo "❌ No cover found for '$title' (ISBN: $isbn)\n";
        $skipped_count++;
    }

    // Small delay to avoid overwhelming Open Library API
    usleep(100000); // 100ms
}

// Example 2: If books are in a custom database table
/*
$table_name = $wpdb->prefix . 'books'; // Adjust based on your setup

$books = $wpdb->get_results("SELECT * FROM $table_name");

foreach ($books as $book) {
    $book_id = $book->id;
    $title = $book->title;
    $isbn = $book->isbn;
    $existing_cover = $book->cover_url;

    if (empty($isbn)) {
        echo "⚠️  Skipping '$title' - No ISBN found\n";
        $skipped_count++;
        continue;
    }

    if (!empty($existing_cover)) {
        echo "⏭️  Skipping '$title' - Cover URL already exists\n";
        $skipped_count++;
        continue;
    }

    // Clean ISBN (remove hyphens)
    $clean_isbn = str_replace('-', '', $isbn);

    // Generate Open Library cover URL
    $cover_url = "https://covers.openlibrary.org/b/isbn/{$clean_isbn}-M.jpg";

    // Verify the cover exists
    $headers = @get_headers($cover_url);
    $cover_exists = $headers && strpos($headers[0], '200') !== false;

    if ($cover_exists) {
        // Update the database
        $wpdb->update(
            $table_name,
            array('cover_url' => $cover_url),
            array('id' => $book_id),
            array('%s'),
            array('%d')
        );
        echo "✅ Updated '$title' - Cover URL: $cover_url\n";
        $updated_count++;
    } else {
        echo "❌ No cover found for '$title' (ISBN: $isbn)\n";
        $skipped_count++;
    }

    // Small delay to avoid overwhelming Open Library API
    usleep(100000); // 100ms
}
*/

echo "\n" . str_repeat("=", 50) . "\n";
echo "Summary:\n";
echo "✅ Updated: $updated_count books\n";
echo "⏭️  Skipped: $skipped_count books\n";
echo str_repeat("=", 50) . "\n\n";
echo "Done! Cover URLs have been populated.\n";
echo "IMPORTANT: If you ran this via web browser, DELETE this file for security!\n";
