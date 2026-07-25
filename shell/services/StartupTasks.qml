
import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Item {
    id: root
    Component.onCompleted: {
        console.log("StartupTasks Loaded!");
        Quickshell.execDetached(["bash", "-c", `
            STATE_FILE="$HOME/.local/share/caelestia/state/startup_tasks.txt"
            mkdir -p "$(dirname "$STATE_FILE")"
            touch "$STATE_FILE"
            
            TASKS_DIR="$HOME/.config/quickshell/caelestia/services/startuptasks"
            MODIFIED=false
            RAN_TASKS=""
            
            TASKS=(
                "01-magic-lamp"
                "02-krohnkite-setup"
            )
            
            for script_name in "\${TASKS[@]}"; do
                script="$TASKS_DIR/$script_name.sh"
                if [[ -f "$script" ]]; then
                    if ! grep -q "^\${script_name}$" "$STATE_FILE"; then
                        bash "$script"
                        if [[ $? -eq 1 ]]; then
                            MODIFIED=true
                        fi
                        echo "$script_name" >> "$STATE_FILE"
                        RAN_TASKS="$RAN_TASKS\\n- $script_name"
                    fi
                fi
            done
            
            if [[ "$MODIFIED" == "true" ]]; then
                qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
            fi

            if [[ -n "$RAN_TASKS" ]]; then
                notify-send "Caelestia Startup Tasks" "Executed the following initialization tasks:$RAN_TASKS" -i dialog-information
            fi
        `]);
    }
}
