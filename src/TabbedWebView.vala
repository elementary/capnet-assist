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
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
*/

public class TabbedWebView : Granite.Widgets.Tab {
    public WebKit.WebView web_view;
    public CertButton.Security security { get; private set; }

    public TabbedWebView (string uri, bool load_cookies) {
        web_view = new WebKit.WebView ();

        page = web_view;

        setup_web_view (load_cookies);

        web_view.insecure_content_detected.connect (() => {
            security = CertButton.Security.MIXED_CONTENT;
        });

        web_view.notify["title"].connect ((view, param_spec) => {
            label = web_view.get_title ();
        });

        web_view.load_changed.connect ((view, event) => {
            switch (event) {
                case WebKit.LoadEvent.STARTED:
                    security = CertButton.Security.LOADING;
                    break;
                case WebKit.LoadEvent.COMMITTED:
                    update_tls_info ();
                    break;
            }
        });

        web_view.load_uri (uri);
    }

    private void update_tls_info () {
        TlsCertificate cert;
        TlsCertificateFlags cert_flags;
        bool is_secure;

        if (!web_view.get_tls_info (out cert, out cert_flags)) {
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

    private void setup_web_view (bool load_cookies) {
        if (load_cookies) {
            var cookies_db_path = Path.build_path (Path.DIR_SEPARATOR_S,
                                                   Environment.get_user_config_dir (),
                                                   "epiphany",
                                                   "cookies.sqlite");

            if (!FileUtils.test (cookies_db_path, FileTest.IS_REGULAR)) {
                debug ("No cookies store found, not saving the cookies...\n");
                return;
            }

            var cookie_manager = web_view.get_context ().get_cookie_manager ();

            cookie_manager.set_accept_policy (WebKit.CookieAcceptPolicy.ALWAYS);
            cookie_manager.set_persistent_storage (cookies_db_path, WebKit.CookiePersistentStorage.SQLITE);
        }
    }
}
