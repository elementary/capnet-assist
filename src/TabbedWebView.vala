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
    public CertButton.Security security { get; private set; }

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
            security = CertButton.Security.MIXED_CONTENT;
        });

        load_changed.connect ((view, event) => {
            switch (event) {
                case WebKit.LoadEvent.STARTED:
                    security = CertButton.Security.LOADING;
                    break;
                case WebKit.LoadEvent.COMMITTED:
                    update_tls_info ();
                    break;
            }
        });
    }

    private void update_tls_info () {
        TlsCertificate cert;
        TlsCertificateFlags cert_flags;
        bool is_secure;

        if (!get_tls_info (out cert, out cert_flags)) {
            // The page is served over HTTP
            is_secure = false;
        } else {
            // The page is served over HTTPS, if cert_flags is set then there's
            // some problem with the certificate provided by the website.
            is_secure = (cert_flags == 0);
        }

        if (is_secure) {
            security = CertButton.Security.SECURE;
        } else {
            security = CertButton.Security.NONE;
        }
    }
}
