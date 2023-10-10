/*
* Copyright 2015-2023 elementary, Inc. (https://elementary.io)
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

public class Captive.MainWindow : Hdy.ApplicationWindow {
    private const string DUMMY_URL = "http://capnet.elementary.io";

    private Granite.HeaderLabel cert_subject;
    private Gtk.Image popover_image;
    private Gtk.Label cert_expiry;
    private Gtk.Label cert_issuer;
    private Gtk.Label popover_label;
    private Gtk.Label title_label;
    private Gtk.MenuButton cert_button;
    private Hdy.TabView tabview;

    // When a download is passed to the browser, it triggers the load failed signal
    private bool download_requested = false;

    public MainWindow (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        popover_image = new Gtk.Image () {
            pixel_size = 48,
            valign = START
        };

        popover_label = new Gtk.Label ("") {
            xalign = 0,
            max_width_chars = 55,
            wrap = true,
            wrap_mode = WORD_CHAR
        };
        popover_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        cert_subject = new Granite.HeaderLabel ("");

        cert_issuer = new Gtk.Label ("") {
            halign = START,
            margin_start = 12
        };

        cert_expiry = new Gtk.Label ("") {
            halign = START,
            margin_start = 12,
            margin_bottom = 6
        };

        var cert_box = new Gtk.Box (VERTICAL, 3);
        cert_box.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        cert_box.add (cert_subject);
        cert_box.add (cert_issuer);
        cert_box.add (cert_expiry);

        var frame = new Gtk.Frame (null) {
            child = cert_box,
            margin_top = 12
        };

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };
        grid.attach (popover_image, 0, 0, 1, 2);
        grid.attach (popover_label, 1, 0);
        grid.attach (frame, 1, 1);
        grid.show_all ();

        var popover = new Gtk.Popover (null) {
            child = grid
        };

        cert_button = new Gtk.MenuButton () {
            popover = popover
        };
        cert_button.get_style_context ().add_class ("titlebutton");

        title_label = new Gtk.Label (_("Log in"));
        title_label.get_style_context ().add_class (Gtk.STYLE_CLASS_TITLE);

        var header_box = new Gtk.Box (HORIZONTAL, 6);
        header_box.add (cert_button);
        header_box.add (title_label);

        var header = new Hdy.HeaderBar () {
            custom_title = header_box,
            show_close_button = true
        };
        header.get_style_context ().add_class ("default-decoration");

        tabview = new Hdy.TabView () {
            hexpand = true,
            vexpand = true
        };

        var tabbar = new Hdy.TabBar () {
            expand_tabs = false,
            inverted = true,
            view = tabview
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.add (header);
        box.add (tabbar);
        box.add (tabview);

        child = box;

        tabview.notify["selected-page"].connect (() => {
            var webview = (TabbedWebView) tabview.get_selected_page ().child;
            title_label.label = webview.title;
            update_security (webview.security);
        });

        tabview.close_page.connect ((page) => {
            tabview.close_page_finish (page, true);

            if (tabview.n_pages == 0) {
                application.quit ();
            }

            return Gdk.EVENT_STOP;
        });
    }

    private void update_security (TabbedWebView.Security security) {
        var web_view = (TabbedWebView) tabview.get_selected_page ().child;
        var uri = web_view.get_uri ();

        string icon_name = "content-loading-symbolic";

        switch (security) {
            case LOADING:
                icon_name = "content-loading-symbolic";
                cert_button.tooltip_text = _("Loading captive portal.");
                break;

            case NONE:
                icon_name = "security-low-symbolic";
                cert_button.tooltip_text = _("“%s” is served over an unprotected connection").printf (uri);
                break;

            case SECURE:
                icon_name = "security-high-symbolic";
                cert_button.tooltip_text = _("“%s” is served over a protected connection").printf (uri);
                break;

            case MIXED_CONTENT:
                icon_name = "security-medium-symbolic";
                cert_button.tooltip_text = _("Some elements of “%s” are served over an unprotected connection").printf (uri);
                break;
        }

        cert_button.image = new Gtk.Image.from_icon_name (icon_name, BUTTON);
        popover_label.label = cert_button.tooltip_text;

        if (security == SECURE) {
            popover_label.get_style_context ().remove_class (Gtk.STYLE_CLASS_WARNING);
            popover_label.get_style_context ().add_class ("success");
        } else {
            popover_label.get_style_context ().remove_class ("success");
            popover_label.get_style_context ().add_class (Gtk.STYLE_CLASS_WARNING);
        }

        popover_image.icon_name = icon_name.replace ("-symbolic", "");

        cert_button.sensitive = security != NONE && security != LOADING;

        TlsCertificate cert;
        TlsCertificateFlags cert_flags;

        if (!web_view.get_tls_info (out cert, out cert_flags)) {
            cert_button.active = false;
            return;
        }

        var gcr_cert = new Gcr.SimpleCertificate (cert.certificate.data);

        Time time;
        gcr_cert.expiry.to_time (out time);

        cert_expiry.label = _("Expires %s").printf (
            time.format (Granite.DateTime.get_default_date_format (false, true, true))
        );

        cert_issuer.label = _("Issued by “%s”").printf (gcr_cert.issuer);

        cert_subject.label = gcr_cert.subject;
    }

    private bool is_privacy_mode_enabled () {
        var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");
        return !privacy_settings.get_boolean ("remember-recent-files") ||
               !privacy_settings.get_boolean ("remember-app-usage");
    }

    private TabbedWebView create_tab (string uri) {
        var webview = new TabbedWebView (!is_privacy_mode_enabled ());
        var tabpage = tabview.append (webview);

        webview.bind_property ("title", tabpage, "title", SYNC_CREATE);

        webview.notify["title"].connect ((view, param_spec) => {
            if (tabpage == tabview.get_selected_page ()) {
                title_label.set_text (webview.title);
            }
        });

        webview.notify["security"].connect ((view, param_spec) => {
            if (tabpage == tabview.get_selected_page ()) {
                update_security (webview.security);
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

        webview.load_uri (uri);
        show_all ();

        return webview;
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

        return false;
    }
}
