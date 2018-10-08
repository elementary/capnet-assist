/*
* Copyright (c) 2016-2017 elementary LLC (http://launchpad.net/capnet-assist)
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
*
*/

public class CertButton : Gtk.ToggleButton {

    public enum Security {
        NONE,
        SECURE,
        LOADING,
        MIXED_CONTENT,
    }

    private Security _security;

    public Security security {
        get {
            return _security;
        }
        set {
            _security = value;

            Icon icon;
            string tooltip;

            switch (value) {
                case Security.LOADING:
                    icon = new ThemedIcon ("content-loading-symbolic");
                    tooltip = _("Loading captive portal.");
                    break;
                case Security.NONE:
                    icon = new ThemedIcon ("security-low-symbolic");
                    tooltip = _("The page is served over an unprotected connection.");
                    break;

                case Security.SECURE:
                    icon = new ThemedIcon ("security-high-symbolic");
                    tooltip = _("The page is served over a protected connection.");
                    break;

                case Security.MIXED_CONTENT:
                    icon = new ThemedIcon ("security-medium-symbolic");
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

    public CaptiveLogin captive_login_window {
        get; set construct;
    }

    public CertButton (CaptiveLogin captive_login_window) {
        Object (security: Security.LOADING, captive_login_window: captive_login_window);
    }

    construct {
        var style_context = get_style_context ();
        style_context.add_class (Gtk.STYLE_CLASS_FLAT);
        style_context.add_class ("titlebutton");

        toggled.connect (on_tls_button_click);
    }

    private void on_tls_button_click () {
        TlsCertificate cert;
        TlsCertificateFlags cert_flags;

        if (!get_active ()) {
            return;
        }

        if (!captive_login_window.get_tls_info (out cert, out cert_flags)) {
            set_active (false);
            return;
        }

        var popover = new Gtk.Popover (this);
        popover.border_width = 12;

        // Wonderful hack we got here, the vapi for Gtk has a wrong definition
        // for the get_gicon () method, it's not reported as an out parameter
        // hence we're stuck with passing everything by value.
        // Since we're badass we pass the INVALID constant that evaluates to 0
        // which is casted into a NULL pointer and allows us to save the date.
        Icon button_icon;
#if VALA_0_30
        ((Gtk.Image) get_image ()).get_gicon (out button_icon, null);
#else
        ((Gtk.Image) get_image ()).get_gicon (out button_icon, Gtk.IconSize.INVALID);
#endif

        var icon = new Gtk.Image.from_gicon (button_icon, Gtk.IconSize.DIALOG);
        icon.valign = Gtk.Align.START;

        var primary_text = new Gtk.Label (captive_login_window.get_uri());
        primary_text.get_style_context ().add_class ("h3");
        primary_text.halign = Gtk.Align.START;
        primary_text.margin_start = 9;
        primary_text.max_width_chars = 70;
        primary_text.wrap = true;
        primary_text.wrap_mode = Pango.WrapMode.WORD_CHAR;

        var secondary_text = new Gtk.Label (get_tooltip_text ());
        secondary_text.halign = Gtk.Align.START;
        secondary_text.margin_start = 9;

        if (security == CertButton.Security.SECURE) {
            icon.get_style_context ().add_class ("success");
            secondary_text.get_style_context ().add_class ("success");
        } else {
            icon.get_style_context ().add_class ("warning");
            secondary_text.get_style_context ().add_class ("warning");
        }

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
                    set_active (false);
                }
            } else if (event_widget != null && !event_widget.is_ancestor (popover)) {
                popover.hide ();
                set_active (false);
            }

            return true;
        });

        popover.show_all ();

        return;
    }
}
