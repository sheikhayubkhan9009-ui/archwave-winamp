 import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

PanelWindow {
    id: retroWinamp

    implicitWidth: (compactMode ? 110 : 275) * uiScale
    implicitHeight: (compactMode ? 78 : 116) * uiScale
    color: "transparent"
    anchors {
        top: true
        right: true
    }
    margins {
        top: retroWinamp.panelTopMargin
        right: retroWinamp.panelRightMargin
    }

    property var availablePlayers: Mpris.players.values
    property int playerIndex: 0
    property real uiScale: 1.0
    property bool compactMode: uiScale <= 0.85
    property int panelTopMargin: 0
    property int panelRightMargin: 0
    property real moveStartGlobalX: 0
    property real moveStartGlobalY: 0
    property int moveStartTopMargin: 0
    property int moveStartRightMargin: 0
    property bool playlistOpen: false
    property var player: availablePlayers.length > 0
                         ? availablePlayers[playerIndex % availablePlayers.length] : null
    property real systemVolume: 0.55
    property real systemBalance: 0.5
    property bool clock24Hour: true
    property string clockText: Qt.formatTime(new Date(), "HH:mm")
    property string distroId: "linux"
    property var distroLogoCandidates: []
    property int distroLogoCandidateIndex: 0
    property int themeIndex: widgetSettings.themeIndex
    property var palettes: [
        { name: "Classic", panel: "#bcbcc0", face: "#c9c9cd", highlight: "#ffffff", lightShade: "#e8e8ec", darkShade: "#85858a", shadow: "#303034", text: "#101014", screen: "#000000", accent: "#9999ff", track: "#a6a6ad", visualizer: "#68dc87" },
        { name: "Carbon", panel: "#252d33", face: "#3b4851", highlight: "#b7c8d0", lightShade: "#7f929b", darkShade: "#1d252a", shadow: "#101518", text: "#edf4f5", screen: "#080d10", accent: "#41d8c1", track: "#4a5860", visualizer: "#8effc2" },
        { name: "Aurora", panel: "#dfcdb1", face: "#f0dec3", highlight: "#fff6e3", lightShade: "#f6e7ce", darkShade: "#a58e6e", shadow: "#584936", text: "#30251b", screen: "#17140f", accent: "#d96b52", track: "#b6a07d", visualizer: "#f1c75b" },
        { name: "Matrix", panel: "#182a20", face: "#294333", highlight: "#a9d4ae", lightShade: "#64856b", darkShade: "#132219", shadow: "#08110b", text: "#d9f3dc", screen: "#030905", accent: "#57e879", track: "#31563c", visualizer: "#8effa4" },
        { name: "Arctic", panel: "#9dbbc5", face: "#c6e0e6", highlight: "#f3ffff", lightShade: "#e0f4f7", darkShade: "#66838c", shadow: "#263e45", text: "#122b33", screen: "#071318", accent: "#50d8ee", track: "#86abb5", visualizer: "#70f0ce" },
        { name: "Ember", panel: "#3a2521", face: "#59362e", highlight: "#f2c4a1", lightShade: "#a77b62", darkShade: "#2b1a17", shadow: "#160d0b", text: "#ffe4ce", screen: "#100705", accent: "#ff7957", track: "#70463a", visualizer: "#ffc15c" }
    ]
    property var palette: palettes[themeIndex]

    Settings {
        id: widgetSettings
        location: Qt.resolvedUrl("winamp-settings.ini")
        property int themeIndex: 0
    }

    onThemeIndexChanged: widgetSettings.themeIndex = themeIndex

    function beginPanelMove(dragArea, mouse) {
        var globalPosition = dragArea.mapToGlobal(Qt.point(mouse.x, mouse.y))
        moveStartGlobalX = globalPosition.x
        moveStartGlobalY = globalPosition.y
        moveStartTopMargin = panelTopMargin
        moveStartRightMargin = panelRightMargin
    }

    function movePanel(dragArea, mouse) {
        if (!screen)
            return
        var globalPosition = dragArea.mapToGlobal(Qt.point(mouse.x, mouse.y))
        var maxTop = Math.max(0, screen.height - implicitHeight)
        var maxRight = Math.max(0, screen.width - implicitWidth)
        panelTopMargin = Math.round(Math.max(0, Math.min(maxTop,
            moveStartTopMargin + globalPosition.y - moveStartGlobalY)))
        panelRightMargin = Math.round(Math.max(0, Math.min(maxRight,
            moveStartRightMargin - globalPosition.x + moveStartGlobalX)))
    }

    component BevelEdges: Item {
        id: bevel
        property bool pressed: false
        property color highlight: "#ffffff"
        property color lightShade: "#e8e8e8"
        property color darkShade: "#858585"
        property color shadow: "#303030"

        Rectangle {
            x: 0; y: 0; width: parent.width; height: 1
            color: bevel.pressed ? bevel.shadow : bevel.highlight
        }
        Rectangle {
            x: 0; y: 1; width: 1; height: parent.height - 2
            color: bevel.pressed ? bevel.darkShade : bevel.lightShade
        }
        Rectangle {
            x: 1; y: 1; width: parent.width - 2; height: 1
            color: bevel.pressed ? bevel.darkShade : bevel.lightShade
        }
        Rectangle {
            x: parent.width - 1; y: 0; width: 1; height: parent.height
            color: bevel.pressed ? bevel.highlight : bevel.shadow
        }
        Rectangle {
            x: 0; y: parent.height - 1; width: parent.width; height: 1
            color: bevel.pressed ? bevel.highlight : bevel.shadow
        }
        Rectangle {
            x: parent.width - 2; y: 1; width: 1; height: parent.height - 2
            color: bevel.pressed ? bevel.lightShade : bevel.darkShade
        }
        Rectangle {
            x: 1; y: parent.height - 2; width: parent.width - 2; height: 1
            color: bevel.pressed ? bevel.lightShade : bevel.darkShade
        }
    }

    function formatTime(positionSeconds) {
        var safeSeconds = Math.max(0, Math.floor(positionSeconds || 0))
        var minutes = Math.floor(safeSeconds / 60)
        var remainder = safeSeconds % 60
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
    }

    function currentFileName() {
        if (!player)
            return "NO MEDIA FILE"
        var sourceUrl = player.metadata ? player.metadata["xesam:url"] : ""
        if (sourceUrl) {
            var fileName = String(sourceUrl).split(/[?#]/)[0]
            fileName = fileName.substring(fileName.lastIndexOf("/") + 1)
            try {
                fileName = decodeURIComponent(fileName)
            } catch (error) {
            }
            if (fileName)
                return fileName
        }
        return player.trackTitle || "UNKNOWN TRACK"
    }

    function setVolumeAt(x, trackWidth) {
        if (trackWidth <= 0)
            return
        systemVolume = Math.max(0, Math.min(1, x / trackWidth))
        applyAudioSettings()
    }

    function setBalanceAt(x, trackWidth) {
        if (trackWidth <= 0)
            return
        systemBalance = Math.max(0, Math.min(1, x / trackWidth))
        applyAudioSettings()
    }

    function applyAudioSettings() {
        var leftVolume = systemVolume * Math.min(1, systemBalance * 2)
        var rightVolume = systemVolume * Math.min(1, (1 - systemBalance) * 2)
        volumeWriteProcess.command = [
            "/usr/bin/pactl", "set-sink-volume", "@DEFAULT_SINK@",
            Math.round(leftVolume * 100) + "%", Math.round(rightVolume * 100) + "%"
        ]
        volumeWriteTimer.restart()
    }

    function refreshAudioSettings() {
        if (!volumeReadProcess.running)
            volumeReadProcess.running = true
    }

    function updateClock() {
        clockText = Qt.formatTime(new Date(), clock24Hour ? "HH:mm" : "h:mm AP")
    }

    function toggleClockFormat() {
        clock24Hour = !clock24Hour
        updateClock()
    }

    function seekAt(x, trackWidth) {
        if (player && player.canSeek && player.length > 0 && trackWidth > 0)
            player.position = Math.max(0, Math.min(1, x / trackWidth)) * player.length
    }

    function cyclePlayer() {
        if (availablePlayers.length > 1)
            playerIndex = (playerIndex + 1) % availablePlayers.length
    }

    function skipBy(seconds) {
        if (player && player.canSeek && player.length > 0)
            player.position = Math.max(0, Math.min(player.length, player.position + seconds))
    }

    function eject() {
        if (playlistOpen)
            playlistOpen = false
        else
            visible = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: retroWinamp.updateClock()
    }

    Timer {
        id: volumeWriteTimer
        interval: 60
        onTriggered: {
            if (!volumeWriteProcess.running)
                volumeWriteProcess.running = true
        }
    }

    Process {
        id: volumeWriteProcess
        command: ["/usr/bin/pactl", "set-sink-volume", "@DEFAULT_SINK@", "55%", "55%"]
        onExited: {
            if (Math.abs(retroWinamp.systemVolume - lastWrittenVolume) > 0.005
                    || Math.abs(retroWinamp.systemBalance - lastWrittenBalance) > 0.005)
                volumeWriteTimer.restart()
            lastWrittenVolume = retroWinamp.systemVolume
            lastWrittenBalance = retroWinamp.systemBalance
        }
        property real lastWrittenVolume: -1
        property real lastWrittenBalance: -1
    }

    Process {
        command: ["/usr/bin/cat", "/etc/os-release"]
        stdout: StdioCollector {}
        Component.onCompleted: running = true
        onExited: function(exitCode) {
            if (exitCode !== 0)
                return
            var lines = stdout.text.split("\n")
            var logo = ""
            for (var i = 0; i < lines.length; ++i) {
                if (lines[i].indexOf("ID=") === 0)
                    retroWinamp.distroId = lines[i].substring(3).replace(/^\"|\"$/g, "")
                else if (lines[i].indexOf("LOGO=") === 0)
                    logo = lines[i].substring(5).replace(/^\"|\"$/g, "")
            }
            var iconName = logo || (retroWinamp.distroId + "-logo")
            if (iconName.charAt(0) === "/") {
                retroWinamp.distroLogoCandidates = [iconName]
            } else {
                var hasExtension = /\.(svg|png|xpm)$/i.test(iconName)
                var baseName = hasExtension ? iconName.replace(/\.(svg|png|xpm)$/i, "") : iconName
                retroWinamp.distroLogoCandidates = hasExtension
                    ? ["/usr/share/pixmaps/" + iconName]
                    : ["/usr/share/pixmaps/" + baseName + ".svg",
                       "/usr/share/pixmaps/" + baseName + ".png",
                       "/usr/share/pixmaps/" + baseName + ".xpm"]
            }
            retroWinamp.distroLogoCandidateIndex = 0
        }
    }

    Process {
        id: volumeReadProcess
        command: ["/usr/bin/pactl", "get-sink-volume", "@DEFAULT_SINK@"]
        stdout: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode !== 0)
                return
            var levels = stdout.text.match(/[0-9]+%/g)
            if (!levels || levels.length === 0)
                return
            var left = parseInt(levels[0], 10) / 100
            var right = levels.length > 1 ? parseInt(levels[1], 10) / 100 : left
            retroWinamp.systemVolume = Math.max(left, right)
            retroWinamp.systemBalance = left + right > 0 ? left / (left + right) : 0.5
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: retroWinamp.refreshAudioSettings()
    }

    Rectangle {
        width: retroWinamp.compactMode ? 110 : 275
        height: retroWinamp.compactMode ? 78 : 116
        scale: retroWinamp.uiScale
        transformOrigin: Item.TopLeft
        color: retroWinamp.palette.panel
        border.color: retroWinamp.palette.shadow
        border.width: 2

        BevelEdges {
            anchors.fill: parent
            anchors.margins: 1
            highlight: retroWinamp.palette.highlight
            lightShade: retroWinamp.palette.lightShade
            darkShade: retroWinamp.palette.darkShade
            shadow: retroWinamp.palette.shadow
        }

        Rectangle {
            id: titleBar
            visible: !retroWinamp.compactMode
            x: 1
            y: 1
            width: parent.width - 2
            height: 15
            color: retroWinamp.palette.panel

            Repeater {
                model: 4
                Rectangle {
                    x: 10
                    y: 3 + index * 2
                    width: titleBar.width - 20
                    height: 1
                    color: "#000000"
                }
            }

            Text {
                anchors.centerIn: parent
                text: "ARCHWAVE"
                color: "#000000"
                font.family: "Sans Serif"
                font.bold: true
                font.pixelSize: 10
                style: Text.Outline
                styleColor: "#ffffff"
            }

            MouseArea {
                id: titleDragArea
                x: 24
                width: 145
                height: parent.height
                cursorShape: Qt.SizeAllCursor
                onPressed: function(mouse) { retroWinamp.beginPanelMove(titleDragArea, mouse) }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        retroWinamp.movePanel(titleDragArea, mouse)
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 77
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 11
                color: retroWinamp.palette.face
                border.color: retroWinamp.palette.shadow
                border.width: 1

                BevelEdges {
                    anchors.fill: parent
                    pressed: compactToggleMouse.pressed
                    highlight: retroWinamp.palette.highlight
                    lightShade: retroWinamp.palette.lightShade
                    darkShade: retroWinamp.palette.darkShade
                    shadow: retroWinamp.palette.shadow
                }
                Text {
                    anchors.centerIn: parent
                    text: "MIN"
                    color: retroWinamp.palette.text
                    font.pixelSize: 5
                    font.bold: true
                }
                MouseArea {
                    id: compactToggleMouse
                    anchors.fill: parent
                    onClicked: retroWinamp.uiScale = 0.75
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 38
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 11
                color: retroWinamp.palette.face
                border.color: retroWinamp.palette.shadow
                border.width: 1

                BevelEdges {
                    anchors.fill: parent
                    pressed: themeMouse.pressed
                    highlight: retroWinamp.palette.highlight
                    lightShade: retroWinamp.palette.lightShade
                    darkShade: retroWinamp.palette.darkShade
                    shadow: retroWinamp.palette.shadow
                }
                Text {
                    anchors.centerIn: parent
                    text: retroWinamp.palette.name.substring(0, 3).toUpperCase()
                    color: retroWinamp.palette.text
                    font.pixelSize: 5
                    font.bold: true
                }
                MouseArea {
                    id: themeMouse
                    anchors.fill: parent
                    onClicked: retroWinamp.themeIndex = (retroWinamp.themeIndex + 1) % retroWinamp.palettes.length
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 11
                color: retroWinamp.palette.face
                border.color: retroWinamp.palette.shadow
                border.width: 1

                BevelEdges {
                    anchors.fill: parent
                    pressed: playerMouse.pressed
                    highlight: retroWinamp.palette.highlight
                    lightShade: retroWinamp.palette.lightShade
                    darkShade: retroWinamp.palette.darkShade
                    shadow: retroWinamp.palette.shadow
                }
                Text {
                    anchors.centerIn: parent
                      text: retroWinamp.availablePlayers.length > 0
                          ? (retroWinamp.playerIndex + 1) + "/" + retroWinamp.availablePlayers.length : "P0"
                    color: retroWinamp.palette.text
                    font.family: "Monospace"
                    font.pixelSize: 5
                }
                MouseArea {
                    id: playerMouse
                    anchors.fill: parent
                    enabled: retroWinamp.availablePlayers.length > 1
                    onClicked: retroWinamp.cyclePlayer()
                }
            }
        }

        Rectangle {
            visible: !retroWinamp.compactMode
            x: 1
            y: 16
            width: parent.width - 2
            height: 1
            color: retroWinamp.palette.shadow
        }

        Rectangle {
            id: display
            x: 8
            y: retroWinamp.compactMode ? 5 : 21
            width: 94
            height: 45
            color: retroWinamp.palette.screen
            border.color: retroWinamp.palette.shadow
            border.width: 1

            Column {
                x: 3
                y: 3
                spacing: -1
                Repeater {
                    model: ["O", "A", "T", "D", "U"]
                    Text {
                        text: modelData
                        color: retroWinamp.palette.accent
                        font.family: "Monospace"
                        font.pixelSize: 6
                    }
                }
            }

            Image {
                id: distroIcon
                x: 12
                y: 5
                width: 10
                height: 10
                source: retroWinamp.distroLogoCandidates.length > 0
                        ? retroWinamp.distroLogoCandidates[retroWinamp.distroLogoCandidateIndex] : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                property real spinAngle: 0
                transform: Rotation {
                    origin.x: distroIcon.width / 2
                    origin.y: distroIcon.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: distroIcon.spinAngle
                }
                NumberAnimation on spinAngle {
                    from: 0
                    to: 360
                    duration: 4200
                    loops: Animation.Infinite
                }
                onStatusChanged: {
                    if (status === Image.Error
                            && retroWinamp.distroLogoCandidateIndex + 1 < retroWinamp.distroLogoCandidates.length)
                        retroWinamp.distroLogoCandidateIndex++
                }
                Text {
                    anchors.centerIn: parent
                    visible: distroIcon.status !== Image.Ready
                             && retroWinamp.distroLogoCandidateIndex >= retroWinamp.distroLogoCandidates.length - 1
                    text: retroWinamp.distroId.substring(0, 1).toUpperCase()
                    color: retroWinamp.palette.accent
                    font.family: "Monospace"
                    font.bold: true
                    font.pixelSize: 8
                }
            }

            Text {
                x: 25
                y: 4
                width: display.width - x - 3
                text: retroWinamp.clockText
                color: retroWinamp.palette.accent
                font.family: "Monospace"
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: retroWinamp.toggleClockFormat()
                }
            }

            Row {
                id: visualizer
                x: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                height: 10
                spacing: 1

                Repeater {
                    model: 24
                    Rectangle {
                        id: visualBar
                        property int peakHeight: 2 + ((index * 7) % 8)
                        width: 2
                        height: 2
                        y: visualizer.height - height
                        color: retroWinamp.palette.visualizer

                        Behavior on height {
                            NumberAnimation { duration: 110 }
                        }

                        Timer {
                            interval: 70 + index * 9
                            repeat: true
                            running: retroWinamp.player && retroWinamp.player.isPlaying
                            onTriggered: visualBar.height = 2 + Math.random() * (visualBar.peakHeight - 2)
                            onRunningChanged: {
                                if (!running)
                                    visualBar.height = 2
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: compactDragArea
                visible: retroWinamp.compactMode
                x: 0
                y: 0
                width: 10
                height: parent.height
                cursorShape: Qt.SizeAllCursor
                onPressed: function(mouse) { retroWinamp.beginPanelMove(compactDragArea, mouse) }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        retroWinamp.movePanel(compactDragArea, mouse)
                }
            }
        }

        Rectangle {
            visible: !retroWinamp.compactMode
            id: trackDisplay
            x: 107
            y: 21
            width: 160
            height: 17
            clip: true
            color: retroWinamp.palette.face
            border.color: retroWinamp.palette.shadow
            border.width: 1

            Text {
                id: titleMarquee
                x: 3
                y: (parent.height - height) / 2
                text: retroWinamp.currentFileName()
                      + (retroWinamp.player ? "  (" + retroWinamp.formatTime(retroWinamp.player.length) + ")" : "")
                color: retroWinamp.palette.text
                font.family: "Monospace"
                font.pixelSize: 9

                onTextChanged: {
                    x = 3
                    if (paintedWidth > trackDisplay.width - 6)
                        titleScroll.restart()
                    else
                        titleScroll.stop()
                }
            }

            SequentialAnimation {
                id: titleScroll
                loops: Animation.Infinite
                running: titleMarquee.paintedWidth > trackDisplay.width - 6

                PauseAnimation { duration: 700 }
                NumberAnimation {
                    target: titleMarquee
                    property: "x"
                    to: trackDisplay.width - titleMarquee.paintedWidth - 3
                    duration: Math.max(1200, (titleMarquee.paintedWidth - trackDisplay.width + 6) * 35)
                    easing.type: Easing.Linear
                }
                PauseAnimation { duration: 900 }
                PropertyAction { target: titleMarquee; property: "x"; value: 3 }
            }
        }

        Text {
            visible: !retroWinamp.compactMode
            x: 108
            y: 39
            width: 44
            height: 13
            text: retroWinamp.player
                  ? (retroWinamp.player.metadata["xesam:audioBitrate"]
                     ? Math.round(retroWinamp.player.metadata["xesam:audioBitrate"] / 1000) + "Kbps"
                     : "N/A Kbps")
                  : "N/A Kbps"
            color: retroWinamp.palette.text
            font.family: "Monospace"
            font.pixelSize: 7
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            Rectangle {
                anchors.fill: parent
                z: -1
                color: retroWinamp.palette.face
                border.color: retroWinamp.palette.shadow
            }
        }

        Rectangle {
            visible: !retroWinamp.compactMode
            x: 154
            y: 39
            width: 52
            height: 13
            color: retroWinamp.palette.face
            border.color: retroWinamp.palette.shadow
            Text {
                anchors.fill: parent
                text: retroWinamp.player && retroWinamp.player.metadata["xesam:audioSampleRate"]
                      ? Math.round(retroWinamp.player.metadata["xesam:audioSampleRate"] / 1000) + "KHz"
                      : "N/A KHz"
                color: retroWinamp.palette.text
                font.family: "Monospace"
                font.pixelSize: 7
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Rectangle {
            visible: !retroWinamp.compactMode
            x: 208
            y: 39
            width: 59
            height: 13
            color: retroWinamp.palette.face
            border.color: retroWinamp.palette.shadow
            Text {
                anchors.fill: parent
                text: "Mono  Stereo"
                color: retroWinamp.palette.text
                font.family: "Monospace"
                font.pixelSize: 7
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Rectangle {
            visible: !retroWinamp.compactMode
            x: 108
            y: 57
            width: 50
            height: 8
            color: retroWinamp.palette.track
            border.color: retroWinamp.palette.shadow
            border.width: 1

            Rectangle {
                width: 7
                height: 11
                x: Math.max(0, Math.min(parent.width - width,
                    parent.width * retroWinamp.systemVolume - width / 2))
                y: -3
                color: retroWinamp.palette.face
                border.color: retroWinamp.palette.shadow
                BevelEdges {
                    anchors.fill: parent
                    pressed: false
                    highlight: retroWinamp.palette.highlight
                    lightShade: retroWinamp.palette.lightShade
                    darkShade: retroWinamp.palette.darkShade
                    shadow: retroWinamp.palette.shadow
                }
                border.width: 1
            }

            MouseArea {
                anchors.fill: parent
                enabled: true
                onClicked: function(mouse) {
                    retroWinamp.setVolumeAt(mouse.x, width)
                }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        retroWinamp.setVolumeAt(mouse.x, width)
                }
            }
        }

        Rectangle {
            visible: !retroWinamp.compactMode
            x: 160
            y: 57
            width: 36
            height: 8
            color: retroWinamp.palette.track
            border.color: retroWinamp.palette.shadow
            border.width: 1
            Rectangle {
                x: Math.max(0, Math.min(parent.width - width,
                    parent.width * retroWinamp.systemBalance - width / 2))
                y: -2
                width: 6
                height: 11
                color: retroWinamp.palette.face
                border.color: retroWinamp.palette.shadow
                BevelEdges {
                    anchors.fill: parent
                    highlight: retroWinamp.palette.highlight
                    lightShade: retroWinamp.palette.lightShade
                    darkShade: retroWinamp.palette.darkShade
                    shadow: retroWinamp.palette.shadow
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: true
                onClicked: function(mouse) {
                    retroWinamp.setBalanceAt(mouse.x, width)
                }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        retroWinamp.setBalanceAt(mouse.x, width)
                }
            }
        }

        Rectangle {
            visible: !retroWinamp.compactMode
            x: 199
            y: 54
            width: 31
            height: 15
            color: retroWinamp.palette.face
            border.color: retroWinamp.palette.shadow
            BevelEdges {
                anchors.fill: parent
                pressed: eqMouse.pressed
                highlight: retroWinamp.palette.highlight
                lightShade: retroWinamp.palette.lightShade
                darkShade: retroWinamp.palette.darkShade
                shadow: retroWinamp.palette.shadow
            }
            Text { anchors.centerIn: parent; text: "EQ"; color: retroWinamp.palette.text; font.pixelSize: 8 }
            MouseArea { id: eqMouse; anchors.fill: parent }
        }

        Rectangle {
            visible: !retroWinamp.compactMode
            x: 233
            y: 54
            width: 31
            height: 15
            color: retroWinamp.playlistOpen ? retroWinamp.palette.accent : retroWinamp.palette.face
            border.color: retroWinamp.palette.shadow
            BevelEdges {
                anchors.fill: parent
                pressed: retroWinamp.playlistOpen || playlistMouse.pressed
                highlight: retroWinamp.palette.highlight
                lightShade: retroWinamp.palette.lightShade
                darkShade: retroWinamp.palette.darkShade
                shadow: retroWinamp.palette.shadow
            }
            Text { anchors.centerIn: parent; text: "PL"; color: retroWinamp.palette.text; font.pixelSize: 8 }
            MouseArea {
                id: playlistMouse
                anchors.fill: parent
                onClicked: retroWinamp.playlistOpen = !retroWinamp.playlistOpen
            }
        }

        Rectangle {
            visible: !retroWinamp.compactMode
            x: 8
            y: 71
            width: parent.width - 16
            height: 9
            color: retroWinamp.palette.track
            border.color: retroWinamp.palette.shadow
            border.width: 1

            Rectangle {
                x: 1
                y: 1
                height: parent.height - 2
                width: {
                    var duration = retroWinamp.player ? retroWinamp.player.length : 0
                    var position = retroWinamp.player ? retroWinamp.player.position : 0
                    return duration > 0
                        ? (parent.width - 2) * Math.max(0, Math.min(1, position / duration))
                        : 0
                }
                color: retroWinamp.palette.accent
            }

            Rectangle {
                width: 10
                height: 11
                x: {
                    var duration = retroWinamp.player ? retroWinamp.player.length : 0
                    var position = retroWinamp.player ? retroWinamp.player.position : 0
                    return duration > 0
                        ? Math.max(0, Math.min(parent.width - width, parent.width * position / duration - width / 2))
                        : 0
                }
                y: -3
                color: retroWinamp.palette.face
                border.color: retroWinamp.palette.shadow
                BevelEdges {
                    anchors.fill: parent
                    pressed: true
                    highlight: retroWinamp.palette.highlight
                    lightShade: retroWinamp.palette.lightShade
                    darkShade: retroWinamp.palette.darkShade
                    shadow: retroWinamp.palette.shadow
                }
                border.width: 1
            }

            MouseArea {
                anchors.fill: parent
                enabled: retroWinamp.player && retroWinamp.player.canSeek
                onClicked: function(mouse) {
                    retroWinamp.seekAt(mouse.x, width)
                }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        retroWinamp.seekAt(mouse.x, width)
                }
            }
        }

        Row {
            x: retroWinamp.compactMode ? 8 : 16
            y: retroWinamp.compactMode ? 55 : 86
            spacing: retroWinamp.compactMode ? 0 : 2

            Row {
                spacing: retroWinamp.compactMode ? 1 : 2
                Repeater {
                    model: retroWinamp.compactMode ? [
                        { label: "<<", action: "rewind" },
                        { label: ">", action: "play" },
                        { label: "||", action: "pause" },
                        { label: "<", action: "back" },
                        { label: ">>", action: "forward" },
                        { label: "EJ", action: "eject" },
                        { label: "TH", action: "theme" }
                    ] : [
                        { label: "<<", action: "rewind" },
                        { label: ">", action: "play" },
                        { label: "||", action: "pause" },
                        { label: "<", action: "back" },
                        { label: ">>", action: "forward" },
                        { label: "EJ", action: "eject" }
                    ]

                    Rectangle {
                        width: retroWinamp.compactMode ? 12 : 20
                        height: retroWinamp.compactMode ? 17 : 19
                        property bool active: modelData.action === "pause"
                                              && retroWinamp.player && retroWinamp.player.isPlaying
                        property bool commandAvailable: {
                            if (modelData.action === "theme") return true
                            if (!retroWinamp.player) return false
                            if (modelData.action === "play") return retroWinamp.player.canPlay
                            if (modelData.action === "pause") return retroWinamp.player.canPause
                            if (modelData.action === "rewind")
                                return retroWinamp.player.canSeek && retroWinamp.player.position > 0
                            if (modelData.action === "back")
                                return retroWinamp.player.canSeek && retroWinamp.player.position > 0
                            if (modelData.action === "forward")
                                return retroWinamp.player.canSeek
                                       && retroWinamp.player.position < retroWinamp.player.length
                            if (modelData.action === "eject") return true
                            return false
                        }
                        property bool sunken: active || transportMouse.pressed
                        color: active ? retroWinamp.palette.accent : retroWinamp.palette.face
                        border.color: retroWinamp.palette.shadow
                        border.width: 1

                        BevelEdges {
                            anchors.fill: parent
                            pressed: parent.sunken
                            highlight: retroWinamp.palette.highlight
                            lightShade: retroWinamp.palette.lightShade
                            darkShade: retroWinamp.palette.darkShade
                            shadow: retroWinamp.palette.shadow
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.commandAvailable ? retroWinamp.palette.text : retroWinamp.palette.darkShade
                            font.family: "Monospace"
                            font.bold: true
                            font.pixelSize: retroWinamp.compactMode ? 7 : 8
                        }

                        MouseArea {
                            id: transportMouse
                            anchors.fill: parent
                            enabled: parent.commandAvailable
                            onClicked: {
                                if (modelData.action === "theme")
                                    retroWinamp.themeIndex = (retroWinamp.themeIndex + 1) % retroWinamp.palettes.length
                                else if (modelData.action === "rewind") retroWinamp.skipBy(-10)
                                else if (modelData.action === "play") retroWinamp.player.play()
                                else if (modelData.action === "pause") retroWinamp.player.pause()
                                else if (modelData.action === "back") retroWinamp.skipBy(-5)
                                else if (modelData.action === "forward") retroWinamp.skipBy(10)
                                else if (modelData.action === "eject") retroWinamp.eject()
                            }
                        }
                    }
                }
            }

            Item { width: 5; height: 1 }

            Rectangle {
                visible: !retroWinamp.compactMode
                width: 42
                height: 19
                property bool active: retroWinamp.player && retroWinamp.player.shuffleSupported
                                      && retroWinamp.player.shuffle
                property bool sunken: active || shuffleMouse.pressed
                color: active ? retroWinamp.palette.accent : retroWinamp.palette.face
                border.color: retroWinamp.palette.shadow
                border.width: 1
                BevelEdges {
                    anchors.fill: parent
                    pressed: parent.sunken
                    highlight: retroWinamp.palette.highlight
                    lightShade: retroWinamp.palette.lightShade
                    darkShade: retroWinamp.palette.darkShade
                    shadow: retroWinamp.palette.shadow
                }
                Text { anchors.centerIn: parent; text: "Shuffle"; color: retroWinamp.palette.text; font.pixelSize: 6 }
                MouseArea {
                    id: shuffleMouse
                    anchors.fill: parent
                    onClicked: {
                        if (retroWinamp.player && retroWinamp.player.shuffleSupported)
                            retroWinamp.player.shuffle = !retroWinamp.player.shuffle
                    }
                }
            }

            Rectangle {
                visible: !retroWinamp.compactMode
                width: 27
                height: 19
                property bool active: retroWinamp.player && retroWinamp.player.loopSupported
                                      && retroWinamp.player.loopState !== MprisLoopState.None
                property bool sunken: active || repeatMouse.pressed
                color: active ? retroWinamp.palette.accent : retroWinamp.palette.face
                border.color: retroWinamp.palette.shadow
                border.width: 1
                BevelEdges {
                    anchors.fill: parent
                    pressed: parent.sunken
                    highlight: retroWinamp.palette.highlight
                    lightShade: retroWinamp.palette.lightShade
                    darkShade: retroWinamp.palette.darkShade
                    shadow: retroWinamp.palette.shadow
                }
                Text { anchors.centerIn: parent; text: "Rep"; color: retroWinamp.palette.text; font.pixelSize: 8 }
                MouseArea {
                    id: repeatMouse
                    anchors.fill: parent
                    onClicked: {
                        if (retroWinamp.player && retroWinamp.player.loopSupported)
                            retroWinamp.player.loopState = retroWinamp.player.loopState === MprisLoopState.None
                                ? MprisLoopState.Playlist : MprisLoopState.None
                    }
                }
            }

            Rectangle {
                visible: !retroWinamp.compactMode
                width: 16
                height: 19
                color: "transparent"
                Rectangle { x: 9; y: 1; width: 4; height: 2; color: "#37ad49" }
                Column {
                    anchors.centerIn: parent
                    spacing: 0
                    Repeater {
                        model: [
                            { barWidth: 7, barColor: "#42b64a" },
                            { barWidth: 11, barColor: "#f2df32" },
                            { barWidth: 14, barColor: "#f28c28" },
                            { barWidth: 14, barColor: "#e53935" },
                            { barWidth: 11, barColor: "#bb31a8" },
                            { barWidth: 7, barColor: "#4854c7" }
                        ]
                        Rectangle {
                            width: modelData.barWidth
                            height: 2
                            color: modelData.barColor
                        }
                    }
                }
            }
        }

        Rectangle {
            id: playlistPanel
            x: 8
            y: 20
            width: parent.width - 16
            height: 88
            z: 20
            visible: retroWinamp.playlistOpen && !retroWinamp.compactMode
            color: retroWinamp.palette.panel
            border.color: retroWinamp.palette.shadow
            border.width: 1

            BevelEdges {
                anchors.fill: parent
                highlight: retroWinamp.palette.highlight
                lightShade: retroWinamp.palette.lightShade
                darkShade: retroWinamp.palette.darkShade
                shadow: retroWinamp.palette.shadow
            }

            Text {
                x: 5
                y: 3
                text: "MEDIA PLAYERS"
                color: retroWinamp.palette.text
                font.family: "Monospace"
                font.pixelSize: 7
                font.bold: true
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 5
                y: 2
                text: "X"
                color: retroWinamp.palette.text
                font.family: "Monospace"
                font.pixelSize: 8
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3
                    onClicked: retroWinamp.playlistOpen = false
                }
            }

            Column {
                x: 4
                y: 16
                width: parent.width - 8
                height: parent.height - 20
                spacing: 2
                clip: true

                Repeater {
                    model: retroWinamp.availablePlayers.length > 0
                           ? retroWinamp.availablePlayers : ["No active media players"]

                    Rectangle {
                        width: playlistPanel.width - 10
                        height: 13
                        property bool hasPlayer: retroWinamp.availablePlayers.length > 0
                        color: hasPlayer && index === retroWinamp.playerIndex
                               ? retroWinamp.palette.accent : retroWinamp.palette.face
                        border.color: retroWinamp.palette.shadow

                        Text {
                            x: 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 6
                            text: parent.hasPlayer
                                  ? (modelData.identity || modelData.desktopEntry || ("Player " + (index + 1)))
                                  : modelData
                            color: retroWinamp.palette.text
                            font.family: "Monospace"
                            font.pixelSize: 7
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: parent.hasPlayer
                            onClicked: {
                                retroWinamp.playerIndex = index
                                retroWinamp.playlistOpen = false
                            }
                        }
                    }
                }
            }
        }

        Repeater {
            model: [
                { rightSide: false, bottomSide: false },
                { rightSide: true, bottomSide: false },
                { rightSide: false, bottomSide: true },
                { rightSide: true, bottomSide: true }
            ]

            Rectangle {
                id: resizeGrip
                property bool rightSide: modelData.rightSide
                property bool bottomSide: modelData.bottomSide
                x: rightSide ? parent.width - 10 : 1
                y: bottomSide ? parent.height - 10 : 1
                width: 9
                height: 9
                color: retroWinamp.palette.panel
                border.color: retroWinamp.palette.shadow

                BevelEdges {
                    anchors.fill: parent
                    highlight: retroWinamp.palette.highlight
                    lightShade: retroWinamp.palette.lightShade
                    darkShade: retroWinamp.palette.darkShade
                    shadow: retroWinamp.palette.shadow
                }
                Rectangle { x: 3; y: 4; width: 4; height: 1; color: retroWinamp.palette.shadow }
                Rectangle { x: 5; y: 6; width: 2; height: 1; color: retroWinamp.palette.shadow }

                MouseArea {
                    id: resizeMouse
                    anchors.fill: parent
                    property real initialScale: 1
                    property real initialX: 0
                    property real initialY: 0
                    cursorShape: resizeGrip.rightSide === resizeGrip.bottomSide
                                 ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                    onPressed: function(mouse) {
                        initialScale = retroWinamp.uiScale
                        initialX = mouse.x
                        initialY = mouse.y
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            var horizontalDirection = resizeGrip.rightSide ? 1 : -1
                            var verticalDirection = resizeGrip.bottomSide ? 1 : -1
                            var delta = (horizontalDirection * (mouse.x - initialX)
                                         + verticalDirection * (mouse.y - initialY)) / 232
                            retroWinamp.uiScale = Math.max(0.75, Math.min(2.5, initialScale + delta))
                        }
                    }
                }
            }
        }
    }
}
