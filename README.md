# Captive Portal Assistant
[![l10n](https://i18n.elementary.io/widgets/desktop/capnet-assist/svg-badge.svg)](https://i18n.elementary.io/projects/desktop/capnet-assist)

A small WebKit app that assists a user with login when a captive portal is detected.

## Building, Testing, and Installation

You'll need the following dependencies:
* desktop-file-utils
* libgcr-3-dev
* libglib2.0-dev
* libgranite-dev
* libgtk-3-dev
* libwebkit2gtk-4.0-dev
* meson
* valac
    
Run `meson` to configure the build environment and then `ninja test` to build and run automated tests

    meson build --prefix=/usr
    ninja test
    
To install, use `ninja install`, then execute with `captive-login`

    sudo ninja install
    io.elementary.capnet-assist

## Debugging

Set the environment variable `G_MESSAGES_DEBUG` to "all" to have the captive-login binary print debug messages.

Use the flag `-f` to force the captive login window to show even if no captive portal is detected.

    io.elementary.capnet-assist -f 

Use the flag `-u` to direct the captive login window to a specific URL. This may not show a window without `-f` if no captive portal is detected.

    io.elementary.capnet-assist -fu https://elementary.io
