#include "Globals.hpp"
#include "Term.hpp"
#include "UI.hpp"
#include "Runner.hpp"
#include <iostream>
#include <fstream>
#include <csignal>
#include <cstdlib>

using namespace std;

// sig_atomic_t is the only type guaranteed to be safe for cross-thread/
// signal-handler access. We use flags to defer all cleanup to the main loop.
volatile sig_atomic_t g_sigint_received = 0;
volatile sig_atomic_t g_sigterm_received = 0;

void handle_sigwinch(int) {
    g_resized = true;
}

void handle_sigint(int) {
    // Only set the flag — do NOT call any library functions from signal context.
    // cleanup happens in the main loop via check_signals().
    g_sigint_received = 1;
}

void handle_sigterm(int) {
    g_sigterm_received = 1;
}

void check_signals() {
    if (g_sigint_received || g_sigterm_received) {
        g_quit = true;
        Term::restore();
        system("rm -rf /tmp/caelestia_pass.txt /tmp/caelestia_askpass.sh /tmp/caelestia_bin");
        exit(130);
    }
}

int main(int argc, char** argv) {
    // Detect bundle dir from arg or exe path
    if (argc > 1) {
        g_bundle_dir = argv[1];
    } else {
        char buf[1024];
        ssize_t len = readlink("/proc/self/exe", buf, sizeof(buf)-1);
        if (len != -1) {
            buf[len] = '\0';
            string path(buf);
            size_t pos = path.find_last_of('/');
            if (pos != string::npos) {
                g_bundle_dir = path.substr(0, pos);
            }
        }
    }

    // Early diagnostic: print bundle dir to stderr so setup.sh can capture it
    std::cerr << "[installer] bundle dir: " << g_bundle_dir << std::endl;

    // Hide cursor immediately to prevent flashing in tmux
    std::cout << "\x1b[?25l" << std::flush;
    Term::init();

    load_theme();

    // Verify critical files exist before attempting the full UI flow
    {
        std::string theme_path = g_bundle_dir + "/installer/theme.json";
        std::string menu_path  = g_bundle_dir + "/installer/menu.json";
        std::string scripts_dir = g_bundle_dir + "/scripts";
        if (!std::ifstream(theme_path).good())
            std::cerr << "[installer] WARNING: theme.json not found at " << theme_path << std::endl;
        if (!std::ifstream(menu_path).good())
            std::cerr << "[installer] WARNING: menu.json not found at " << menu_path << std::endl;
        // scripts/ dir is critical — if missing, the installer cannot execute steps
        std::ifstream test_script(scripts_dir + "/00a-system-update.sh");
        if (!test_script.good())
            std::cerr << "[installer] WARNING: scripts directory missing at " << scripts_dir << std::endl;
    }

    signal(SIGWINCH, handle_sigwinch);
    signal(SIGINT, handle_sigint);
    signal(SIGTERM, handle_sigterm);

    // Phase 1: Splash
    std::cerr << "[installer] phase 1: splash_screen" << std::endl;
    UI::splash_screen();
    check_signals();

    // Phase 2: Sudo Auth
    std::cerr << "[installer] phase 2: sudo_prompt" << std::endl;
    if (!UI::sudo_prompt()) {
        std::cerr << "[installer] user cancelled at sudo prompt" << std::endl;
        Term::restore();
        return 0;
    }
    check_signals();

    // Phase 3 & 4: Dynamic Menu
    if (!g_menu.is_null() && g_menu.contains("menu")) {
        std::cerr << "[installer] phase 3: render_menu" << std::endl;
        if (!UI::render_menu(g_menu["menu"], "CONFIGURATION MENU")) {
            std::cerr << "[installer] user backed out of menu" << std::endl;
            Term::restore();
            return 0; // User backed out or exited
        }
        
        // Export all answers as environment variables for the bash scripts
        for (const auto& pair : g_answers) {
            setenv(pair.first.c_str(), pair.second.c_str(), 1);
        }
    } else {
        std::cerr << "[installer] phase 3: skipped (no menu loaded)" << std::endl;
    }

    // Fallback distro logic if somehow not set
    const char* env_distro = getenv("BASE_DISTRO");
    if (env_distro && string(env_distro) != "") {
        g_base_distro = env_distro;
    }

    check_signals();
    // Phase 5: Execute
    std::cerr << "[installer] phase 5: execute (" << Runner::steps.size() << " steps)" << std::endl;
    Runner::execute();

    check_signals();
    // Phase 6: Finalize
    std::cerr << "[installer] phase 6: summary_screen" << std::endl;
    UI::summary_screen();
    Term::restore();

    if (g_answers["REMOVE_CACHE"] == "true") {
        string cache_dir = string(getenv("XDG_CACHE_HOME") ? getenv("XDG_CACHE_HOME") : (string(getenv("HOME")) + "/.cache")) + "/caelestia-kde";
        system(("rm -rf \"" + cache_dir + "\"").c_str());
    }
    
    // Secure cleanup of sudo credentials
    system("rm -rf /tmp/caelestia_pass.txt /tmp/caelestia_askpass.sh /tmp/caelestia_bin");

    // Cleanup cmake build cache as it contains absolute paths
    string cmake_cleanup = "rm -rf " + g_bundle_dir + "/shell/build " + g_bundle_dir + "/shell/plugin/build";
    system(cmake_cleanup.c_str());

    if (g_logout) {
        cout << "\n\n\nLogging out...\n";
        system("qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null");
    } else {
        cout << "\n\n\nExiting installer. Please remember to log out manually later.\n";
    }

    // Write completion marker so setup.sh can distinguish success from early exit
    std::cerr << "[installer] done (success)" << std::endl;
    return 0;
}
