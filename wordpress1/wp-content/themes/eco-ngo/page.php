<?php
/**
 * The template for displaying all pages.
 *
 * This is the template that displays all pages by default.
 * Please note that this is the WordPress construct of pages
 * and that other 'pages' on your WordPress site may use a
 * different template.
 *
 * @link https://codex.wordpress.org/Template_Hierarchy
 *
 * @package Eco NGO
 */

get_header();

$eco_ngo_sidebar_position = get_theme_mod('eco_ngo_single_page_sidebar_option', 'right');
?>

<section id="service-page" class="<?php echo $eco_ngo_sidebar_position == 'none' ? 'no-sidebar' : 'has-sidebar'; ?>">
    <div class="featured-img">
        <div class="post-thumbnail">
            <?php
            if ( has_post_thumbnail() ) :
                the_post_thumbnail();
            else :
                // Get custom fallback image set from the Customizer
                $eco_ngo_custom_fallback_img = get_theme_mod( 'eco_ngo_custom_fallback_img' );

                if ( ! empty( $eco_ngo_custom_fallback_img ) ) :
                    ?>
                    <img src="<?php echo esc_url( $eco_ngo_custom_fallback_img ); ?>">
                <?php else : ?>
                    <img src="<?php echo esc_url( get_template_directory_uri() . '/images/exist_img.png' ); ?>">
                <?php endif;
            endif;
            ?>
        </div>
        <div class="single-meta-box">
            <h2 class="my-3"><?php the_title(); ?></h2>
            <?php if ( get_theme_mod('eco_ngo_breadcrumb_setting',true) ) : ?>
                  <div class="bread_crumb text-center">
                    <?php eco_ngo_breadcrumb();  ?>
                  </div>
                <?php endif; ?>
        </div>
    </div>
    <div class="container">
        <div class="row">
            <?php if ($eco_ngo_sidebar_position == 'left') : ?>
                <div class="col-lg-4 col-md-4 sidebar">
                    <?php get_sidebar(); ?>
                </div>
            <?php endif; ?>
            <div class="<?php echo $eco_ngo_sidebar_position == 'none' ? 'col-lg-12' : 'col-lg-8'; ?> col-md-8">
                <div class="site-content">
                    <?php
                    if (have_posts()) :
                        the_post();
                        the_content();
                    endif;
                    if ($post->comment_status == 'open') {
                        comments_template('', true);
                    }
                    wp_link_pages(array(
                        'before' => '<div class="section-pagination">',
                        'after' => '</div>',
                        'link_before' => '<span class="inner-pagination">',
                        'link_after' => '</span>',
                    ));
                    ?>
                </div>
            </div>
            <?php if ($eco_ngo_sidebar_position == 'right') : ?>
                <div class="col-lg-4 col-md-4 sidebar">
                    <?php get_sidebar(); ?>
                </div>
            <?php endif; ?>
        </div>
    </div>
</section>
<?php get_footer(); ?>

