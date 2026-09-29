<div align="center">

# Oh là là

**Accents the phone way, on Omarchy.**
Hold a letter, pick é, ñ, ü or č from a popup.

`de.gransoftware.ohlala`&nbsp;&nbsp;·&nbsp;&nbsp;![version](https://img.shields.io/badge/version-1.0.0-2f6f4e?style=flat-square)&nbsp;![shell](https://img.shields.io/badge/Omarchy-shell%20plugin-3b4252?style=flat-square)

<br>

<img src="preview-light.webp" alt="A finger holds the E key on a white keyboard; above it the Oh là là popup offers € é è ê ë ē ė ę, with é highlighted and the flags of French, Spanish, Hungarian and Czech below" width="49%">&nbsp;<img src="preview-dark.webp" alt="The same popup in the dark Tokyo Night theme, above a finger holding the E key on a backlit dark keyboard" width="49%">

<sub>Follows the active Omarchy theme and font — Snow and Tokyo Night here.</sub>

</div>

<br>

## Install

```bash
sudo pacman -S --needed keyd wtype wl-clipboard jq
omarchy plugin add https://github.com/gran-software-solutions/ohlala-omarchy-plugin.git --enable --yes
~/.config/omarchy/plugins/de.gransoftware.ohlala/bin/ohlala setup
```

`setup` writes `/etc/keyd/default.conf` and starts [keyd](https://github.com/rvaiya/keyd),
so it asks for your sudo password. It refuses to overwrite a keyd config it did not write.

### Update and remove

```bash
omarchy plugin update de.gransoftware.ohlala
```

```bash
~/.config/omarchy/plugins/de.gransoftware.ohlala/bin/ohlala remove
omarchy plugin remove de.gransoftware.ohlala
```

## Use

Hold a letter for a moment and the popup appears. Hold `Shift` too for capitals.

| | |
| --- | --- |
| `1` – `9` | Pick that character |
| the same letter · `→` · `l` · `Tab` | Next |
| `←` · `h` | Previous |
| `Enter` · `Space` · click | Pick the highlighted one |
| any other key · click outside | Cancel |

Below the row you see which languages use the highlighted letter.

## Your own letters

Copy the defaults and edit them:

```bash
mkdir -p ~/.config/ohlala
cp ~/.config/omarchy/plugins/de.gransoftware.ohlala/accents.conf ~/.config/ohlala/
```

Each line is `letter = characters`, in popup order:

```ini
e = é è ê ë
s = š ß ś
S = Š ẞ Ś
```

Capitals come for free; add an uppercase line only to change them. New
characters for a letter work right away. After you add or remove a letter, run
`bin/ohlala setup` again so keyd watches the right keys.

<details>
<summary><b>How it works</b></summary>
<br>

keyd turns every configured letter into "tap types the letter, hold for 350 ms
runs `bin/ohlala <letter>`". That script finds your Hyprland session and asks
the kept-loaded overlay inside `omarchy-shell` to show the popup, so there is
no cold start.

When you pick, the overlay calls `bin/ohlala type <char>`. In terminals it types
the character with `wtype`. Everywhere else it pastes it and puts your previous
clipboard back, because Chromium drops characters that `wtype` types.

If the keyboard ever misbehaves, `Backspace` + `Escape` + `Enter` kills keyd.

</details>

## Vibe-coded

Every line of this plugin was written by [Claude](https://claude.com/claude-code)
from conversational prompts. keyd runs as root and the overlay runs unsandboxed
inside `omarchy-shell`, so read the source before you enable it.

## License

[MIT](LICENSE) © Gran Software Solutions
