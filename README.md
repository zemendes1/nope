[![nope logo](/screenshots/app-icon.png)](https://github.com/zemendes1/nope)

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/zemendes1/nope)](https://github.com/zemendes1/nope/releases/latest)
[![GitHub all releases](https://img.shields.io/github/downloads/zemendes1/nope/total)](https://github.com/zemendes1/nope/releases)
[![GitHub](https://img.shields.io/github/license/zemendes1/nope)](https://github.com/zemendes1/nope/blob/master/LICENSE)
[![GitHub Sponsors](https://img.shields.io/badge/sponsor-zemendes1-ec5cc7.svg)](https://github.com/sponsors/zemendes1)

# nope

nope is a macOS menu bar app that stops built-in apps you never use, like Apple Music or Games, from launching.

Launch nope and those apps won't be able to open, even when macOS tries to open them on its own, for example when your Bluetooth headphones reconnect.

Left-click the menu bar icon to turn it on or off.

nope is based on [noTunes](https://github.com/tombonez/noTunes) by Tom Taylor.

## Installation

### Direct Download

Download the latest release from the [Releases page](https://github.com/zemendes1/nope/releases/latest).

## Usage

### Set nope to launch at startup

#### Ventura and later:

1. Navigate to System Settings
2. Select General
3. Select Login Items
4. Click the + under Open at Login and select nope

#### Before Ventura:

Navigate to System Preferences -> Users & Groups. Under your user, select "Login Items", click the lock on the bottom left and enter your login password to make changes. Click the plus sign (+) in the main panel and search for nope. Select it and click "Add".

### Toggle nope

Left click the menu bar icon to toggle between its active states.

**Enabled (prevents iTunes/Music from opening)**

![nope enabled](/screenshots/menubar-enabled.png)

**Disabled (allows iTunes/Music to open)**

![nope disabled](/screenshots/menubar-disabled.png)

### Hide Menu Bar Icon

Right click or control-click the menu bar icon and click `Hide Icon`.

### Restore Menu Bar Icon

[Quit nope](#quit-nope), run the following command in Terminal and re-open the app:

```bash
defaults delete com.zemendes1.nope
```

### Quit nope

To quit the app either:

**With menu bar icon visible**

Right click or control-click the menu bar icon and click quit.

**With menu bar icon hidden**

Quit the app via Activity Monitor or run the following command in Terminal:

```bash
osascript -e 'quit app "nope"'
```

### Open something else instead

nope can open another app or website whenever a blocked app tries to launch.

Right-click or control-click the menu bar icon, then pick from:

- **Instead of Music, open**: Spotify, TIDAL, YouTube Music (web), SoundCloud (web), or any app via **Choose App…**
- **Instead of Games, open**: Steam, Epic Games Launcher, or any app via **Choose App…**

Apps that aren't installed are greyed out. Pick **Nothing** to turn a replacement off.

You can also set them from Terminal with an app path, a website, or a bundle ID. The keys are `replacement` (Music) and `gamesReplacement` (Games):

```bash
defaults write com.zemendes1.nope replacement https://music.youtube.com/
defaults write com.zemendes1.nope gamesReplacement /Applications/Steam.app
defaults delete com.zemendes1.nope replacement
```

## Support

If you like my work, consider supporting me through [GitHub Sponsors](https://github.com/sponsors/zemendes1) 🩷

## License

The code is available under the [MIT License](https://github.com/zemendes1/nope/blob/master/LICENSE).
