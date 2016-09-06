configure_file(org.pantheon.capnet-assist.desktop ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.capnet-assist.desktop)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.capnet-assist.desktop DESTINATION share/applications)
