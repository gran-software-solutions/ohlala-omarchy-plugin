// Oh là là: press-and-hold accent picker. Lives inside omarchy-shell as a
// kept-loaded overlay, so showing it is an IPC call rather than a Quickshell
// cold start:
//
//   omarchy-shell shell summon de.gransoftware.ohlala '{"key":"e","chars":"é è ê"}'
//
// Number keys pick instantly; repeating the base letter or arrows move the
// highlight (also h/l), Enter/Space or a click picks; any other key, or a click
// outside the popup, cancels. The chosen character is typed by
// bin/ohlala type <char>.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property bool opened: false
  property var chars: []
  property string baseKey: ""
  property int sel: 0

  readonly property string helperPath: Qt.resolvedUrl("bin/ohlala").toString().replace(/^file:\/\//, "")

  readonly property int pad: Style.space(10)
  readonly property int cellW: Style.space(32)
  readonly property int cellH: Style.space(42)

  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = {} }
    var list = String(payload.chars || "").split(" ").filter(c => c.length > 0)
    if (list.length === 0) { root.close(); return }
    // Holding the letter while the popup is open must not reset the picker.
    if (root.opened) return
    root.chars = list
    root.baseKey = String(payload.key || "").toLowerCase()
    root.sel = 0
    root.opened = true
    Qt.callLater(function() { keys.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function pick(i) {
    if (i < 0 || i >= chars.length) return
    var ch = chars[i]
    root.close()
    Quickshell.execDetached([root.helperPath, "type", ch])
  }

  // ISO 639-1 codes of the main languages that use each accented letter, shown as
  // flag + code under the row for the highlighted one. Keyed by lowercase; uppercase
  // letters are looked up via toLowerCase().
  property var langs: ({
    "ä": "de sv fi sk",
    "à": "fr it pt ca",
    "á": "es pt hu cs",
    "â": "fr pt ro",
    "ã": "pt",
    "å": "sv da no",
    "æ": "da no",
    "ā": "lv",
    "ą": "pl lt",
    "é": "fr es hu cs",
    "è": "fr it ca",
    "ê": "fr pt",
    "ë": "fr nl sq",
    "ē": "lv",
    "ė": "lt",
    "ę": "pl lt",
    "í": "es pt hu cs",
    "ì": "it",
    "î": "fr ro",
    "ï": "fr nl ca",
    "ī": "lv",
    "į": "lt",
    "ö": "de sv fi hu tr",
    "ó": "pl es hu pt",
    "ò": "it ca",
    "ô": "fr pt sk",
    "õ": "pt et",
    "ø": "da no",
    "œ": "fr",
    "ō": "la mi ja",
    "ü": "de tr hu es",
    "ú": "es pt hu cs",
    "ù": "fr it",
    "û": "fr",
    "ū": "lv lt",
    "č": "sr hr cs sk sl",
    "ć": "sr hr pl",
    "ç": "fr pt tr ca",
    "š": "sr hr cs sk sl",
    "ß": "de",
    "ś": "pl",
    "ž": "sr hr cs sk sl",
    "ź": "pl",
    "ż": "pl mt",
    "đ": "sr hr vi",
    "ñ": "es",
    "ń": "pl",
    "ÿ": "fr nl",
    "ý": "cs sk is",
    "ł": "pl"
  })

  // Flag for each language code; Catalan and Latin have no emoji flag, so they get a plain one.
  property var flags: ({
    "de": "🇩🇪",
    "sv": "🇸🇪",
    "fi": "🇫🇮",
    "sk": "🇸🇰",
    "fr": "🇫🇷",
    "it": "🇮🇹",
    "pt": "🇵🇹",
    "ca": "🏳️",
    "es": "🇪🇸",
    "hu": "🇭🇺",
    "cs": "🇨🇿",
    "ro": "🇷🇴",
    "da": "🇩🇰",
    "no": "🇳🇴",
    "lv": "🇱🇻",
    "pl": "🇵🇱",
    "lt": "🇱🇹",
    "nl": "🇳🇱",
    "sq": "🇦🇱",
    "tr": "🇹🇷",
    "et": "🇪🇪",
    "la": "🏳️",
    "mi": "🇳🇿",
    "ja": "🇯🇵",
    "sr": "🇷🇸",
    "hr": "🇭🇷",
    "sl": "🇸🇮",
    "mt": "🇲🇹",
    "vi": "🇻🇳",
    "is": "🇮🇸"
  })

  function langCodes(ch) {
    return (langs[(ch || "").toLowerCase()] || "").split(" ").filter(c => c.length > 0)
  }

  PanelWindow {
    id: popup
    visible: root.opened
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "ohlala"
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Full-screen transparent surface with the card centered: a click anywhere off
    // the card lands on this surface and closes the picker.
    anchors { top: true; bottom: true; left: true; right: true }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onPressed: root.close()
    }

    // Omarchy popup card: themed background and font, with a hairline border tinted
    // from the text color (softer than the accent outline) and gentle rounding.
    BorderSurface {
      id: card
      anchors.centerIn: parent
      width: card.borderLeft + root.pad + Math.max(row.width, langRow.width) + root.pad + card.borderRight
      height: card.borderTop + root.pad + row.height + Style.spacing.lg + separator.height
        + Style.spacing.lg + langRow.height + root.pad + card.borderBottom
      color: Color.popups.background
      border.width: 1
      border.color: Util.alpha(Color.popups.text, 0.14)
      radius: Style.space(6)
      scale: 2.5

      opacity: root.opened ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

      // Swallow clicks on the card's own padding so they don't reach the close area.
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
      }

      Row {
        id: row
        x: (card.width - width) / 2
        y: card.borderTop + root.pad
        spacing: Style.spacing.xs

        Repeater {
          model: root.chars

          // Shared hover/keyboard-cursor chrome used by Omarchy panel rows.
          CursorSurface {
            id: cell
            required property int index
            required property string modelData
            width: root.cellW
            height: root.cellH
            hasCursor: index === root.sel

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              y: Style.space(3)
              text: cell.modelData
              font.family: Style.font.family
              font.pixelSize: Style.space(19)
              color: Color.popups.text
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Style.space(3)
              text: cell.index + 1
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              color: cell.hasCursor ? Color.accent : Util.alpha(Color.popups.text, 0.45)
            }
            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: root.sel = cell.index
              onClicked: root.pick(cell.index)
            }
          }
        }
      }

      PanelSeparator {
        id: separator
        x: card.borderLeft + root.pad
        width: card.width - card.borderLeft - card.borderRight - 2 * root.pad
        anchors.top: row.bottom
        anchors.topMargin: Style.spacing.lg
        foreground: Color.popups.text
      }

      // Languages that use the highlighted letter: flag + ISO code.
      Row {
        id: langRow
        x: (card.width - width) / 2
        anchors.top: separator.bottom
        anchors.topMargin: Style.spacing.lg
        spacing: Style.spacing.lg

        Repeater {
          model: root.langCodes(root.chars[root.sel])

          Text {
            required property string modelData
            text: (root.flags[modelData] || "") + " " + modelData.toUpperCase()
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            color: Util.alpha(Color.popups.text, 0.7)
          }
        }
      }

      Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: function(event) {
          if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) root.pick(event.key - Qt.Key_1)
          else if (event.text && event.text.toLowerCase() === root.baseKey) root.sel = (root.sel + 1) % root.chars.length
          else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) root.sel = Math.max(0, root.sel - 1)
          else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_Tab) root.sel = Math.min(root.chars.length - 1, root.sel + 1)
          else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.pick(root.sel)
          else root.close()
          event.accepted = true
        }
      }
    }
  }
}
