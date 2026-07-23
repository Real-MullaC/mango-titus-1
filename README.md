<div align="center">
  <img src="./config/quickshell/assets/ctt_logo.png" alt="mango-titus" width="96" height="96"/>

  # mango-titus
  ### dwm-titus–shaped desktop on [mangowm](https://github.com/mangowm/mango) for Wayland.

</div>

---

This is a **Wayland** desktop modeled on [dwm-titus](https://github.com/ChrisTitusTech/dwm-titus): the same Quickshell panel, launcher, control center, and day-to-day workflow, running on [mangowm](https://github.com/mangowm/mango) instead of X11 dwm. Quickshell is kept (not DMS). **Arch Linux** is the primary test target; Fedora and Debian/Ubuntu are supported in `install.sh` but exercised second.

mango-titus is namespaced so it can **live alongside dwm-titus** on the same machine. Config lives under `~/.config/mango-titus/`, helpers are `mango-titus-*` on `PATH`, and the session is **Mango Titus** — it does not overwrite `~/.config/quickshell`, shadow `dwm-*` binaries, or replace stock `~/.config/mango` unless you opt in with `--replace-mango-config`. Pick **dwm** or **Mango Titus** at the display manager; both can remain installed.

### Features

- **Quickshell** panel, launcher, control center, notifications, and power menu
- **mangowm** tiling compositor (tags, floating, fullscreen, overview, scratchpads)
- **Window rules** and keybinds aligned with the dwm-titus desktop habits
- **Wallpaper** via `awww`, lock via `swaylock-effects`, idle via `swayidle`
- **Screenshots** with Flameshot + Wayland portals
- **Multi-monitor** helpers (`mango-titus-display-setup` / `mango-titus-display-profile`)
- **Nord-themed** defaults with theme apply helpers
- **Optional gaming extras** on the full profile (Steam, Gamescope, GameMode, MangoHud where available)

---

## Install

| Path | Best for | Result |
|------|----------|--------|
| `install.sh` | Existing Arch, Fedora, or Debian/Ubuntu system | Installs dependencies, deploys mango-titus config + Quickshell, and registers the Wayland session |

### Install on an Existing System

```bash
git clone https://github.com/ChrisTitusTech/mango-titus.git
cd mango-titus

./install.sh --profile recommended
```

Profiles:

| Profile | Use when you want |
|---------|-------------------|
| `recommended` | mangowm, Quickshell, terminals, fonts, theming, screenshots, audio, brightness, portals, and session helpers (default) |
| `full` | `recommended` plus optional extras; on Fedora x86_64, gaming packages after `--enable-gaming` |

Login / display manager:

| Flag | Notes |
|------|-------|
| `--login lightdm` | Default — slick-greeter (greeter may need Xorg/Xlibre) |
| `--login greetd` | Wayland-native (tuigreet) |
| `--login ly` | TUI display manager |

Other useful flags:

```bash
./install.sh --profile full --enable-gaming
./install.sh --replace-mango-config   # opt-in: also touch stock ~/.config/mango
```

Ensure `~/.local/bin` is on your `PATH`. The installer installs `mango-titus-session` to `/usr/local/bin` so display managers find it.

### Starting mango-titus

With a display manager, log out, select the **Mango Titus** session, and log back in.

From a TTY or script:

```bash
mango-titus-session
```

After login, use these first:

| Keybind | Action |
|---------|--------|
| <kbd>SUPER</kbd> + <kbd>X</kbd> | Open terminal |
| <kbd>SUPER</kbd> + <kbd>R</kbd> | Toggle Quickshell launcher |
| <kbd>SUPER</kbd> + <kbd>F1</kbd> | Open control center |
| <kbd>SUPER</kbd> + <kbd>/</kbd> | Open keybind viewer |

---

## ⌨️ Keybindings

Press <kbd>SUPER</kbd> + <kbd>/</kbd> for an **interactive keybind viewer**.

Binds live in `bind.conf` (deployed to `~/.config/mango-titus/bind.conf`).

### Essential Keybinds

| Keybind | Action |
|---------|--------|
| <kbd>SUPER</kbd> + <kbd>X</kbd> | Open terminal |
| <kbd>SUPER</kbd> + <kbd>R</kbd> / <kbd>SUPER</kbd> + <kbd>Space</kbd> | Toggle Quickshell launcher |
| <kbd>SUPER</kbd> + <kbd>Q</kbd> | Close window |
| <kbd>ALT</kbd> + arrows | Focus window by direction |
| <kbd>SUPER</kbd> + <kbd>Shift</kbd> + arrows | Swap window by direction |
| <kbd>SUPER</kbd> + <kbd>1-9</kbd> | Switch to tag (workspace) |
| <kbd>SUPER</kbd> + <kbd>Shift</kbd> + <kbd>1-9</kbd> | Move window to tag |
| <kbd>SUPER</kbd> + <kbd>Space</kbd> | Toggle floating |
| <kbd>SUPER</kbd> + <kbd>F</kbd> | Fullscreen |
| <kbd>SUPER</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd> | Fake fullscreen |
| <kbd>SUPER</kbd> + <kbd>Tab</kbd> | Overview |
| <kbd>SUPER</kbd> + <kbd>N</kbd> | Cycle layout |
| <kbd>SUPER</kbd> + <kbd>Ctrl</kbd> + <kbd>Q</kbd> | Power menu |
| <kbd>SUPER</kbd> + <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Q</kbd> | Quit mangowm |

---

## 🔧 Configuration

mango-titus is configured with mangowm conf files under `~/.config/mango-titus/` (no recompile):

| File | Purpose |
|------|---------|
| `config.conf` | Compositor options, autostart / `exec-once` |
| `bind.conf` | Keybinds and mouse binds |
| `rule.conf` | Window rules |
| `tag.conf` / `monitor.conf` / `env.conf` | Tags, monitors, environment |
| `quickshell/` | Panel, launcher, control center, themes |
| `scripts/` | Lock, wallpaper, screenshot, terminal, idle, session |

Reload compositor config after edits (default: <kbd>SUPER</kbd> + <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd>), or restart Quickshell from the control center / `mango-titus-cc action restart-quickshell`.

Useful commands:

```bash
mango-titus-display-setup wizard
mango-titus-display-profile list
mango-titus-theme-apply
mango-titus-health scan-user
~/.config/mango-titus/scripts/lock.sh
~/.config/mango-titus/scripts/wallpaper.sh
```

---

## 🔍 Troubleshooting

**Black screen / session doesn't start:**
- Confirm mangowm is installed and `mango-titus-session` exists (`command -v mango-titus-session`).
- Check `~/.config/mango-titus/config.conf` and that `~/.local/bin` is on `PATH`.
- Try from a TTY: `mango-titus-session` and read the errors.

**No status bar / Quickshell missing:**
- Install the recommended desktop layer: `./install.sh --profile recommended`
- Verify: `ls ~/.config/mango-titus/quickshell/shell.qml`
- Run manually: `qs -c ~/.config/mango-titus/quickshell --no-duplicate`

**Terminal doesn't open (<kbd>SUPER</kbd>+<kbd>X</kbd>):**
- Install a terminal (`alacritty`, `kitty`, …) or edit `scripts/terminal.sh` / binds
- Browser / defaults: `mango-titus-default-apps`
- Display: `mango-titus-display-setup` (use `detect` first)
- Health: Control Center → System Health, or `mango-titus-health scan-user`

**Panel shows a JSON error instead of “Desktop”:**
- Ensure helpers are current (`mango-titus-state`); they use current `mmsg` JSON IPC (`get focusing-client`), not legacy `mmsg -g` flags.

**Multi-monitor issues:**
- Run `mango-titus-display-setup wizard` and save a profile under `~/.config/mango-titus/display-profiles/`

**Dependency check:**
```bash
mango-titus-check-deps
```

---

## 📁 Project Structure

| Path | Purpose |
|------|---------|
| `install.sh` | Bootstrap for Arch, Fedora, and Debian/Ubuntu |
| `config.conf`, `bind.conf`, `rule.conf`, … | mangowm session config → `~/.config/mango-titus/` |
| `mango-titus.desktop` | Wayland session entry for display managers |
| `config/quickshell/` | Quickshell shell → `~/.config/mango-titus/quickshell/` |
| `scripts/` | Session helpers (lock, wallpaper, screenshot, display, …) |
| `scripts/helpers/` | Quickshell backends → `~/.local/share/mango-titus/scripts` (`mango-titus-*` on PATH) |
