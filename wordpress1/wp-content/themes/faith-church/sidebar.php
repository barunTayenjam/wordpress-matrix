<?php if (is_active_sidebar('sidebar-1')) : ?> <!-- Check if the sidebar has active widgets -->
    <aside id="secondary" class="widget-area"> <!-- Sidebar container -->
        <?php dynamic_sidebar('sidebar-1'); ?> <!-- Display the widgets in the 'sidebar-1' area -->
    </aside>
<?php endif; ?> <!-- End of sidebar check -->
