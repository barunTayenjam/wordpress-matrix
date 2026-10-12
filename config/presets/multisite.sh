#!/bin/bash
# Multisite preset (subdirectory by default; --multisite flag overrides mode).
preset_description() { echo "WordPress Multisite"; }
preset_post_install() {
    apply_multisite "$PRESET_SITE" "${multisite:-subdirectory}"
}
