/*
* Copyright (c) 2016 lementary Developers (https://launchpad.net/capnet-assist)
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

    public Application () {
        Object (application_id: "org.pantheon.captive-login");
    }

    public override void activate () {
        if (!is_busy) {
            mark_busy ();

            var browser = new ValaBrowser (this);
            if (browser.is_captive_portal ()) {
                debug ("Opening browser to login");
                browser.start ();
            } else {
                debug ("Already logged in and connected, or no internet connection. Shutting down.");
                quit ();
            }
        }
    }

    public static int main (string[] args) {
        Environment.set_application_name (Constants.APP_NAME);
        Environment.set_prgname (Constants.APP_NAME);

        var application = new Captive.Application ();

        return application.run (args);
    }
}
