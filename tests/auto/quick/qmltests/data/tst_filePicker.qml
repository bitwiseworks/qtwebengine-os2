/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the QtWebEngine module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:GPL-EXCEPT$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 as published by the Free Software
** Foundation with exceptions as appearing in the file LICENSE.GPL3-EXCEPT
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.0
import QtTest 1.0
import QtWebEngine 1.2
import "../mock-delegates/TestParams" 1.0

TestWebEngineView {
    id: webEngineView
    width: 400
    height: 300

    function driveLetter() {
        if (Qt.platform.os !== "windows")
            return "";
        return "C:/";
    }

    SignalSpy {
        id: titleSpy
        target: webEngineView
        signalName: "titleChanged"
    }
    SignalSpy {
        id: terminationSpy
        target: webEngineView
        signalName: "renderProcessTerminated"
    }

    TestCase {
        name: "WebEngineViewSingleFileUpload"
        when: windowShown

        function init() {
            FilePickerParams.filePickerOpened = false
            FilePickerParams.selectFiles = false
            FilePickerParams.selectedFilesUrl = []
            titleSpy.clear()
            terminationSpy.clear()
        }

        function cleanup() {
            // Test that the render process doesn't crash, and make sure if it does it does so now.
            wait(1000)
            verify(terminationSpy.count == 0, "Render process didn't self terminate")

            // FIXME: Almost every second url loading progress does get stuck at about 90 percent, so the loadFinished signal won't arrive.
            // This cleanup function is a workaround for this problem.
            webEngineView.url = Qt.resolvedUrl("about:blank")
            webEngineView.waitForLoadSucceeded()
        }

        function test_acceptSingleFileSelection_data() {
            return [
                   { tag: driveLetter() + "/test.txt", input: driveLetter() + "/test.txt", expected: "test.txt" },
                   { tag: driveLetter() + "test.txt", input: driveLetter() + "test.txt", expected: "Failed to Upload" },
                   { tag: driveLetter() + "/tést.txt", input: driveLetter() + "/tést.txt", expected: "tést.txt" },
                   { tag: driveLetter() + "/t%65st.txt", input: driveLetter() + "/t%65st.txt", expected: "t%65st.txt" },
                   { tag: "file:///" + driveLetter() + "test.txt", input: "file:///" + driveLetter() + "test.txt", expected: "test.txt" },
                   { tag: "file:///" + driveLetter() + "tést.txt", input: "file:///" + driveLetter() + "tést.txt", expected: "tést.txt" },
                   { tag: "file:///" + driveLetter() + "t%65st.txt", input: "file:///" + driveLetter() + "t%65st.txt", expected: "test.txt" },
                   { tag: "file://" + driveLetter() + "test.txt", input: "file://" + driveLetter() + "test.txt", expected: "test.txt" },
                   { tag: "file:/" + driveLetter() + "test.txt", input: "file:/" + driveLetter() + "test.txt", expected: "test.txt"},
                   { tag: "file:test//test.txt", input: "file:test//test.txt", expected: "Failed to Upload" },
                   { tag: "http://test.txt", input: "http://test.txt", expected: "Failed to Upload" },
                   { tag: "qrc:/test.txt", input: "qrc:/test.txt", expected: "Failed to Upload" },
            ];
        }

        function test_acceptSingleFileSelection(row) {
            var expectedFileName;

            // Default dialog
            webEngineView.url = Qt.resolvedUrl("singlefileupload.html");
            verify(webEngineView.waitForLoadSucceeded());

            FilePickerParams.selectFiles = true;
            FilePickerParams.selectedFilesUrl.push(row.input);

            keyClick(Qt.Key_Enter); // Focus is on the button. Open FileDialog.
            tryCompare(FilePickerParams, "filePickerOpened", true);
            tryCompare(webEngineView, "title", row.expected);


            // Custom dialog
            var finished = false;

            function acceptedFileHandler(request) {
                request.accepted = true;
                request.dialogAccept(row.input);
                finished = true;
            }

            webEngineView.fileDialogRequested.connect(acceptedFileHandler);
            webEngineView.url = Qt.resolvedUrl("singlefileupload.html");
            verify(webEngineView.waitForLoadSucceeded());

            keyClick(Qt.Key_Enter); // Focus is on the button. Open FileDialog.
            tryVerify(function() { return finished; });
            tryCompare(webEngineView, "title", row.expected);
            webEngineView.fileDialogRequested.disconnect(acceptedFileHandler);
        }

        function test_acceptMultipleFilesSelection() {
            webEngineView.url = Qt.resolvedUrl("multifileupload.html")
            verify(webEngineView.waitForLoadSucceeded())

            FilePickerParams.selectFiles = true
            FilePickerParams.selectedFilesUrl.push(Qt.resolvedUrl("test1.html"))
            FilePickerParams.selectedFilesUrl.push(Qt.resolvedUrl("test2.html"))

            keyPress(Qt.Key_Enter) // Focus is on the button. Open FileDialog.
            tryCompare(FilePickerParams, "filePickerOpened", true)
            tryCompare(webEngineView, "title", "test1.html,test2.html")
        }

        function test_acceptDirectory() {
            webEngineView.url = Qt.resolvedUrl("directoryupload.html")
            verify(webEngineView.waitForLoadSucceeded())

            FilePickerParams.selectFiles = true
            FilePickerParams.selectedFilesUrl.push(Qt.resolvedUrl("../data"))

            keyClick(Qt.Key_Enter) // Focus is on the button. Open FileDialog.
            tryCompare(FilePickerParams, "filePickerOpened", true)
            // Check that the title is a file list (eg. "test1.html,test2.html")
            tryVerify(function() { return webEngineView.title.match("^([^,]+,)+[^,]+$"); })
        }

        function test_reject() {
            webEngineView.url = Qt.resolvedUrl("singlefileupload.html")
            verify(webEngineView.waitForLoadSucceeded())

            titleSpy.clear()
            keyPress(Qt.Key_Enter) // Focus is on the button. Open FileDialog.
            wait(100)
            compare(titleSpy.count, 0)
        }

        function test_acceptMultipleFilesWithCustomDialog_data() {
            return [
                   { tag: "path", input: [driveLetter() + "/test1.txt", driveLetter() + "/test2.txt"], expectedValue: "test1.txt,test2.txt" },
                   { tag: "file", input: ["file:///" + driveLetter() + "test1.txt", "file:/" + driveLetter() + "test2.txt"], expectedValue: "test1.txt,test2.txt" },
                   { tag: "mixed", input: ["file:///" + driveLetter() + "test1.txt", driveLetter() + "/test2.txt"], expectedValue: "test1.txt,test2.txt" },
            ];
        }

        function test_acceptMultipleFilesWithCustomDialog(row) {
            // Default dialog
            webEngineView.url = Qt.resolvedUrl("multifileupload.html");
            verify(webEngineView.waitForLoadSucceeded());

            FilePickerParams.selectFiles = true;
            FilePickerParams.selectedFilesUrl = row.input;

            keyClick(Qt.Key_Enter); // Focus is on the button. Open FileDialog.
            tryCompare(FilePickerParams, "filePickerOpened", true);
            tryCompare(webEngineView, "title", row.expectedValue);


            // Custom dialog
            var finished = false;

            function acceptedFileHandler(request) {
                request.accepted = true;
                request.dialogAccept(row.input);
                finished = true;
            }

            webEngineView.fileDialogRequested.connect(acceptedFileHandler);
            webEngineView.url = Qt.resolvedUrl("multifileupload.html");
            verify(webEngineView.waitForLoadSucceeded());

            keyClick(Qt.Key_Enter); // Focus is on the button. Open FileDialog.
            tryVerify(function() { return finished; });
            tryCompare(webEngineView, "title", row.expectedValue);
            webEngineView.fileDialogRequested.disconnect(acceptedFileHandler);
        }

        function test_acceptFileOnWindows_data() {
            return [
                   { tag: "C:test.txt", input: "C:test.txt", expected: "Failed to Upload"},
                   { tag: "C:test:txt", input: "C:test:txt", expected: "Failed to Upload"},
                   { tag: "C:/test.txt", input: "C:/test.txt", expected: "test.txt"},
                   { tag: "C:\\test.txt", input: "C:\\test.txt", expected: "test.txt"},
                   { tag: "C:\\Documents and Settings\\test\\test.txt", input: "C:\\Documents and Settings\\test\\test.txt", expected: "test.txt"},
                   { tag: "\\\\applib\\products\\a%2Db\\ abc%5F9\\t.est\\test.txt", input: "file://applib/products/a%2Db/ abc%5F9/4148.920a/media/test.txt", expected: "test.txt"},
                   { tag: "file://applib/products/a%2Db/ abc%5F9/t.est/test.txt", input: "file://applib/products/a%2Db/ abc%5F9/4148.920a/media/test.txt", expected: "test.txt"},
                   { tag: "file://applib/products/a-b/abc_1/t.est/test.txt", input: "file://applib/products/a-b/abc_1/t.est/test.txt", expected: "test.txt"},
                   { tag: "file:\\\\applib\\products\\a-b\\abc_1\\t:est\\test.txt", input: "file:\\\\applib\\products\\a-b\\abc_1\\t:est\\test.txt", expected: "test.txt"},
                   { tag: "file:C:/test.txt", input: "file:C:/test.txt", expected: "Failed to Upload"},
                   { tag: "file:/C:/test.txt", input: "file:/C:/test.txt", expected: "Failed to Upload"},
                   { tag: "file://C:/test.txt", input: "file://C:/test.txt", expected: "Failed to Upload"},
                   { tag: "file:///C:test.txt", input: "file:///C:test.txt", expected: "Failed to Upload"},
                   { tag: "file:///C:/test.txt", input: "file:///C:/test.txt", expected: "test.txt"},
                   { tag: "file:///C:\\test.txt", input: "file:///C:\\test.txt", expected: "test.txt"},
                   { tag: "file:\\//C:/test.txt", input: "file:\\//C:/test.txt", expected: "test.txt"},
                   { tag: "file:\\\\/C:\\test.txt", input: "file:\\\\/C:\\test.txt", expected: "test.txt"},
                   { tag: "\\\\?\\C:/test.txt", input: "\\\\?\\C:/test.txt", expected: "Failed to Upload"},
            ];
        }

        function test_acceptFileOnWindows(row) {
            if (Qt.platform.os !== "windows")
                skip("Windows-only test");

            // Default dialog
            webEngineView.url = Qt.resolvedUrl("singlefileupload.html");
            verify(webEngineView.waitForLoadSucceeded());

            FilePickerParams.selectFiles = true;
            FilePickerParams.selectedFilesUrl.push(row.input);

            keyClick(Qt.Key_Enter); // Focus is on the button. Open FileDialog.
            tryCompare(FilePickerParams, "filePickerOpened", true);
            tryCompare(webEngineView, "title", row.expected);


            // Custom dialog
            var finished = false;

            function acceptedFileHandler(request) {
                request.accepted = true;
                request.dialogAccept(row.input);
                finished = true;
            }

            webEngineView.fileDialogRequested.connect(acceptedFileHandler);
            webEngineView.url = Qt.resolvedUrl("singlefileupload.html");
            verify(webEngineView.waitForLoadSucceeded());

            keyClick(Qt.Key_Enter); // Focus is on the button. Open FileDialog.
            tryVerify(function() { return finished; });
            tryCompare(webEngineView, "title", row.expected);
            webEngineView.fileDialogRequested.disconnect(acceptedFileHandler);
        }
    }
}