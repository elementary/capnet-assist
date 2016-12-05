pkg_check_modules(DEPS REQUIRED
    gtk+-3.0
    gio-2.0
    webkit2gtk-4.0
    granite>=0.3
    gcr-3
    gcr-ui-3
)
add_definitions(${DEPS_CFLAGS})

link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

set(CFLAGS
    ${DEPS_CFLAGS}
    -D_VERSION=\"${VERSION}\"
    -D_INSTALL_PREFIX=\"${CMAKE_INSTALL_PREFIX}\"
    -D_SOURCE_ROOT_DIR=\"${CMAKE_SOURCE_DIR}\"
    -DGCR_API_SUBJECT_TO_CHANGE
    -g
)

set(CAPTIVE_LOGIN_PACKAGES
    gtk+-3.0
    gio-2.0
    webkit2gtk-4.0
    granite
    gcr-3
    gcr-ui-3
)

set(VALAC_OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --target-glib=${TARGET_GLIB}
    --thread
    -g
)

vala_precompile(VALA_C
    config.vala
    Application.vala
    CaptiveLogin.vala
    CertButton.vala
    TabbedWebView.vala
PACKAGES
    ${CAPTIVE_LOGIN_PACKAGES}
OPTIONS
    ${VALAC_OPTIONS}
)

add_definitions(${CFLAGS})

#Here we define our executable name.
add_executable(captive-login ${VALA_C} )

install (TARGETS captive-login RUNTIME DESTINATION bin)
