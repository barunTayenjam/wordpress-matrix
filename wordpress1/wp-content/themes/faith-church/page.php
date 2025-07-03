<?php 
// Include the header template
get_header(); 
?>

<div id="primary" class="container my-4">
    <?php 
    // Check if there are posts to display
    if (have_posts()) : 
        // Loop through the posts
        while (have_posts()) : the_post(); 
    ?>
        <!-- Article container for the post -->
        <article id="post-<?php the_ID(); ?>" <?php post_class(); ?>>
            <!-- Display the post title -->
            <h1 class="mb-4"><?php the_title(); ?></h1>
            
            <!-- Post content section -->
            <div class="content">
                <?php 
                // Display the post content
                the_content(); 
                ?>

                <?php 
                // Add pagination links for multi-page posts
                wp_link_pages( array(
                    'before'      => '<div class="page-links">' . esc_html__( 'Pages:', 'faith-church' ),
                    'after'       => '</div>',
                    'link_before' => '<span class="page-number">',
                    'link_after'  => '</span>',
                ) );
                ?>
            </div>
        </article>
    <?php 
        // End the loop
        endwhile; 
    // End the if statement
    endif; 
    ?>
</div>

<?php 
// Include the footer template
get_footer(); 
?>