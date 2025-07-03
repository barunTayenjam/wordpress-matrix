<?php

/*----------------------------------------------------------------------------------*/

$eco_ngo_common_inline_css = '';

$eco_ngo_scroll_top_alignment = get_theme_mod('eco_ngo_scroll_top_alignment', 'Right');

$eco_ngo_alignment_styles = [
    'Left' => 'left: 20px;',
    'Center' => 'right: 0; left: 0; margin: 0 auto;',
    'Right' => 'right: 20px;'
];

$alignment_style = $eco_ngo_alignment_styles[$eco_ngo_scroll_top_alignment] ?? $eco_ngo_alignment_styles['Right'];

$eco_ngo_common_inline_css .= "a.scrollup,button#scroll_2 { $alignment_style }";

/*----------------------------------------------------------------------------------*/


$eco_ngo_footer_background_color = get_theme_mod('eco_ngo_footer_background_color', '#151725');

if (!empty($eco_ngo_footer_background_color)) {
    $eco_ngo_common_inline_css .= ".footer-widgets { background: " . esc_attr($eco_ngo_footer_background_color) . "}";
}

/*----------------------------------------------------------------------------------*/

$eco_ngo_footer_background_image = get_theme_mod('eco_ngo_footer_background_image', '');

if (!empty($eco_ngo_footer_background_image)) {
    $eco_ngo_common_inline_css .= ".footer-widgets { background-image: url('" . esc_url($eco_ngo_footer_background_image) . "') !important; background-size: cover; background-repeat: no-repeat; }";
}

/*----------------------------------------------------------------------------------*/

$eco_ngo_copyright_alignment = get_theme_mod('eco_ngo_copyright_alignment', 'Center');

$eco_ngo_copyright_alignment_styles = [
    'Left' => 'text-align: left;',
    'Center' => 'text-align: center;',
    'Right' => 'text-align: right;'
];

$alignment_style = $eco_ngo_copyright_alignment_styles[$eco_ngo_copyright_alignment] ?? $eco_ngo_copyright_alignment_styles['Center'];

$eco_ngo_common_inline_css .= "#footer-copyright p { $alignment_style }";

/*----------------------------------------------------------------------------------*/

$eco_ngo_container_width = get_theme_mod('eco_ngo_container_width');

if (!empty($eco_ngo_container_width)) {
    $eco_ngo_common_inline_css .= "@media (min-width: 1024px) { 
        body, #header.nav-stick.header-fixed,.loading { 
            width: " . esc_attr($eco_ngo_container_width) . "%; 
            margin: 0 auto; 
        } 
        .admin-bar #header.nav-stick.header-fixed { 
            margin-top: 32px; 
        } 
    }";
}

/*----------------------------------------------------------------------------------*/   

$eco_ngo_responsive_scroll_to_top_setting = get_theme_mod( 'eco_ngo_responsive_scroll_to_top_setting', true );

if ( $eco_ngo_responsive_scroll_to_top_setting == true && get_theme_mod( 'eco_ngo_scroll_to_top_setting', true ) != true ) {
    $eco_ngo_common_inline_css .= "a.scrollup,button#scroll_2 {
        display: none !important;
    }";
}

if ( $eco_ngo_responsive_scroll_to_top_setting == true ) {
    $eco_ngo_common_inline_css .= "@media screen and (max-width: 768px) {
        a.scrollup,button#scroll_2 {
            display: block !important;
        }
    }";
} elseif ( $eco_ngo_responsive_scroll_to_top_setting == false ) {
    $eco_ngo_common_inline_css .= "@media screen and (max-width: 768px) {
        a.scrollup,button#scroll_2 {
            display: none !important;
        }
    }";
}

/*----------------------------------------------------------------------------------*/ 

$eco_ngo_responsive_preloader_setting = get_theme_mod( 'eco_ngo_responsive_preloader_setting', false );

if ( $eco_ngo_responsive_preloader_setting == true && get_theme_mod( 'eco_ngo_preloader_setting', false ) == false ) {
    $eco_ngo_common_inline_css .= "@media screen and (min-width: 768px) {
        .loading {
            display: none !important;
        }
    }";
}

if ( $eco_ngo_responsive_preloader_setting == false ) {
    $eco_ngo_common_inline_css .= "@media screen and (max-width: 768px) {
        .loading {
            display: none !important;
        }
    }";
}

/*----------------------------------------------------------------------------------*/ 