#!/bin/bash

# preseed configuration for unattended installation
(
cat <<EOF
dash dash/sh boolean false
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
locales locales/default_environment_locale select en_US.UTF-8
EOF
) | debconf-set-selections

# apply configuration to already installed packages
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C dpkg --configure -a
