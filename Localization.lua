local _, ns = ...

---------------------------------------------------------------------------
-- Localization table  (English fallback via __index)
---------------------------------------------------------------------------
local L = setmetatable({}, { __index = function(_, k) return k end })
ns.L = L

---------------------------------------------------------------------------
-- Simplified Chinese  (zhCN)  -  China mainland
---------------------------------------------------------------------------
if GetLocale() == "zhCN" then

    -- Keybindings
    L["Toggle Chat Visibility"]     = "切换聊天可见性"
    L["Hold to Peek"]               = "按住窥视"

    -- Config panel title / status
    L["Settings"]                   = "设置"
    L["Hidden"]                     = "已隐藏"
    L["Visible"]                    = "可见"

    -- Config sections
    L["General"]                    = "常规"
    L["Combat"]                     = "战斗"
    L["Automation"]                 = "自动化"
    L["Appearance"]                 = "外观"
    L["Chat"]                       = "聊天"
    L["Zone Memory"]                = "区域记忆"
    L["Compatibility"]              = "兼容性"
    L["Profiles"]                   = "配置文件"

    -- General
    L["Show toggle button"]         = "显示切换按钮"
    L["Lock button position"]       = "锁定按钮位置"
    L["Reset Position"]             = "重置位置"
    L["Show minimap button"]        = "显示小地图按钮"
    L["Reset Minimap Pos"]          = "重置小地图位置"

    -- Combat
    L["Auto-hide in combat"]        = "战斗中自动隐藏"
    L["Auto-show after combat"]     = "战斗后自动显示"
    L["Auto-show on ready-check / encounter"] = "就绪确认/首领战自动显示"

    -- Automation
    L["Auto-hide in instances"]     = "副本中自动隐藏"
    L["Dungeons"]                   = "地下城"
    L["Raids"]                      = "团队副本"
    L["PvP"]                        = "PvP"
    L["Arenas"]                     = "竞技场"
    L["Scenarios"]                  = "场景战役"
    L["Inactivity timer"]           = "不活动计时器"
    L["off"]                        = "关闭"
    L["Show chat on new message"]   = "收到新消息时显示聊天"

    -- Appearance
    L["Fade transition (smooth easing)"]    = "淡入淡出过渡（平滑缓动）"
    L["Fade duration"]              = "淡入淡出时长"
    L["Hidden opacity"]             = "隐藏时透明度"
    L["Show on mouse-over"]         = "鼠标悬停时显示"
    L["Mouseover fade-out delay"]   = "鼠标移开后淡出延迟"
    L["Colorblind mode (high contrast)"]    = "色盲模式（高对比度）"

    -- Chat
    L["Blink button on whisper"]    = "收到密语时按钮闪烁"
    L["Show whispers while hidden"] = "隐藏时显示密语"
    L["Play sound on whisper"]      = "收到密语时播放声音"
    L["Keep combat log visible"]    = "保持战斗记录可见"
    L["Hide chat for screenshots"]  = "截图时隐藏聊天"
    L["Scroll to recent on unhide"] = "显示时滚动到最新消息"
    L["Hide typing area"]           = "隐藏输入区域"
    L["Show chat on Enter key"]     = "按回车键时显示聊天"

    -- Zone Memory
    L["Remember chat state per zone"] = "按区域记住聊天状态"
    L["Clear Memory"]               = "清除记忆"
    L["Zone memory cleared."]       = "区域记忆已清除。"

    -- Compatibility
    L["Alpha mode (Chattynator / Prat / ElvUI)"] = "透明度模式 (Chattynator / Prat / ElvUI)"
    L["No third-party chat addons detected"]     = "未检测到第三方聊天插件"
    L["Detected:"]                  = "已检测到:"
    L["enable Alpha mode"]          = "请启用透明度模式"

    -- Profiles
    L["Active:"]                    = "当前:"
    L["New"]                        = "新建"
    L["Copy"]                       = "复制"
    L["Rename"]                     = "重命名"
    L["Delete"]                     = "删除"
    L["Export"]                     = "导出"
    L["Import"]                     = "导入"
    L["Bind to Spec"]               = "绑定到专精"
    L["No spec binding"]            = "未绑定专精"
    L["Spec profiles: retail only"] = "专精配置: 仅正式服"
    L["Cannot rename the Default profile."]  = "无法重命名默认配置文件。"
    L["Cannot delete Default profile."]      = "无法删除默认配置文件。"

    -- Profile popup dialogs
    L["Create"]                     = "创建"
    L["Cancel"]                     = "取消"
    L["Reset"]                      = "重置"
    L["OK"]                         = "确定"
    L["HideChat - New profile name:"]       = "HideChat - 新配置文件名称:"
    L["HideChat - Copy current profile to:"] = "HideChat - 复制当前配置文件到:"
    L["HideChat - Rename profile \"%s\" to:"] = "HideChat - 将配置文件「%s」重命名为:"
    L["HideChat - Delete profile \"%s\"?"]    = "HideChat - 删除配置文件「%s」？"
    L["HideChat - Reset all settings to defaults?"] = "HideChat - 重置所有设置为默认值？"
    L["HideChat - Paste import string:"]    = "HideChat - 粘贴导入字符串:"
    L["HideChat - Export string (copy this):"] = "HideChat - 导出字符串（复制此内容）:"

    -- Reset + commands
    L["Reset All Settings"]         = "重置所有设置"
    L["Key Bindings: ESC > Key Bindings > HideChat"] = "按键绑定: ESC > 按键绑定 > HideChat"
    L["Hold to Peek: bindable key, shows chat while held"] = "按住窥视: 可绑定按键，按住时显示聊天"
    L["toggle"]                     = "切换"
    L["force state"]                = "强制状态"
    L["this panel"]                 = "此面板"
    L["diagnostics"]                = "诊断信息"
    L["detailed debug output"]      = "详细调试输出"
    L["profiles"]                   = "配置文件"
    L["restore defaults"]           = "恢复默认"

    -- Notifications
    L["Chat hidden"]                = "聊天已隐藏"
    L["Chat visible"]               = "聊天可见"

    -- Config buttons
    L["Toggle"]                     = "切换"

    -- Tooltips
    L["Status: Hidden"]             = "状态: 已隐藏"
    L["Status: Visible"]            = "状态: 可见"
    L["Left-click: Toggle chat"]    = "左键点击: 切换聊天"
    L["Left-click: Toggle"]         = "左键点击: 切换"
    L["Right-click: Settings"]      = "右键点击: 设置"
    L["Middle-click: Quick reply"]  = "中键点击: 快速回复"
    L["Drag: Move button"]          = "拖拽: 移动按钮"
    L["Drag: Reposition"]           = "拖拽: 重新定位"
    L["New whisper!"]               = "新密语！"

    -- Slash command messages
    L["Profile \"%s\" already exists."]       = "配置文件「%s」已存在。"
    L["Profile \"%s\" imported successfully."] = "配置文件「%s」导入成功。"
    L["Export string for \"%s\":"]            = "「%s」的导出字符串:"
    L["Profile not found."]         = "未找到配置文件。"
    L["Invalid import string."]     = "无效的导入字符串。"
    L["Failed to decode import string."]     = "解码导入字符串失败。"
    L["Failed to parse import data."]        = "解析导入数据失败。"
    L["Import data contains no valid settings."] = "导入数据不包含有效设置。"
    L["Usage: /hc import HC1:..."]  = "用法: /hc import HC1:..."
    L["Settings reset to defaults."] = "设置已重置为默认值。"
    L["No recent whisper to reply to."] = "没有最近的密语可回复。"

    -- Status command
    L["Profile:"]                   = "配置文件:"
    L["Chat:"]                      = "聊天:"
    L["hidden"]                     = "已隐藏"
    L["visible"]                    = "可见"
    L["Mode:"]                      = "模式:"
    L["Fade:"]                      = "淡出:"
    L["Opacity:"]                   = "透明度:"
    L["Instance auto-hide: on"]     = "副本自动隐藏: 开启"
    L["Inactivity:"]                = "不活动:"
    L["Mouseover reveal: on"]       = "鼠标悬停显示: 开启"
    L["Combat log kept: on"]        = "保持战斗记录: 开启"
    L["Raid auto-show: on"]         = "团队自动显示: 开启"
    L["Whisper sound: on"]          = "密语提示音: 开启"
    L["Zone memory: on"]            = "区域记忆: 开启"
    L["Chat addons:"]               = "聊天插件:"
    L["on"]                         = "开启"
    L["Combat:"]                    = "战斗:"
