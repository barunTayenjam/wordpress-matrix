<?php if ( true == get_theme_mod( 'eco_ngo_our_cases_on_off', 'on' ) ) : ?>
<?php 
$eco_ngo_our_cases_short_heading = get_theme_mod('eco_ngo_our_cases_short_heading');
$eco_ngo_our_case_count = get_theme_mod('eco_ngo_our_case_count');
?>
<section id="home_our_cases" class="py-5">
  <div class="container">
    <?php if ( ! empty( $eco_ngo_our_cases_short_heading ) ): ?>
      <h4 class="text-left mb-3"><?php echo esc_html( $eco_ngo_our_cases_short_heading ); ?></h4>
    <?php endif; ?>
    <div class="row">
      <?php for ($i=1; $i <= $eco_ngo_our_case_count; $i++) {     
        $eco_ngo_our_cases_image = get_theme_mod('eco_ngo_our_cases_image'.$i);
        $eco_ngo_industry_our_cause_heading = get_theme_mod('eco_ngo_industry_our_cause_heading'.$i);
        $eco_ngo_industry_our_case_goal_amount = get_theme_mod('eco_ngo_industry_our_case_goal_amount'.$i);
        $eco_ngo_industry_our_case_rase_amount = get_theme_mod('eco_ngo_industry_our_case_rase_amount'.$i);
        $eco_ngo_industry_our_case_left_days = get_theme_mod('eco_ngo_industry_our_case_left_days'.$i); 
      ?>     
        <div class="col-lg-4 col-md-4 px-3 mb-4">
          <?php if ( ! empty( $eco_ngo_our_cases_image ) ) : ?>
            <div class="heroes_main_box text-center">
              <img class="mb-4" src="<?php echo esc_url( $eco_ngo_our_cases_image ); ?>">
            </div>
          <?php endif; ?>
          <div class="heroes_content_box text-center mt-5 mb-4">
            <?php if ( ! empty( $eco_ngo_industry_our_cause_heading ) ) : ?>
              <h5 class="mb-3"><?php echo esc_html( $eco_ngo_industry_our_cause_heading ); ?></h5>
            <?php endif; ?>
            <div class="goal-box row">
              <div class="col-lg-4 col-md-12 col-sm-4 col-4 goal-box-main">
                <?php if ( ! empty( $eco_ngo_industry_our_case_goal_amount ) ) : ?>
                  <div class="text-box">
                      <p class="mb-0 default-text"><?php echo esc_html('Goal','eco-ngo'); ?></p>
                      <p class="mb-0"><?php echo esc_html( $eco_ngo_industry_our_case_goal_amount ); ?></p>
                  </div>
                <?php endif; ?>
              </div>
              <div class="col-lg-4 col-md-12 col-sm-4 col-4 goal-box-main">
                <?php if ( ! empty( $eco_ngo_industry_our_case_rase_amount ) ) : ?>
                  <div class="text-box">
                    <p class="mb-0 default-text"><?php echo esc_html('Rise','eco-ngo'); ?></p>
                    <p class="mb-0"><?php echo esc_html( $eco_ngo_industry_our_case_rase_amount ); ?></p>
                  </div>
                <?php endif; ?>
              </div>
              <div class="col-lg-4 col-md-12 col-sm-4 col-4 goal-box-main">
                <?php if ( ! empty( $eco_ngo_industry_our_case_left_days ) ) : ?>
                  <div class="text-box">
                    <p class="mb-0 default-text"><?php echo esc_html('Left','eco-ngo'); ?></p>
                    <p class="mb-0"><?php echo esc_html( $eco_ngo_industry_our_case_left_days ); ?></p>
                  </div>
                <?php endif; ?>
              </div>
            </div>
            
          </div>
        </div>
      <?php } ?>
    </div>
  </div>
</section>
<?php endif; ?>
