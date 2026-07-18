#include "shell/plugin/src/Caelestia/Services/lyriccandidate.hpp"
int main() {
    caelestia::services::LyricCandidate c(caelestia::services::LyricsBackend::Local, "", "", "");
    caelestia::services::LyricCandidate d;
    return c == d;
}
