project(
    'io.elementary.capnet-assist',
    'vala', 'c',
    version: '2.3.0',
    default_options: 'sysconfdir=/etc'
)

i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="captive-login"', '-DGCR_API_SUBJECT_TO_CHANGE', language:'c')

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/CaptiveLogin.vala',
    'src/CertButton.vala',
    'src/TabbedWebView.vala',
    dependencies: [
        dependency('gcr-3'),
        dependency('gcr-ui-3'),
        dependency('gio-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('libhandy-1', version: '>=1.0.0'),
        dependency('webkit2gtk-4.0')
    ],
    install : true
)

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')

install_data(
    '90captive_portal_test',
    install_dir: join_paths(get_option('sysconfdir'), 'NetworkManager', 'dispatcher.d')
)
