<?php get_header(); ?> <!-- Include the header template -->

<div id="primary" class="container my-4"> <!-- Main container for the page content -->

    <?php if (have_posts()) : while (have_posts()) : the_post(); ?> <!-- Start the loop to display posts -->

        <article id="post-<?php the_ID(); ?>" <?php post_class(); ?>> <!-- Article container with post-specific classes -->

            <h1 class="mb-4"><?php the_title(); ?></h1> <!-- Display the post title -->

            <div class="meta mb-3">
                <span>
                    <?php _e('Posted on', 'faith-church'); ?> 
                    <?php echo get_the_date(); ?> <!-- Display the post date -->
                </span>
            </div>

            <div class="content">
                <?php the_content(); ?> <!-- Display the post content -->

                <?php 
                // Pagination for multi-page posts
                wp_link_pages( array(
                    'before'      => '<div class="page-links">' . esc_html__( 'Pages:', 'faith-church' ),
                    'after'       => '</div>',
                    'link_before' => '<span class="page-number">',
                    'link_after'  => '</span>',
                ) );
                ?>
            </div>

            <!-- ADD THIS SECTION TO DISPLAY TAGS -->
            <?php 
            $faith_church_tags_list = get_the_tag_list('<span class="tag">', ', ', '</span>'); // Get the list of post tags
            if ($faith_church_tags_list) {
                echo '<div class="post-tags mt-3"><strong>' . esc_html__('Tags:', 'faith-church') . '</strong> ' . $faith_church_tags_list . '</div>';
            }
            ?>

            <?php if (comments_open() || get_comments_number()) : ?> <!-- Check if comments are enabled or available -->
                <div class="comments mt-5">
                    <?php comments_template(); ?> <!-- Load the comments template -->
                </div>
            <?php endif; ?>

        </article> <!-- End of article -->
        
    <?php endwhile; endif; ?> <!-- End of the loop -->

</div> <!-- End of primary container -->

<?php get_footer(); ?> <!-- Include the footer template -->