end

---------------------------------------------------------------------------
-- German  (deDE)
---------------------------------------------------------------------------
if GetLocale() == "deDE" then

    -- Keybindings
    L["Toggle Chat Visibility"]     = "Chat-Sichtbarkeit umschalten"
    L["Hold to Peek"]               = "Halten zum Vorschau"

    -- Config panel title / status
    L["Settings"]                   = "Einstellungen"
    L["Hidden"]                     = "Versteckt"
    L["Visible"]                    = "Sichtbar"

    -- Config sections
    L["General"]                    = "Allgemein"
    L["Combat"]                     = "Kampf"
    L["Automation"]                 = "Automatisierung"
    L["Appearance"]                 = "Darstellung"
    L["Chat"]                       = "Chat"
    L["Zone Memory"]                = "Gebietsspeicher"
    L["Compatibility"]              = "Kompatibilität"
    L["Profiles"]                   = "Profile"

    -- General
    L["Show toggle button"]         = "Umschaltknopf anzeigen"
    L["Lock button position"]       = "Knopfposition sperren"
    L["Reset Position"]             = "Position zurücksetzen"
    L["Show minimap button"]        = "Minikarten-Knopf anzeigen"
    L["Reset Minimap Pos"]          = "Minikarten-Pos. zurücksetzen"

    -- Combat
    L["Auto-hide in combat"]        = "Im Kampf automatisch ausblenden"
    L["Auto-show after combat"]     = "Nach dem Kampf automatisch einblenden"
    L["Auto-show on ready-check / encounter"] = "Bei Bereitschaftscheck/Begegnung automatisch einblenden"

    -- Automation
    L["Auto-hide in instances"]     = "In Instanzen automatisch ausblenden"
    L["Dungeons"]                   = "Dungeons"
    L["Raids"]                      = "Schlachtzüge"
    L["PvP"]                        = "PvP"
    L["Arenas"]                     = "Arenen"
    L["Scenarios"]                  = "Szenarien"
    L["Inactivity timer"]           = "Inaktivitäts-Timer"
    L["off"]                        = "aus"
    L["Show chat on new message"]   = "Chat bei neuer Nachricht anzeigen"

    -- Appearance
    L["Fade transition (smooth easing)"]    = "Überblendung (sanfter Verlauf)"
    L["Fade duration"]              = "Überblendungsdauer"
    L["Hidden opacity"]             = "Deckkraft im verborgenen Zustand"
    L["Show on mouse-over"]         = "Bei Mausberührung anzeigen"
    L["Mouseover fade-out delay"]   = "Maus-Ausblendverzögerung"
    L["Colorblind mode (high contrast)"]    = "Farbenblind-Modus (hoher Kontrast)"

    -- Chat
    L["Blink button on whisper"]    = "Knopf bei Flüstern blinken"
    L["Show whispers while hidden"] = "Flüsternachrichten im verborgenen Zustand anzeigen"
    L["Play sound on whisper"]      = "Ton bei Flüstern abspielen"
    L["Keep combat log visible"]    = "Kampflog sichtbar halten"
    L["Hide chat for screenshots"]  = "Chat für Screenshots ausblenden"
    L["Scroll to recent on unhide"] = "Beim Einblenden zu neuesten Nachrichten scrollen"
    L["Hide typing area"]           = "Eingabebereich ausblenden"
    L["Show chat on Enter key"]     = "Chat bei Eingabetaste anzeigen"

    -- Zone Memory
    L["Remember chat state per zone"] = "Chat-Status pro Gebiet merken"
    L["Clear Memory"]               = "Speicher löschen"
    L["Zone memory cleared."]       = "Gebietsspeicher gelöscht."

    -- Compatibility
    L["Alpha mode (Chattynator / Prat / ElvUI)"] = "Alpha-Modus (Chattynator / Prat / ElvUI)"
    L["No third-party chat addons detected"]     = "Keine Chat-Addons von Drittanbietern erkannt"
    L["Detected:"]                  = "Erkannt:"
    L["enable Alpha mode"]          = "Alpha-Modus aktivieren"

    -- Profiles
    L["Active:"]                    = "Aktiv:"
    L["New"]                        = "Neu"
    L["Copy"]                       = "Kopieren"
    L["Rename"]                     = "Umbenennen"
    L["Delete"]                     = "Löschen"
    L["Export"]                     = "Exportieren"
    L["Import"]                     = "Importieren"
    L["Bind to Spec"]               = "An Spezialisierung binden"
    L["No spec binding"]            = "Keine Spezialisierung gebunden"
    L["Spec profiles: retail only"] = "Spezialisierungsprofile: nur Retail"
    L["Cannot rename the Default profile."]  = "Das Standardprofil kann nicht umbenannt werden."
    L["Cannot delete Default profile."]      = "Das Standardprofil kann nicht gelöscht werden."

    -- Profile popup dialogs
    L["Create"]                     = "Erstellen"
    L["Cancel"]                     = "Abbrechen"
    L["Reset"]                      = "Zurücksetzen"
    L["OK"]                         = "OK"
    L["HideChat - New profile name:"]       = "HideChat - Neuer Profilname:"
    L["HideChat - Copy current profile to:"] = "HideChat - Aktuelles Profil kopieren nach:"
    L["HideChat - Rename profile \"%s\" to:"] = "HideChat - Profil \"%s\" umbenennen in:"
    L["HideChat - Delete profile \"%s\"?"]    = "HideChat - Profil \"%s\" löschen?"
    L["HideChat - Reset all settings to defaults?"] = "HideChat - Alle Einstellungen auf Standard zurücksetzen?"
    L["HideChat - Paste import string:"]    = "HideChat - Import-String einfügen:"
    L["HideChat - Export string (copy this):"] = "HideChat - Export-String (dies kopieren):"

    -- Reset + commands
    L["Reset All Settings"]         = "Alle Einstellungen zurücksetzen"
    L["Key Bindings: ESC > Key Bindings > HideChat"] = "Tastenbelegung: ESC > Tastenbelegung > HideChat"
    L["Hold to Peek: bindable key, shows chat while held"] = "Halten zum Vorschau: belegbare Taste, zeigt Chat beim Halten"
    L["toggle"]                     = "umschalten"
    L["force state"]                = "Zustand erzwingen"
    L["this panel"]                 = "dieses Fenster"
    L["diagnostics"]                = "Diagnose"
    L["detailed debug output"]      = "detaillierte Debug-Ausgabe"
    L["profiles"]                   = "Profile"
    L["restore defaults"]           = "Standards wiederherstellen"

    -- Notifications
    L["Chat hidden"]                = "Chat versteckt"
    L["Chat visible"]               = "Chat sichtbar"

    -- Config buttons
    L["Toggle"]                     = "Umschalten"

    -- Tooltips
    L["Status: Hidden"]             = "Status: Versteckt"
    L["Status: Visible"]            = "Status: Sichtbar"
    L["Left-click: Toggle chat"]    = "Linksklick: Chat umschalten"
    L["Left-click: Toggle"]         = "Linksklick: Umschalten"
    L["Right-click: Settings"]      = "Rechtsklick: Einstellungen"
    L["Middle-click: Quick reply"]  = "Mittelklick: Schnellantwort"
    L["Drag: Move button"]          = "Ziehen: Knopf bewegen"
    L["Drag: Reposition"]           = "Ziehen: Neu positionieren"
    L["New whisper!"]               = "Neue Flüsternachricht!"

    -- Slash command messages
    L["Profile \"%s\" already exists."]       = "Profil \"%s\" existiert bereits."
    L["Profile \"%s\" imported successfully."] = "Profil \"%s\" erfolgreich importiert."
    L["Export string for \"%s\":"]            = "Export-String für \"%s\":"
    L["Profile not found."]         = "Profil nicht gefunden."
    L["Invalid import string."]     = "Ungültiger Import-String."
    L["Failed to decode import string."]     = "Import-String konnte nicht dekodiert werden."
    L["Failed to parse import data."]        = "Importdaten konnten nicht analysiert werden."
    L["Import data contains no valid settings."] = "Importdaten enthalten keine gültigen Einstellungen."
    L["Usage: /hc import HC1:..."]  = "Verwendung: /hc import HC1:..."
    L["Settings reset to defaults."] = "Einstellungen auf Standard zurückgesetzt."
    L["No recent whisper to reply to."] = "Keine aktuelle Flüsternachricht zum Antworten."

    -- Status command
    L["Profile:"]                   = "Profil:"
    L["Chat:"]                      = "Chat:"
    L["hidden"]                     = "versteckt"
    L["visible"]                    = "sichtbar"
    L["Mode:"]                      = "Modus:"
    L["Fade:"]                      = "Überblendung:"
    L["Opacity:"]                   = "Deckkraft:"
    L["Instance auto-hide: on"]     = "Instanz-Autoverbergen: an"
    L["Inactivity:"]                = "Inaktivität:"
    L["Mouseover reveal: on"]       = "Mausberührungs-Anzeige: an"
    L["Combat log kept: on"]        = "Kampflog behalten: an"
    L["Raid auto-show: on"]         = "Schlachtzug-Autoanzeige: an"
    L["Whisper sound: on"]          = "Flüsterton: an"
    L["Zone memory: on"]            = "Gebietsspeicher: an"
    L["Chat addons:"]               = "Chat-Addons:"
    L["on"]                         = "an"
    L["Combat:"]                    = "Kampf:"
