<footer class="faith-church-footer-wrap text-light py-4"> <!-- Footer section with dark background and light text -->
    <div class="container text-center"> <!-- Center-aligned content within a Bootstrap container -->
        <p>
            <?php 
            // Display dynamic copyright year
            echo esc_html__('Copyright', 'faith-church') . ' &copy; ' . date('Y') . ' | ';

            // Display translatable "All Rights Reserved" text
            esc_html_e('All Rights Reserved', 'faith-church'); 
            ?>

            <?php 
            // Get the footer credit text from the theme customizer with a default translatable fallback
            $faith_church_footer_credit = get_theme_mod(
                'footer_credit', 
                sprintf(
                    esc_html__('Design By: %s', 'faith-church'),
                    '<a href="https://webxthemes.com/" target="_blank" class="text-light">Patrickoslo</a>'
                )
            );

            // Output the footer credit with allowed HTML tags for security
            echo wp_kses_post($faith_church_footer_credit); 
            ?>
        </p>
    </div>
</footer>

<?php wp_footer(); ?> <!-- WordPress function to include necessary footer scripts and hooks -->

</body>
</html>
