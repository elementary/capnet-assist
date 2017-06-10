/*
* Copyright (c) 2015-2017 elementary LLC. (http://launchpad.net/capnet-assist)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
*/

public class CaptiveLogin : Gtk.ApplicationWindow {
    private const string DUMMY_URL = "http://capnet.elementary.io";

    private CertButton cert_button;
    private Gtk.Label title_label;

    private Granite.Widgets.DynamicNotebook notebook;

    // When a download is passed to the browser, it triggers the load failed signal
    private bool download_requested = false;

    public CaptiveLogin (Gtk.Application app) {
        Object (application: app);

        unowned Captive.Settings saved_state = Captive.Settings.get_default ();
        set_default_size (saved_state.window_width, saved_state.window_height);

        switch (saved_state.window_state) {
            case Captive.Settings.WindowState.MAXIMIZED:
                this.maximize ();
                break;
            default:
                break;
        }
    }

    construct {
        cert_button = new CertButton (this);

        title_label = new Gtk.Label (_("Log in"));
        title_label.get_style_context ().add_class (Gtk.STYLE_CLASS_TITLE);

        var header_grid = new Gtk.Grid ();
        header_grid.column_spacing = 6;
        header_grid.margin_top = 3;
        header_grid.margin_bottom = 3;
        header_grid.add (cert_button);
        header_grid.add (title_label);

        var header = new Gtk.HeaderBar ();
        header.show_close_button = true;
        header.get_style_context ().add_class ("compact");
        header.custom_title = header_grid;

        set_titlebar (header);

        notebook = new Granite.Widgets.DynamicNotebook ();
        notebook.tab_bar_behavior = Granite.Widgets.DynamicNotebook.TabBarBehavior.SINGLE;
        notebook.allow_drag = false;
        notebook.allow_new_window = false;
        notebook.allow_restoring = false;
        notebook.add_button_visible = false;

        add (notebook);

        set_keep_above (true);
        skip_taskbar_hint = true;
        stick ();

        connect_signals ();
    }

    bool is_privacy_mode_enabled () {
        var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");
        return !privacy_settings.get_boolean ("remember-recent-files") ||
               !privacy_settings.get_boolean ("remember-app-usage");
    }

    private void connect_signals () {
        this.destroy.connect (application.quit);

        notebook.tab_switched.connect ((old_tab, new_tab) => {
            var captive_view = (TabbedWebView) new_tab;
            title_label.label = captive_view.label;

            cert_button.security = captive_view.security;
        });

        notebook.close_tab_requested.connect ((tab) => {
            if (notebook.n_tabs == 1) {
                application.quit ();
            } else if (notebook.n_tabs == 2) {
                notebook.show_tabs = false;
            }

            return true;
        });
    }

    private TabbedWebView create_tab (string uri) {
        var tab = new TabbedWebView (uri, !is_privacy_mode_enabled ());

        notebook.insert_tab (tab, notebook.n_tabs);
        notebook.show_tabs = notebook.n_tabs > 1;

        tab.notify["label"].connect ((view, param_spec) => {
            if (tab == this.notebook.current) {
                title_label.set_text (tab.label);
            }
        });

        tab.notify["security"].connect ((view, param_spec) => {
            if (tab == this.notebook.current) {
                cert_button.security = tab.security;
            }
        });

        tab.web_view.create.connect ((navigation_action)=> {
            create_tab (navigation_action.get_request().get_uri ());

            return null;
        });

        tab.web_view.decide_policy.connect ((decision, type) => {
            switch (type) {
                case WebKit.PolicyDecisionType.NEW_WINDOW_ACTION:
                    if (decision is WebKit.ResponsePolicyDecision) {
                        create_tab ((decision as WebKit.ResponsePolicyDecision).request.get_uri ());
                    }
                break;
                case WebKit.PolicyDecisionType.RESPONSE:
                    if (decision is WebKit.ResponsePolicyDecision) {
                        var policy = (WebKit.ResponsePolicyDecision) decision;
                        if (!policy.is_mime_type_supported ()) {
                            try {
                                var url = policy.request.get_uri ();
                                AppInfo.launch_default_for_uri (url, null);
                                download_requested = true;
                            } catch (Error e) {
                                warning ("No app to handle urls: %s", e.message);
                            }

                            return false;
                        }
                    }
                break;
            }

            return true;
        });

        return tab;
    }

    public bool get_tls_info (out TlsCertificate certificate, out TlsCertificateFlags errors) {
        var web_view = ((TabbedWebView) notebook.current).web_view;

        return web_view.get_tls_info (out certificate, out errors);
    }

    public string get_uri () {
        var web_view = ((TabbedWebView) notebook.current).web_view;

        return web_view.get_uri ();
    }

    public void start (string? browser_url) {
        var default_tab = create_tab (browser_url ?? DUMMY_URL);

        default_tab.web_view.load_failed.connect ((event, uri, error) => {
            // The user has canceled the page loading eg. by clicking on a link.
            if ((Error) error is WebKit.NetworkError.CANCELLED) {
                return true;
            }

            // Download started, but interrupted
            if (download_requested) {
                download_requested = false;
                return true;
            }

            application.quit ();
            return true;
        });

        show_all ();
    }

    public override bool delete_event (Gdk.EventAny event) {
        int window_width;
        int window_height;
        get_size (out window_width, out window_height);
        unowned Captive.Settings saved_state = Captive.Settings.get_default ();
        saved_state.window_width = window_width;
        saved_state.window_height = window_height;
        if (is_maximized) {
            saved_state.window_state = Captive.Settings.WindowState.MAXIMIZED;
        } else {
            saved_state.window_state = Captive.Settings.WindowState.NORMAL;
        }

        return false;
    }
}
