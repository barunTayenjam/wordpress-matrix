<?php
/**
Template Name: Page Fullwidth
**/

get_header();
?>

<section id="site-content" class="section-padding-80">
	<div class="container">
		<div class="site-content">
			<?php if ( has_post_thumbnail() ) { ?>
			    <div class="post-thumbnail mb-3">
			      <?php the_post_thumbnail(''); ?>
			    </div>
		 	<?php }?>
		 	<h2 class="mb-3"><?php the_title(); ?></h2>
			<?php the_post(); the_content(); ?>
		</div>
		 <?php 
			if( $post->comment_status == 'open' ) { 
				comments_template( '', true ); // show comments 
			}
		?>
	</div>
</section>

<?php get_footer(); ?>