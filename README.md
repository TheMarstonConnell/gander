# gander
gander is a very lightweight text editor for macOS. It does one thing really well: simply edit plaintext. Everything else is superfluous and doesn't matter to the function of this app. Regard it as a TextEdit replacement rather than a VSCode replacement.
<img width="857" height="673" alt="image" src="https://github.com/user-attachments/assets/e952e408-51a9-4147-8b2b-62d8e90682fa" />

## Install
Head to the [Releases](https://github.com/TheMarstonConnell/gander/releases) tab and download the DMG of the version you want. Open it and drag it to `Applications`. You will likely need to allow it from the security settings since it is currently an unsigned application that macOS will surely flag as malicious.
## Config
Click `Open Config...` in the file menu to edit the config file. Every config value is a simple `key=value` list.

Example config:
```
# Gander Configuration
# Changes take effect on next app launch.
#
# Available themes: Catppuccin Frappe, Catppuccin Latte, Catppuccin Macchiato, Catppuccin Mocha, Dracula, Monokai Extended, Nord, OneHalfDark, OneHalfLight, Solarized Dark, Solarized Light, ansi, base16, base16-256
#
theme=Solarized Light
```

### Themeing
gander supports themeing. It supports the same themes as [`bat`](https://github.com/sharkdp/bat/tree/master/assets/themes).

Dracula example:
<img width="841" height="664" alt="image" src="https://github.com/user-attachments/assets/6edcda9c-80cf-474d-8ad5-10fd1baf7eff" />
