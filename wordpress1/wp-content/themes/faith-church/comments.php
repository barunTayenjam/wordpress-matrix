<?php
// Check if the post is password protected; if so, return early without displaying comments
if (post_password_required()) {
    return;
}
?>

<div id="comments" class="comments-area"> <!-- Comments section container -->

    <?php if (have_comments()) : ?> <!-- Check if there are any comments -->
        <h3 class="comments-title">
            <?php
            // Display the number of comments with proper singular/plural handling
            printf(
                _nx('One comment', '%1$s comments', get_comments_number(), 'comments title', 'faith-church'),
                number_format_i18n(get_comments_number())
            );
            ?>
        </h3>

        <ul class="comment-list"> <!-- List of comments -->
            <?php
            wp_list_comments(array(
                'style' => 'ul', // Set the list style
                'short_ping' => true, // Shorter pingbacks for better readability
            ));
            ?>
        </ul>

        <?php the_comments_navigation(); ?> <!-- Navigation for comments pagination -->
    <?php endif; ?>

    <?php
    // Display message if comments are closed
    if (!comments_open()) {
        echo '<p class="no-comments">' . __('Comments are closed.', 'faith-church') . '</p>';
    }
    ?>

    <?php comment_form(); ?> <!-- Display the comment form -->

</div> <!-- End of comments section -->
