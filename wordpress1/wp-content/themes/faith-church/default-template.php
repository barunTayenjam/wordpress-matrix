<?php 
/*
 * Template Name: Theme Default Template
 * Description: This is the default page template for the theme.
 */

get_header(); // Load the header.php file
?>

<!-- Main content container -->
<div id="primary" class="pce-home-page">
	<?php 
		// Display the content of the page
		the_content(); 
	?>
</div>

<?php 
// Load the footer.php file
get_footer(); 
?>