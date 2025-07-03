<?php 
/**
Template Name: Default homepage
*/
?>
<?php 
	get_header();
	get_template_part('sections/home','slider');
	get_template_part('sections/home','product');
	get_template_part('sections/home','content');
	get_footer();
?>