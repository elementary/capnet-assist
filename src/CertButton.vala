/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2016-2023 elementary, Inc. (https://elementary.io)
 */

public class Captive.CertButton : Gtk.MenuButton {
    public MainWindow captive_login_window { get; construct set; }

    public enum Security {
        NONE,
        SECURE,
        LOADING,
        MIXED_CONTENT,
    }

    private Security _security = LOADING;
    public Security security {
        get {
            return _security;
        }
        set {
            _security = value;

            var uri = captive_login_window.get_uri ();

            switch (value) {
                case LOADING:
                    icon_name = "content-loading-symbolic";
                    tooltip_text = _("Loading captive portal.");
                    break;

                case NONE:
                    icon_name = "security-low-symbolic";
                    tooltip_text = _("“%s” is served over an unprotected connection").printf (uri);
                    break;

                case SECURE:
                    icon_name = "security-high-symbolic";
                    tooltip_text = _("“%s” is served over a protected connection").printf (uri);
                    break;

                case MIXED_CONTENT:
                    icon_name = "security-medium-symbolic";
                    tooltip_text = _("Some elements of “%s” are served over an unprotected connection").printf (uri);
                    break;
            }

            popover_label.label = tooltip_text;

            if (security == SECURE) {
                popover_label.get_style_context ().remove_class (Gtk.STYLE_CLASS_WARNING);
                popover_label.get_style_context ().add_class ("success");
            } else {
                popover_label.get_style_context ().remove_class ("success");
                popover_label.get_style_context ().add_class (Gtk.STYLE_CLASS_WARNING);
            }

            popover_image.icon_name = icon_name.replace ("-symbolic", "");

            image = new Gtk.Image.from_icon_name (icon_name, BUTTON);
            sensitive = value != CertButton.Security.NONE && value != CertButton.Security.LOADING;
        }
    }

    private Granite.HeaderLabel cert_subject;
    private Gtk.Image popover_image;
    private Gtk.Label cert_expiry;
    private Gtk.Label cert_issuer;
    private Gtk.Label popover_label;
    private string icon_name = "content-loading-symbolic";

    public CertButton (MainWindow captive_login_window) {
        Object (captive_login_window: captive_login_window);
    }

    construct {
        var style_context = get_style_context ();
        style_context.add_class (Gtk.STYLE_CLASS_FLAT);
        style_context.add_class ("titlebutton");

        popover_image = new Gtk.Image () {
            pixel_size = 48,
            valign = START
        };

        popover_label = new Gtk.Label ("") {
            xalign = 0,
            max_width_chars = 55,
            wrap = true,
            wrap_mode = WORD_CHAR
        };
        popover_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        cert_subject = new Granite.HeaderLabel ("");

        cert_issuer = new Gtk.Label ("") {
            halign = START,
            margin_start = 12
        };

        cert_expiry = new Gtk.Label ("") {
            halign = START,
            margin_start = 12,
            margin_bottom = 6
        };

        var cert_box = new Gtk.Box (VERTICAL, 3);
        cert_box.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        cert_box.add (cert_subject);
        cert_box.add (cert_issuer);
        cert_box.add (cert_expiry);

        var frame = new Gtk.Frame (null) {
            child = cert_box,
            margin_top = 12
        };

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin = 12
        };
        grid.attach (popover_image, 0, 0, 1, 2);
        grid.attach (popover_label, 1, 0);
        grid.attach (frame, 1, 1);
        grid.show_all ();

        popover = new Gtk.Popover (this) {
            child = grid
        };

        toggled.connect (on_tls_button_click);
    }

    private void on_tls_button_click () {
        TlsCertificate cert;
        TlsCertificateFlags cert_flags;

        if (!active) {
            return;
        }

        if (!captive_login_window.get_tls_info (out cert, out cert_flags)) {
            active = false;
            return;
        }

        var gcr_cert = new Gcr.SimpleCertificate (cert.certificate.data);

        Time time;
        gcr_cert.expiry.to_time (out time);

        cert_expiry.label = _("Expires %s").printf (
            time.format (Granite.DateTime.get_default_date_format (false, true, true))
        );

        cert_issuer.label = _("Issued by “%s”").printf (gcr_cert.issuer);

        cert_subject.label = gcr_cert.subject;
    }
}
