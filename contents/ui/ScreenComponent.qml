import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: screenItem
    visible: false
    clip: true // Fixes the glitches? The glitches are caused by desktopsBar going out of screen?

    property alias desktopsBarRepeater: desktopsBarRepeater
    property alias bigDesktopsRepeater: bigDesktopsRepeater
    property alias desktopBackground: desktopBackground
    // property alias activitiesBackgrounds: activitiesBackgrounds

    property int desktopsBarHeight: Math.round(height / 6) // valid only if position of desktopsBar is top or bottom
    property int desktopsBarWidth: Math.round(width / 6) // valid only if position of desktopsBar is left or right
    property int bigDesktopMargin
    property bool animating: false
    property real ratio: width / height

    property int screenIndex: model.index

    Behavior on bigDesktopMargin {
        enabled: mainWindow.easingType !== mainWindow.noAnimation
        NumberAnimation { id: bigDesktopMarginAnimation; duration: configAnimationsDuration; easing.type: mainWindow.easingType; }
    }

    // Repeater {
    //     id: activitiesBackgrounds
    //     model: workspace.activities.length
    PlasmaCore.WindowThumbnail {
        id: desktopBackground
        anchors.fill: parent
        visible: winId !== 0
        opacity: mainWindow.configBlurBackground ? 0 : 1
    }
    // }

    FastBlur {
        id: blurBackground
        anchors.fill: parent
        source: desktopBackground
        radius: 64
        visible: desktopBackground.winId !== 0 && mainWindow.configBlurBackground
        // cached: true
    }

    Rectangle { // To apply some transparency without interfere with children transparency
        id: desktopsBarBackground
        anchors.fill: desktopsBar
        color: "black"
        opacity: 0.1
        visible: mainWindow.configShowDesktopBarBackground
    }

    ScrollView {
        id: desktopsBar
        contentWidth: desktopsWrapper.width
        contentHeight: desktopsWrapper.height
        clip: true

        states: [
            State {
                when: mainWindow.configDesktopBarPosition === Enums.Position.Top
                PropertyChanges {
                    target: desktopsBar
                    height: desktopsBarHeight
                }
                AnchorChanges {
                    target: desktopsBar
                    anchors.bottom: bigDesktops.top
                    anchors.right: screenItem.right
                    anchors.left: screenItem.left
                }
            },
            State {
                when: mainWindow.configDesktopBarPosition === Enums.Position.Bottom
                PropertyChanges {
                    target: desktopsBar
                    height: desktopsBarHeight
                }
                AnchorChanges {
                    target: desktopsBar
                    anchors.top: bigDesktops.bottom
                    anchors.right: screenItem.right
                    anchors.left: screenItem.left
                }
            },
            State {
                when: mainWindow.configDesktopBarPosition === Enums.Position.Left
                PropertyChanges {
                    target: desktopsBar
                    width: desktopsBarWidth
                }
                AnchorChanges {
                    target: desktopsBar
                    anchors.bottom: screenItem.bottom
                    anchors.top: screenItem.top
                    anchors.right: bigDesktops.left
                }
            },
            State {
                when: mainWindow.configDesktopBarPosition === Enums.Position.Right
                PropertyChanges {
                    target: desktopsBar
                    width: desktopsBarWidth
                }
                AnchorChanges {
                    target: desktopsBar
                    anchors.bottom: screenItem.bottom
                    anchors.top: screenItem.top
                    anchors.left: bigDesktops.right
                }
            }
        ]

        Item { // To centralize children
            id: desktopsWrapper
            width: childrenRect.width + mainWindow.smallDesktopMargin
            height: childrenRect.height + mainWindow.smallDesktopMargin
            x: desktopsBar.width < desktopsWrapper.width ? 0 : (desktopsBar.width - desktopsWrapper.width) / 2
            y: desktopsBar.height < desktopsWrapper.height ? 0 : (desktopsBar.height - desktopsWrapper.height) / 2
            // anchors.horizontalCenter: parent.horizontalCenter
            // anchors.verticalCenter: parent.verticalCenter

            Repeater {
                id: desktopsBarRepeater
                model: mainWindow.workWithActivities ? workspace.activities.length : workspace.desktops

                DesktopComponent {
                    id: smallDesktop
                    activity: mainWindow.workWithActivities ? workspace.activities[model.index] : ""

                    states: [
                        State {
                            when: mainWindow.horizontalDesktopsLayout
                            PropertyChanges {
                                target: smallDesktop
                                x: mainWindow.smallDesktopMargin + model.index * (smallDesktop.width + mainWindow.smallDesktopMargin)
                                y: mainWindow.smallDesktopMargin
                                width: (smallDesktop.height / screenItem.height) * screenItem.width
                                height: desktopsBar.height - mainWindow.smallDesktopMargin * 2
                            }
                        },
                        State {
                            when: !mainWindow.horizontalDesktopsLayout
                            PropertyChanges {
                                target: smallDesktop
                                x: mainWindow.smallDesktopMargin
                                y: mainWindow.smallDesktopMargin + model.index * (smallDesktop.height + mainWindow.smallDesktopMargin)
                                width: desktopsBar.width - mainWindow.smallDesktopMargin * 2
                                height: (smallDesktop.width / screenItem.width) * screenItem.height
                            }
                        }
                    ]

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: workspace.currentDesktop = model.index + 1;
                    }
                }
            }
        }
    }

    SwipeView {
        id: bigDesktops
        anchors.fill: parent
        clip: true
        currentIndex: mainWindow.currentActivityOrDesktop
        orientation: mainWindow.horizontalDesktopsLayout ? Qt.Horizontal : Qt.Vertical

        Behavior on anchors.topMargin {
            enabled: mainWindow.easingType !== mainWindow.noAnimation && mainWindow.configDesktopBarPosition === Enums.Position.Top

            NumberAnimation {
                duration: mainWindow.configAnimationsDuration
                easing.type: mainWindow.easingType

                onRunningChanged: {
                    screenItem.animating = running;

                    if (!running && mainWindow.activated && mainWindow.easingType === Easing.InExpo) {
                        mainWindow.deactivate();
                    }
                }  
            }
        }

        Behavior on anchors.bottomMargin {
            enabled: mainWindow.easingType !== mainWindow.noAnimation && mainWindow.configDesktopBarPosition === Enums.Position.Bottom

            NumberAnimation {
                duration: mainWindow.configAnimationsDuration
                easing.type: mainWindow.easingType

                onRunningChanged: {
                    screenItem.animating = running;

                    if (!running && mainWindow.activated && mainWindow.easingType === Easing.InExpo) {
                        mainWindow.deactivate();
                    }
                }   
            }
        }

        Behavior on anchors.leftMargin {
            enabled: mainWindow.easingType !== mainWindow.noAnimation && mainWindow.configDesktopBarPosition === Enums.Position.Left

            NumberAnimation {
                duration: mainWindow.configAnimationsDuration
                easing.type: mainWindow.easingType

                onRunningChanged: {
                    screenItem.animating = running;

                    if (!running && mainWindow.activated && mainWindow.easingType === Easing.InExpo) {
                        mainWindow.deactivate();
                    }
                }
            }
        }

        Behavior on anchors.rightMargin {
            enabled: mainWindow.easingType !== mainWindow.noAnimation && mainWindow.configDesktopBarPosition === Enums.Position.Right

            NumberAnimation {
                duration: mainWindow.configAnimationsDuration
                easing.type: mainWindow.easingType

                onRunningChanged: {
                    screenItem.animating = running;

                    if (!running && mainWindow.activated && mainWindow.easingType === Easing.InExpo) {
                        mainWindow.deactivate();
                    }
                }
            }
        }

        Repeater {
            id: bigDesktopsRepeater
            model: mainWindow.workWithActivities ? workspace.activities.length : workspace.desktops

            Item { // Cannot set geometry of SwipeView's root item
                property alias bigDesktop: bigDesktop

                TapHandler {
                    acceptedButtons: Qt.AllButtons

                    onTapped: {
                        if (mainWindow.selectedClientItem)
                            switch (eventPoint.event.button) {
                                case Qt.LeftButton:
                                    mainWindow.toggleActive();
                                    break;
                                case Qt.MiddleButton:
                                    mainWindow.selectedClientItem.client.closeWindow();
                                    break;
                                case Qt.RightButton:
                                    if (mainWindow.workWithActivities)
                                        if (mainWindow.selectedClientItem.client.activities.length === 0)
                                            mainWindow.selectedClientItem.client.activities.push(workspace.activities[model.index]);
                                        else
                                            mainWindow.selectedClientItem.client.activities = [];
                                    else
                                        if (mainWindow.selectedClientItem.client.desktop === -1)
                                            mainWindow.selectedClientItem.client.desktop = model.index + 1;
                                        else
                                            mainWindow.selectedClientItem.client.desktop = -1;
                                    break;
                            }
                        else 
                            mainWindow.toggleActive();
                    }
                }

                DesktopComponent {
                    id: bigDesktop
                    big: true
                    activity: mainWindow.workWithActivities ? workspace.activities[model.index] : ""
                    anchors.centerIn: parent
                    width: desktopRatio < screenItem.ratio ? parent.width - screenItem.bigDesktopMargin
                            : parent.height / screenItem.height * screenItem.width - screenItem.bigDesktopMargin
                    height: desktopRatio > screenItem.ratio ? parent.height - screenItem.bigDesktopMargin
                            : parent.width / screenItem.width * screenItem.height - screenItem.bigDesktopMargin

                    property real desktopRatio: parent.width / parent.height
                }
            }
        }

        onCurrentIndexChanged: {
            mainWindow.workWithActivities ? workspace.currentActivity = workspace.activities[currentIndex]
                    : workspace.currentDesktop = currentIndex + 1;
        }
    }

    function showDesktopsBar() {
        switch (mainWindow.configDesktopBarPosition) {
            case Enums.Position.Top:
                bigDesktops.anchors.topMargin = screenItem.desktopsBarHeight;
                break;
            case Enums.Position.Bottom:
                bigDesktops.anchors.bottomMargin = screenItem.desktopsBarHeight;
                break;
            case Enums.Position.Left:
                bigDesktops.anchors.leftMargin = screenItem.desktopsBarWidth;
                break;
            case Enums.Position.Right:
                bigDesktops.anchors.rightMargin = screenItem.desktopsBarWidth;
                break;
        }
        screenItem.bigDesktopMargin = 40;
    }

    function hideDesktopsBar() {
        bigDesktops.anchors.topMargin = 0;
        bigDesktops.anchors.bottomMargin = 0;
        bigDesktops.anchors.leftMargin = 0;
        bigDesktops.anchors.rightMargin = 0;
        screenItem.bigDesktopMargin = 0;
    }

    function updateDesktopWindowId() {
        const clients = workspace.clientList(); 
        for (let i = 0; i < clients.length; i++) {
            if (clients[i].desktopWindow && clients[i].screen === screenItem.screenIndex) {
                screenItem.desktopBackground.winId = clients[i].windowId;
                return;
            }
        }
    }

    Component.onCompleted: {
        updateDesktopWindowId();
    }
}