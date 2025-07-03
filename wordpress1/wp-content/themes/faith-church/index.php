<?php 
// Include the header template
get_header(); 
?>

<div id="primary" class="container my-4">
    <?php 
    // Check if there are posts to display
    if (have_posts()) : 
    ?>
        <div class="row">
            <?php 
            // Loop through the posts
            while (have_posts()) : the_post(); 
            ?>
                <div class="col-md-4 mb-4">
                    <!-- Card container for each post -->
                    <div class="card">
                        <?php 
                        // Check if the post has a featured image
                        if (has_post_thumbnail()) : 
                        ?>
                            <!-- Display the featured image with a link to the post -->
                            <a href="<?php the_permalink(); ?>">
                                <?php the_post_thumbnail('medium', ['class' => 'card-img-top']); ?>
                            </a>
                        <?php endif; ?>
                        
                        <!-- Card body for post content -->
                        <div class="card-body">
                            <!-- Post title with a link to the post -->
                            <h5 class="card-title">
                                <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                            </h5>
                            <!-- Post excerpt -->
                            <p class="card-text"><?php the_excerpt(); ?></p>
                        </div>
                    </div>
                </div>
            <?php 
            // End the loop
            endwhile; 
            ?>
        </div>

        <!-- Pagination section -->
        <div class="pagination mt-4">
            <?php
            // Display pagination links
            the_posts_pagination( array(
                'mid_size'  => 2, // Number of page links to show on either side of the current page
                'prev_text' => false, // Removes "Previous" button
                'next_text' => false, // Removes "Next" button
            ) );
            ?>
        </div>

    <?php 
    // If no posts are found, display a message
    else : 
    ?>
        <p><?php _e('No posts found.', 'faith-church'); ?></p>
    <?php 
    // End the if statement
    endif; 
    ?>
</div>

<?php 
// Include the footer template
get_footer(); 
?>