end

---------------------------------------------------------------------------
-- Spanish  (esES / esMX)
---------------------------------------------------------------------------
if GetLocale() == "esES" or GetLocale() == "esMX" then

    -- Keybindings
    L["Toggle Chat Visibility"]     = "Alternar visibilidad del chat"
    L["Hold to Peek"]               = "Mantener para espiar"

    -- Config panel title / status
    L["Settings"]                   = "Ajustes"
    L["Hidden"]                     = "Oculto"
    L["Visible"]                    = "Visible"

    -- Config sections
    L["General"]                    = "General"
    L["Combat"]                     = "Combate"
    L["Automation"]                 = "Automatización"
    L["Appearance"]                 = "Apariencia"
    L["Chat"]                       = "Chat"
    L["Zone Memory"]                = "Memoria de zona"
    L["Compatibility"]              = "Compatibilidad"
    L["Profiles"]                   = "Perfiles"

    -- General
    L["Show toggle button"]         = "Mostrar botón de alternancia"
    L["Lock button position"]       = "Bloquear posición del botón"
    L["Reset Position"]             = "Restablecer posición"
    L["Show minimap button"]        = "Mostrar botón del minimapa"
    L["Reset Minimap Pos"]          = "Restablecer pos. del minimapa"

    -- Combat
    L["Auto-hide in combat"]        = "Ocultar automáticamente en combate"
    L["Auto-show after combat"]     = "Mostrar automáticamente tras el combate"
    L["Auto-show on ready-check / encounter"] = "Mostrar en verificación/encuentro"

    -- Automation
    L["Auto-hide in instances"]     = "Ocultar automáticamente en instancias"
    L["Dungeons"]                   = "Mazmorras"
    L["Raids"]                      = "Bandas"
    L["PvP"]                        = "PvP"
    L["Arenas"]                     = "Arenas"
    L["Scenarios"]                  = "Escenarios"
    L["Inactivity timer"]           = "Temporizador de inactividad"
    L["off"]                        = "desactivado"
    L["Show chat on new message"]   = "Mostrar chat con mensaje nuevo"

    -- Appearance
    L["Fade transition (smooth easing)"]    = "Transición suave (atenuación)"
    L["Fade duration"]              = "Duración de la transición"
    L["Hidden opacity"]             = "Opacidad al ocultar"
    L["Show on mouse-over"]         = "Mostrar al pasar el ratón"
    L["Mouseover fade-out delay"]   = "Retardo de desvanecimiento del ratón"
    L["Colorblind mode (high contrast)"]    = "Modo daltónico (alto contraste)"

    -- Chat
    L["Blink button on whisper"]    = "Parpadear botón con susurro"
    L["Show whispers while hidden"] = "Mostrar susurros mientras está oculto"
    L["Play sound on whisper"]      = "Reproducir sonido con susurro"
    L["Keep combat log visible"]    = "Mantener registro de combate visible"
    L["Hide chat for screenshots"]  = "Ocultar chat para capturas"
    L["Scroll to recent on unhide"] = "Desplazar a recientes al mostrar"
    L["Hide typing area"]           = "Ocultar área de escritura"
    L["Show chat on Enter key"]     = "Mostrar chat al pulsar Intro"

    -- Zone Memory
    L["Remember chat state per zone"] = "Recordar estado del chat por zona"
    L["Clear Memory"]               = "Borrar memoria"
    L["Zone memory cleared."]       = "Memoria de zona borrada."

    -- Compatibility
    L["Alpha mode (Chattynator / Prat / ElvUI)"] = "Modo alfa (Chattynator / Prat / ElvUI)"
    L["No third-party chat addons detected"]     = "No se detectaron addons de chat de terceros"
    L["Detected:"]                  = "Detectado:"
    L["enable Alpha mode"]          = "activar modo alfa"

    -- Profiles
    L["Active:"]                    = "Activo:"
    L["New"]                        = "Nuevo"
    L["Copy"]                       = "Copiar"
    L["Rename"]                     = "Renombrar"
    L["Delete"]                     = "Eliminar"
    L["Export"]                     = "Exportar"
    L["Import"]                     = "Importar"
    L["Bind to Spec"]               = "Vincular a especialización"
    L["No spec binding"]            = "Sin vínculo de especialización"
    L["Spec profiles: retail only"] = "Perfiles de espec.: solo Retail"
    L["Cannot rename the Default profile."]  = "No se puede renombrar el perfil predeterminado."
    L["Cannot delete Default profile."]      = "No se puede eliminar el perfil predeterminado."

    -- Profile popup dialogs
    L["Create"]                     = "Crear"
    L["Cancel"]                     = "Cancelar"
    L["Reset"]                      = "Restablecer"
    L["OK"]                         = "Aceptar"
    L["HideChat - New profile name:"]       = "HideChat - Nombre del nuevo perfil:"
    L["HideChat - Copy current profile to:"] = "HideChat - Copiar perfil actual a:"
    L["HideChat - Rename profile \"%s\" to:"] = "HideChat - Renombrar perfil \"%s\" a:"
    L["HideChat - Delete profile \"%s\"?"]    = "HideChat - ¿Eliminar perfil \"%s\"?"
    L["HideChat - Reset all settings to defaults?"] = "HideChat - ¿Restablecer todos los ajustes?"
    L["HideChat - Paste import string:"]    = "HideChat - Pegar cadena de importación:"
    L["HideChat - Export string (copy this):"] = "HideChat - Cadena de exportación (copiar):"

    -- Reset + commands
    L["Reset All Settings"]         = "Restablecer todos los ajustes"
    L["Key Bindings: ESC > Key Bindings > HideChat"] = "Atajos: ESC > Atajos de teclado > HideChat"
    L["Hold to Peek: bindable key, shows chat while held"] = "Mantener para espiar: tecla asignable, muestra el chat"
    L["toggle"]                     = "alternar"
    L["force state"]                = "forzar estado"
    L["this panel"]                 = "este panel"
    L["diagnostics"]                = "diagnósticos"
    L["detailed debug output"]      = "salida de depuración detallada"
    L["profiles"]                   = "perfiles"
    L["restore defaults"]           = "restaurar valores predeterminados"

    -- Notifications
    L["Chat hidden"]                = "Chat oculto"
    L["Chat visible"]               = "Chat visible"

    -- Config buttons
    L["Toggle"]                     = "Alternar"

    -- Tooltips
    L["Status: Hidden"]             = "Estado: Oculto"
    L["Status: Visible"]            = "Estado: Visible"
    L["Left-click: Toggle chat"]    = "Clic izquierdo: Alternar chat"
    L["Left-click: Toggle"]         = "Clic izquierdo: Alternar"
    L["Right-click: Settings"]      = "Clic derecho: Ajustes"
    L["Middle-click: Quick reply"]  = "Clic central: Respuesta rápida"
    L["Drag: Move button"]          = "Arrastrar: Mover botón"
    L["Drag: Reposition"]           = "Arrastrar: Reposicionar"
    L["New whisper!"]               = "¡Nuevo susurro!"

    -- Slash command messages
    L["Profile \"%s\" already exists."]       = "El perfil \"%s\" ya existe."
    L["Profile \"%s\" imported successfully."] = "Perfil \"%s\" importado correctamente."
    L["Export string for \"%s\":"]            = "Cadena de exportación para \"%s\":"
    L["Profile not found."]         = "Perfil no encontrado."
    L["Invalid import string."]     = "Cadena de importación no válida."
    L["Failed to decode import string."]     = "Error al decodificar la cadena de importación."
    L["Failed to parse import data."]        = "Error al analizar los datos de importación."
    L["Import data contains no valid settings."] = "Los datos no contienen ajustes válidos."
    L["Usage: /hc import HC1:..."]  = "Uso: /hc import HC1:..."
    L["Settings reset to defaults."] = "Ajustes restablecidos."
    L["No recent whisper to reply to."] = "No hay susurro reciente para responder."

    -- Status command
    L["Profile:"]                   = "Perfil:"
    L["Chat:"]                      = "Chat:"
    L["hidden"]                     = "oculto"
    L["visible"]                    = "visible"
    L["Mode:"]                      = "Modo:"
    L["Fade:"]                      = "Transición:"
    L["Opacity:"]                   = "Opacidad:"
    L["Instance auto-hide: on"]     = "Ocultación en instancia: activada"
    L["Inactivity:"]                = "Inactividad:"
    L["Mouseover reveal: on"]       = "Mostrar con ratón: activado"
    L["Combat log kept: on"]        = "Registro de combate: activado"
    L["Raid auto-show: on"]         = "Mostrar en banda: activado"
    L["Whisper sound: on"]          = "Sonido de susurro: activado"
    L["Zone memory: on"]            = "Memoria de zona: activada"
    L["Chat addons:"]               = "Addons de chat:"
    L["on"]                         = "activado"
    L["Combat:"]                    = "Combate:"
