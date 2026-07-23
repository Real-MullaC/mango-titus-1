#!/usr/bin/env bash
# mango-titus bootstrap — dwm-titus–shaped desktop on mangowm (namespaced paths)
# Distros: Arch (primary test), Fedora, Debian/Ubuntu. Gaming mirrors dwm-titus full.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_HOME="${HOME}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$REAL_HOME/.config}"
WALLPAPER_DIR="$REAL_HOME/Pictures/backgrounds"
MANGO_CONFIG="$CONFIG_DIR/mango-titus"

PROFILE=recommended
ENABLE_GAMING=0
REPLACE_MANGO_CONFIG=0
LOGIN_DM="${LOGIN_DM:-}" # lightdm | greetd | ly — set by --login or prompt

usage() {
	cat <<'EOF'
Usage: ./install.sh [options]

  --profile recommended  default desktop (Arch tested first)
  --profile full         recommended + optional extras; gaming on Fedora x86_64
                         with --enable-gaming (same idea as dwm-titus)
  --enable-gaming        approve Steam/Gamescope/GameMode/MangoHud where available

  --login lightdm        default — slick-greeter (needs Xorg or Xlibre for greeter)
  --login greetd         Wayland-native (tuigreet)
  --login ly             TUI display manager

  --replace-mango-config  also back up/replace stock ~/.config/mango (opt-in;
                          default leaves stock mangowm config untouched)

  Env: LOGIN_DM=lightdm|greetd|ly  (same as --login)
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--profile)
		PROFILE=${2:?}
		shift 2
		;;
	--enable-gaming)
		ENABLE_GAMING=1
		shift
		;;
	--login)
		LOGIN_DM=${2:?}
		shift 2
		;;
	--replace-mango-config)
		REPLACE_MANGO_CONFIG=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown option: $1" >&2
		usage >&2
		exit 1
		;;
	esac
done

choose_login_dm() {
	case "${LOGIN_DM,,}" in
	lightdm | greetd | ly)
		LOGIN_DM="${LOGIN_DM,,}"
		return 0
		;;
	"")
		;;
	*)
		echo "Invalid --login / LOGIN_DM: $LOGIN_DM (use lightdm|greetd|ly)" >&2
		exit 1
		;;
	esac

	if [[ -t 0 ]]; then
		echo ""
		echo "Login / display manager:"
		echo "  1) LightDM + slick-greeter  (default — greeter needs Xorg or Xlibre)"
		echo "  2) greetd + tuigreet        (Wayland-native)"
		echo "  3) Ly                      (TUI)"
		echo -n "Choice [1]: "
		local ans
		read -r ans || ans=1
		case "${ans:-1}" in
		2 | greetd) LOGIN_DM=greetd ;;
		3 | ly) LOGIN_DM=ly ;;
		*) LOGIN_DM=lightdm ;;
		esac
	else
		LOGIN_DM=lightdm
	fi
}

choose_login_dm

echo "===================================================="
echo "  mango-titus bootstrap (dwm-titus shape on mangowm)"
echo "  profile=$PROFILE  enable_gaming=$ENABLE_GAMING  login=$LOGIN_DM"
echo "  (primary test target: Arch Linux)"
echo "===================================================="

mkdir -p "$CONFIG_DIR" "$WALLPAPER_DIR"

ensure_aur_helper() {
	# Only the helper name goes to stdout (callers capture it). Build noise → stderr.
	if command -v paru &>/dev/null; then
		echo paru
	elif command -v yay &>/dev/null; then
		echo yay
	else
		git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin >&2
		(cd /tmp/yay-bin && makepkg -si --noconfirm) >&2
		command -v yay >/dev/null || {
			echo "failed to install yay" >&2
			return 1
		}
		echo yay
	fi
}

install_arch_gaming() {
	[[ $ENABLE_GAMING -eq 1 ]] || return 0
	echo "Gaming extras (dwm-titus full-style): Steam, Gamescope, GameMode, MangoHud"
	local aur_helper
	aur_helper=$(ensure_aur_helper)
	sudo pacman -S --needed --noconfirm steam gamemode lib32-gamemode mangohud lib32-mangohud || true
	"$aur_helper" -S --needed --noconfirm gamescope || true
}

