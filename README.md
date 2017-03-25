# Captive Portal Assistant
[![l10n](https://i18n.elementary.io/widgets/desktop/capnet-assist/svg-badge.svg)](https://i18n.elementary.io/projects/desktop/capnet-assist)

A small WebKit app that assists a user with login when a captive portal is detected.

## Building, Testing, and Installation

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make all test` to build and run automated tests

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make all test
    
To install, use `make install`, then execute with `captive-login`

    sudo make install
    captive-login

## Debugging

Set the environment variable `G_MESSAGES_DEBUG` to "all" to have the captive-login binary print debug messages.

Use the flag `-f` to force the captive login window to show even if no captive portal is detected.

    captive-login -f 

Use the flag `-u` to direct the captive login window to a specific URL. This may not show a window without `-f` if no captive portal is detected.

    captive-login -fu https://elementary.io
