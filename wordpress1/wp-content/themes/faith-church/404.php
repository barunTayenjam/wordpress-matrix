<?php 
// Include the header template
get_header(); 
?>

<div id="primary" class="container my-4 text-center">
    <!-- Display the 404 error message -->
    <h1 class="display-4"><?php _e('404 - Page Not Found', 'faith-church'); ?></h1>
    
    <!-- Search form section -->
    <div class="search-form mt-4">
        <?php 
        // Include the search form template
        get_search_form(); 
        ?>
    </div>
    
    <!-- Additional message for the 404 page -->
    <p class="lead"><?php _e('Sorry, the page you are looking for does not exist.', 'faith-church'); ?></p>
    
    <!-- Link to return to the home page -->
    <a href="<?php echo esc_url(home_url('/')); ?>" class="btn btn-primary">
        <?php _e('Back to Home', 'faith-church'); ?>
    </a>
</div>

<?php 
// Include the footer template
get_footer(); 
?>