end

---------------------------------------------------------------------------
-- French  (frFR)
---------------------------------------------------------------------------
if GetLocale() == "frFR" then

    -- Keybindings
    L["Toggle Chat Visibility"]     = "Basculer la visibilité du chat"
    L["Hold to Peek"]               = "Maintenir pour apercevoir"

    -- Config panel title / status
    L["Settings"]                   = "Paramètres"
    L["Hidden"]                     = "Masqué"
    L["Visible"]                    = "Visible"

    -- Config sections
    L["General"]                    = "Général"
    L["Combat"]                     = "Combat"
    L["Automation"]                 = "Automatisation"
    L["Appearance"]                 = "Apparence"
    L["Chat"]                       = "Discussion"
    L["Zone Memory"]                = "Mémoire de zone"
    L["Compatibility"]              = "Compatibilité"
    L["Profiles"]                   = "Profils"

    -- General
    L["Show toggle button"]         = "Afficher le bouton bascule"
    L["Lock button position"]       = "Verrouiller la position du bouton"
    L["Reset Position"]             = "Réinitialiser la position"
    L["Show minimap button"]        = "Afficher le bouton minicarte"
    L["Reset Minimap Pos"]          = "Réinitialiser pos. minicarte"

    -- Combat
    L["Auto-hide in combat"]        = "Masquer auto en combat"
    L["Auto-show after combat"]     = "Afficher auto après le combat"
    L["Auto-show on ready-check / encounter"] = "Afficher auto en appel/rencontre"

    -- Automation
    L["Auto-hide in instances"]     = "Masquer auto en instance"
    L["Dungeons"]                   = "Donjons"
    L["Raids"]                      = "Raids"
    L["PvP"]                        = "PvP"
    L["Arenas"]                     = "Arènes"
    L["Scenarios"]                  = "Scénarios"
    L["Inactivity timer"]           = "Minuteur d'inactivité"
    L["off"]                        = "désactivé"
    L["Show chat on new message"]   = "Afficher le chat lors d'un nouveau message"

    -- Appearance
    L["Fade transition (smooth easing)"]    = "Transition en fondu (atténuation douce)"
    L["Fade duration"]              = "Durée du fondu"
    L["Hidden opacity"]             = "Opacité masquée"
    L["Show on mouse-over"]         = "Afficher au survol de la souris"
    L["Mouseover fade-out delay"]   = "Délai de disparition au survol"
    L["Colorblind mode (high contrast)"]    = "Mode daltonien (contraste élevé)"

    -- Chat
    L["Blink button on whisper"]    = "Clignoter le bouton lors d'un chuchotement"
    L["Show whispers while hidden"] = "Afficher les chuchotements quand masqué"
    L["Play sound on whisper"]      = "Jouer un son lors d'un chuchotement"
    L["Keep combat log visible"]    = "Garder le journal de combat visible"
    L["Hide chat for screenshots"]  = "Masquer le chat pour les captures d'écran"
    L["Scroll to recent on unhide"] = "Défiler vers les récents à l'affichage"
    L["Hide typing area"]           = "Masquer la zone de saisie"
    L["Show chat on Enter key"]     = "Afficher le chat avec la touche Entrée"

    -- Zone Memory
    L["Remember chat state per zone"] = "Mémoriser l'état du chat par zone"
    L["Clear Memory"]               = "Effacer la mémoire"
    L["Zone memory cleared."]       = "Mémoire de zone effacée."

    -- Compatibility
    L["Alpha mode (Chattynator / Prat / ElvUI)"] = "Mode alpha (Chattynator / Prat / ElvUI)"
    L["No third-party chat addons detected"]     = "Aucun addon de chat tiers détecté"
    L["Detected:"]                  = "Détecté :"
    L["enable Alpha mode"]          = "activer le mode alpha"

    -- Profiles
    L["Active:"]                    = "Actif :"
    L["New"]                        = "Nouveau"
    L["Copy"]                       = "Copier"
    L["Rename"]                     = "Renommer"
    L["Delete"]                     = "Supprimer"
    L["Export"]                     = "Exporter"
    L["Import"]                     = "Importer"
    L["Bind to Spec"]               = "Lier à la spécialisation"
    L["No spec binding"]            = "Aucune liaison de spéc."
    L["Spec profiles: retail only"] = "Profils de spéc. : Retail uniquement"
    L["Cannot rename the Default profile."]  = "Impossible de renommer le profil par défaut."
    L["Cannot delete Default profile."]      = "Impossible de supprimer le profil par défaut."

    -- Profile popup dialogs
    L["Create"]                     = "Créer"
    L["Cancel"]                     = "Annuler"
    L["Reset"]                      = "Réinitialiser"
    L["OK"]                         = "OK"
    L["HideChat - New profile name:"]       = "HideChat - Nom du nouveau profil :"
    L["HideChat - Copy current profile to:"] = "HideChat - Copier le profil actuel vers :"
    L["HideChat - Rename profile \"%s\" to:"] = "HideChat - Renommer le profil « %s » en :"
    L["HideChat - Delete profile \"%s\"?"]    = "HideChat - Supprimer le profil « %s » ?"
    L["HideChat - Reset all settings to defaults?"] = "HideChat - Réinitialiser tous les paramètres ?"
    L["HideChat - Paste import string:"]    = "HideChat - Coller la chaîne d'import :"
    L["HideChat - Export string (copy this):"] = "HideChat - Chaîne d'export (copier) :"

    -- Reset + commands
    L["Reset All Settings"]         = "Réinitialiser tous les paramètres"
    L["Key Bindings: ESC > Key Bindings > HideChat"] = "Raccourcis : ESC > Raccourcis > HideChat"
    L["Hold to Peek: bindable key, shows chat while held"] = "Maintenir pour apercevoir : touche assignable, affiche le chat"
    L["toggle"]                     = "basculer"
    L["force state"]                = "forcer l'état"
    L["this panel"]                 = "ce panneau"
    L["diagnostics"]                = "diagnostics"
    L["detailed debug output"]      = "sortie de débogage détaillée"
    L["profiles"]                   = "profils"
    L["restore defaults"]           = "restaurer les valeurs par défaut"

    -- Notifications
    L["Chat hidden"]                = "Chat masqué"
    L["Chat visible"]               = "Chat visible"

    -- Config buttons
    L["Toggle"]                     = "Basculer"

    -- Tooltips
    L["Status: Hidden"]             = "Statut : Masqué"
    L["Status: Visible"]            = "Statut : Visible"
    L["Left-click: Toggle chat"]    = "Clic gauche : Basculer le chat"
    L["Left-click: Toggle"]         = "Clic gauche : Basculer"
    L["Right-click: Settings"]      = "Clic droit : Paramètres"
    L["Middle-click: Quick reply"]  = "Clic milieu : Réponse rapide"
    L["Drag: Move button"]          = "Glisser : Déplacer le bouton"
    L["Drag: Reposition"]           = "Glisser : Repositionner"
    L["New whisper!"]               = "Nouveau chuchotement !"

    -- Slash command messages
    L["Profile \"%s\" already exists."]       = "Le profil « %s » existe déjà."
    L["Profile \"%s\" imported successfully."] = "Profil « %s » importé avec succès."
    L["Export string for \"%s\":"]            = "Chaîne d'export pour « %s » :"
    L["Profile not found."]         = "Profil introuvable."
    L["Invalid import string."]     = "Chaîne d'import invalide."
    L["Failed to decode import string."]     = "Échec du décodage de la chaîne d'import."
    L["Failed to parse import data."]        = "Échec de l'analyse des données d'import."
    L["Import data contains no valid settings."] = "Les données d'import ne contiennent aucun paramètre valide."
    L["Usage: /hc import HC1:..."]  = "Utilisation : /hc import HC1:..."
    L["Settings reset to defaults."] = "Paramètres réinitialisés."
    L["No recent whisper to reply to."] = "Aucun chuchotement récent pour répondre."

    -- Status command
    L["Profile:"]                   = "Profil :"
    L["Chat:"]                      = "Chat :"
    L["hidden"]                     = "masqué"
    L["visible"]                    = "visible"
    L["Mode:"]                      = "Mode :"
    L["Fade:"]                      = "Fondu :"
    L["Opacity:"]                   = "Opacité :"
    L["Instance auto-hide: on"]     = "Masquage auto en instance : activé"
    L["Inactivity:"]                = "Inactivité :"
    L["Mouseover reveal: on"]       = "Affichage au survol : activé"
    L["Combat log kept: on"]        = "Journal de combat : activé"
    L["Raid auto-show: on"]         = "Affichage auto en raid : activé"
    L["Whisper sound: on"]          = "Son de chuchotement : activé"
    L["Zone memory: on"]            = "Mémoire de zone : activée"
    L["Chat addons:"]               = "Addons de chat :"
    L["on"]                         = "activé"
    L["Combat:"]                    = "Combat :"
