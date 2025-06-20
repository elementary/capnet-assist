/*
 * Copyright 2016-2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

public class Captive.Application : Gtk.Application {
    private string? debug_url = null;

    public static Settings settings;

    public Application () {
        Object (application_id: "io.elementary.capnet-assist", flags: ApplicationFlags.HANDLES_COMMAND_LINE);
    }

    static construct {
        settings = new Settings ("io.elementary.desktop.capnet-assist");
    }

    construct {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);
    }

    public override void activate () {
        if (!settings.get_boolean ("enabled")) {
            quit ();
            return;
        }

        if (!is_busy) {
            mark_busy ();

            var main_window = new MainWindow (this);

            settings.bind ("window-height", main_window, "default-height", DEFAULT);
            settings.bind ("window-width", main_window, "default-width", DEFAULT);

            if (settings.get_boolean ("is-maximized")) {
                main_window.maximize ();
            }

            settings.bind ("is-maximized", main_window, "maximized", SettingsBindFlags.SET);

            main_window.start (debug_url);
        }
    }

    public override void startup () {
        base.startup ();

        Granite.init ();
        Adw.init ();

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == DARK;
        });

        var quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            if (active_window != null) {
                active_window.destroy ();
            }
        });

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q"});
    }

    public override int command_line (ApplicationCommandLine command_line) {
        OptionEntry[] options = new OptionEntry[1];
        options[0] = { "url", 'u', 0, OptionArg.STRING, ref debug_url, _("Load this address in the browser window"), _("URL") };

        string[] args = command_line.get_arguments ();

        try {
            var opt_context = new OptionContext ("- OptionContext example");
            opt_context.set_help_enabled (true);
            opt_context.add_main_entries (options, null);
            unowned string[] tmp = args;
            opt_context.parse (ref tmp);
        } catch (OptionError e) {
            command_line.print ("error: %s\n", e.message);
            command_line.print ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
            return -1;
        }

        activate ();

        return 0;
    }

    public static int main (string[] args) {
        Environment.set_application_name ("captive-login");
        Environment.set_prgname ("captive-login");

        var application = new Captive.Application ();

        return application.run (args);
    }
}
