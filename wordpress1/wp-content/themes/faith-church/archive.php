<?php get_header(); ?> <!-- Include the header template -->

<div id="primary" class="container my-4"> <!-- Main container for the archive page -->

    <h1><?php the_archive_title(); ?></h1> <!-- Display the archive title (e.g., category name, tag name, etc.) -->

    <?php if (have_posts()) : ?> <!-- Check if there are posts available -->
        <div class="row"> <!-- Bootstrap row for post grid layout -->

            <?php while (have_posts()) : the_post(); ?> <!-- Loop through the posts -->
                <div class="col-md-4 mb-4"> <!-- Bootstrap column for a 3-column layout -->
                    <div class="card"> <!-- Bootstrap card component -->

                        <?php if (has_post_thumbnail()) : ?> <!-- Check if the post has a featured image -->
                            <a href="<?php the_permalink(); ?>"> <!-- Link to the single post -->
                                <?php the_post_thumbnail('medium', ['class' => 'card-img-top']); ?> <!-- Display post thumbnail -->
                            </a>
                        <?php endif; ?>

                        <div class="card-body"> <!-- Card body for content -->
                            <h5 class="card-title">
                                <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a> <!-- Post title with link -->
                            </h5>
                            <p class="card-text"><?php the_excerpt(); ?></p> <!-- Display the post excerpt -->
                        </div>
                    </div>
                </div> <!-- End of Bootstrap column -->
            <?php endwhile; ?> <!-- End of the loop -->

        </div> <!-- End of row -->

        <?php
        // Pagination for navigating between pages
        the_posts_pagination(array(
            'prev_text' => __('Previous', 'faith-church'),
            'next_text' => __('Next', 'faith-church'),
        ));
        ?>

    <?php else : ?> <!-- If no posts are found -->
        <p><?php _e('No posts found.', 'faith-church'); ?></p>
    <?php endif; ?>

</div> <!-- End of primary container -->

<?php get_footer(); ?> <!-- Include the footer template -->
