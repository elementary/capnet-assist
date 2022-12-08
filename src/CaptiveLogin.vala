/*
* Copyright 2015-2022 elementary, Inc. (https://elementary.io)
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
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA.
*
*/

public class CaptiveLogin : Hdy.ApplicationWindow {
    private const string DUMMY_URL = "http://capnet.elementary.io";

    private CertButton cert_button;
    private Gtk.Label title_label;
    private Hdy.TabView tabview;

    // When a download is passed to the browser, it triggers the load failed signal
    private bool download_requested = false;

    public CaptiveLogin (Gtk.Application app) {
        Object (application: app);

        set_default_size (Captive.Application.settings.get_int ("window-width"), Captive.Application.settings.get_int ("window-height"));

        if (Captive.Application.settings.get_boolean ("is-maximized")) {
            maximize ();
        }
    }

    construct {
        Hdy.init ();

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        cert_button = new CertButton (this);

        title_label = new Gtk.Label (_("Log in"));
        title_label.get_style_context ().add_class (Gtk.STYLE_CLASS_TITLE);

        var header_grid = new Gtk.Grid () {
            column_spacing = 6
        };
        header_grid.add (cert_button);
        header_grid.add (title_label);

        var header = new Hdy.HeaderBar () {
            custom_title = header_grid,
            show_close_button = true
        };
        header.get_style_context ().add_class ("default-decoration");

        tabview = new Hdy.TabView () {
            expand = true
        };

        var tabbar = new Hdy.TabBar () {
            expand_tabs = false,
            view = tabview
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.add (header);
        box.add (tabbar);
        box.add (tabview);

        add (box);

        set_keep_above (true);
        skip_taskbar_hint = true;
        stick ();

        this.destroy.connect (application.quit);

        tabview.notify["selected-page"].connect (() => {
            var captive_view = (TabbedWebView) tabview.get_selected_page ().child;
            title_label.label = captive_view.title;
            cert_button.security = captive_view.security;
        });

        tabview.close_page.connect ((page) => {
            tabview.close_page_finish (page, true);

            if (tabview.n_pages == 0) {
                application.quit ();
            }

            return Gdk.EVENT_STOP;
        });
    }

    bool is_privacy_mode_enabled () {
        var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");
        return !privacy_settings.get_boolean ("remember-recent-files") ||
               !privacy_settings.get_boolean ("remember-app-usage");
    }
    private TabbedWebView create_tab (string uri) {
        var webview = new TabbedWebView (!is_privacy_mode_enabled ());
        webview.load_uri (uri);

        var tabpage = tabview.append (webview);

        show_all ();

        webview.bind_property ("title", tabpage, "title");

        webview.notify["title"].connect ((view, param_spec) => {
            if (tabpage == tabview.get_selected_page ()) {
                title_label.set_text (webview.title);
            }
        });

        webview.notify["security"].connect ((view, param_spec) => {
            if (tabpage == tabview.get_selected_page ()) {
                cert_button.security = webview.security;
            }
        });

        webview.create.connect ((navigation_action)=> {
            create_tab (navigation_action.get_request ().get_uri ());

            return null;
        });

        webview.decide_policy.connect ((decision, type) => {
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

        return webview;
    }

    public bool get_tls_info (out TlsCertificate certificate, out TlsCertificateFlags errors) {
        var web_view = (TabbedWebView) tabview.get_selected_page ().child;

        return web_view.get_tls_info (out certificate, out errors);
    }

    public string get_uri () {
        var web_view = (TabbedWebView) tabview.get_selected_page ().child;

        return web_view.get_uri ();
    }

    public void start (string? browser_url) {
        var default_tab = create_tab (browser_url ?? DUMMY_URL);

        default_tab.load_failed.connect ((event, uri, error) => {
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
        Captive.Application.settings.set_int ("window-width", window_width);
        Captive.Application.settings.set_int ("window-height", window_height);
        if (is_maximized) {
            Captive.Application.settings.set_boolean ("is-maximized", true);
        } else {
            Captive.Application.settings.set_boolean ("is-maximized", false);
        }

        return false;
    }
}