end

---------------------------------------------------------------------------
-- Italian  (itIT)
---------------------------------------------------------------------------
if GetLocale() == "itIT" then

    -- Keybindings
    L["Toggle Chat Visibility"]     = "Attiva/Disattiva visibilità chat"
    L["Hold to Peek"]               = "Tieni premuto per sbirciare"

    -- Config panel title / status
    L["Settings"]                   = "Impostazioni"
    L["Hidden"]                     = "Nascosto"
    L["Visible"]                    = "Visibile"

    -- Config sections
    L["General"]                    = "Generale"
    L["Combat"]                     = "Combattimento"
    L["Automation"]                 = "Automazione"
    L["Appearance"]                 = "Aspetto"
    L["Chat"]                       = "Chat"
    L["Zone Memory"]                = "Memoria di zona"
    L["Compatibility"]              = "Compatibilità"
    L["Profiles"]                   = "Profili"

    -- General
    L["Show toggle button"]         = "Mostra pulsante di attivazione"
    L["Lock button position"]       = "Blocca posizione pulsante"
    L["Reset Position"]             = "Reimposta posizione"
    L["Show minimap button"]        = "Mostra pulsante minimappa"
    L["Reset Minimap Pos"]          = "Reimposta pos. minimappa"

    -- Combat
    L["Auto-hide in combat"]        = "Nascondi auto in combattimento"
    L["Auto-show after combat"]     = "Mostra auto dopo il combattimento"
    L["Auto-show on ready-check / encounter"] = "Mostra auto in verifica/incontro"

    -- Automation
    L["Auto-hide in instances"]     = "Nascondi auto nelle istanze"
    L["Dungeons"]                   = "Dungeon"
    L["Raids"]                      = "Incursioni"
    L["PvP"]                        = "PvP"
    L["Arenas"]                     = "Arene"
    L["Scenarios"]                  = "Scenari"
    L["Inactivity timer"]           = "Timer di inattività"
    L["off"]                        = "disattivato"
    L["Show chat on new message"]   = "Mostra chat con nuovo messaggio"

    -- Appearance
    L["Fade transition (smooth easing)"]    = "Transizione dissolvenza (attenuazione morbida)"
    L["Fade duration"]              = "Durata dissolvenza"
    L["Hidden opacity"]             = "Opacità da nascosto"
    L["Show on mouse-over"]         = "Mostra al passaggio del mouse"
    L["Mouseover fade-out delay"]   = "Ritardo dissolvenza al passaggio"
    L["Colorblind mode (high contrast)"]    = "Modalità daltonici (alto contrasto)"

    -- Chat
    L["Blink button on whisper"]    = "Lampeggia pulsante con sussurro"
    L["Show whispers while hidden"] = "Mostra sussurri quando nascosto"
    L["Play sound on whisper"]      = "Riproduci suono con sussurro"
    L["Keep combat log visible"]    = "Mantieni registro combattimento visibile"
    L["Hide chat for screenshots"]  = "Nascondi chat per screenshot"
    L["Scroll to recent on unhide"] = "Scorri ai recenti quando mostrato"
    L["Hide typing area"]           = "Nascondi area di digitazione"
    L["Show chat on Enter key"]     = "Mostra chat con tasto Invio"

    -- Zone Memory
    L["Remember chat state per zone"] = "Ricorda stato chat per zona"
    L["Clear Memory"]               = "Cancella memoria"
    L["Zone memory cleared."]       = "Memoria di zona cancellata."

    -- Compatibility
    L["Alpha mode (Chattynator / Prat / ElvUI)"] = "Modalità alfa (Chattynator / Prat / ElvUI)"
    L["No third-party chat addons detected"]     = "Nessun addon chat di terze parti rilevato"
    L["Detected:"]                  = "Rilevato:"
    L["enable Alpha mode"]          = "attiva modalità alfa"

    -- Profiles
    L["Active:"]                    = "Attivo:"
    L["New"]                        = "Nuovo"
    L["Copy"]                       = "Copia"
    L["Rename"]                     = "Rinomina"
    L["Delete"]                     = "Elimina"
    L["Export"]                     = "Esporta"
    L["Import"]                     = "Importa"
    L["Bind to Spec"]               = "Associa a specializzazione"
    L["No spec binding"]            = "Nessuna associazione di spec."
    L["Spec profiles: retail only"] = "Profili spec.: solo Retail"
    L["Cannot rename the Default profile."]  = "Impossibile rinominare il profilo predefinito."
    L["Cannot delete Default profile."]      = "Impossibile eliminare il profilo predefinito."

    -- Profile popup dialogs
    L["Create"]                     = "Crea"
    L["Cancel"]                     = "Annulla"
    L["Reset"]                      = "Reimposta"
    L["OK"]                         = "OK"
    L["HideChat - New profile name:"]       = "HideChat - Nome nuovo profilo:"
    L["HideChat - Copy current profile to:"] = "HideChat - Copia profilo attuale in:"
    L["HideChat - Rename profile \"%s\" to:"] = "HideChat - Rinomina profilo \"%s\" in:"
    L["HideChat - Delete profile \"%s\"?"]    = "HideChat - Eliminare il profilo \"%s\"?"
    L["HideChat - Reset all settings to defaults?"] = "HideChat - Reimpostare tutte le impostazioni?"
    L["HideChat - Paste import string:"]    = "HideChat - Incolla stringa di importazione:"
    L["HideChat - Export string (copy this):"] = "HideChat - Stringa di esportazione (copia):"

    -- Reset + commands
    L["Reset All Settings"]         = "Reimposta tutte le impostazioni"
    L["Key Bindings: ESC > Key Bindings > HideChat"] = "Tasti: ESC > Associazioni tasti > HideChat"
    L["Hold to Peek: bindable key, shows chat while held"] = "Tieni per sbirciare: tasto assegnabile, mostra chat"
    L["toggle"]                     = "attiva/disattiva"
    L["force state"]                = "forza stato"
    L["this panel"]                 = "questo pannello"
    L["diagnostics"]                = "diagnostica"
    L["detailed debug output"]      = "output di debug dettagliato"
    L["profiles"]                   = "profili"
    L["restore defaults"]           = "ripristina predefiniti"

    -- Notifications
    L["Chat hidden"]                = "Chat nascosta"
    L["Chat visible"]               = "Chat visibile"

    -- Config buttons
    L["Toggle"]                     = "Attiva/Disattiva"

    -- Tooltips
    L["Status: Hidden"]             = "Stato: Nascosto"
    L["Status: Visible"]            = "Stato: Visibile"
    L["Left-click: Toggle chat"]    = "Clic sinistro: Attiva/Disattiva chat"
    L["Left-click: Toggle"]         = "Clic sinistro: Attiva/Disattiva"
    L["Right-click: Settings"]      = "Clic destro: Impostazioni"
    L["Middle-click: Quick reply"]  = "Clic centrale: Risposta rapida"
    L["Drag: Move button"]          = "Trascina: Sposta pulsante"
    L["Drag: Reposition"]           = "Trascina: Riposiziona"
    L["New whisper!"]               = "Nuovo sussurro!"

    -- Slash command messages
    L["Profile \"%s\" already exists."]       = "Il profilo \"%s\" esiste già."
    L["Profile \"%s\" imported successfully."] = "Profilo \"%s\" importato con successo."
    L["Export string for \"%s\":"]            = "Stringa di esportazione per \"%s\":"
    L["Profile not found."]         = "Profilo non trovato."
    L["Invalid import string."]     = "Stringa di importazione non valida."
    L["Failed to decode import string."]     = "Decodifica stringa di importazione fallita."
    L["Failed to parse import data."]        = "Analisi dati di importazione fallita."
    L["Import data contains no valid settings."] = "I dati non contengono impostazioni valide."
    L["Usage: /hc import HC1:..."]  = "Uso: /hc import HC1:..."
    L["Settings reset to defaults."] = "Impostazioni reimpostate."
    L["No recent whisper to reply to."] = "Nessun sussurro recente a cui rispondere."

    -- Status command
    L["Profile:"]                   = "Profilo:"
    L["Chat:"]                      = "Chat:"
    L["hidden"]                     = "nascosto"
    L["visible"]                    = "visibile"
    L["Mode:"]                      = "Modalità:"
    L["Fade:"]                      = "Dissolvenza:"
    L["Opacity:"]                   = "Opacità:"
    L["Instance auto-hide: on"]     = "Nascondi auto in istanza: attivo"
    L["Inactivity:"]                = "Inattività:"
    L["Mouseover reveal: on"]       = "Mostra al passaggio: attivo"
    L["Combat log kept: on"]        = "Registro combattimento: attivo"
    L["Raid auto-show: on"]         = "Mostra auto in incursione: attivo"
    L["Whisper sound: on"]          = "Suono sussurro: attivo"
    L["Zone memory: on"]            = "Memoria di zona: attivo"
    L["Chat addons:"]               = "Addon chat:"
    L["on"]                         = "attivo"
    L["Combat:"]                    = "Combattimento:"
