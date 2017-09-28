/*
* Copyright (c) 2016-2017 elementary LLC (https://launchpad.net/capnet-assist)
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
*/

public class Captive.Application : Gtk.Application {
    private bool force_show = false;
    private string? debug_url = null;

    public Application () {
        Object (application_id: "io.elementary.capnet-assist", flags: ApplicationFlags.HANDLES_COMMAND_LINE);
    }

    private bool is_captive_portal () {
        var network_monitor = NetworkMonitor.get_default ();
        return network_monitor.get_connectivity () = NetworkConnectivity.PORTAL;
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
