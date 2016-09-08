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
        LOADING,
        MIXED_CONTENT,
    }

    public Security security {
        set {
            Icon icon;
            string tooltip;

            switch (value) {
                case Security.LOADING:
                    icon = new ThemedIcon ("content-loading-symbolic");
                    tooltip = _("Loading captive portal.");
                    break;
                case Security.NONE:
                    icon = new ThemedIcon.from_names ({"channel-insecure-symbolic", "security-low"});
                    tooltip = _("The page is served over an unprotected connection.");
                    break;

                case Security.SECURE:
                    icon = new ThemedIcon.from_names ({"channel-secure-symbolic", "security-high"});
                    tooltip = _("The page is served over a protected connection.");
                    break;

                case Security.MIXED_CONTENT:
                    icon = new ThemedIcon.from_names ({"channel-insecure-symbolic", "security-low"});
                    tooltip = _("Some elements of this page are served over an unprotected connection.");
                    break;

                default:
                    assert_not_reached ();
            }

            image = new Gtk.Image.from_gicon (icon, Gtk.IconSize.BUTTON);
            tooltip_text = tooltip;
            set_sensitive (value != CertButton.Security.NONE && value != CertButton.Security.LOADING);
        }
    }

    public CertButton () {
        Object (security: Security.LOADING);
    }

    construct {
        var style_context = get_style_context ();
        style_context.add_class (Gtk.STYLE_CLASS_FLAT);
        style_context.add_class ("titlebutton");
    }
}