end

---------------------------------------------------------------------------
-- Russian  (ruRU)
---------------------------------------------------------------------------
if GetLocale() == "ruRU" then

    -- Keybindings
    L["Toggle Chat Visibility"]     = "Переключить видимость чата"
    L["Hold to Peek"]               = "Удерживать для просмотра"

    -- Config panel title / status
    L["Settings"]                   = "Настройки"
    L["Hidden"]                     = "Скрыт"
    L["Visible"]                    = "Виден"

    -- Config sections
    L["General"]                    = "Общие"
    L["Combat"]                     = "Бой"
    L["Automation"]                 = "Автоматизация"
    L["Appearance"]                 = "Внешний вид"
    L["Chat"]                       = "Чат"
    L["Zone Memory"]                = "Память зоны"
    L["Compatibility"]              = "Совместимость"
    L["Profiles"]                   = "Профили"

    -- General
    L["Show toggle button"]         = "Показать кнопку переключения"
    L["Lock button position"]       = "Заблокировать позицию кнопки"
    L["Reset Position"]             = "Сбросить позицию"
    L["Show minimap button"]        = "Показать кнопку миникарты"
    L["Reset Minimap Pos"]          = "Сбросить позицию миникарты"

    -- Combat
    L["Auto-hide in combat"]        = "Скрывать автоматически в бою"
    L["Auto-show after combat"]     = "Показывать после боя"
    L["Auto-show on ready-check / encounter"] = "Показывать при проверке/бое с боссом"

    -- Automation
    L["Auto-hide in instances"]     = "Скрывать в подземельях"
    L["Dungeons"]                   = "Подземелья"
    L["Raids"]                      = "Рейды"
    L["PvP"]                        = "PvP"
    L["Arenas"]                     = "Арены"
    L["Scenarios"]                  = "Сценарии"
    L["Inactivity timer"]           = "Таймер бездействия"
    L["off"]                        = "выкл"
    L["Show chat on new message"]   = "Показать чат при новом сообщении"

    -- Appearance
    L["Fade transition (smooth easing)"]    = "Плавный переход (мягкое затухание)"
    L["Fade duration"]              = "Длительность затухания"
    L["Hidden opacity"]             = "Прозрачность в скрытом режиме"
    L["Show on mouse-over"]         = "Показывать при наведении мыши"
    L["Mouseover fade-out delay"]   = "Задержка скрытия после наведения"
    L["Colorblind mode (high contrast)"]    = "Режим для дальтоников (высокий контраст)"

    -- Chat
    L["Blink button on whisper"]    = "Мигать кнопкой при шёпоте"
    L["Show whispers while hidden"] = "Показывать шёпот, когда скрыт"
    L["Play sound on whisper"]      = "Звук при шёпоте"
    L["Keep combat log visible"]    = "Оставить журнал боя видимым"
    L["Hide chat for screenshots"]  = "Скрыть чат для скриншотов"
    L["Scroll to recent on unhide"] = "Прокрутить к последним при показе"
    L["Hide typing area"]           = "Скрыть область ввода"
    L["Show chat on Enter key"]     = "Показать чат по нажатию Enter"

    -- Zone Memory
    L["Remember chat state per zone"] = "Запоминать состояние чата по зоне"
    L["Clear Memory"]               = "Очистить память"
    L["Zone memory cleared."]       = "Память зоны очищена."

    -- Compatibility
    L["Alpha mode (Chattynator / Prat / ElvUI)"] = "Режим альфа (Chattynator / Prat / ElvUI)"
    L["No third-party chat addons detected"]     = "Сторонние аддоны чата не обнаружены"
    L["Detected:"]                  = "Обнаружено:"
    L["enable Alpha mode"]          = "включить режим альфа"

    -- Profiles
    L["Active:"]                    = "Активный:"
    L["New"]                        = "Новый"
    L["Copy"]                       = "Копировать"
    L["Rename"]                     = "Переименовать"
    L["Delete"]                     = "Удалить"
    L["Export"]                     = "Экспорт"
    L["Import"]                     = "Импорт"
    L["Bind to Spec"]               = "Привязать к специализации"
    L["No spec binding"]            = "Без привязки к спец."
    L["Spec profiles: retail only"] = "Профили спец.: только Retail"
    L["Cannot rename the Default profile."]  = "Невозможно переименовать профиль по умолчанию."
    L["Cannot delete Default profile."]      = "Невозможно удалить профиль по умолчанию."

    -- Profile popup dialogs
    L["Create"]                     = "Создать"
    L["Cancel"]                     = "Отмена"
    L["Reset"]                      = "Сбросить"
    L["OK"]                         = "OK"
    L["HideChat - New profile name:"]       = "HideChat - Имя нового профиля:"
    L["HideChat - Copy current profile to:"] = "HideChat - Скопировать текущий профиль в:"
    L["HideChat - Rename profile \"%s\" to:"] = "HideChat - Переименовать профиль «%s» в:"
    L["HideChat - Delete profile \"%s\"?"]    = "HideChat - Удалить профиль «%s»?"
    L["HideChat - Reset all settings to defaults?"] = "HideChat - Сбросить все настройки?"
    L["HideChat - Paste import string:"]    = "HideChat - Вставьте строку импорта:"
    L["HideChat - Export string (copy this):"] = "HideChat - Строка экспорта (скопируйте):"

    -- Reset + commands
    L["Reset All Settings"]         = "Сбросить все настройки"
    L["Key Bindings: ESC > Key Bindings > HideChat"] = "Назначение клавиш: ESC > Назначение клавиш > HideChat"
    L["Hold to Peek: bindable key, shows chat while held"] = "Удерживать для просмотра: назначаемая клавиша, показывает чат"
    L["toggle"]                     = "переключить"
    L["force state"]                = "принудительное состояние"
    L["this panel"]                 = "эта панель"
    L["diagnostics"]                = "диагностика"
    L["detailed debug output"]      = "подробный отладочный вывод"
    L["profiles"]                   = "профили"
    L["restore defaults"]           = "восстановить по умолчанию"

    -- Notifications
    L["Chat hidden"]                = "Чат скрыт"
    L["Chat visible"]               = "Чат виден"

    -- Config buttons
    L["Toggle"]                     = "Переключить"

    -- Tooltips
    L["Status: Hidden"]             = "Статус: Скрыт"
    L["Status: Visible"]            = "Статус: Виден"
    L["Left-click: Toggle chat"]    = "ЛКМ: Переключить чат"
    L["Left-click: Toggle"]         = "ЛКМ: Переключить"
    L["Right-click: Settings"]      = "ПКМ: Настройки"
    L["Middle-click: Quick reply"]  = "СКМ: Быстрый ответ"
    L["Drag: Move button"]          = "Перетащить: Переместить кнопку"
    L["Drag: Reposition"]           = "Перетащить: Изменить позицию"
    L["New whisper!"]               = "Новый шёпот!"

    -- Slash command messages
    L["Profile \"%s\" already exists."]       = "Профиль «%s» уже существует."
    L["Profile \"%s\" imported successfully."] = "Профиль «%s» успешно импортирован."
    L["Export string for \"%s\":"]            = "Строка экспорта для «%s»:"
    L["Profile not found."]         = "Профиль не найден."
    L["Invalid import string."]     = "Недопустимая строка импорта."
    L["Failed to decode import string."]     = "Не удалось декодировать строку импорта."
    L["Failed to parse import data."]        = "Не удалось разобрать данные импорта."
    L["Import data contains no valid settings."] = "Данные не содержат допустимых настроек."
    L["Usage: /hc import HC1:..."]  = "Использование: /hc import HC1:..."
    L["Settings reset to defaults."] = "Настройки сброшены."
    L["No recent whisper to reply to."] = "Нет недавнего шёпота для ответа."

    -- Status command
    L["Profile:"]                   = "Профиль:"
    L["Chat:"]                      = "Чат:"
    L["hidden"]                     = "скрыт"
    L["visible"]                    = "виден"
    L["Mode:"]                      = "Режим:"
    L["Fade:"]                      = "Затухание:"
    L["Opacity:"]                   = "Прозрачность:"
    L["Instance auto-hide: on"]     = "Скрытие в подземельях: вкл"
    L["Inactivity:"]                = "Бездействие:"
    L["Mouseover reveal: on"]       = "Показ при наведении: вкл"
    L["Combat log kept: on"]        = "Журнал боя: вкл"
    L["Raid auto-show: on"]         = "Показ в рейде: вкл"
    L["Whisper sound: on"]          = "Звук шёпота: вкл"
    L["Zone memory: on"]            = "Память зоны: вкл"
    L["Chat addons:"]               = "Аддоны чата:"
    L["on"]                         = "вкл"
    L["Combat:"]                    = "Бой:"
end
