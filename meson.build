project(
    'io.elementary.capnet-assist',
    'vala', 'c',
    version: '8.0.0',
    meson_version: '>= 0.57',
    default_options: 'sysconfdir=/etc'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), '-DGCR_API_SUBJECT_TO_CHANGE', language:'c')

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
    'src/MainWindow.vala',
    'src/TabbedWebView.vala',
    dependencies: [
        dependency('gcr-4'),
        dependency('gio-2.0'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite-7', version: '>=7.0.0'),
        dependency('gtk4'),
        dependency('libadwaita-1', version: '>=1.0.0'),
        dependency('webkitgtk-6.0')
    ],
    install : true
)

gnome.post_install(glib_compile_schemas: true)

subdir('data')
subdir('po')
