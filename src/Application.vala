/*
* Copyright (c) 2016 elementary LLC (https://launchpad.net/capnet-assist)
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
*/

public class Captive.Application : Gtk.Application {
    private bool force_show = false;
    private string? debug_url = null;

    public Application () {
        Object (application_id: "org.pantheon.captive-login", flags: ApplicationFlags.HANDLES_COMMAND_LINE);
    }

    private bool is_captive_portal () {
        var network_monitor = NetworkMonitor.get_default ();

        // No connection is available at the moment, don't bother trying the
        // connectivity check
        if (network_monitor.get_connectivity () != NetworkConnectivity.FULL) {
            return true;
        }

        var page = "http://connectivitycheck.android.com/generate_204";
        debug ("Getting 204 page");

        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", page);

        session.send_message (message);

        debug ("Return code: %u", message.status_code);

        /*
         * If there is an active connection to the internet, this will
         * successfully connect to the connectivity checker and return 204.
         * If there is no internet connection (including no captive portal), this
         * request will fail and libsoup will return a transport failure status
         * code (<100).
         * Otherwise, libsoup will resolve the redirect to the captive portal,
         * which will return status code 200.
         */
        return message.status_code == 200;
    }

    public override void activate () {
        var settings = new Settings ();
        if (!settings.enabled) {
            quit ();
            return;
        }

        if (!is_busy) {
            mark_busy ();

            var browser = new CaptiveLogin (this);
            if (is_captive_portal () || force_show) {
                debug ("Opening browser to login");
                browser.start (debug_url);
            } else {
                debug ("Already logged in and connected, or no internet connection. Shutting down.");
                quit ();
            }
        }
    }

    public override int command_line (ApplicationCommandLine command_line) {
        OptionEntry[] options = new OptionEntry[2];
        options[0] = { "force-window", 'f', 0, OptionArg.NONE, ref force_show, "Force the browser window to appear", null };
        options[1] = { "url", 'u', 0, OptionArg.STRING, ref debug_url, "Load the folowing URL on the browser window", "URL" };

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
        Environment.set_application_name (Constants.APP_NAME);
        Environment.set_prgname (Constants.APP_NAME);

        var application = new Captive.Application ();

        return application.run (args);
    }
}
