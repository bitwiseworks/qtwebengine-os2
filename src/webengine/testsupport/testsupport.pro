CXX_MODULE = qml
TARGET = qtwebenginetestsupportplugin
TARGET_SHORT = qtwebt
TARGETPATH = QtWebEngine/testsupport
IMPORT_VERSION = 1.0

QT += qml quick
QT_PRIVATE += webengine-private gui-private

SOURCES = plugin.cpp

load(qml_plugin)
