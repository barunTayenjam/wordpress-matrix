<?php
/**
 * The Template for displaying all single products
 *
 * This template can be overridden by copying it to yourtheme/woocommerce/single-product.php.
 *
 * HOWEVER, on occasion WooCommerce will need to update template files and you
 * (the theme developer) will need to copy the new files to your theme to
 * maintain compatibility. We try to do this as little as possible, but it does
 * happen. When this occurs the version of the template file will be bumped and
 * the readme will list any important changes.
 *
 * @see 	    https://docs.woocommerce.com/document/template-structure/
 * @author 		WooThemes
 * @package 	WooCommerce/Templates
 * @version     1.6.4
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly
}

get_header( 'shop' ); ?>

	<div id="skip-content">
		<div class="featured-img">
			<div class="post-thumbnail">
				<div class="img-responsive center-block"></div>
			</div>
			<div class="single-meta-box">
				<h2 class="my-3"><?php esc_html_e('Product Page', 'eco-ngo'); ?></h2>
				<?php if ( get_theme_mod('eco_ngo_breadcrumb_setting',true) ) : ?>
		          <div class="bread_crumb text-center">
		            <?php eco_ngo_breadcrumb();  ?>
		          </div>
		        <?php endif; ?>
			</div>
		</div>
		<div class="container">
    <div class="row">
        <?php
        $eco_ngo_product_sidebar_position = get_theme_mod( 'eco_ngo_product_sidebar_position', 'right' );

        if ( 'left' === $eco_ngo_product_sidebar_position ) : ?>
            <div class="col-lg-3 sidebar">
                <?php
                /**
                 * Hook: woocommerce_sidebar hook.
                 *
                 * @hooked woocommerce_get_sidebar - 10
                 */
                get_sidebar();
                ?>
            </div>
            <div class="col-lg-9 col-md-9">
        <?php elseif ( 'right' === $eco_ngo_product_sidebar_position ) : ?>
            <div class="col-lg-9 col-md-9">
        <?php else : ?>
            <div class="col-lg-12">
        <?php endif; ?>

                <?php
                /**
                 * woocommerce_before_main_content hook.
                 *
                 * @hooked woocommerce_output_content_wrapper - 10 (outputs opening divs for the content)
                 * @hooked woocommerce_breadcrumb - 20
                 */
                do_action( 'woocommerce_before_main_content' );
                ?>

                <?php while ( have_posts() ) : the_post(); ?>
                    <?php wc_get_template_part( 'content', 'single-product' ); ?>
                <?php endwhile; // end of the loop. ?>

                <?php
                /**
                 * woocommerce_after_main_content hook.
                 *
                 * @hooked woocommerce_output_content_wrapper_end - 10 (outputs closing divs for the content)
                 */
                do_action( 'woocommerce_after_main_content' );
                ?>
            </div>
        <?php if ( 'right' === $eco_ngo_product_sidebar_position ) : ?>
            <div class="col-lg-3 sidebar">
                <?php
                /**
                 * Hook: woocommerce_sidebar hook.
                 *
                 * @hooked woocommerce_get_sidebar - 10
                 */
                get_sidebar();
                ?>
            </div>
        <?php endif; ?>
    </div>
</div>
	</div>

<?php get_footer( 'shop' );