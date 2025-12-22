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

    // 主布局
    RowLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // 左侧配置面板
        Pane {
            Layout.preferredWidth: 380
            Layout.fillHeight: true
            Material.elevation: 2
            padding: 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // 标题栏
                Pane {
                    Layout.fillWidth: true
                    Material.elevation: 1
                    Material.background: Material.primary
                    padding: 16

                    RowLayout {
                        anchors.fill: parent

                        Label {
                            text: window.tr("config_settings")
                            font.pixelSize: 20
                            font.bold: true
                            color: "white"
                        }

                        Item { Layout.fillWidth: true }

                        // 语言选择
                        Label {
                            text: "Language:"
                            color: "white"
                            font.pixelSize: 12
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

                            Connections {
                                target: backend
                                function onLanguageChanged() {
                                    languageCombo.currentIndex = backend.languageIndex
                                }
                            }
                        }
                    }
                }

                // 标签页
                TabBar {
                    id: tabBar
                    Layout.fillWidth: true
                    Material.accent: Material.Teal

                    TabButton {
                        text: window.tr("layout")
                        width: implicitWidth
                    }
                    TabButton {
                        text: window.tr("text")
                        width: implicitWidth
                    }
                    TabButton {
                        text: window.tr("effects")
                        width: implicitWidth
                    }
                }

                // 标签页内容
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: tabBar.currentIndex

                    // 布局设置页
                    ScrollView {
                        id: layoutScrollView
                        clip: true
                        contentWidth: availableWidth

                        ColumnLayout {
                            width: layoutScrollView.availableWidth
                            spacing: 16

                            Pane {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                Material.elevation: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    Label {
                                        text: window.tr("layout_type")
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: Material.foreground
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
                                                // 更新 model 并保持选中项
                                                var idx = layoutCombo.currentIndex
                                                layoutCombo.model = backend.layoutItems
                                                layoutCombo.currentIndex = idx
                                            }
                                        }
                                    }
                                }
                            }

                            Pane {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                Layout.topMargin: 0
                                Material.elevation: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    Label {
                                        text: window.tr("logo_settings")
                                        font.pixelSize: 14
                                        font.bold: true
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
                                        color: Material.hintTextColor
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
                                }
                            }

                            Pane {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                Layout.topMargin: 0
                                Material.elevation: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    Label {
                                        text: window.tr("output_settings")
                                        font.pixelSize: 14
                                        font.bold: true
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

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // 文字设置页
                    ScrollView {
                        id: textScrollView
                        clip: true
                        contentWidth: availableWidth

                        ColumnLayout {
                            width: textScrollView.availableWidth
                            spacing: 8

                            Repeater {
                                model: [
                                    {labelKey: "left_top", key: "left_top"},
                                    {labelKey: "left_bottom", key: "left_bottom"},
                                    {labelKey: "right_top", key: "right_top"},
                                    {labelKey: "right_bottom", key: "right_bottom"}
                                ]

                                Pane {
                                    Layout.fillWidth: true
                                    Layout.margins: 16
                                    Layout.topMargin: index === 0 ? 16 : 0
                                    Material.elevation: 1

                                    property string posKey: modelData.key
                                    property string labelKey: modelData.labelKey

                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 8

                                        Label {
                                            text: window.tr(labelKey)
                                            font.pixelSize: 14
                                            font.bold: true
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

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // 效果设置页
                    ScrollView {
                        id: effectsScrollView
                        clip: true
                        contentWidth: availableWidth

                        ColumnLayout {
                            width: effectsScrollView.availableWidth
                            spacing: 16

                            Pane {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                Material.elevation: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    Label {
                                        text: window.tr("effect_settings")
                                        font.pixelSize: 14
                                        font.bold: true
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
                                }
                            }

                            Pane {
                                Layout.fillWidth: true
                                Layout.margins: 16
                                Layout.topMargin: 0
                                Material.elevation: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    Label {
                                        text: window.tr("focal_settings")
                                        font.pixelSize: 14
                                        font.bold: true
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

                            Item { Layout.fillHeight: true }
                        }
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
                            text: window.tr("save_config")
                            Material.background: Material.Teal
                            Material.foreground: "white"
                            onClicked: {
                                if (backend) {
                                    backend.saveConfig()
                                    savedSnackbar.open()
                                }
                            }
                        }

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

        // 右侧文件和预览面板
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // 目录设置
            Pane {
                Layout.fillWidth: true
                Material.elevation: 1
                padding: 16

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: window.tr("input_dir")
                            Layout.preferredWidth: 80
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
                            Layout.preferredWidth: 80
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
                }
            }

            // 文件列表和预览区域
            SplitView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical

                // 文件列表
                Pane {
                    SplitView.preferredHeight: 200
                    SplitView.minimumHeight: 100
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
                                    text: window.tr("pending_files")
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                Button {
                                    text: window.tr("refresh")
                                    flat: true
                                    onClicked: {
                                        if (backend) backend.refreshFileList()
                                    }
                                }

                                Button {
                                    text: window.tr("add")
                                    flat: true
                                    onClicked: addFilesDialog.open()
                                }

                                Button {
                                    text: window.tr("clear")
                                    flat: true
                                    onClicked: {
                                        if (backend) backend.clearFileList()
                                    }
                                }

                                Label {
                                    text: (backend ? backend.fileCount : 0) + " " + window.tr("images_count")
                                    color: Material.hintTextColor
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
                                height: 40
                                highlighted: ListView.isCurrentItem

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16

                                    Label {
                                        text: modelData
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
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
                        }
                    }
                }

                // 预览区域
                Pane {
                    SplitView.fillHeight: true
                    SplitView.minimumHeight: 300
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
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#2d2d2d"

                            Image {
                                id: previewImage
                                anchors.fill: parent
                                anchors.margins: 16
                                fillMode: Image.PreserveAspectFit
                                source: backend ? backend.previewImage : ""
                                asynchronous: true
                                cache: false

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
                            }
                        }
                    }
                }
            }

            // 底部进度和操作栏
            Pane {
                Layout.fillWidth: true
                Material.elevation: 2
                padding: 16

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    // 进度条
                    RowLayout {
                        Layout.fillWidth: true
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

                    // 操作按钮
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