install_fedora_gaming() {
	[[ $ENABLE_GAMING -eq 1 ]] || return 0
	local arch
	arch=$(uname -m)
	if [[ $arch != x86_64 ]]; then
		echo "Skipping Fedora gaming extras (x86_64 only, like dwm-titus)."
		return 0
	fi
	echo "Gaming extras (dwm-titus full-style): enabling repos + packages"
	# Same third-party intent as dwm-titus; user passed --enable-gaming
	sudo dnf install -y \
		https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
		|| true
	sudo dnf copr enable -y christitustech/copr-fedora || true
	sudo dnf install -y \
		steam gamescope \
		gamemode.x86_64 gamemode.i686 \
		mangohud.x86_64 mangohud.i686 || true
	if getent group gamemode >/dev/null 2>&1; then
		sudo usermod -aG gamemode "$USER" || true
	fi
}

install_arch() {
	echo "System: Arch (pacman + AUR) — primary test distro"
	sudo pacman -Syu --needed --noconfirm \
		git base-devel \
		awww quickshell \
		alacritty kitty \
		thunar gvfs gvfs-smb tumbler thunar-archive-plugin file-roller \
		firefox \
		xdg-utils xdg-user-dirs \
		mate-polkit libnotify \
		pipewire pipewire-pulse wireplumber pavucontrol alsa-utils \
		brightnessctl playerctl \
		bluez bluez-utils blueman \
		noto-fonts-emoji ttf-meslo-nerd \
		networkmanager network-manager-applet \
		flameshot \
		xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
		nwg-look dconf gnome-keyring \
		qt5ct qt6ct \
		swayidle wlr-randr \
		power-profiles-daemon \
		dex \
		wl-clipboard cliphist

	local aur_helper
	aur_helper=$(ensure_aur_helper)
	"$aur_helper" -S --needed --noconfirm \
		mangowm-git swaylock-effects-git wayland-pipewire-idle-inhibit \
		wl-clip-persist

	if [[ $PROFILE == full ]]; then
		install_arch_gaming
	fi
}

install_fedora() {
	echo "System: Fedora (dnf)"
	sudo dnf install -y git dnf-plugins-core
	sudo dnf install -y --nogpgcheck \
		--repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" \
		terra-release

	sudo dnf install -y \
		mangowm awww quickshell \
		alacritty kitty \
		Thunar gvfs gvfs-smb tumbler thunar-archive-plugin file-roller \
		firefox \
		xdg-utils xdg-user-dirs \
		mate-polkit libnotify \
		pipewire pipewire-pulseaudio wireplumber pavucontrol alsa-utils pulseaudio-utils \
		brightnessctl playerctl \
		bluez blueman \
		google-noto-color-emoji-fonts google-noto-sans-mono-fonts \
		NetworkManager network-manager-applet \
		flameshot \
		xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
		nwg-look dconf gnome-keyring \
		qt5ct qt6ct \
		swayidle wlr-randr \
		power-profiles-daemon \
		dex-autostart \
		wl-clipboard cliphist

	if ! sudo dnf install -y swaylock-effects; then
		sudo dnf install -y swaylock
	fi
	sudo dnf install -y wayland-pipewire-idle-inhibit wl-clip-persist || true

	if [[ $PROFILE == full ]]; then
		install_fedora_gaming
	fi
}

