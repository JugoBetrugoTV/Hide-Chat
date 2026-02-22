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
    L["Colorblind mode (high contrast)"]    = "色盲模式（高对比度）"

    -- Chat
    L["Blink button on whisper"]    = "收到密语时按钮闪烁"
    L["Show whispers while hidden"] = "隐藏时显示密语"
    L["Play sound on whisper"]      = "收到密语时播放声音"
    L["Keep combat log visible"]    = "保持战斗记录可见"
    L["Hide chat for screenshots"]  = "截图时隐藏聊天"
    L["Scroll to recent on unhide"] = "显示时滚动到最新消息"

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
