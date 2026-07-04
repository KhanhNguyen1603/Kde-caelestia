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
        
        // 1. Fetch remote commits
        curlProcess.command = ["curl", "-s", `https://api.github.com/repos/ladybug-me/caelestia-dots-kde/commits?sha=${currentBranch}`];
        curlProcess.running = true;
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
        id: curlProcess
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (!Array.isArray(data)) return;
                    
                    const parsedCommits = [];
                    let foundLocal = false;
                    
                    for (let i = 0; i < data.length; i++) {
                        const c = data[i];
                        if (root._localCommit && c.sha === root._localCommit) {
                            foundLocal = true;
                            break;
                        }
                        
                        parsedCommits.push({
                            hash: c.sha.substring(0, 7),
                            subject: c.commit.message.split("\n")[0],
                            author: c.commit.author.name,
                            date: new Date(c.commit.author.date).toLocaleString(Qt.locale(), Locale.ShortFormat)
                        });
                    }
                    
                    root.commits = parsedCommits;
                    const prevCount = root.pendingCount;
                    root.pendingCount = parsedCommits.length;
                    root.hasUpdate = root.pendingCount > 0;
                    
                    if (root.hasUpdate && prevCount === 0 && root.loaded) {
                        Toaster.toast(qsTr("System Update Available"), qsTr("%1 new commits on %2 branch").arg(root.pendingCount).arg(root.currentBranch), "update");
                    }
                } catch(e) {
                    console.log("UpdateChecker JSON parse error:", e);
                }
            }
        }
    }

    Timer {
        running: GlobalConfig.general.checkUpdates
        repeat: true
        interval: 30 * 60 * 1000 // 30 mins
        onTriggered: root.checkUpdates()
    }
}
