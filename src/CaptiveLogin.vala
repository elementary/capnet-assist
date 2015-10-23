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
    private const string DUMMY_URL = "http://elementary.io";
    
    private WebKit.WebView web_view;
    
    public ValaBrowser () {
        set_default_size (1000, 680);
        set_keep_above (true);
        set_skip_taskbar_hint (true);

        var header = new Gtk.HeaderBar ();
        header.set_show_close_button (true);
        header.get_style_context ().remove_class ("header-bar");

        this.set_titlebar (header);
        this.title = ValaBrowser.TITLE;

        create_widgets ();
        connect_signals ();
    }

    private void create_widgets () {
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

    private void connect_signals () {
        this.destroy.connect (Gtk.main_quit);
        //should title change?
        this.web_view.notify["title"].connect ((view, param_spec) => {
            this.title = this.web_view.get_title ();
        });

        this.web_view.load_changed.connect ((view, event) => {
            if (event == WebKit.LoadEvent.FINISHED) {
                if (isLoggedIn ()) {
                    debug ("Logged in!");
                    Gtk.main_quit ();
                } else {
                    debug ("Still not logged in.");
                }
            }
        });

        this.web_view.load_failed.connect ((event, uri, error) => {
            if (error is WebKit.NetworkError.CANCELLED)
                return true;

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
