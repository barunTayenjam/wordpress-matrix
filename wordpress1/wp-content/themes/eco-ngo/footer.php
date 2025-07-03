<!-- Start: Footer Sidebar
============================= -->
<?php if ( is_active_sidebar( 'footer-widget-area' ) ) { ?>
    <?php if ( true == get_theme_mod( 'eco_ngo_footer_widgets_display_setting', 'off' ) ) : ?>
        <footer id="footer-widgets" class="footer-sidebar footer_bg">
            <div class="footer-widgets">
                <div class="container">
                    <div class="row">
                        <?php dynamic_sidebar( 'footer-widget-area' ); ?>
                    </div>
                </div>
            </div>
        </footer>
    <?php endif; ?>
<?php } else { ?>
        <?php if ( ! is_active_sidebar( 'footer-widget-area' ) ) : ?>
        	<footer id="footer-widgets" class="footer-sidebar footer_bg">
            <div class="footer-widgets">
                <div class="container">
                    <div class="row">
                        <div class="col-lg-3 col-md-6 col-sm-12 mb-lg-0 mb-4">
					        <aside id="archives-3" class="widget widget_archive">
					            <h5 class="widget-title"><?php esc_html_e( 'Archives List', 'eco-ngo' ); ?></h5>
					            <span class="animate-border border-black"></span>
					            <ul>
					                <?php wp_get_archives( array( 'type' => 'monthly' ) ); ?>
					            </ul>
					        </aside>
                        </div>
                        <div class="col-lg-3 col-md-6 col-sm-12 mb-lg-0 mb-4">
                        	<aside id="pages-2" class="widget widget_pages">
							    <h5 class="widget-title"><?php esc_html_e('Our Pages', 'eco-ngo'); ?></h5>
							    <span class="animate-border border-black"></span>
							    <ul>
							        <?php
							        wp_list_categories(array(
							            'title_li' => '',
							        ));
							        ?>
							    </ul>
							</aside>
                        </div>
                        <div class="col-lg-3 col-md-6 col-sm-12 mb-lg-0 mb-4">
					        <aside id="recent-posts-2" class="widget widget_recent_entries">
							    <h5 class="widget-title"><?php esc_html_e('Recent Posts', 'eco-ngo'); ?></h5>
							    <span class="animate-border border-black"></span>
							    <ul class="wp-block-latest-posts__list">
							        <?php
							        $eco_ngo_recent_posts = wp_get_recent_posts(array(
							            'numberposts' => 5, // Adjust the number of posts to display
							            'post_status' => 'publish',
							        ));
							        foreach ($eco_ngo_recent_posts as $post) :
							            ?>
							            <li>
							                <a href="<?php echo esc_url(get_permalink($post['ID'])); ?>">
							                    <?php echo esc_html($post['post_title']); ?>
							                </a>
							            </li>
							        <?php endforeach; ?>
							    </ul>
							</aside>
                        </div>
                        <div class="col-lg-3 col-md-6 col-sm-12 mb-lg-0 mb-4">
							<aside id="tag_cloud-2" class="widget widget_tag_cloud">
							    <h5 class="widget-title"><?php esc_html_e('Tag Cloud', 'eco-ngo'); ?></h5>
							    <span class="animate-border border-black"></span>
							    <?php wp_tag_cloud(array(
							        'smallest' => 10,   // Minimum font size
							        'largest' => 22,    // Maximum font size
							        'unit' => 'px',     // Font size unit (pixels)
							        'number' => 20,      // Maximum number of tags to display
							        'format' => 'array' // Display as an array for more control
							    )); ?>
							    <div class="tagcloud">
							        <?php
							        $tags = get_tags(); // Get all tags
							        foreach ($tags as $tag) :
							        ?>
							            <a href="<?php echo esc_url(get_tag_link($tag->term_id)); ?>" class="custom-tag-link">
							                <?php echo esc_html($tag->name); ?>
							            </a>
							        <?php endforeach; ?>
							    </div>
							</aside>
                        </div>
                    </div>
                </div>
            </div>
        </footer>
    <?php endif; ?>
<?php } ?>
<!-- End: Footer Sidebar
============================= -->
<?php
	if ( ! defined( 'ECO_NGO_FREE_LINK' ) ) {
		define('ECO_NGO_FREE_LINK',__('https://www.mishkatwp.com/themes/free-ngo-wordpress-theme/','eco-ngo'));
	}
	$eco_ngo_copyright_content   = get_theme_mod('copyright_content','Copyright &copy; [current_year] [site_title] | Powered by [theme_author]');
	$eco_ngo_copyright_content_text   = get_theme_mod('eco_ngo_copyright_content_text','Eco NGO WordPress Theme');
?>

<section id="footer-copyright">
	<div class="container">
		<div class="text-center">
			<?php if ( true == get_theme_mod( 'eco_ngo_copyright_on_off', 'on' ) ) : ?>
				<p class="mb-0">
					 <?php 
						$eco_ngo_copyright_allowed_tags = array(
							'[current_year]' => date_i18n('Y'),
							'[site_title]'   => '<a href="' . esc_url( ECO_NGO_FREE_LINK ) . '" target="_blank">'.$eco_ngo_copyright_content_text.'</a>',
							'[theme_author]' => sprintf(__('<a href="https://wordpress.org/" target="_blank">WordPress.org</a>', 'eco-ngo')),
						);
						echo apply_filters('eco_ngo_footer_copyright', wp_kses_post(eco_ngo_str_replace_assoc($eco_ngo_copyright_allowed_tags, $eco_ngo_copyright_content)));
					?>
				</p>
			<?php endif; ?>
			<?php if( get_theme_mod( 'eco_ngo_scroll_to_top_setting',true) == 1 || get_theme_mod( 'eco_ngo_responsive_scroll_to_top_setting',true) == 1) { ?>
			    <?php if ( get_theme_mod( 'eco_ngo_scroll_to_top_type', 'advance-scroll' ) == 'advance-scroll' ) { ?>
			        <?php do_action('eco_ngo_top_scroller'); ?>
			    <?php } elseif ( get_theme_mod( 'eco_ngo_scroll_to_top_type' ) == 'simple-scroll' ) { ?>
			        <a href="#" class="scrollup"><i class="fa fa-arrow-up"></i></a>
			    <?php } ?>
			<?php } ?>
		</div>
	</div>
</section>
</div>
</div>
<?php wp_footer(); ?>
</body>
</html>