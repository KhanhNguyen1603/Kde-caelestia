pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.utils
import qs.services

Singleton {
    id: root

    property bool hasUpdate: false
    property string currentBranch: "main"
    property var commits: []
    property var availableBranches: ["main", "testing"]
    property int pendingCount: 0

    property string _localCommit: ""
    property bool loaded: false

    function checkUpdates(branch) {
        if (branch === undefined) branch = "";
        if (!GlobalConfig.general.checkUpdates) return;
        if (branch !== "") currentBranch = branch;
        
        let bashCmd = `
REPO="$HOME/.cache/caelestia-update-repo"
if [ ! -d "$REPO" ]; then
    git clone --bare --filter=blob:none https://github.com/ladybug-me/caelestia-dots-kde.git "$REPO" >/dev/null 2>&1
else
    git -C "$REPO" fetch origin ${currentBranch}:${currentBranch} >/dev/null 2>&1
fi
if [ -n "${root._localCommit}" ]; then
    git -C "$REPO" log --format="%h|%s|%an|%cI" ${root._localCommit}..${currentBranch} 2>/dev/null || echo ""
else
    echo ""
fi
`
        gitProcess.command = ["bash", "-c", bashCmd];
        gitProcess.running = true;
    }

    function reload() {
        loaded = false;
        localCommitProcess.running = true;
    }

    // Process to read local commit
    Process {
        id: localCommitProcess
        running: true
        command: ["cat", Paths.absolutePath("~/.config/quickshell/caelestia/.current_commit")]
        stdout: StdioCollector {
            onStreamFinished: {
                root._localCommit = text.trim();
                root.loaded = true;
                root.checkUpdates();
            }
        }
    }

    Process {
        id: gitProcess
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const lines = text.trim().split("\n");
                    const parsedCommits = [];
                    
                    for (let i = 0; i < lines.length; i++) {
                        const line = lines[i].trim();
                        if (line === "") continue;
                        const parts = line.split("|");
                        if (parts.length >= 4) {
                            parsedCommits.push({
                                hash: parts[0],
                                subject: parts[1],
                                author: parts[2],
                                date: new Date(parts[3]).toLocaleString(Qt.locale(), Locale.ShortFormat)
                            });
                        }
                    }
                    
                    root.commits = parsedCommits;
                    const prevCount = root.pendingCount;
                    root.pendingCount = parsedCommits.length;
                    root.hasUpdate = root.pendingCount > 0;
                    
                    if (root.hasUpdate && prevCount === 0 && root.loaded) {
                        Toaster.toast(qsTr("System Update Available"), qsTr("%1 new commits on %2 branch").arg(root.pendingCount).arg(root.currentBranch), "update");
                    }
                } catch(e) {
                    console.log("UpdateChecker git parse error:", e);
                }
            }
        }
    }

}
