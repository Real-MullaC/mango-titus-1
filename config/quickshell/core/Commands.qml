pragma Singleton

import Quickshell

Singleton {
    id: root

    // Models intentionally assign Process.command imperatively before each run
    // (BND-2); that is the supported reuse pattern for Quickshell Process.

    function helperCommand(helper, action, args, preferManaged) {
        const argv = args || [];
        const managedScript = "\"$data_dir/scripts/" + helper + "\"";
        const dataDir = "data_dir=${XDG_DATA_HOME:-$HOME/.local/share}/mango-titus";
        const runManaged = "[ -x " + managedScript + " ] && exec " + managedScript + " \"$@\"";
        const runPath = "command -v " + helper + " >/dev/null 2>&1 && exec " + helper + " \"$@\"";
        const fallback = "exec " + managedScript + " \"$@\"";
        const orderedChecks = preferManaged
            ? [runManaged, runPath, fallback]
            : [runPath, runManaged, fallback];
        const script = [dataDir].concat(orderedChecks).join("; ");

        const command = ["sh", "-c", script, helper];
        if (action !== undefined && action !== null) {
            command.push(action);
        }

        return command.concat(argv);
    }

    function launcherHelperCommand(action, args) {
        return helperCommand("mango-titus-launcher", action, args, true);
    }

    function networkHelperCommand(action, args) {
        return helperCommand("mango-titus-network", action, args, false);
    }

    function controlsHelperCommand(action, args) {
        return helperCommand("mango-titus-controls", action, args, true);
    }

    function controlCenterHelperCommand(action, args) {
        return helperCommand("mango-titus-cc", action, args, true);
    }

    function stateHelperCommand(action, args) {
        return helperCommand("mango-titus-state", action, args, true);
    }

    function lockHelperCommand() {
        // Prefer mango-titus lock script (swaylock-effects)
        return ["sh", "-c", 'exec "${XDG_CONFIG_HOME:-$HOME/.config}/mango-titus/scripts/lock.sh"'];
    }

    function powerHelperCommand(action) {
        // poweroff|reboot|suspend — seat-aware (see mango-titus-power)
        return helperCommand("mango-titus-power", action, [], true);
    }

    function systemHealthHelperCommand(action, args) {
        return helperCommand("mango-titus-health", action, args, true);
    }
}
