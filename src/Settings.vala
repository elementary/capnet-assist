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
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*/

public class Captive.Settings : Granite.Services.Settings {
    public enum WindowState {
        NORMAL,
        MAXIMIZED,
        FULLSCREEN
    }

    public int window_width { get; set; }
    public int window_height { get; set; }
    public WindowState window_state { get; set; }
    public bool enabled { get; set; }

    private static Settings main_settings;
    public static unowned Settings get_default () {
        if (main_settings == null)
            main_settings = new Settings ();
        return main_settings;
    }

    public Settings () {
        base ("io.elementary.desktop.capnet-assist");
    }
}
