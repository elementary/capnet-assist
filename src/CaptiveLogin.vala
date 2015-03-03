using Gtk;

public class ValaBrowser : Window {

    private const string TITLE = "Log in";
    private const string DUMMY_URL = "http://elementary.io";
    
    private WebKit.WebView web_view;
    
    public ValaBrowser () {
        set_default_size (1000, 680);

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
        var scrolled_window = new ScrolledWindow (null, null);
        scrolled_window.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scrolled_window.add (this.web_view);
        var vbox = new Box (Gtk.Orientation.VERTICAL, 0);
        vbox.set_homogeneous (false);
        vbox.pack_start (scrolled_window,true,true,0);
        add (vbox);
    }
    
    public bool isLoggedIn () {
        var page = "http://clients3.google.com/generate_204";
        stdout.printf ("Getting 204 page\n");

        var session = new Soup.SessionAsync ();
        var message = new Soup.Message ("GET", page);

        session.send_message (message);

        stdout.printf ("Return code: %u\n",message.status_code);
        return message.status_code == 204;
    }

    private void connect_signals () {
        this.destroy.connect (Gtk.main_quit);
        //should title change?
        this.web_view.title_changed.connect ((source, frame, title) => {
            this.title = "%s - %s".printf (title, ValaBrowser.TITLE);
        });
        
        this.web_view.document_load_finished.connect ( (frame) => {
            if (isLoggedIn ()) {
                stdout.printf ("Logged in!\n");
                Gtk.main_quit ();
            } else
                stdout.printf ("Still not logged in.\n");
            stdout.flush ();
        });
    }
    
    public void start () {
        show_all ();
        this.web_view.open (ValaBrowser.DUMMY_URL);
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        var browser = new ValaBrowser ();
        
        if (!browser.isLoggedIn ()){
            stdout.printf ("Opening browser to login\n");
            browser.start ();
            Gtk.main ();
        } else {
            stdout.printf ("Already logged in and connected, shutting down.\n");
        }

        return 0;
    }
}
