project(
    'io.elementary.capnet-assist',
    'vala', 'c',
    version: '2.4.4',
    meson_version: '>= 0.57',
    default_options: 'sysconfdir=/etc'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="captive-login"', '-DGCR_API_SUBJECT_TO_CHANGE', language:'c')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

executable(
    meson.project_name(),
    config_file,
    'src/Application.vala',
    'src/CertButton.vala',
    'src/MainWindow.vala',
    'src/TabbedWebView.vala',
    dependencies: [
        dependency('gcr-3'),
        dependency('gio-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('libhandy-1', version: '>=1.0.0'),
        dependency('webkit2gtk-4.1')
    ],
    install : true
)

gnome.post_install(glib_compile_schemas: true)

subdir('data')
subdir('po')
