/*
* Copyright (c) 2016 elementary LLC (http://launchpad.net/capnet-assist)
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
*
*/

public class CertButton : Gtk.ToggleButton {

    public enum Security {
        NONE,
        SECURE,
        MIXED_CONTENT,
    }

    public CertButton () {

    }

    construct {
        image = new Gtk.Image.from_icon_name ("content-loading-symbolic", Gtk.IconSize.BUTTON);
        sensitive = false;

        var style_context = get_style_context ();
        style_context.add_class (Gtk.STYLE_CLASS_FLAT);
        style_context.add_class ("titlebutton");
    }
}
