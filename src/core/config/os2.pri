include(common.pri)

gn_args += \
    use_sysroot=false \
    enable_session_service=false \
    is_multi_dll_chrome=false

# No clang for OS/2 ATM.
gn_args += is_clang=false use_lld=false

!contains(QT_CONFIG, no-pkg-config) {
    # Strip '>2 /dev/null' from $$pkgConfigExecutable()
    PKGCONFIG = $$first($$list($$pkgConfigExecutable()))
    gn_args += pkg_config=\"$$PKGCONFIG\"
    PKG_CONFIG_HOST = $$(GN_PKG_CONFIG_HOST)
    pkgConfigLibDir = $$(PKG_CONFIG_LIBDIR)
    pkgConfigSysrootDir = $$(PKG_CONFIG_SYSROOT_DIR)
    isEmpty(PKG_CONFIG_HOST): cross_compile {
        !isEmpty(pkgConfigLibDir)|!isEmpty(pkgConfigSysrootDir) {
            PKG_CONFIG_HOST = $$pkgConfigHostExecutable()
        }
    }
    isEmpty(PKG_CONFIG_HOST): PKG_CONFIG_HOST = $$QMAKE_PKG_CONFIG_HOST
    gn_args += host_pkg_config=\"$$PKG_CONFIG_HOST\"
}

qtConfig(webengine-system-zlib) {
    qtConfig(webengine-system-minizip): gn_args += use_system_zlib=true use_system_minizip=true
    qtConfig(webengine-printing-and-pdf): gn_args += pdfium_use_system_zlib=true
}
qtConfig(webengine-system-png) {
    gn_args += use_system_libpng=true
    qtConfig(webengine-printing-and-pdf): gn_args += pdfium_use_system_libpng=true
}
qtConfig(webengine-system-jpeg): gn_args += use_system_libjpeg=true
qtConfig(webengine-system-freetype): gn_args += use_system_freetype=true
qtConfig(webengine-system-harfbuzz): gn_args += use_system_harfbuzz=true

qtConfig(webengine-system-libevent): gn_args += use_system_libevent=true
qtConfig(webengine-system-libwebp):  gn_args += use_system_libwebp=true
qtConfig(webengine-system-libxml2):  gn_args += use_system_libxml=true use_system_libxslt=true
qtConfig(webengine-system-opus):     gn_args += use_system_opus=true
qtConfig(webengine-system-snappy):   gn_args += use_system_snappy=true
qtConfig(webengine-system-libvpx):   gn_args += use_system_libvpx=true
qtConfig(webengine-system-icu):      gn_args += use_system_icu=true icu_use_data_file=false
qtConfig(webengine-system-ffmpeg):   gn_args += use_system_ffmpeg=true
qtConfig(webengine-system-re2):      gn_args += use_system_re2=true
qtConfig(webengine-system-lcms2):    gn_args += use_system_lcms2=true
