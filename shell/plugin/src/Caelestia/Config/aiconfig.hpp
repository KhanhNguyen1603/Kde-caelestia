#pragma once

#include "configobject.hpp"
#include <qstring.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class AiConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, ollamaUrl, u"http://localhost:11434"_s)
    CONFIG_PROPERTY(QString, ollamaModel, u"llama3"_s)
    
    CONFIG_PROPERTY(bool, saveChatHistory, true)
    CONFIG_PROPERTY(QString, ollamaHistoryJson, u"[]"_s)

    CONFIG_PROPERTY(bool, snapToDefaultOllama, true)
    CONFIG_PROPERTY(QString, defaultOllamaModel, u"llama3"_s)

    CONFIG_PROPERTY(QString, defaultProvider, u"ollama"_s)
    CONFIG_PROPERTY(bool, enableOllama, true)

    // Claude Code provider: shells out to the `claude` CLI in headless mode using
    // the user's existing subscription login (~/.claude) — no API key involved.
    CONFIG_PROPERTY(bool, enableClaudeCode, false)
    CONFIG_PROPERTY(QString, claudeCodeBin, u"claude"_s)
    CONFIG_PROPERTY(QString, defaultClaudeCodeModel, u"default"_s)
    // Effort / thinking level passed to `claude --effort` ("default" = don't pass).
    CONFIG_PROPERTY(QString, claudeCodeEffort, u"default"_s)

    // Multiple logins, each backed by its own CLAUDE_CONFIG_DIR. claudeAccountsJson
    // is a JSON array of {"id","name"}; the ~/.claude login is always present as an
    // implicit "Default" (id ""). loginTerminal is used for the interactive login.
    CONFIG_PROPERTY(QString, claudeAccountsJson, u"[]"_s)
    CONFIG_PROPERTY(QString, activeClaudeAccount, u""_s)
    CONFIG_PROPERTY(QString, loginTerminal, u"konsole"_s)

    // Master switch for the sidebar assistant, independent of which providers are
    // enabled — so turning a provider off no longer means losing the whole tab.
    CONFIG_PROPERTY(bool, enableAiAssistant, true)
    CONFIG_PROPERTY(bool, enableCelestialMode, true)
    CONFIG_PROPERTY(bool, showNews, true)
    CONFIG_PROPERTY(bool, showCaelestiaMode, true)
    CONFIG_PROPERTY(QString, orionModel, u"qwen3.5:9b"_s)

    CONFIG_PROPERTY(QString, activeProvider, u"ollama"_s)
    CONFIG_PROPERTY(QString, activeOllamaModel, u"llama3"_s)

public:
    explicit AiConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
