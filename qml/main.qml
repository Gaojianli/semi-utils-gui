import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 800
    minimumWidth: 1000
    minimumHeight: 700

    // 语言追踪属性，用于触发所有翻译文本更新
    property int currentLang: backend ? backend.languageIndex : 0

    // 翻译辅助函数，依赖 currentLang 触发更新
    function tr(key) {
        // 引用 currentLang 确保语言变化时重新求值
        var dummy = currentLang
        return backend ? backend.tr(key) : key
    }

    title: tr("app_title")

    // Material 主题设置
    Material.theme: Material.Light
    Material.accent: Material.Teal
    Material.primary: Material.BlueGrey

    // 窗口关闭时自动保存配置
    onClosing: {
        if (backend) {
            backend.saveConfig()
        }
    }

    // 文件选择对话框
    FolderDialog {
        id: inputFolderDialog
        title: window.tr("select_input_dir")
        onAccepted: {
            if (backend) {
                backend.inputDir = selectedFolder.toString().replace("file://", "")
                backend.refreshFileList()
            }
        }
    }

    FolderDialog {
        id: outputFolderDialog
        title: window.tr("select_output_dir")
        onAccepted: {
            if (backend) {
                backend.outputDir = selectedFolder.toString().replace("file://", "")
            }
        }
    }

    FileDialog {
        id: addFilesDialog
        title: window.tr("select_images")
        nameFilters: ["Image Files (*.jpg *.jpeg *.png *.JPG *.JPEG *.PNG)"]
        fileMode: FileDialog.OpenFiles
        onAccepted: {
            if (backend) {
                var paths = []
                for (var i = 0; i < selectedFiles.length; i++) {
                    paths.push(selectedFiles[i].toString().replace("file://", ""))
                }
                backend.addFiles(paths)
            }
        }
    }

    // 主布局：左右分栏
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ==================== 左侧面板 ====================
        Pane {
            Layout.preferredWidth: 460
            Layout.fillHeight: true
            Material.elevation: 2
            padding: 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // 顶部：Tab + 语言选择
                Pane {
                    Layout.fillWidth: true
                    Material.elevation: 1
                    Material.background: Material.primary
                    leftPadding: 12
                    rightPadding: 16
                    topPadding: 12
                    bottomPadding: 12

                    RowLayout {
                        anchors.fill: parent
                        spacing: 4

                        TabBar {
                            id: mainTabBar
                            Material.accent: "white"
                            background: Rectangle { color: "transparent" }

                            TabButton {
                                text: window.tr("process")
                                font.pixelSize: 16
                                font.bold: mainTabBar.currentIndex === 0
                                Material.foreground: "white"
                                implicitWidth: Math.max(120, contentItem.implicitWidth + leftPadding + rightPadding)
                            }
                            TabButton {
                                text: window.tr("settings")
                                font.pixelSize: 16
                                font.bold: mainTabBar.currentIndex === 1
                                Material.foreground: "white"
                                implicitWidth: Math.max(120, contentItem.implicitWidth + leftPadding + rightPadding)
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: "Language:"
                            color: "white"
                            font.pixelSize: 12
                            Layout.rightMargin: 4
                        }

                        ComboBox {
                            id: languageCombo
                            model: backend ? backend.languageOptions : ["中文", "English"]
                            Component.onCompleted: {
                                if (backend) currentIndex = backend.languageIndex
                            }
                            onActivated: function(index) {
                                if (backend && index >= 0) {
                                    backend.languageIndex = index
                                }
                            }
                            implicitWidth: 120
                            implicitHeight: 36
                            Layout.rightMargin: 8

                            Connections {
                                target: backend
                                function onLanguageChanged() {
                                    languageCombo.currentIndex = backend.languageIndex
                                }
                            }
                        }
                    }
                }

                // 中间：配置内容（根据 Tab 切换）
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: mainTabBar.currentIndex

                    // ========== Process Tab 左侧内容 ==========
                    ColumnLayout {
                        spacing: 0

                        Pane {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Material.elevation: 0
                            padding: 16
                            background: Item {}

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 12

                                Label {
                                    text: window.tr("dir_settings")
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Label {
                                        text: window.tr("input_dir")
                                        Layout.preferredWidth: 70
                                    }

                                    TextField {
                                        id: inputDirField
                                        Layout.fillWidth: true
                                        text: backend ? backend.inputDir : ""
                                        readOnly: true
                                        Material.accent: Material.Teal
                                    }

                                    Button {
                                        text: window.tr("browse")
                                        onClicked: inputFolderDialog.open()
                                        Material.background: Material.Teal
                                        Material.foreground: "white"
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Label {
                                        text: window.tr("output_dir")
                                        Layout.preferredWidth: 70
                                    }

                                    TextField {
                                        id: outputDirField
                                        Layout.fillWidth: true
                                        text: backend ? backend.outputDir : ""
                                        onTextEdited: {
                                            if (backend) backend.outputDir = text
                                        }
                                        Material.accent: Material.Teal
                                    }

                                    Button {
                                        text: window.tr("browse")
                                        onClicked: outputFolderDialog.open()
                                        Material.background: Material.Teal
                                        Material.foreground: "white"
                                    }
                                }

                                Item { Layout.fillHeight: true }

                                CheckBox {
                                    id: autoOpenCheckbox
                                    text: window.tr("auto_open_output")
                                    Component.onCompleted: {
                                        if (backend) checked = backend.autoOpenOutput
                                    }
                                    onToggled: {
                                        if (backend) backend.autoOpenOutput = checked
                                    }
                                    Material.accent: Material.Teal

                                    Connections {
                                        target: backend
                                        function onAutoOpenOutputChanged() {
                                            autoOpenCheckbox.checked = backend.autoOpenOutput
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Button {
                                        Layout.fillWidth: true
                                        text: window.tr("start_processing")
                                        enabled: backend ? (!backend.processing && backend.fileCount > 0) : false
                                        Material.background: Material.Green
                                        Material.foreground: "white"
                                        font.bold: true
                                        onClicked: {
                                            if (backend) backend.startProcessing()
                                        }
                                    }

                                    Button {
                                        Layout.fillWidth: true
                                        text: window.tr("cancel")
                                        enabled: backend ? backend.processing : false
                                        Material.background: Material.Red
                                        Material.foreground: "white"
                                        onClicked: {
                                            if (backend) backend.cancelProcessing()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ========== Settings Tab 左侧内容 ==========
                    ColumnLayout {
                        spacing: 0

                        // 可滚动的配置区域
                        ScrollView {
                            id: settingsScrollView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth

                            ColumnLayout {
                                width: settingsScrollView.availableWidth
                                spacing: 12

                                // 布局设置组
                                Pane {
                                    Layout.fillWidth: true
                                    Layout.margins: 16
                                    Layout.bottomMargin: 0
                                    Material.elevation: 3

                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 12

                                        Label {
                                            text: window.tr("layout_settings")
                                            font.pixelSize: 14
                                            font.bold: true
                                            color: Material.primary
                                        }

                                        Label {
                                            text: window.tr("layout_type")
                                            font.pixelSize: 12
                                        }

                                        ComboBox {
                                            id: layoutCombo
                                            Layout.fillWidth: true
                                            model: backend ? backend.layoutItems : []
                                            Component.onCompleted: {
                                                if (backend) currentIndex = backend.layoutIndex
                                            }
                                            onActivated: function(index) {
                                                if (backend && index >= 0) {
                                                    backend.layoutIndex = index
                                                }
                                            }
                                            Material.accent: Material.Teal

                                            Connections {
                                                target: backend
                                                function onLayoutIndexChanged() {
                                                    layoutCombo.currentIndex = backend.layoutIndex
                                                }
                                                function onLayoutItemsChanged() {
                                                    var idx = layoutCombo.currentIndex
                                                    layoutCombo.model = backend.layoutItems
                                                    layoutCombo.currentIndex = idx
                                                }
                                            }
                                        }

                                        Switch {
                                            id: logoSwitch
                                            text: window.tr("enable_logo")
                                            Component.onCompleted: {
                                                if (backend) checked = backend.logoEnabled
                                            }
                                            onToggled: {
                                                if (backend) backend.logoEnabled = checked
                                            }
                                            Material.accent: Material.Teal

                                            Connections {
                                                target: backend
                                                function onLogoEnabledChanged() {
                                                    logoSwitch.checked = backend.logoEnabled
                                                }
                                            }
                                        }

                                        Label {
                                            text: window.tr("default_logo")
                                            font.pixelSize: 12
                                        }

                                        ComboBox {
                                            id: defaultLogoCombo
                                            Layout.fillWidth: true
                                            model: backend ? backend.logoItems : []
                                            Component.onCompleted: {
                                                if (backend) currentIndex = backend.defaultLogoIndex
                                            }
                                            onActivated: function(index) {
                                                if (backend && index >= 0) {
                                                    backend.defaultLogoIndex = index
                                                }
                                            }

                                            Connections {
                                                target: backend
                                                function onDefaultLogoIndexChanged() {
                                                    defaultLogoCombo.currentIndex = backend.defaultLogoIndex
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Label {
                                                text: window.tr("output_quality")
                                            }
                                            Slider {
                                                id: qualitySlider
                                                Layout.fillWidth: true
                                                from: 1
                                                to: 100
                                                stepSize: 1
                                                Component.onCompleted: {
                                                    if (backend) value = backend.quality
                                                }
                                                onMoved: {
                                                    if (backend) backend.quality = value
                                                }
                                                Material.accent: Material.Teal

                                                Connections {
                                                    target: backend
                                                    function onQualityChanged() {
                                                        qualitySlider.value = backend.quality
                                                    }
                                                }
                                            }
                                            Label {
                                                text: Math.round(qualitySlider.value) + "%"
                                                font.bold: true
                                            }
                                        }
                                    }
                                }

                                // 文字设置组
                                Pane {
                                    Layout.fillWidth: true
                                    Layout.margins: 16
                                    Layout.bottomMargin: 0
                                    Layout.topMargin: 0
                                    Material.elevation: 3

                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 8

                                        Label {
                                            text: window.tr("text_settings")
                                            font.pixelSize: 14
                                            font.bold: true
                                            color: Material.primary
                                        }

                                        Repeater {
                                            model: [
                                                {labelKey: "left_top", key: "left_top"},
                                                {labelKey: "left_bottom", key: "left_bottom"},
                                                {labelKey: "right_top", key: "right_top"},
                                                {labelKey: "right_bottom", key: "right_bottom"}
                                            ]

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 4

                                                property string posKey: modelData.key
                                                property string labelKey: modelData.labelKey

                                                Label {
                                                    text: window.tr(labelKey)
                                                    font.pixelSize: 12
                                                }

                                                ComboBox {
                                                    id: textCombo
                                                    Layout.fillWidth: true
                                                    model: backend ? backend.textItems : []
                                                    Component.onCompleted: {
                                                        if (backend) currentIndex = backend.getTextIndex(posKey)
                                                    }
                                                    onActivated: function(idx) {
                                                        if (backend && idx >= 0) {
                                                            backend.setTextIndex(posKey, idx)
                                                        }
                                                    }
                                                }

                                                TextField {
                                                    id: customTextField
                                                    Layout.fillWidth: true
                                                    placeholderText: window.tr("custom_text")
                                                    visible: backend ? (backend.getTextIndex(posKey) === backend.customTextIndex) : false
                                                    Component.onCompleted: {
                                                        if (backend) text = backend.getCustomText(posKey)
                                                    }
                                                    onTextEdited: {
                                                        if (backend) backend.setCustomText(posKey, text)
                                                    }
                                                    Material.accent: Material.Teal
                                                }
                                            }
                                        }
                                    }
                                }

                                // 效果设置组
                                Pane {
                                    Layout.fillWidth: true
                                    Layout.margins: 16
                                    Layout.topMargin: 0
                                    Material.elevation: 3

                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 8

                                        Label {
                                            text: window.tr("effect_settings")
                                            font.pixelSize: 14
                                            font.bold: true
                                            color: Material.primary
                                        }

                                        Switch {
                                            id: shadowSwitch
                                            text: window.tr("add_shadow")
                                            Component.onCompleted: {
                                                if (backend) checked = backend.shadowEnabled
                                            }
                                            onToggled: {
                                                if (backend) backend.shadowEnabled = checked
                                            }
                                            Material.accent: Material.Teal

                                            Connections {
                                                target: backend
                                                function onShadowEnabledChanged() {
                                                    shadowSwitch.checked = backend.shadowEnabled
                                                }
                                            }
                                        }

                                        Switch {
                                            id: whiteMarginSwitch
                                            text: window.tr("add_white_border")
                                            Component.onCompleted: {
                                                if (backend) checked = backend.whiteMarginEnabled
                                            }
                                            onToggled: {
                                                if (backend) backend.whiteMarginEnabled = checked
                                            }
                                            Material.accent: Material.Teal

                                            Connections {
                                                target: backend
                                                function onWhiteMarginEnabledChanged() {
                                                    whiteMarginSwitch.checked = backend.whiteMarginEnabled
                                                }
                                            }
                                        }

                                        Switch {
                                            id: paddingRatioSwitch
                                            text: window.tr("padding_ratio")
                                            Component.onCompleted: {
                                                if (backend) checked = backend.paddingRatioEnabled
                                            }
                                            onToggled: {
                                                if (backend) backend.paddingRatioEnabled = checked
                                            }
                                            Material.accent: Material.Teal

                                            Connections {
                                                target: backend
                                                function onPaddingRatioEnabledChanged() {
                                                    paddingRatioSwitch.checked = backend.paddingRatioEnabled
                                                }
                                            }
                                        }

                                        Switch {
                                            id: equivFocalSwitch
                                            text: window.tr("use_equiv_focal")
                                            Component.onCompleted: {
                                                if (backend) checked = backend.equivFocalEnabled
                                            }
                                            onToggled: {
                                                if (backend) backend.equivFocalEnabled = checked
                                            }
                                            Material.accent: Material.Teal

                                            Connections {
                                                target: backend
                                                function onEquivFocalEnabledChanged() {
                                                    equivFocalSwitch.checked = backend.equivFocalEnabled
                                                }
                                            }
                                        }
                                    }
                                }

                                Item { height: 16 }
                            }
                        }

                        // 底部按钮
                        Pane {
                            Layout.fillWidth: true
                            Material.elevation: 2
                            padding: 12

                            RowLayout {
                                anchors.fill: parent
                                spacing: 8

                                Button {
                                    Layout.fillWidth: true
                                    text: window.tr("reset_config")
                                    flat: true
                                    onClicked: {
                                        if (backend) backend.loadConfig()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==================== 右侧面板（文件列表/预览） ====================
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: mainTabBar.currentIndex

            // ========== Process Tab 右侧：文件列表 + 进度条 ==========
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // 文件列表
                Pane {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Material.elevation: 1
                    padding: 0

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // 工具栏
                        Pane {
                            Layout.fillWidth: true
                            Material.background: Material.color(Material.Grey, Material.Shade100)
                            padding: 8

                            RowLayout {
                                anchors.fill: parent
                                spacing: 8

                                Label {
                                    text: window.tr("pending_files") + " (" + (backend ? backend.fileCount : 0) + " " + window.tr("images_count") + ")"
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                Button {
                                    text: window.tr("refresh")
                                    icon.name: "view-refresh"
                                    flat: true
                                    onClicked: {
                                        if (backend) backend.refreshFileList()
                                    }
                                }

                                Button {
                                    text: window.tr("add")
                                    icon.name: "list-add"
                                    flat: true
                                    onClicked: addFilesDialog.open()
                                }

                                Button {
                                    text: window.tr("clear")
                                    icon.name: "edit-clear"
                                    flat: true
                                    onClicked: {
                                        if (backend) backend.clearFileList()
                                    }
                                }
                            }
                        }

                        // 表头
                        Pane {
                            Layout.fillWidth: true
                            Material.background: Material.color(Material.Grey, Material.Shade200)
                            padding: 0
                            topPadding: 8
                            bottomPadding: 8

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                Label {
                                    text: window.tr("file_name")
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: window.tr("shoot_time")
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Label {
                                    text: window.tr("file_size")
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.preferredWidth: 70
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }

                        // 文件列表
                        ListView {
                            id: fileListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: backend ? backend.fileList : []
                            currentIndex: backend ? backend.selectedFileIndex : -1

                            delegate: ItemDelegate {
                                width: fileListView.width
                                height: 48
                                highlighted: ListView.isCurrentItem

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12

                                    Label {
                                        text: modelData.name || ""
                                        font.pixelSize: 14
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        text: modelData.datetime || ""
                                        color: Material.hintTextColor
                                        font.pixelSize: 13
                                    }

                                    Label {
                                        text: modelData.size || ""
                                        color: Material.hintTextColor
                                        font.pixelSize: 13
                                        Layout.preferredWidth: 70
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                onClicked: {
                                    if (backend) {
                                        fileListView.currentIndex = index
                                        backend.selectedFileIndex = index
                                    }
                                }
                            }

                            ScrollBar.vertical: ScrollBar {}

                            // 空列表提示
                            Label {
                                anchors.centerIn: parent
                                text: window.tr("no_files_in_dir")
                                color: Material.hintTextColor
                                visible: fileListView.count === 0
                            }
                        }
                    }
                }

                // 进度条
                Pane {
                    Layout.fillWidth: true
                    Material.elevation: 1
                    padding: 12

                    RowLayout {
                        anchors.fill: parent
                        spacing: 12

                        ProgressBar {
                            id: progressBar
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: backend ? backend.progress : 0
                            Material.accent: Material.Teal
                        }

                        Label {
                            text: backend ? backend.progressText : ""
                            color: Material.hintTextColor
                        }
                    }
                }
            }

            // ========== Settings Tab 右侧：预览 ==========
            Pane {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Material.elevation: 1
                padding: 0

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // 预览标题栏
                    Pane {
                        Layout.fillWidth: true
                        Material.background: Material.color(Material.Grey, Material.Shade100)
                        padding: 8

                        RowLayout {
                            anchors.fill: parent

                            Label {
                                text: window.tr("preview_title")
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Button {
                                text: window.tr("refresh_preview")
                                flat: true
                                onClicked: {
                                    if (backend) backend.refreshPreview()
                                }
                            }
                        }
                    }

                    // 预览图片
                    Rectangle {
                        id: previewContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#2d2d2d"
                        clip: true

                        property real imageScale: 1.0
                        property real minScale: 0.5
                        property real maxScale: 5.0
                        property real imageOffsetX: 0
                        property real imageOffsetY: 0

                        function resetView() {
                            imageScale = 1.0
                            imageOffsetX = 0
                            imageOffsetY = 0
                        }

                        Item {
                            id: imageWrapper
                            anchors.fill: parent
                            anchors.margins: 16

                            Image {
                                id: previewImage
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: previewContainer.imageOffsetX
                                anchors.verticalCenterOffset: previewContainer.imageOffsetY
                                width: parent.width
                                height: parent.height
                                fillMode: Image.PreserveAspectFit
                                source: backend ? backend.previewImage : ""
                                asynchronous: true
                                cache: false
                                scale: previewContainer.imageScale
                                transformOrigin: Item.Center

                                onStatusChanged: {
                                    if (status === Image.Ready) {
                                        previewContainer.resetView()
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent

                                property real lastX: 0
                                property real lastY: 0

                                onPressed: function(event) {
                                    lastX = event.x
                                    lastY = event.y
                                    cursorShape = Qt.ClosedHandCursor
                                }

                                onReleased: {
                                    cursorShape = Qt.OpenHandCursor
                                }

                                onPositionChanged: function(event) {
                                    if (pressed) {
                                        var dx = event.x - lastX
                                        var dy = event.y - lastY
                                        previewContainer.imageOffsetX += dx
                                        previewContainer.imageOffsetY += dy
                                        lastX = event.x
                                        lastY = event.y
                                    }
                                }

                                onDoubleClicked: {
                                    previewContainer.resetView()
                                }

                                onWheel: function(event) {
                                    var delta = event.angleDelta.y / 120
                                    var scaleFactor = 1.0 + delta * 0.15
                                    var oldScale = previewContainer.imageScale
                                    var newScale = oldScale * scaleFactor

                                    newScale = Math.max(previewContainer.minScale, Math.min(previewContainer.maxScale, newScale))

                                    if (newScale !== oldScale) {
                                        var centerX = imageWrapper.width / 2 + previewContainer.imageOffsetX
                                        var centerY = imageWrapper.height / 2 + previewContainer.imageOffsetY

                                        var mouseOffsetX = event.x - centerX
                                        var mouseOffsetY = event.y - centerY

                                        var scaleChange = newScale / oldScale

                                        previewContainer.imageOffsetX -= mouseOffsetX * (scaleChange - 1)
                                        previewContainer.imageOffsetY -= mouseOffsetY * (scaleChange - 1)

                                        previewContainer.imageScale = newScale
                                    }
                                }

                                cursorShape: Qt.OpenHandCursor
                            }
                        }

                        BusyIndicator {
                            anchors.centerIn: parent
                            running: backend ? backend.previewLoading : false
                            Material.accent: Material.Teal
                        }

                        Label {
                            anchors.centerIn: parent
                            text: backend ? backend.previewMessage : ""
                            color: "#aaaaaa"
                            visible: previewImage.status !== Image.Ready && !(backend && backend.previewLoading)
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Label {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 8
                            text: Math.round(previewContainer.imageScale * 100) + "%"
                            color: "#888888"
                            font.pixelSize: 12
                            visible: previewImage.status === Image.Ready
                        }

                        Button {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: 8
                            text: "1:1"
                            flat: true
                            visible: previewImage.status === Image.Ready && (previewContainer.imageScale !== 1.0 || previewContainer.imageOffsetX !== 0 || previewContainer.imageOffsetY !== 0)
                            onClicked: previewContainer.resetView()
                            Material.foreground: "#888888"
                        }
                    }
                }
            }
        }
    }

    // Snackbar 提示
    Pane {
        id: savedSnackbar
        visible: false
        Material.elevation: 6
        Material.background: Material.color(Material.Grey, Material.Shade800)
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 24
        padding: 16

        function open() {
            visible = true
            snackbarTimer.start()
        }

        Timer {
            id: snackbarTimer
            interval: 2000
            onTriggered: savedSnackbar.visible = false
        }

        Label {
            text: window.tr("config_saved")
            color: "white"
        }
    }

    // 完成对话框
    Dialog {
        id: finishedDialog
        title: window.tr("process_complete")
        standardButtons: Dialog.Ok
        anchors.centerIn: parent
        modal: true
        width: 400

        contentItem: Label {
            text: window.tr("all_done") + "\n" + window.tr("output_dir_label") + (backend ? backend.outputDir : "")
            wrapMode: Text.Wrap
        }
    }

    Connections {
        target: backend
        function onProcessingFinished() {
            finishedDialog.open()
        }
    }
}
