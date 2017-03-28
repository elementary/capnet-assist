configure_file(io.elementary.capnet-assist.desktop ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.capnet-assist.desktop)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.capnet-assist.desktop DESTINATION share/applications)

include (GSettings)

add_schema (io.elementary.capnet-assist.gschema.xml)
