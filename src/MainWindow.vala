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

public class Captive.MainWindow : Gtk.ApplicationWindow {
    private const string DUMMY_URL = "http://capnet.elementary.io";

    private Adw.TabView tabview;
    private Granite.HeaderLabel cert_subject;
    private Gtk.Image popover_image;
    private Gtk.Label cert_expiry;
    private Gtk.Label cert_issuer;
    private Gtk.Label popover_label;
    private Gtk.Label title_label;
    private Gtk.MenuButton cert_button;

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
        popover_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

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
        cert_box.add_css_class (Granite.STYLE_CLASS_VIEW);
        cert_box.append (cert_subject);
        cert_box.append (cert_issuer);
        cert_box.append (cert_expiry);

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

        var popover = new Gtk.Popover () {
            child = grid
        };

        cert_button = new Gtk.MenuButton () {
            popover = popover
        };
        cert_button.add_css_class ("titlebutton");

        title_label = new Gtk.Label (_("Log in"));
        title_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var header_box = new Gtk.Box (HORIZONTAL, 6);
        header_box.append (cert_button);
        header_box.append (title_label);

        titlebar = new Gtk.HeaderBar () {
            title_widget = header_box,
            show_title_buttons = true
        };
        titlebar.add_css_class ("default-decoration");

        tabview = new Adw.TabView () {
            hexpand = true,
            vexpand = true
        };

        var tabbar = new Adw.TabBar () {
            expand_tabs = false,
            inverted = true,
            view = tabview
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.append (tabbar);
        box.append (tabview);

        child = box;

        tabview.notify["selected-page"].connect (() => {
            var webview = (TabbedWebView) tabview.get_selected_page ().child;
            title_label.label = webview.title;
            update_security (webview);
        });

        tabview.close_page.connect ((page) => {
            tabview.close_page_finish (page, true);

            if (tabview.n_pages == 0) {
                application.quit ();
            }

            return Gdk.EVENT_STOP;
        });
    }

    private void update_security (TabbedWebView web_view) {
        cert_button.icon_name = icon_name = web_view.security.to_icon_name ();
        cert_button.tooltip_text = web_view.security_to_string ();

        popover_label.label = cert_button.tooltip_text;

        if (web_view.security == SECURE) {
            popover_label.css_classes = {"success"};
        } else {
            popover_label.css_classes = {Granite.STYLE_CLASS_WARNING};
        }

        popover_image.icon_name = cert_button.icon_name.replace ("-symbolic", "");

        cert_button.sensitive = web_view.security != NONE && web_view.security != LOADING;

        if (web_view.certificate == null) {
            cert_button.active = false;
            return;
        }

        cert_expiry.label = _("Expires %s").printf (
            web_view.certificate.expiry_date.format (Granite.DateTime.get_default_date_format (false, true, true))
        );

        cert_issuer.label = _("Issued by “%s”").printf (web_view.certificate.issuer_name);

        cert_subject.label = web_view.certificate.subject_name;
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
                update_security (webview);
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
                        var policy = (WebKit.ResponsePolicyDecision) decision;
                        create_tab (policy.request.get_uri ());
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
                default:
                    break;
            }

            return true;
        });

        webview.load_uri (uri);

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

        present ();
    }
}
