import QtQuick 1.1
import com.nokia.meego 1.0
import Hue 0.1

Page {
    id: root
    tools: commonTools

    property alias lights: lights

    QtObject {
        id: units

        function gu(val) {
            return val * 10;
        }
    }

    Groups {
        id: groups
    }

    Lights {
        id: lights
    }

    Column {
        anchors.fill: parent

        Rectangle {
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#222222" }
                GradientStop { position: 1.0; color: "#111111" }
            }
            id: groupItem
            width: parent.width
            height: units.gu(8)
            clip: true

            Row {
                id: mainRow
                anchors { fill: parent; leftMargin: units.gu(2); rightMargin: units.gu(2) }
                spacing: units.gu(2)
                visible: opacity > 0

                ListView {
                    id: groupsListView
                    model: groups
                    width: parent.width - onOffSwitch.width - parent.spacing
                    height: parent.height
                    clip: true
                    snapMode: ListView.SnapOneItem
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    currentIndex: groupsDialog.selectedIndex

                    delegate: Label {
                        id: groupNameLabel
                        width: groupsListView.width
                        height: groupsListView.height
                        text: name
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: units.gu(4)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            groupsDialog.openRefresh();
                        }
                    }
                }


                Switch {
                    id: onOffSwitch
                    checked: groups.get(groupsDialog.selectedIndex).on
                    anchors.verticalCenter: parent.verticalCenter
                    onCheckedChanged: {
                        groups.get(groupsDialog.selectedIndex).on = checked;
                    }

                    Connections {
                        target: groups.get(groupsDialog.selectedIndex)
                        onOnChanged: {
                            print("group on changed", groups.get(groupsDialog.selectedIndex).on);
                        }
                    }
                }
            }

        }

        ListView {
            id: lightsListView
            anchors { left: parent.left; right: parent.right }
            height: parent.height - y

            property variant expandedItem

            model: LightsFilterModel {
                lights: lights
                groupId: 0
            }

            delegate: Rectangle {
                id: delegateItem
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#222222" }
                    GradientStop { position: 1.0; color: "#111111" }
                }
                opacity: model.reachable ? 1.0 : 0.5

                width: parent.width
                height: units.gu(8)
                clip: true

                states: [
                    State {
                        name: "expanded"; when: lightsListView.expandedItem == delegateItem
                        PropertyChanges { target: delegateItem; height: delegateColumn.height + units.gu(2) }
                    },
                    State {
                        name: "rename"
                        PropertyChanges { target: mainRow; opacity: 0 }
                        PropertyChanges { target: renameRow; opacity: 1 }
                    }

                ]
                transitions: [
                    Transition {
                        from: "*"; to: "*"
                        NumberAnimation { properties: "height"; duration: 150 }
                        NumberAnimation { properties: "opacity"; duration: 150 }
                    }
                ]

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (delegateItem.state == "expanded") {
                            lightsListView.expandedItem = null
                        } else {
                            lightsListView.expandedItem = delegateItem
                        }
                    }
                    onPressAndHold: {
                        if (delegateItem.state == "rename") {
                            delegateItem.state = ""
                        } else {
                            delegateItem.state = "rename"
                        }
                    }
                }

                Column {
                    id: delegateColumn
                    anchors { left: parent.left; right: parent.right; leftMargin: units.gu(2); rightMargin: units.gu(2) }
                    spacing: units.gu(2)
                    height: childrenRect.height

                    Item {
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        height: units.gu(8)
                        Row {
                            id: mainRow
                            anchors.fill: parent
                            anchors { topMargin: units.gu(1); bottomMargin: units.gu(1) }
                            spacing: units.gu(2)
                            visible: opacity > 0

                            Image {
                                id: icon
                                height: parent.height
                                width: height
                                anchors.verticalCenter: parent.verticalCenter
                                source: model.reachable ? model.on ? "image://theme/icon-m-camera-torch-on" : "image://theme/icon-m-camera-torch-off" : "image://theme/icon-m-camera-flash-off-choice"
                                rotation: model.reachable ? 180 : 0
                            }

                            Label {
                                width: parent.width - onOffSwitch.width - icon.width - parent.spacing * 2
                                text: model.name
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Switch {
                                id: onOffSwitch
                                checked: model.on
                                anchors.verticalCenter: parent.verticalCenter
                                onCheckedChanged: {
                                    lights.get(index).on = checked;
                                }

                                Component.onCompleted: {
                                    print("switch created. light is on", model.on);
                                }
                                Connections {
                                    target: lights.get(index)
                                    onOnChanged: {
                                        print("lightbulb on changed", lights.get(index).on);
                                    }
                                }
                            }
                        }
                        Row {
                            id: renameRow
                            anchors.fill: parent
                            spacing: units.gu(2)
                            height: units.gu(6)
                            visible: opacity > 0
                            opacity: 0

                            TextField {
                                id: renameTextField
                                width: parent.width - okButton.width - parent.spacing
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.name
                            }
                            Button {
                                id: okButton
                                text: "OK"
                                anchors.verticalCenter: parent.verticalCenter
                                width: units.gu(8)
                                onClicked: {
                                    lights.get(index).name = renameTextField.text
                                    delegateItem.state = ""
                                }
                            }
                        }
                    }

                    Row {
                        anchors { left: parent.left; right: parent.right }
                        spacing: units.gu(1)
                        Image {
                            height: brightnessSlider.height
                            width: height
                            source: "image://theme/icon-m-camera-torch-off"
                            rotation: 180
                        }
                        Slider {
                            id: brightnessSlider
                            width: parent.width - height * 2 - parent.spacing * 2
                            minimumValue: 0
                            maximumValue: 255
                            value: model.bri
                            onValueChanged: {
                                print("val changed")
                                lights.get(index).bri = value
                            }
                        }
                        Image {
                            height: brightnessSlider.height
                            width: height
                            source: "image://theme/icon-m-camera-torch-on"
                            rotation: 180
                        }
                    }


                    ColorPickerQtQuick1 {
                        id: colorPicker
                        anchors { left: parent.left; right: parent.right }
                        height: width / 3
                        color: root.lights.get(index).color
                        active: root.lights.get(index).colormode == LightInterface.ColorModeHS || root.lights.get(index).colormode == LightInterface.ColorModeXY

                        touchDelegate: Rectangle {
                            height: units.gu(4)
                            width: units.gu(4)
                            color: "white"
                            radius: units.gu(1)
                        }

                        onColorChanged: {
                            if (pressed) {
                                root.lights.get(index).color = colorPicker.color;
                            }
                        }
                    }

                    ColorPickerCtQtQuick1 {
                        id: colorPickerCt
                        anchors { left: parent.left; right: parent.right }
                        height: width / 4
                        ct: root.lights.get(index).ct
                        active: root.lights.get(index).colormode == LightInterface.ColorModeCT

                        touchDelegate: Rectangle {
                            height: colorPickerCt.height
                            width: units.gu(1)
                            border.width: units.gu(.5)
                            color: "transparent"
                            border.color: "black"
                        }

                        onCtChanged: {
                            if (pressed) {
                                root.lights.get(index).ct = colorPickerCt.ct;
                            }
                        }
                    }

    //                OptionSelector {
    //                    model: ListModel {
    //                        id: effectModel
    //                        ListElement { name: "No effect"; value: "none" }
    //                        ListElement { name: "Color loop"; value: "colorloop" }
    //                    }
    //                    selectedIndex: {
    //                        for (var i = 0; i < effectModel.count; i++) {
    //                            if (effectModel.get(i).value == lights.get(index).effect) {
    //                                return i;
    //                            }
    //                        }
    //                    }

    //                    onSelectedIndexChanged: {
    //                        lights.get(index).effect = effectModel.get(selectedIndex).value;
    //                    }

    //                    delegate: OptionSelectorDelegate {
    //                        text: name
    //                    }
    //                }
                }
            }
        }
    }

    SelectionDialog {
        id: groupsDialog
        titleText: "Select group"
        selectedIndex: 0

        function openRefresh() {
            dialogModel.clear();
            for (var i = 0; i < groupsListView.count; ++i) {
                dialogModel.append({name: groups.get(i).name})
            }
            open();
        }

        model: ListModel {
            id: dialogModel
        }

        onSelectedIndexChanged: {
            groupNameLabel.text = groups.get(groupsDialog.selectedIndex).name
        }
    }
}
