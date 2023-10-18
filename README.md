# Captive Network Assistant

[![Translation status](https://l10n.elementary.io/widgets/desktop/-/capnet-assist/svg-badge.svg)](https://l10n.elementary.io/engage/desktop/?utm_source=widget)

Log into captive portals—like Wi-Fi networks at coffee shops, airports, and trains—with ease. Captive Network Assistant automatically opens to help you get connected.

![Screenshot](https://raw.github.com/elementary/capnet-assist/master/data/screenshot.png)

## Building, Testing, and Installation

Run `flatpak-builder` to configure the build environment, download dependencies, build, and install

```bash
flatpak-builder build io.elementary.capnet-assist.yml --user --install --force-clean --install-deps-from=appcenter
```

Then execute with

```bash
flatpak run io.elementary.capnet-assist
```

## Debugging

Set the environment variable `G_MESSAGES_DEBUG` to "all" to have the captive-login binary print debug messages.

Use the flag `-u` to direct the captive login window to a specific URL:

```bash
flatpak run io.elementary.capnet-assist -u https://elementary.io
```
    
An example HTML file is included in this repository, e.g. for screenshots, but note you must give access permission and include a `file://` path:

```bash
flatpak override --user --filesystem=/home/username/Projects/elementary/capnet-assist/data/example.html:ro io.elementary.capnet-assist
flatpak run io.elementary.capnet-assist -u file:///home/username/Projects/elementary/capnet-assist/data/example.html
```
