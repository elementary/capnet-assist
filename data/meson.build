install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

install_data(
    meson.project_name () + '.desktop',
    install_dir: join_paths(get_option('datadir'), 'applications')
)

test (
    'Validate desktop file',
    find_program('desktop-file-validate'),
    args: join_paths(meson.current_source_dir (), meson.project_name () + '.desktop')
)