install_debian() {
	echo "System: Debian/Ubuntu (apt) — supported; Arch is tested first"
	sudo apt-get update
	sudo apt-get install -y \
		git \
		awww || true
	sudo apt-get install -y swww || true
	sudo apt-get install -y \
		alacritty kitty \
		thunar gvfs gvfs-backends tumbler thunar-archive-plugin file-roller \
		firefox-esr || sudo apt-get install -y firefox || true
	sudo apt-get install -y \
		xdg-utils xdg-user-dirs \
		mate-polkit libnotify-bin \
		pipewire pipewire-pulse wireplumber pavucontrol alsa-utils \
		brightnessctl playerctl \
		bluez blueman \
		fonts-noto-color-emoji fonts-noto-mono \
		network-manager network-manager-gnome \
		flameshot \
		xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
		dconf-cli gnome-keyring \
		qt5ct qt6ct \
		swayidle \
		power-profiles-daemon \
		wlr-randr \
		dex \
		wl-clipboard cliphist || true
	sudo apt-get install -y wl-clip-persist || true

	# Distro packages may lag; install mangowm/quickshell/swaylock-effects when available
	sudo apt-get install -y quickshell mangowm swaylock || true
	echo "Note: On Debian/Ubuntu, verify mangowm + quickshell + swaylock-effects"
	echo "      packages exist for your release; Arch is the primary test path."

	if [[ $PROFILE == full && $ENABLE_GAMING -eq 1 ]]; then
		echo "Gaming on Debian: install Steam/GameMode from your preferred method"
		echo "(dwm-titus gaming COPR path is Fedora-focused)."
		sudo apt-get install -y steam-installer gamemode mangohud || true
	fi
}

case "$PROFILE" in
core | recommended | full) ;;
*)
	echo "Invalid --profile: $PROFILE" >&2
	exit 1
	;;
esac

if command -v pacman &>/dev/null; then
	install_arch
elif command -v dnf &>/dev/null; then
	install_fedora
elif command -v apt-get &>/dev/null; then
	install_debian
else
	echo "Unsupported distro (need pacman, dnf, or apt)." >&2
	exit 1
fi

echo "----------------------------------------------------"
echo "Deploying mango-titus + Quickshell config from $REPO_DIR"
echo "----------------------------------------------------"

DATA_DIR="${XDG_DATA_HOME:-$REAL_HOME/.local/share}/mango-titus"
QS_CONFIG="$MANGO_CONFIG/quickshell"
LOCAL_BIN="$REAL_HOME/.local/bin"
LEGACY_DATA="${XDG_DATA_HOME:-$REAL_HOME/.local/share}/mangowm-titus"
LEGACY_QS="${XDG_CONFIG_HOME:-$CONFIG_DIR}/quickshell"
STOCK_MANGO="$CONFIG_DIR/mango"

# Migrate legacy fork data dir (mangowm-titus → mango-titus)
if [[ -d $LEGACY_DATA && ! -d $DATA_DIR ]]; then
	mv "$LEGACY_DATA" "$DATA_DIR"
	echo "Migrated data dir: $LEGACY_DATA → $DATA_DIR"
elif [[ -d $LEGACY_DATA && -d $DATA_DIR ]]; then
	echo "Note: both $LEGACY_DATA and $DATA_DIR exist; leaving legacy in place"
fi

# Migrate only fork-managed Quickshell (never steal dwm-titus unmanaged QS)
if [[ -f $LEGACY_QS/.mangowm-titus-managed && ! -d $QS_CONFIG ]]; then
	mkdir -p "$MANGO_CONFIG"
	mv "$LEGACY_QS" "$QS_CONFIG"
	rm -f "$QS_CONFIG/.mangowm-titus-managed"
	touch "$QS_CONFIG/.mango-titus-managed"
	echo "Migrated Quickshell: $LEGACY_QS → $QS_CONFIG"
fi

# Opt-in only: touch stock mangowm ~/.config/mango
if [[ $REPLACE_MANGO_CONFIG -eq 1 && -d $STOCK_MANGO && ! -L $STOCK_MANGO ]]; then
	backup="${STOCK_MANGO}.bak.$(date +%Y%m%d%H%M%S)"
	mv "$STOCK_MANGO" "$backup"
	echo "Backed up stock mango config to $backup (--replace-mango-config)"
fi

mkdir -p "$MANGO_CONFIG/scripts" "$MANGO_CONFIG/display-profiles" \
	"$DATA_DIR/scripts" "$DATA_DIR/config" "$LOCAL_BIN" "$QS_CONFIG"

