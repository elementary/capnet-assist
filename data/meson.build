install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

desktop_file = i18n.merge_file(
    'desktop',
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'desktop'
)

test (
    'Validate desktop file',
    find_program('desktop-file-validate'),
    args: desktop_file
)
