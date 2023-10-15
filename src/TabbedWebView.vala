/*
* Copyright 2016-2023 elementary, Inc. (https://elementary.io)
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

public class Captive.TabbedWebView : WebKit.WebView {
    public bool load_cookies { get; construct; }
    public Security security { get; private set; }
    public Gcr.SimpleCertificate? certificate { get; private set; default = null; }

    public enum Security {
        NONE,
        SECURE,
        LOADING,
        MIXED_CONTENT;

        public string to_icon_name () {
            switch (this) {
                case NONE:
                    return "security-low-symbolic";

                case SECURE:
                    return "security-high-symbolic";

                case MIXED_CONTENT:
                    return "security-medium-symbolic";

                case LOADING:
                default:
                    return "content-loading-symbolic";
            };
        }
    }

    public TabbedWebView (bool load_cookies) {
        Object (load_cookies: load_cookies);
    }

    construct {
        if (load_cookies) {
            var cookies_db_path = Path.build_path (
                Path.DIR_SEPARATOR_S,
                Environment.get_user_config_dir (),
                "epiphany",
                "cookies.sqlite"
            );

            if (FileUtils.test (cookies_db_path, FileTest.IS_REGULAR)) {
                var cookie_manager = get_context ().get_cookie_manager ();

                cookie_manager.set_accept_policy (WebKit.CookieAcceptPolicy.ALWAYS);
                cookie_manager.set_persistent_storage (cookies_db_path, WebKit.CookiePersistentStorage.SQLITE);
            } else {
                critical ("No cookies store found, not saving the cookies…");
            }
        }

        insecure_content_detected.connect (() => {
            security = MIXED_CONTENT;
        });

        load_changed.connect ((view, event) => {
            switch (event) {
                case WebKit.LoadEvent.STARTED:
                    security = LOADING;
                    break;
                case WebKit.LoadEvent.COMMITTED:
                    update_tls_info ();
                    break;
            }
        });
    }

    public string security_to_string () {
        switch (security) {
            case NONE:
                return _("“%s” is served over an unprotected connection").printf (get_uri ());

            case SECURE:
                return _("“%s” is served over a protected connection").printf (get_uri ());

            case MIXED_CONTENT:
                return _("Some elements of “%s” are served over an unprotected connection").printf (get_uri ());

            case LOADING:
            default:
                return _("Loading captive portal");
        };
    }

    private void update_tls_info () {
        TlsCertificate cert;
        TlsCertificateFlags cert_flags;
        bool is_secure;

        if (!get_tls_info (out cert, out cert_flags)) {
            // The page is served over HTTP
            is_secure = false;
            certificate = null;
        } else {
            // The page is served over HTTPS, if cert_flags is set then there's
            // some problem with the certificate provided by the website.
            is_secure = (cert_flags == 0);
            certificate = new Gcr.SimpleCertificate (cert.certificate.data);
        }

        if (is_secure) {
            security = SECURE;
        } else {
            security = NONE;
        }
    }
}
