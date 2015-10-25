/***
    BEGIN LICENSE

    Copyright (C) 2015 elementary LLC.
    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/

public class ValaBrowser : Gtk.Window {

    private const string TITLE = "Log in";
    private const string DUMMY_URL = "https://elementary.io";
    
    private WebKit.WebView web_view;
    private Gtk.Button tls_button;
    private Gtk.Label title_label;
    
    public ValaBrowser () {
        set_default_size (1000, 680);
        set_keep_above (true);
        set_skip_taskbar_hint (true);

        create_widgets ();
        connect_signals ();
    }

    private void create_widgets () {
        var header = new Gtk.HeaderBar ();
        header.set_show_close_button (true);
        header.get_style_context ().remove_class ("header-bar");

        this.set_titlebar (header);

        this.tls_button = new Gtk.Button ();
        this.tls_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        this.tls_button.set_no_show_all (true);
        this.tls_button.button_release_event.connect (on_tls_button_click);

        var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        hbox.pack_start (this.tls_button);
        this.title_label = new Gtk.Label (ValaBrowser.TITLE);
        this.title_label.get_style_context ().add_class (Gtk.STYLE_CLASS_TITLE);
        hbox.pack_start (title_label);

        header.set_custom_title (hbox);

        this.web_view = new WebKit.WebView ();

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scrolled_window.add (this.web_view);

        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        vbox.set_homogeneous (false);
        vbox.pack_start (scrolled_window, true, true, 0);

        add (vbox);
    }
    
    public bool isLoggedIn () {
        var network_monitor = NetworkMonitor.get_default ();

        // No connection is available at the moment, don't bother trying the
        // connectivity check
        if (!network_monitor.get_network_available ()) {
            return true;
        }

        var page = "http://connectivitycheck.android.com/generate_204";
        debug ("Getting 204 page");

        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", page);

        session.send_message (message);

        debug ("Return code: %u", message.status_code);
        return message.status_code == 204;
    }

    private void update_tls_info () {
        TlsCertificate cert;
        TlsCertificateFlags cert_flags;
        Icon icon;
        bool is_secure;

        if (!this.web_view.get_tls_info (out cert, out cert_flags)) {
            // The page is served over HTTP
            is_secure = false;
        } else {
            // The page is served over HTTPS, if cert_flags is set then there's
            // some problem with the certificate provided by the website.
            is_secure = (cert_flags == 0);
        }

        if (is_secure) {
            icon = new ThemedIcon.from_names ({"channel-secure-symbolic", "security-high"});
            this.tls_button.set_tooltip_text ("The page is served over a protected connection.");
        } else {
            icon = new ThemedIcon.from_names ({"channel-insecure-symbolic", "security-low"});
            this.tls_button.set_tooltip_text ("The page is served over an unprotected connection.");
        }

        var image = new Gtk.Image.from_gicon (icon, Gtk.IconSize.BUTTON);
        this.tls_button.set_image (image);
    }

    private bool on_tls_button_click (Gdk.EventButton event) {
        TlsCertificate cert;
        TlsCertificateFlags cert_flags;

        if (!this.web_view.get_tls_info (out cert, out cert_flags)) {
            return true;
        }

        var popover = new Gtk.Popover (this.tls_button);
        popover.set_border_width (6);
        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        vbox.set_homogeneous (false);
        popover.add (vbox);
        var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        hbox.set_homogeneous (false);
        // Wonderful hack we got here, the vapi for Gtk has a wrong definition
        // for the get_gicon () method, it's not reported as an out parameter
        // hence we're stuck with passing everything by value.
        // Since we're badass we pass the INVALID constant that evaluates to 0
        // which is casted into a NULL pointer and allows us to save the date.
        Icon button_icon;
        (this.tls_button.get_image () as Gtk.Image).get_gicon (out button_icon, Gtk.IconSize.INVALID);
        hbox.pack_start (new Gtk.Image.from_gicon (button_icon, Gtk.IconSize.LARGE_TOOLBAR), false, false);
        hbox.pack_start (new Gtk.Label (this.tls_button.get_tooltip_text ()), false, false);
        vbox.pack_start (hbox, false, false);

        var gcr_cert = new Gcr.SimpleCertificate (cert.certificate.data);
        var cert_details = new Gcr.CertificateWidget (gcr_cert);
        vbox.pack_start (cert_details);

        // This hack has been borrowed from midori, the widget provided by the
        // GCR library would fail with an assertion when the 'details' button was
        // clicked
        popover.button_press_event.connect ((event) => {
            return true;
        });
        popover.button_release_event.connect ((event) => {
            var child = popover.get_child ();
            var event_widget = Gtk.get_event_widget (event);

            if (child != null && event.window == popover.get_window ()) {
                Gtk.Allocation child_alloc;
                popover.get_allocation (out child_alloc);

                if (event.x < child_alloc.x ||
                    event.x > child_alloc.x + child_alloc.width ||
                    event.y < child_alloc.y ||
                    event.y > child_alloc.y + child_alloc.height) {
                    popover.hide ();
                }

            } 
            else if (event_widget != null && !event_widget.is_ancestor (popover)) {
                popover.hide ();
            }

            return true;
        });

        popover.show_all ();

        return true;
    }

    private void connect_signals () {
        this.destroy.connect (Gtk.main_quit);
        //should title change?
        this.web_view.notify["title"].connect ((view, param_spec) => {
            this.title_label.set_text (this.web_view.get_title ());
        });

        this.web_view.load_changed.connect ((view, event) => {
            switch (event) {
            case WebKit.LoadEvent.FINISHED:
                if (isLoggedIn ()) {
                    debug ("Logged in!");
                    Gtk.main_quit ();
                } else {
                    debug ("Still not logged in.");
                }
                break;

            case WebKit.LoadEvent.STARTED:
                this.tls_button.hide ();
                break;

            case WebKit.LoadEvent.COMMITTED:
                update_tls_info ();
                this.tls_button.show ();
                break;
            }
        });

        this.web_view.load_failed.connect ((event, uri, error) => {
            // The user has canceled the page loading eg. by clicking on a link.
            if ((Error)error is WebKit.NetworkError.CANCELLED) {
                return true;
            }

            Gtk.main_quit ();
            return true;
        });
    }

    public void start () {
        show_all ();
        this.web_view.load_uri (ValaBrowser.DUMMY_URL);
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        var browser = new ValaBrowser ();

        if (!browser.isLoggedIn ()) {
            debug ("Opening browser to login");
            browser.start ();
            Gtk.main ();
        } else {
            debug ("Already logged in and connected, shutting down.");
        }

        return 0;
    }
}
