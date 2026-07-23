# DMS configs removed

Chris Titus’s mango-titus attempt used **DankMaterialShell (DMS)** here
(`colors.conf`, `layout.conf`) with `exec-once=dms run` and DMS IPC binds.

**Removed** — this fork keeps **Quickshell** for 1:1 parity with dwm-titus.

| Former DMS piece | Replacement |
|------------------|-------------|
| `dms run` shell | `quickshell --no-duplicate` in `config.conf` |
| Spotlight / launcher IPC | Quickshell `launcher` IPC in `bind.conf` |
| Notifications / clipboard / settings IPC | Quickshell (when dwm-titus shell config is ported) |
| DMS lock | `swaylock-effects` + `swayidle` (`scripts/lock.sh`, `scripts/idle.sh`) |
| DMS colors / layout | Quickshell theme + mango `config.conf` appearance |
