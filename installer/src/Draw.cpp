#include "Draw.hpp"
#include "Globals.hpp"
#include <iostream>

using namespace std;

namespace Draw {
    const string esc = "\x1b[";
    const string reset = esc + "0m";
    const string bold = esc + "1m";
    const string dim = esc + "2m";
    
    // Colors
    string color(const string& name) {
        if (name.empty()) {
            return "";
        }

        if (name.find("\x1b[") != string::npos) {
            return name;
        }

        if (name == "reset") {
            return reset;
        }
        if (name == "bold") {
            return bold;
        }
        if (name == "dim") {
            return dim;
        }

        static const string bold_prefix = "bold_";
        if (name.rfind(bold_prefix, 0) == 0 && name.size() > bold_prefix.size()) {
            return bold + color(name.substr(bold_prefix.size()));
        }

        auto it = g_theme_colors.find(name);
        if (it != g_theme_colors.end()) {
            return it->second;
        }
        // Use terminal default foreground so light/dark themes remain readable.
        return esc + "39m";
    }
    
    // Box chars
    const string h_line = "-";
    const string v_line = "|";
    const string corner = "+";

    string to(int line, int col) {
        return esc + to_string(line) + ";" + to_string(col) + "H";
    }

    string clear() {
        return esc + "2J" + to(1, 1);
    }

    string sync_start() { return esc + "?2026h"; }
    string sync_end()   { return esc + "?2026l"; }

    void box(int x, int y, int w, int h, const string& title, const string& border_color, const string& title_color) {
        if (w < 2 || h < 2) return;
        string c = color(border_color);
        string tc = title_color.empty() ? reset : color(title_color);
        string out = c;
        
        string h_str(w - 2, '-');
        out += to(y, x) + corner + h_str + corner;
        out += to(y + h - 1, x) + corner + h_str + corner;
        
        for (int i = 1; i < h - 1; i++) {
            out += to(y + i, x) + v_line;
            out += to(y + i, x + w - 1) + v_line;
        }

        if (!title.empty()) {
            int pad = (w - title.length()) / 2;
            if (pad > 0) {
                out += to(y, x + pad) + bold + reset + c + "[" + reset + bold + tc + title + reset + c + "]" + reset;
            }
        }
        cout << out << reset;
    }

    void animated_box(int x, int y, int w, int h, const string& title, const string& border_color, const string& title_color) {
        // Direct delegate — no animation, instant rendering
        box(x, y, w, h, title, border_color, title_color);
    }

    void text(int x, int y, const string& txt, const string& color_name) {
        string c = color_name.empty() ? "" : color(color_name);
        cout << to(y, x) << c << txt << reset;
    }
}