for f in config.conf bind.conf env.conf rule.conf monitor.conf tag.conf; do
	[[ -f "$REPO_DIR/$f" ]] && cp -f "$REPO_DIR/$f" "$MANGO_CONFIG/$f"
done
[[ -f "$REPO_DIR/config/swaylock-effects.conf" ]] &&
	cp -f "$REPO_DIR/config/swaylock-effects.conf" "$MANGO_CONFIG/swaylock-effects.conf"
[[ -f "$REPO_DIR/config/themes.toml" ]] &&
	cp -f "$REPO_DIR/config/themes.toml" "$MANGO_CONFIG/themes.toml"
[[ -f "$REPO_DIR/config/hotkeys.toml" ]] &&
	cp -f "$REPO_DIR/config/hotkeys.toml" "$MANGO_CONFIG/hotkeys.toml"

# Session scripts (top-level under scripts/, including mango-titus-*)
if [[ -d "$REPO_DIR/scripts" ]]; then
	find "$REPO_DIR/scripts" -maxdepth 1 -type f -exec cp -f {} "$MANGO_CONFIG/scripts/" \;
	chmod +x "$MANGO_CONFIG/scripts/"* 2>/dev/null || true
fi

# Remove legacy dwm-* / old helper names from our PATH and data dir
if [[ -d $LOCAL_BIN ]]; then
	for stale in "$LOCAL_BIN"/dwm-* "$LOCAL_BIN"/mango-quickshell-state \
		"$LOCAL_BIN"/mango-display-setup "$LOCAL_BIN"/mango-display-profile \
		"$LOCAL_BIN"/theme-apply.sh; do
		[[ -e $stale || -L $stale ]] || continue
		# Only remove symlinks that point into our data/config trees
		if [[ -L $stale ]]; then
			target=$(readlink -f "$stale" 2>/dev/null || true)
			case $target in
			"$DATA_DIR"/* | "$LEGACY_DATA"/* | "$MANGO_CONFIG"/* | "$STOCK_MANGO"/*)
				rm -f "$stale"
				;;
			esac
		fi
	done
fi
if [[ -d $DATA_DIR/scripts ]]; then
	find "$DATA_DIR/scripts" -maxdepth 1 -type f \( -name 'dwm-*' -o -name 'mango-quickshell-state' -o -name 'theme-apply.sh' \) -delete 2>/dev/null || true
fi

# Quickshell helpers → data dir + ~/.local/bin (mango-titus-* always;
# shared agnostic tools only if missing — prefer dwm /usr/local/bin copies)
if [[ -d "$REPO_DIR/scripts/helpers" ]]; then
	cp -f "$REPO_DIR/scripts/helpers/"* "$DATA_DIR/scripts/"
	chmod +x "$DATA_DIR/scripts/"*
	for h in "$DATA_DIR/scripts/"mango-titus-*; do
		[[ -f $h ]] || continue
		base=$(basename "$h")
		ln -sfn "$h" "$LOCAL_BIN/$base"
	done
	# Shared with dwm-titus (same basenames). Do not overwrite an existing install.
	for shared in webapp-launch webapp-create protonrestart; do
		src="$DATA_DIR/scripts/$shared"
		[[ -x $src ]] || continue
		if command -v "$shared" >/dev/null 2>&1; then
			echo "Keeping existing $shared on PATH ($(command -v "$shared"))"
			continue
		fi
		ln -sfn "$src" "$LOCAL_BIN/$shared"
	done
fi

# Theme apply + session wrapper on PATH
if [[ -x $MANGO_CONFIG/scripts/mango-titus-theme-apply ]]; then
	cp -f "$MANGO_CONFIG/scripts/mango-titus-theme-apply" "$DATA_DIR/scripts/mango-titus-theme-apply"
	chmod +x "$DATA_DIR/scripts/mango-titus-theme-apply"
	ln -sfn "$DATA_DIR/scripts/mango-titus-theme-apply" "$LOCAL_BIN/mango-titus-theme-apply"
fi
if [[ -x $MANGO_CONFIG/scripts/mango-titus-session ]]; then
	ln -sfn "$MANGO_CONFIG/scripts/mango-titus-session" "$LOCAL_BIN/mango-titus-session"
	# Display managers (Ly/LightDM/greetd) use a minimal PATH — ~/.local/bin is not enough.
	sudo install -Dm755 "$MANGO_CONFIG/scripts/mango-titus-session" \
		/usr/local/bin/mango-titus-session
fi

# Short session helper names used by binds (do not conflict with dwm-titus)
for h in screenshot.sh wallpaper.sh lock.sh terminal.sh \
	mango-titus-display-setup mango-titus-display-profile; do
	if [[ -x $MANGO_CONFIG/scripts/$h ]]; then
		ln -sfn "$MANGO_CONFIG/scripts/$h" "$LOCAL_BIN/${h%.sh}"
	fi
done

# Quickshell under namespaced tree only — never touch ~/.config/quickshell
if [[ -d "$REPO_DIR/config/quickshell" ]]; then
	cp -a "$REPO_DIR/config/quickshell/." "$QS_CONFIG/"
	rm -f "$QS_CONFIG/.mangowm-titus-managed"
	touch "$QS_CONFIG/.mango-titus-managed"
	echo "Installed Quickshell → $QS_CONFIG"
fi

# Terminal seed configs (do not clobber existing user configs)
for term in alacritty kitty; do
	src="$REPO_DIR/config/$term"
	dst="${XDG_CONFIG_HOME:-$CONFIG_DIR}/$term"
	if [[ -d "$src" && ! -d "$dst" ]]; then
		mkdir -p "$dst"
		cp -a "$src/." "$dst/"
		echo "Seeded $term config → $dst"
	fi
done

# Shared data config copies
cp -f "$REPO_DIR/config/themes.toml" "$DATA_DIR/config/themes.toml" 2>/dev/null || true
cp -f "$REPO_DIR/config/hotkeys.toml" "$DATA_DIR/config/hotkeys.toml" 2>/dev/null || true
cp -f "$REPO_DIR/config/swaylock-effects.conf" "$DATA_DIR/config/swaylock-effects.conf" 2>/dev/null || true

if [[ -f "$REPO_DIR/mango-titus.desktop" ]]; then
	sudo install -Dm644 "$REPO_DIR/mango-titus.desktop" \
		/usr/share/wayland-sessions/mango-titus.desktop
	# Remove legacy session entry from earlier fork installs
	sudo rm -f /usr/share/wayland-sessions/mango.desktop
fi

disable_other_login_managers() {
	local keep=$1
	local u
	for u in lightdm.service greetd.service 'ly@tty1.service' 'ly@tty2.service'; do
		case "$keep:$u" in
		lightdm:lightdm.service | greetd:greetd.service | ly:ly@tty2.service) continue ;;
		esac
		sudo systemctl disable --now "$u" 2>/dev/null || true
	done
	# Restore getty on tty2 unless Ly owns it
	if [[ $keep != ly ]]; then
		sudo systemctl enable getty@tty2.service 2>/dev/null || true
	fi
}

install_login_arch_xorg() {
	# LightDM greeter (and optional Ly X sessions) need an X server.
	if pacman -Qq 2>/dev/null | grep -q '^xlibre'; then
		echo "Xlibre detected — skipping xorg-server for LightDM greeter"
	else
		sudo pacman -S --needed --noconfirm xorg-server xorg-xauth
	fi
}

configure_login_lightdm() {
	if command -v pacman >/dev/null 2>&1; then
		install_login_arch_xorg
		sudo pacman -S --needed --noconfirm lightdm lightdm-slick-greeter
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y lightdm slick-greeter xorg-x11-server-Xorg ||
			sudo dnf install -y lightdm slick-greeter
	elif command -v apt-get >/dev/null 2>&1; then
		sudo apt-get install -y lightdm slick-greeter xserver-xorg
	fi

	local seat_section=SeatDefaults
	local greeter_session=lightdm-slick-greeter
	local session_wrapper=/etc/lightdm/Xsession
	local logind_check=false

	if command -v dnf >/dev/null 2>&1; then
		seat_section='Seat:*'
		greeter_session=slick-greeter
		session_wrapper=
		logind_check=true
	elif command -v apt-get >/dev/null 2>&1; then
		greeter_session=slick-greeter
	fi

	local tmp
	tmp=$(mktemp)
	{
		if [[ $logind_check == true ]]; then
			printf '%s\n' '[LightDM]' 'logind-check-graphical=true' ''
		fi
		printf '[%s]\n' "$seat_section"
		printf 'greeter-session=%s\n' "$greeter_session"
		printf 'user-session=mango-titus\n'
		if [[ -n $session_wrapper ]]; then
			printf 'session-wrapper=%s\n' "$session_wrapper"
		fi
	} >"$tmp"

	if [[ -f /etc/lightdm/lightdm.conf ]] &&
		! cmp -s "$tmp" /etc/lightdm/lightdm.conf; then
		sudo cp -a /etc/lightdm/lightdm.conf \
			"/etc/lightdm/lightdm.conf.bak.$(date +%Y%m%d%H%M%S)"
	fi
	sudo install -Dm644 "$tmp" /etc/lightdm/lightdm.conf
	rm -f "$tmp"

	if [[ ! -f /etc/lightdm/slick-greeter.conf ]]; then
		sudo tee /etc/lightdm/slick-greeter.conf >/dev/null <<'EOF'
[Greeter]
theme-name=Adwaita-dark
icon-theme-name=Adwaita
background-color=#2E3440
draw-user-backgrounds=false
show-hostname=true
show-power=true
activate-numlock=false
EOF
	fi

	disable_other_login_managers lightdm
	sudo systemctl enable lightdm.service
	sudo systemctl set-default graphical.target
	echo "Login: LightDM + slick-greeter (default session: mango-titus)"
}

configure_login_greetd() {
	if command -v pacman >/dev/null 2>&1; then
		sudo pacman -S --needed --noconfirm greetd greetd-tuigreet
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y greetd tuigreet || sudo dnf install -y greetd
	elif command -v apt-get >/dev/null 2>&1; then
		sudo apt-get install -y greetd tuigreet || sudo apt-get install -y greetd
	fi

	local greeter_cmd='tuigreet'
	if command -v tuigreet >/dev/null 2>&1; then
		greeter_cmd='tuigreet --time --remember --remember-session --sessions /usr/share/wayland-sessions:/usr/share/xsessions'
	elif command -v agreety >/dev/null 2>&1; then
		greeter_cmd='agreety --cmd /usr/local/bin/mango-titus-session'
	else
		echo "No tuigreet/agreety found; configure /etc/greetd/config.toml manually" >&2
	fi

	sudo install -d /etc/greetd
	sudo tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "$greeter_cmd"
user = "greeter"
EOF

	disable_other_login_managers greetd
	sudo systemctl enable greetd.service
	sudo systemctl set-default graphical.target
	echo "Login: greetd + tuigreet (Wayland sessions from /usr/share/wayland-sessions)"
}

configure_login_ly() {
	# Ly is in Arch [extra]; Fedora/Debian may need COPR/PPA or skip.
	if command -v pacman >/dev/null 2>&1; then
		sudo pacman -S --needed --noconfirm ly
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y ly || {
			echo "Ly package not available via dnf; install manually" >&2
			return 1
		}
	elif command -v apt-get >/dev/null 2>&1; then
		sudo apt-get install -y ly || {
			echo "Ly package not available via apt; install manually" >&2
			return 1
		}
	fi

	# Prefer mango-titus Wayland session when ly supports session defaults
	if [[ -f /etc/ly/config.ini ]]; then
		sudo sed -i -E \
			-e 's|^#?[[:space:]]*animation[[:space:]]*=.*|animation = none|' \
			/etc/ly/config.ini 2>/dev/null || true
	fi

	disable_other_login_managers ly
	# Ly owns tty2 (ArchWiki / upstream); disable getty on that VT
	sudo systemctl disable getty@tty2.service
	sudo systemctl enable ly@tty2.service
	sudo systemctl set-default graphical.target
	echo "Login: Ly on tty2 (pick Wayland session \"Mango Titus\")"
}

configure_login() {
	case "$LOGIN_DM" in
	lightdm) configure_login_lightdm ;;
	greetd) configure_login_greetd ;;
	ly) configure_login_ly ;;
	*)
		echo "Unknown LOGIN_DM=$LOGIN_DM" >&2
		exit 1
		;;
	esac
}

configure_network_manager() {
	# Quickshell NET panel + nm-applet need NetworkManager, not systemd-networkd alone.
	if ! command -v nmcli >/dev/null 2>&1; then
		echo "NetworkManager (nmcli) not installed; skip NM enable." >&2
		return 0
	fi

	# Avoid two stacks fighting over the same NIC (networkd often left enabled after Arch install)
	if systemctl is-enabled systemd-networkd.service >/dev/null 2>&1 ||
		systemctl is-active systemd-networkd.service >/dev/null 2>&1; then
		echo "Disabling systemd-networkd so NetworkManager can own the NIC…"
		sudo systemctl disable --now \
			systemd-networkd.service \
			systemd-networkd.socket \
			systemd-networkd-varlink.socket \
			systemd-networkd-resolve-hook.socket \
			systemd-networkd-varlink-metrics.socket \
			2>/dev/null || true
		if [[ -d /etc/systemd/network ]]; then
			sudo mkdir -p /etc/systemd/network/disabled-by-mango-titus
			sudo find /etc/systemd/network -maxdepth 1 -type f -name '*.network' \
				-exec mv {} /etc/systemd/network/disabled-by-mango-titus/ \; 2>/dev/null || true
		fi
	fi

	sudo systemctl enable --now NetworkManager.service
	sleep 1
	# Ensure ethernet is connected (Quickshell reads nmcli device state)
	local eth
	eth=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null |
		awk -F: '$2 == "ethernet" && $3 != "unmanaged" { print $1; exit }')
	if [[ -n $eth ]]; then
		sudo nmcli device set "$eth" managed yes 2>/dev/null || true
		if ! nmcli -t -f DEVICE,STATE device status | grep -q "^${eth}:connected"; then
			sudo nmcli device connect "$eth" 2>/dev/null ||
				sudo nmcli connection add type ethernet ifname "$eth" con-name Wired \
					ipv4.method auto ipv6.method auto 2>/dev/null ||
				true
			sudo nmcli device connect "$eth" 2>/dev/null || true
		fi
	fi
	echo "NetworkManager enabled (required for Quickshell NET / nm-applet)"
	nmcli -t -f DEVICE,STATE,CONNECTION device status 2>/dev/null || true
}

configure_network_manager
configure_login

if [[ ! -d "$WALLPAPER_DIR/nord-background" ]]; then
	git clone https://github.com/ChrisTitusTech/nord-background.git \
		"$WALLPAPER_DIR/nord-background"
else
	git -C "$WALLPAPER_DIR/nord-background" pull --ff-only || true
fi

if command -v xdg-user-dirs-update &>/dev/null; then
	xdg-user-dirs-update
fi

echo "----------------------------------------------------"
echo "Done. Reboot → login ($LOGIN_DM) → session \"Mango Titus\"."
echo "  Or from a TTY: mango-titus-session"
echo "  Config       : $MANGO_CONFIG"
echo "  Quickshell   : $QS_CONFIG"
echo "  Helpers      : $DATA_DIR/scripts (mango-titus-* in $LOCAL_BIN;"
echo "                 webapp-launch/create + protonrestart only if missing on PATH)"
echo "  Wallpapers   : $WALLPAPER_DIR"
echo "Display wizard : mango-titus-display-setup wizard"
echo "Ensure $LOCAL_BIN is on your PATH."
if [[ $PROFILE == full && $ENABLE_GAMING -eq 1 ]]; then
	echo "Gaming packages requested (log out/in if added to gamemode group)."
fi
echo "----------------------------------------------------"
