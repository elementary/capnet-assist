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

    private enum HeaderButtonState {
        LOADING,
        WARNING,
        SECURITY_NONE,
        SECURITY_SECURE,
        SECURITY_MIXED_CONTENT,
    }

    private const string TITLE = _("Log in");
    private const string DUMMY_URL = "http://elementary.io/capnet-assist";
    private const string GENERATE_204_URL = "http://connectivitycheck.android.com/generate_204";
    
    private WebKit.WebView web_view;
    private Gtk.Stack stack;
    private Granite.Widgets.AlertView alert_view;
    private Gtk.ToggleButton header_button;
    private Gtk.Label title_label;
    
    private uint web_view_retries = 0;
    private const uint MAX_RETRIES = 3;
    // Flag used to check if web_view.load_failed was triggered before web_view.load_changed
    private bool load_failed = false;
    private HeaderButtonState header_button_state = HeaderButtonState.SECURITY_NONE;
    // Is false if any pages successfully finished loading
    private bool first_load = true;
    
    public ValaBrowser () {
        setup_ui ();
        connect_signals ();
        setup_web_view ();
        
        init ();
    }
    
    public async void init () {
        if (yield is_captive_portal ()) {
            debug ("Opening browser to login");
            web_view.load_uri (DUMMY_URL);
        } else {
            debug ("Already logged in and connected, or no internet connection. Shutting down.");
            Gtk.main_quit ();
        }
    }
    
    public static async void sleep_async(int timeout, GLib.Cancellable? cancellable = null) {
        ulong cancel = 0;
        uint timeout_src = 0;
        if (cancellable != null) {
         if (cancellable.is_cancelled ()) 
                return;
         cancel = cancellable.cancelled.connect (()=>sleep_async.callback());
        }
        timeout_src = Timeout.add(timeout, sleep_async.callback);
        yield;
        Source.remove (timeout_src);

        if (cancel != 0 && ! cancellable.is_cancelled ()) {
            cancellable.disconnect (cancel);
        }
    }

    bool is_privacy_mode_enabled () {
        var privacy_settings = new GLib.Settings ("org.gnome.desktop.privacy");
        
        return !privacy_settings.get_boolean ("remember-recent-files") ||
                !privacy_settings.get_boolean ("remember-app-usage");
    }

    private void setup_web_view () {
        if (!is_privacy_mode_enabled ()) {
            var cookies_db_path = Path.build_path (Path.DIR_SEPARATOR_S,
                                                   Environment.get_user_config_dir (),
                                                   "epiphany",
                                                   "cookies.sqlite");

            if (!FileUtils.test (cookies_db_path, FileTest.IS_REGULAR)) {
                debug ("No cookies store found, not saving the cookies...\n");
                return;
            }

            var cookie_manager = web_view.get_context ().get_cookie_manager ();

            cookie_manager.set_accept_policy (WebKit.CookieAcceptPolicy.ALWAYS);
            cookie_manager.set_persistent_storage (cookies_db_path, WebKit.CookiePersistentStorage.SQLITE);
        }
    }

    private void setup_ui () {
        header_button = new Gtk.ToggleButton ();
        
        var header_button_style_context = header_button.get_style_context ();
        header_button_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
        header_button_style_context.add_class ("titlebutton");
        header_button.set_sensitive (false);
        header_button.toggled.connect (on_header_button_click);

        var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        hbox.set_margin_top (3);
        hbox.set_margin_bottom (3);
        hbox.pack_start (header_button);

        title_label = new Gtk.Label (ValaBrowser.TITLE);
        title_label.get_style_context ().add_class (Gtk.STYLE_CLASS_TITLE);
        hbox.pack_start (title_label);

        var header = new Gtk.HeaderBar ();
        header.set_show_close_button (true);
        header.get_style_context ().add_class ("compact");
        header.set_custom_title (hbox);
        
        set_titlebar (header);

        web_view = new WebKit.WebView ();
        
        alert_view = new Granite.Widgets.AlertView (
           _("Could not establish connection to captive portal."), 
           _("We detected a captive portal connection, but we were unable to connect to it.\nConsider going closer to the access point for a better connection."), 
           "network-error"
        );
        alert_view.show_action (_("Retry connection"));
        
        stack = new Gtk.Stack ();
        stack.add (web_view);
        stack.add (alert_view);
          
        set_default_size (1240, 900);
        set_keep_above (true);
        set_skip_taskbar_hint (true);
        stick ();
        add (stack);
    }
    
    public bool is_connected () {
        var network_monitor = NetworkMonitor.get_default ();
 
         // No connection is available at the moment, don't bother trying the
         // connectivity check
         if (network_monitor.get_connectivity () != NetworkConnectivity.FULL) {
             return false;
         }

        return true;
    }
    
    /*
     * If there is an active connection to the internet, this will 
     * successfully connect to the connectivity checker and return 204. 
     * If there is no internet connection (including no captive portal), this
     * request will fail and libsoup will return a transport failure status 
     * code (<100).
     * Otherwise, libsoup will resolve the redirect to the captive portal, 
     * which will return status code 200.
     */    
    public async uint get_connectivity_soup_response () {
        var connectivity_retries = 0;
        var session = new Soup.Session ();
        Soup.Message message = null;
        
        do {
             message = new Soup.Message ("GET", GENERATE_204_URL);
     
             session.send_message (message);
     
             debug ("Return code: %u", message.status_code); 
             
             if(message.status_code > 0 && message.status_code < 100) { 
                // The condition above is libsoup's SOUP_STATUS_IS_TRANSPORT_ERROR macro
                debug ("Transport error, retrying check");
                connectivity_retries++;
                yield sleep_async (3000);
                continue;
             } else {
                break;
             }
        } while(connectivity_retries < MAX_RETRIES);
        
        return message.status_code;
    }
    
    public async bool is_logged_in () {
        debug ("Checking logged in");
        return is_connected () &&  (yield get_connectivity_soup_response ()) == 204;
    }
    
    public async bool is_captive_portal () {
        debug ("Checking captive portal");
        return is_connected () && (yield get_connectivity_soup_response ())  == 200;
    }

    private HeaderButtonState get_tls_state () {
        TlsCertificate cert;
        TlsCertificateFlags cert_flags;
        bool is_secure;

        if (!web_view.get_tls_info (out cert, out cert_flags)) {
            // The page is served over HTTP
            is_secure = false;
        } else {
            // The page is served over HTTPS, if cert_flags is set then there's
            // some problem with the certificate provided by the website.
            is_secure = (cert_flags == 0);
        }

        if (is_secure) {
            return HeaderButtonState.SECURITY_SECURE;
        } else {
            return HeaderButtonState.SECURITY_NONE;
        }
    }

    private void update_header_button (HeaderButtonState new_state) {
        header_button_state = new_state;
    
        Icon icon;
        string tooltip;

        switch (header_button_state) {
            case HeaderButtonState.SECURITY_NONE:
                icon = new ThemedIcon.from_names ({"channel-insecure-symbolic", "security-low"});
                tooltip = _("The page is served over an unprotected connection.");
                break;

            case HeaderButtonState.SECURITY_SECURE:
                icon = new ThemedIcon.from_names ({"channel-secure-symbolic", "security-high"});
                tooltip = _("The page is served over a protected connection.");
                break;

            case HeaderButtonState.SECURITY_MIXED_CONTENT:
                icon = new ThemedIcon.from_names ({"channel-insecure-symbolic", "security-low"});
                tooltip = _("Some elements of this page are served over an unprotected connection.");
                break;
            
            case HeaderButtonState.WARNING:
                icon = new ThemedIcon.from_names ({"dialog-warning-symbolic", "dialog-warning"});
                tooltip = _("Some elements of this page are served over an unprotected connection.");
                break;
                
            case HeaderButtonState.LOADING:
                icon = new ThemedIcon ("content-loading-symbolic");
                tooltip = _("Loading captive portal.");
            break;

            default:
                assert_not_reached ();
        }

        header_button.set_image (new Gtk.Image.from_gicon (icon, Gtk.IconSize.BUTTON));
        header_button.set_tooltip_text (tooltip);
        header_button.set_sensitive (
            header_button_state == HeaderButtonState.SECURITY_MIXED_CONTENT ||
            header_button_state == HeaderButtonState.SECURITY_SECURE
        );
    }

    private void on_header_button_click () {
        TlsCertificate cert;
        TlsCertificateFlags cert_flags;

        if (!header_button.get_active ()) {
            return;
        }
        if (!web_view.get_tls_info (out cert, out cert_flags)) {
            header_button.set_active (false);
            return;
        }

        var popover = new Gtk.Popover (header_button);
        popover.set_border_width (12);

        // Wonderful hack we got here, the vapi for Gtk has a wrong definition
        // for the get_gicon () method, it's not reported as an out parameter
        // hence we're stuck with passing everything by value.
        // Since we're badass we pass the INVALID constant that evaluates to 0
        // which is casted into a NULL pointer and allows us to save the date.
        Icon button_icon;
#if VALA_0_30
        ((Gtk.Image) header_button.get_image ()).get_gicon (out button_icon, null);
#else
        ((Gtk.Image) header_button.get_image ()).get_gicon (out button_icon, Gtk.IconSize.INVALID);
#endif

        var icon = new Gtk.Image.from_gicon (button_icon, Gtk.IconSize.DIALOG);
        if (header_button_state == HeaderButtonState.SECURITY_SECURE) {
            icon.get_style_context ().add_class ("success");
        } else {
            icon.get_style_context ().add_class ("warning");
        }
        icon.valign = Gtk.Align.START;

        var primary_text = new Gtk.Label (web_view.get_uri());
        primary_text.get_style_context ().add_class ("h3");
        primary_text.halign = Gtk.Align.START;
        primary_text.margin_start = 9;

        var secondary_text = new Gtk.Label (header_button.get_tooltip_text ());
        if (header_button_state == HeaderButtonState.SECURITY_SECURE) {
            secondary_text.get_style_context ().add_class ("success");
        } else {
            secondary_text.get_style_context ().add_class ("warning");
        }
        secondary_text.halign = Gtk.Align.START;
        secondary_text.margin_start = 9;

        var gcr_cert = new Gcr.SimpleCertificate (cert.certificate.data);
        var cert_details = new Gcr.CertificateWidget (gcr_cert);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 3;
        grid.attach (icon, 0, 0, 1, 2);
        grid.attach (primary_text, 1, 0, 1, 1);
        grid.attach (secondary_text, 1, 1, 1, 1);
        grid.attach (cert_details, 1, 2, 1, 1);
        
        popover.add (grid);

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
                    header_button.set_active (false);
                }
            } else if (event_widget != null && !event_widget.is_ancestor (popover)) {
                popover.hide ();
                header_button.set_active (false);
            }

            return true;
        });

        popover.show_all ();

        return;
    }

    private void connect_signals () {
        this.destroy.connect (Gtk.main_quit);
        
        web_view.notify["title"].connect ((view, param_spec) => {
            title_label.set_text (web_view.get_title ());
        });

        web_view.load_changed.connect ((view, event) => {
            switch (event) {
                case WebKit.LoadEvent.FINISHED:
                    debug("Load finished");
                    
                    web_view_load_finished ();
                    
                    if (!load_failed) { 
                        update_header_button (HeaderButtonState.SECURITY_NONE);
                        
                        first_load = false;
                    }
                    
                    break;

                case WebKit.LoadEvent.STARTED:
                    debug("Started");

                    load_failed = false;
                    update_header_button (HeaderButtonState.LOADING);
                    break;

                case WebKit.LoadEvent.COMMITTED:
                    debug("Committed");
                    
                    update_header_button (get_tls_state ());
                    break;
            }
        });

        web_view.insecure_content_detected.connect (() => {
            update_header_button (HeaderButtonState.SECURITY_MIXED_CONTENT);
        });

        web_view.load_failed.connect ((event, uri, error) => {
            // The user has canceled the page loading eg. by clicking on a link.
            if ((Error)error is WebKit.NetworkError.CANCELLED) {
                return true;
            }
            debug ("Load failed");
            
            load_failed = true;

            if (web_view_retries < MAX_RETRIES && first_load) {
                /*
                 * The signal is load_failed, but the webview is only ever requested to run
                 * when is_captive_portal returns true. So if we're unable to load it now, 
                 * it means we're on a faulty connection.
                 */
                debug("Faulty connection, retrying in 3 seconds");
                update_header_button (HeaderButtonState.LOADING);
                
                Timeout.add (3000, () => { 
                    debug("Reloading");
                    
                    reload (false);
                    
                    return false;
                });
                web_view_retries++;
            } else {
                show_alert_view ();
            }
           
            return true;
        });
        
        alert_view.action_activated.connect (() => {            
            reload ();
            
            show_web_view ();
        });
    }
    
    public async void web_view_load_finished () {
        if (load_failed) {
            return;
        }
        
        is_logged_in.begin ((obj, res) => {
            if (is_logged_in.end(res)) {
                debug ("Logged in!");
                
                if(!visible) {
                    Gtk.main_quit ();
                }
            } else {
                debug ("Still not logged in.");
                
                show_web_view ();
            }
        });
    }
    
    public async void reload (bool reset = true) {
        if (reset) {
            web_view_retries = 0; 
        }
        
        if (web_view.uri == "") {
            web_view.load_uri (DUMMY_URL);
        } else {
            web_view.reload ();
        }
    }
    
    
    public void show_alert_view () {
        debug ("Showing alert view");
        
        if (!visible) {
            show_all ();
        }
        
        update_header_button (HeaderButtonState.WARNING);        
        stack.visible_child = alert_view;
    }
    
    public void show_web_view () {
        debug ("Showing web view");
        
        if (!visible) {
            show_all ();
        }
        
        stack.visible_child = web_view;
    }
    
    public static int main (string[] args) {
        Gtk.init (ref args);

        var browser = new ValaBrowser ();
        
        Gtk.main ();
        
        return 0;
    }
}
