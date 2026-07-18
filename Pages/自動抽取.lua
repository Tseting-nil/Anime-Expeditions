local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")
local Players = game:GetService("Players")

local function DisarmErrorTraps()
	local n = 0
	for _, conn in ipairs(getconnections(ScriptContext.Error)) do
		if conn.Enabled then
			local ok = pcall(function()
				conn:Disable()
			end)
			if not ok then
				pcall(function()
					conn.Enabled = false
				end)
			end
			n = n + 1
		end
	end
	return n
end

do
	local ok, n = pcall(DisarmErrorTraps)
	if not ok then
		warn("[自動召喚] 拆除檢測器失敗, 中止 (繼續執行可能導致被延遲踢出)")
	end
	print("[自動召喚] 已拆除 " .. n .. " 個檢測器")
end

if getgenv().AutoSummon and getgenv().AutoSummon._Shutdown then
	pcall(getgenv().AutoSummon._Shutdown)
end

local Lang = "zh" -- 預設為中文
local i18n = {
	zh = {
		load_failed = "[自動召喚] 載入遊戲模組失敗: %s",
		regui_compile_failed = "ReGui 原始碼編譯失敗",
		regui_load_failed = "[自動召喚] 載入 ReGui 失敗: %s",
		window_title = "動漫遠征 - 自動召喚",
		sep_settings = "設定",
		label_banner = "卡池",
		banner_standard = "標準 (Standard)",
		banner_mini = "小型 (Mini)",
		banner_newplayer = "新手活動 (NewPlayerEvent)",
		label_summon_tier = "抽取檔位",
		sep_game_settings = "遊戲設定 (會同步到伺服器)",
		cb_fast_summon = "快速抽取 (跳過全螢幕彈窗)",
		log_fast_summon = "快速抽取 -> %s",
		log_fast_summon_failed = "<font color='#ff4545'>快速抽取設定失敗</font>",
		cb_summon_max = "最大抽數 (解鎖 50x 檔位)",
		log_summon_max = "最大抽數 -> %s  (可用檔位: 1x / %dx)",
		log_summon_max_failed = "<font color='#ff4545'>最大抽數設定失敗</font>",
		cb_silence_popups = "靜音結果彈窗 (Obtained Rewards)",
		log_silenced = "<font color='#e6b400'>已靜音 %d 個結果彈窗回呼</font>",
		log_unsilenced = "<font color='#acabaf'>已還原 %d 個結果彈窗回呼</font>",
		label_interval = "間隔 (秒)",
		cb_stop_when_broke = "餘額不足時自動停止",
		sep_status = "狀態",
		label_balance = "餘額: %d %s",
		label_balance_empty = "餘額: -",
		label_cost = "本次花費: %d   [單抽 %s]%s",
		label_cost_empty = "本次花費: -",
		label_cost_format = "%d (原價 %d, 折 %d%%)",
		label_cost_tier_warning = "  <%dx 不可用, 目前 1x / %dx>",
		label_stats = "已召喚: %d 次 / 已花費: %d   可用檔位: 1x / %dx",
		label_stats_empty = "已召喚: 0 次 / 已花費: 0",
		sep_actions = "操作",
		btn_summon_once = "召喚一次",
		log_auto_loop_started = "<font color='#e6b400'>自動循環已啟動</font>",
		log_auto_loop_stopped = "<font color='#acabaf'>自動循環已停止</font>",
		rb_auto_summon = "自動召喚",
		btn_reset_stats = "重設統計",
		log_stats_reset = "統計已重設",
		sep_pity = "保底進度",
		label_no_pity = "此卡池無保底資料",
		log_pity_slider = "%d / %d",
		sep_auto_sell = "自動刪除設定",
		col_rarity = "等級",
		col_normal = "非閃亮",
		col_shiny = "閃亮",
		log_auto_sell_updated = "自動刪除 %s%s -> %s",
		log_auto_sell_shiny = " (閃亮)",
		log_auto_sell_failed = "<font color='#ff4545'>自動刪除設定失敗: %s</font>",
		log_summon_result_header = "<font color='#e6b400'>===== 抽到 %d 隻 =====</font>",
		log_summon_result_sold = " <font color='#ff6b6b'>(刪除)</font>",
		log_summon_result_unresolved = "(無法解析)",
		log_summon_result_summary = "<font color='#acabaf'>自動刪除 %d / %d 隻, 留下 %d 隻</font>",
		warn_update_node_not_found = "[自動召喚] 找不到 _updateNode, 召喚結果不會顯示",
		err_tier_not_allowed = "檔位 %dx 不被伺服器接受。目前可用: 1x / %dx  (%s)",
		hint_enable_max_tier = "開啟「最大抽數」設定可解鎖 50x",
		hint_disable_max_tier = "關閉「最大抽數」設定可用 10x",
		err_insufficient_balance = "餘額不足: 需要 %d %s, 只有 %d",
		err_send_failed = "發送失敗: %s",
		log_summon_success = "<font color='#82bc5b'>%s x%d  實扣 %d %s</font>",
		log_summon_cost_mismatch = "<font color='#e6b400'>注意: 實扣 %d 與預估 %d 不符</font>",
		log_summon_no_change = "<font color='#ff4545'>%s x%d 已送出但餘額沒變 -- 伺服器可能拒絕了 (檔位/背包/其他)</font>",
		log_summon_sent = "%s x%d 已送出 (預估 %d %s), 等待伺服器確認...",
		log_ready = "就緒。Standard 實付 %d (原價 %d)。",
		log_ready_tiers = "<font color='#acabaf'>抽取只有 1x / 10x / 50x 三檔; 目前可用: 1x / %dx</font>",
		log_ready_settings = "<font color='#acabaf'>快速抽取=%s  最大抽數=%s</font>",
		print_loaded = "[自動召喚] 已載入 -- 外部 API: getgenv().AutoSummon",
	},
	en = {
		load_failed = "[Auto Summon] Failed to load game modules: %s",
		regui_compile_failed = "ReGui source code compilation failed",
		regui_load_failed = "[Auto Summon] Failed to load ReGui: %s",
		window_title = "Anime Expedition - Auto Summon",
		sep_settings = "Settings",
		label_banner = "Banner",
		banner_standard = "Standard",
		banner_mini = "Mini",
		banner_newplayer = "NewPlayerEvent",
		label_summon_tier = "Summon Tier",
		sep_game_settings = "Game Settings (Syncs to Server)",
		cb_fast_summon = "Fast Summon (Skip full screen popups)",
		log_fast_summon = "Fast Summon -> %s",
		log_fast_summon_failed = "<font color='#ff4545'>Fast Summon setting failed</font>",
		cb_summon_max = "Summon Max (Unlock 50x tier)",
		log_summon_max = "Summon Max -> %s  (Available Tiers: 1x / %dx)",
		log_summon_max_failed = "<font color='#ff4545'>Summon Max setting failed</font>",
		cb_silence_popups = "Silence Result Popups (Obtained Rewards)",
		log_silenced = "<font color='#e6b400'>Silenced %d result popup callbacks</font>",
		log_unsilenced = "<font color='#acabaf'>Restored %d result popup callbacks</font>",
		label_interval = "Interval (sec)",
		cb_stop_when_broke = "Auto-stop when balance is insufficient",
		sep_status = "Status",
		label_balance = "Balance: %d %s",
		label_balance_empty = "Balance: -",
		label_cost = "Cost: %d   [Single %s]%s",
		label_cost_empty = "Cost: -",
		label_cost_format = "%d (Base %d, Off %d%%)",
		label_cost_tier_warning = "  <%dx N/A, currently 1x / %dx>",
		label_stats = "Summoned: %d   Spent: %d   Tiers: 1x / %dx",
		label_stats_empty = "Summoned: 0   Spent: 0",
		sep_actions = "Actions",
		btn_summon_once = "Summon Once",
		log_auto_loop_started = "<font color='#e6b400'>Auto Loop Started</font>",
		log_auto_loop_stopped = "<font color='#acabaf'>Auto Loop Stopped</font>",
		rb_auto_summon = "Auto Summon",
		btn_reset_stats = "Reset Stats",
		log_stats_reset = "Statistics reset",
		sep_pity = "Pity Progress",
		label_no_pity = "No pity data for this banner",
		log_pity_slider = "%d / %d",
		sep_auto_sell = "Auto Sell Settings",
		col_rarity = "Rarity",
		col_normal = "Normal",
		col_shiny = "Shiny",
		log_auto_sell_updated = "Auto Sell %s%s -> %s",
		log_auto_sell_shiny = " (Shiny)",
		log_auto_sell_failed = "<font color='#ff4545'>Auto Sell setting failed: %s</font>",
		log_summon_result_header = "<font color='#e6b400'>===== Summoned %d Units =====</font>",
		log_summon_result_sold = " <font color='#ff6b6b'>(Sold)</font>",
		log_summon_result_unresolved = "(Unresolved)",
		log_summon_result_summary = "<font color='#acabaf'>Auto sold %d / %d units, keeping %d</font>",
		warn_update_node_not_found = "[Auto Summon] _updateNode not found, summon results will not be displayed",
		err_tier_not_allowed = "Tier %dx is not accepted by the server. Available: 1x / %dx  (%s)",
		hint_enable_max_tier = "Turn on 'Summon Max' to unlock 50x",
		hint_disable_max_tier = "Turn off 'Summon Max' to use 10x",
		err_insufficient_balance = "Insufficient Balance: Need %d %s, have %d",
		err_send_failed = "Send failed: %s",
		log_summon_success = "<font color='#82bc5b'>%s x%d  Deducted %d %s</font>",
		log_summon_cost_mismatch = "<font color='#e6b400'>Note: Actual deduction %d does not match estimate %d</font>",
		log_summon_no_change = "<font color='#ff4545'>%s x%d sent but balance did not change -- server might have rejected it (Tier/Inventory/etc.)</font>",
		log_summon_sent = "%s x%d sent (estimated cost %d %s), waiting for server confirmation...",
		log_ready = "Ready. Standard actual cost %d (base %d).",
		log_ready_tiers = "<font color='#acabaf'>Summons only support 1x / 10x / 50x. Currently available: 1x / %dx</font>",
		log_ready_settings = "<font color='#acabaf'>Fast Summon=%s  Summon Max=%s</font>",
		print_loaded = "[Auto Summon] Loaded -- External API: getgenv().AutoSummon",
	}
}

pcall(function()
	if isfile and isfile("Tsetingnil_script/keysystem.json") then
		local content = readfile("Tsetingnil_script/keysystem.json")
		if content then
			local scriptLang = nil
			local ok, data = pcall(function()
				return game:GetService("HttpService"):JSONDecode(content)
			end)
			if ok and data and data.script_language then
				scriptLang = data.script_language
			else
				scriptLang = content:match('"script_language"%s*:%s*"([^"]+)"')
			end
			if scriptLang then
				local sl = scriptLang:lower()
				if sl:find("chinese") or sl:find("zh") then
					Lang = "zh"
				elseif sl:find("english") or sl:find("en") then
					Lang = "en"
				end
			end
		end
	end
end)

local function t(key, ...)
	local langTable = i18n[Lang] or i18n["zh"]
	local template = langTable[key] or key
	if select("#", ...) > 0 then
		if type(template) == "string" then
			local ok, res = pcall(string.format, template, ...)
			if ok then
				return res
			end
		end
	end
	return template
end

local L = t

local Running = true
local Connections = {}

task.spawn(function()
	while Running do
		task.wait(5)
		pcall(DisarmErrorTraps)
	end
end)

local function SafeRequire(inst)
	local old = getthreadidentity()
	setthreadidentity(2)
	local ok, res = pcall(require, inst)
	setthreadidentity(old)
	if not ok then
		error(res, 0)
	end
	return res
end

local Nodes, Dependencies, Fusion, BannerInfo, NetworkEvents
local loadOk, loadErr = pcall(function()
	local NodesFolder = ReplicatedStorage:WaitForChild("Nodes", 20)
	Nodes = SafeRequire(NodesFolder)
	NetworkEvents = NodesFolder:WaitForChild("Network", 20):WaitForChild("NetworkEvents", 20)
	local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage", 20)
	Dependencies = SafeRequire(FusionPackage:WaitForChild("Dependencies"))
	Fusion = SafeRequire(FusionPackage:WaitForChild("Fusion"))
	BannerInfo = SafeRequire(ReplicatedStorage.Shared.Information.BannerInfo)
end)

if not loadOk then
	warn("[自動召喚] 載入遊戲模組失敗: " .. tostring(loadErr))
	return
end

local peek = Fusion.peek

-- 抽取只有三個檔位: 1x / 10x / 50x 
local ABSOLUTE_MAX = BannerInfo.SummonMaxLimit or 50
local TIERS = {
	1,
	10,
	50
}

local function GetSetting(name)
	local v = false
	pcall(function()
		v = Nodes.GET_SETTING_VALUE:InvokeSelf(name) == true
	end)
	return v
end

local function SetSetting(name, value)
	return pcall(function()
		Nodes.CLIENT_CHANGE_SETTING:FireServer(name, value)
	end)
end

-- GetMaxTier / IsTierAllowed 定義在 GetBannerMeta / GetBalance 之後 (它們是 local, 這裡還看不到)
local GetMaxTier, IsTierAllowed

local SelectedBanner = "Standard"
local SummonAmount = 10
local Interval = 1.0
local StopWhenBroke = true
local AutoLoop = false
local TotalSummons = 0
local TotalSpent = 0

-- Banner 選項 (顯示名稱 -> 內部 ID)
local BannerOptions = {
	L("banner_standard"),
	L("banner_mini"),
	L("banner_newplayer")
}
local BannerIdOf = {
	[L("banner_standard")] = "Standard",
	[L("banner_mini")] = "Mini",
	[L("banner_newplayer")] = "NewPlayerEvent",
}

-- 目前的 banner 折扣 (session boost, 會隨活動變動)
local function GetBannerDiscount()
	local ok, d = pcall(function()
		local sd = peek(Dependencies.SessionData) or {}
		local b = (sd.SessionBoosts or {}).BannerDiscount or {}
		return b.Total or 0
	end)
	return (ok and d) or 0
end

-- 從 live BannerData 讀 banner 資訊, 並照遊戲公式算出實付價
-- (Processors.Banner: Cost = Discount and round(base * (1 - discount)) or base)
local function GetBannerMeta(bannerId)
	local info
	local ok = pcall(function()
		local bd = peek(Dependencies.BannerData) or {}
		local b = bd[bannerId]
		info = b and b.BannerInfo
	end)
	if not (ok and info and info.Cost) then
		info = (BannerInfo.Banners or {})[bannerId] or {}
	end
	local base = info.Cost or 50
	local cost = base
	if info.Discount then
		cost = math.round(base * (1 - GetBannerDiscount()))
	end
	return {
		Cost = cost,
		BaseCost = base,
		Discounted = info.Discount and cost ~= base,
		Currency = info.Currency or "Gem",
	}
end

local function GetBalance(currency)
	local ok, amt = pcall(function()
		local pd = peek(Dependencies.PlayerData) or {}
		local item = (pd.ItemData or {})[currency]
		return item and item.Amount or 0
	end)
	return (ok and amt) or 0
end

-- 遊戲的 u44: 一鍵最大抽的數量, 也就是伺服器認可的「大檔位」
function GetMaxTier()
	if not GetSetting("SummonMax") then
		return 10
	end
	local meta = GetBannerMeta(SelectedBanner)
	local n = math.floor(GetBalance(meta.Currency) / math.max(meta.Cost, 1))
	return math.clamp(n, 10, ABSOLUTE_MAX)
end

-- 伺服器只收 1 或 GetMaxTier(), 中間值一律拒絕
function IsTierAllowed(t)
	return t == 1 or t == GetMaxTier()
end

local function DoSummon(bannerId, amount)
	return pcall(function()
		Nodes.BANNER_SUMMON:FireServer(bannerId, amount)
	end)
end

-- ==================== [ 塔名解析 ] ====================
local Info = Dependencies.Information

local RARITY_COLOR = {
	Rare = "#0095FF",
	Epic = "#990AFF",
	Legendary = "#FFCB0E",
	Mythic = "#F7DD1B",
	Exclusive = "#B7F9FF",
	Secret = "#FF4040",
}

local Translator, TransProbe
do
	local LS = game:GetService("LocalizationService")
	local ok, tr = pcall(function()
		return LS:GetTranslatorForLocaleAsync(LS.RobloxLocaleId)
	end)
	if not ok then
		ok, tr = pcall(function()
			return LS:GetTranslatorForPlayerAsync(Players.LocalPlayer)
		end)
	end
	if ok and tr then
		Translator = tr
        -- Translate 需要一個 GuiObject 當 context
		pcall(function()
			TransProbe = Instance.new("TextLabel")
			TransProbe.Name = "_AutoSummonTransProbe"
			TransProbe.Visible = false
			TransProbe.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		end)
	end
end

local NameCache = {}

local function ResolveName(asset)
	if NameCache[asset] then
		return NameCache[asset]
	end
	local display = asset
	pcall(function()
		local d = Info:GetAssetDisplayName(asset)
		if type(d) == "string" and d ~= "" then
			display = d
		end
	end)

    -- 翻成在地語言 (遊戲 UI 顯示的就是這個)
	if Lang == "zh" and Translator and TransProbe then
		pcall(function()
			local t = Translator:Translate(TransProbe, display)
			if type(t) == "string" and t ~= "" then
				display = t
			end
		end)
	end
	local rarity
	pcall(function()
		rarity = Info:GetAssetRarity(asset)
	end)
	local res = {
		Display = display,
		Rarity = rarity,
		Asset = asset
	}
	NameCache[asset] = res
	return res
end

local ReGui
local uiOk, uiErr = pcall(function()
	local src = game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/169b7303e1418cb301bad5ab427e9351/raw/372563922422a685b9b10a8b9c65256107ce4b23/GUI:ReGui")
	local chunk = loadstring(src)
	if not chunk then
		error("ReGui 原始碼編譯失敗", 0)
	end
	ReGui = chunk()
end)

if not uiOk or not ReGui then
	warn(L("regui_load_failed", tostring(uiErr)))
	Running = false
	return
end

local Log
local UIReady = false

local function ComboPick(items, arg)
	if type(arg) == "number" then
		return items[arg]
	end
	return arg
end

-- 前向宣告: 上面的設定切換會用到, 實作在下方「靜音結果彈窗」
local SetPopupSilenced

local Window = ReGui:Window({
	Title = L("window_title"),
	Size = UDim2.fromOffset(420, 490),
	Theme = "DarkTheme",
})

Window:Separator({
	Text = L("sep_settings")
})

Window:Combo({
	Label = L("label_banner"),
	Selected = 1,
	Items = BannerOptions,
	Callback = function(_, arg)
		local name = ComboPick(BannerOptions, arg)
		SelectedBanner = BannerIdOf[name] or "Standard"
	end,
})

-- 抽取只有 1x / 10x / 50x 三檔
local TIER_ITEMS = {
	"1x",
	"10x",
	"50x"
}
Window:Combo({
	Label = L("label_summon_tier"),
	Selected = 2, -- 預設 10x
	Items = TIER_ITEMS,
	Callback = function(_, arg)
		local name = ComboPick(TIER_ITEMS, arg)
		SummonAmount = tonumber(string.match(tostring(name), "%d+")) or 10
	end,
})

Window:Separator({
	Text = L("sep_game_settings")
})

-- 這兩個是遊戲本身的設定: Value 先讀遊戲現值, 使用者切換時走 CLIENT_CHANGE_SETTING 同步回伺服器。
-- UIReady 擋掉建立期的假觸發, 否則一載入就會把初始值回送 (等於亂改玩家設定)。
Window:Checkbox({
	Label = L("cb_fast_summon"),
	Value = GetSetting("FastSummon"),
	Callback = function(_, v)
		if not UIReady then
			return
		end
		if SetSetting("FastSummon", v) then
			Log(L("log_fast_summon", tostring(v)))
		else
			Log(L("log_fast_summon_failed"))
		end
	end,
})

Window:Checkbox({
	Label = L("cb_summon_max"),
	Value = GetSetting("SummonMax"),
	Callback = function(_, v)
		if not UIReady then
			return
		end
		if SetSetting("SummonMax", v) then
			task.wait(0.5) -- 等伺服器回寫 PlayerData, 不然 GetMaxTier 讀到舊值
			Log(L("log_summon_max", tostring(v), GetMaxTier()))
		else
			Log(L("log_summon_max_failed"))
		end
	end,
})

Window:Checkbox({
	Label = L("cb_silence_popups"),
	Value = false,
	Callback = function(_, v)
		if not UIReady then
			return
		end
		local n = SetPopupSilenced(v)
		Log(v and L("log_silenced", n) or L("log_unsilenced", n))
	end,
})

Window:DragFloat({
	Label = L("label_interval"),
	Value = Interval,
	Minimum = 1.0,
	Maximum = 3.0,
	Format = "%.1f s",
	Callback = function(_, v)
		Interval = v
	end,
})

Window:Checkbox({
	Label = L("cb_stop_when_broke"),
	Value = StopWhenBroke,
	Callback = function(_, v)
		StopWhenBroke = v
	end,
})

Window:Separator({
	Text = L("sep_status")
})

local BalanceLabel = Window:Label({
	Text = L("label_balance_empty")
})
local CostLabel = Window:Label({
	Text = L("label_cost_empty")
})
local StatsLabel = Window:Label({
	Text = L("label_stats_empty")
})

Window:Separator({
	Text = L("sep_actions")
})

local Console = Window:Console({
	ReadOnly = true,
	AutoScroll = true,
	MaxLines = 60,
	RichText = true,
	Size = UDim2.new(1, 0, 0, 130),
})

function Log(fmt, ...)
	local msg = select("#", ...) > 0 and string.format(fmt, ...) or fmt
	local line = string.format("[%s] %s", os.date("%H:%M:%S"), msg)
	local ok = pcall(function()
		local old = getthreadidentity()
		if old ~= 8 then
			setthreadidentity(8)
		end
		Console:AppendText(line)
		if old ~= 8 then
			setthreadidentity(old)
		end
	end)
	if not ok then
		print("[自動召喚] " .. line)
	end
end

-- 執行一次召喚, 回傳 是否成功, 訊息
local function SummonOnce()
	local amount = SummonAmount
	if not IsTierAllowed(amount) then
		local maxTier = GetMaxTier()
		local hint = (maxTier == 10) and L("hint_enable_max_tier") or L("hint_disable_max_tier")
		return false, L("err_tier_not_allowed", amount, maxTier, hint)
	end
	local meta = GetBannerMeta(SelectedBanner)
	local cost = meta.Cost * amount
	local balance = GetBalance(meta.Currency)
	if StopWhenBroke and balance < cost then
		return false, L("err_insufficient_balance", cost, tostring(meta.Currency), balance)
	end
	local ok, err = DoSummon(SelectedBanner, amount)
	if not ok then
		return false, L("err_send_failed", tostring(err))
	end
	task.spawn(function()
		local before = balance
		for _ = 1, 12 do -- 最多等 ~1.2s
			task.wait(0.1)
			local now = GetBalance(meta.Currency)
			if now ~= before then
				local spent = before - now
				TotalSummons = TotalSummons + amount
				TotalSpent = TotalSpent + spent
				Log(L("log_summon_success", SelectedBanner, amount, spent, tostring(meta.Currency)))
				if spent ~= cost then
					Log(L("log_summon_cost_mismatch", spent, cost))
				end
				return
			end
		end
		Log(L("log_summon_no_change", SelectedBanner, amount))
	end)
	return true, L("log_summon_sent", SelectedBanner, amount, cost, tostring(meta.Currency))
end

local function RunOnce()
	local ok, msg = SummonOnce()
	if ok then
		Log("<font color='#82bc5b'>%s</font>", msg)
	else
		Log("<font color='#ff4545'>%s</font>", msg)
	end
	return ok
end

local LoopBox
local SuppressLoopCb = false
local ActionRow = Window:Row({
	Expanded = true
})

ActionRow:Button({
	Text = L("btn_summon_once"),
	Callback = RunOnce,
})

local function ApplyLoop(v)
	v = v and true or false
	if AutoLoop == v then
		return
	end
	AutoLoop = v
	Log(v and L("log_auto_loop_started") or L("log_auto_loop_stopped"))
end

local function SetLoop(v)
	ApplyLoop(v)
	SuppressLoopCb = true
	pcall(function()
		LoopBox:SetValue(AutoLoop)
	end)
	SuppressLoopCb = false
end

LoopBox = ActionRow:Radiobox({
	Label = L("rb_auto_summon"),
	Value = false,
	Callback = function(_, v)
		if SuppressLoopCb then
			return
		end
		ApplyLoop(v)
	end,
})

ActionRow:Button({
	Text = L("btn_reset_stats"),
	Callback = function()
		TotalSummons = 0
		TotalSpent = 0
		Console:Clear()
		Log(L("log_stats_reset"))
	end,
})

-- ==================== [ 保底進度 ] ====================
-- 每個卡池的保底組合不同 (實證):
--   Standard       Legendary 50 / Mythic 400 / Secret 10000
--   Mini           Legendary 50 / Mythic 400          (沒有 Secret)
--   NewPlayerEvent Legendary 20 / Mythic 50           (需求值也不同)
--   需求值: peek(Dependencies.BannerData)[banner].BannerInfo.Pity
--   目前值: peek(Dependencies.PlayerData).BannerData[banner].Pity
Window:Separator({
	Text = L("sep_pity")
})

local PityCanvas = Window:Canvas()
local PityBars = {}
local PityKey = nil   -- 目前建好的 banner+需求 簽章, 變了才重建

local function GetPity(bannerId)
	local req, cur
	pcall(function()
		local bd = peek(Dependencies.BannerData) or {}
		local b = bd[bannerId]
		req = b and b.BannerInfo and b.BannerInfo.Pity
	end)
	pcall(function()
		local pd = peek(Dependencies.PlayerData) or {}
		local b = pd.BannerData and pd.BannerData[bannerId]
		cur = b and b.Pity
	end)
	return (type(req) == "table") and req or {}, (type(cur) == "table") and cur or {}
end

local function SyncPityBars(bannerId)
	local req, cur = GetPity(bannerId)

    -- 照需求值由小到大排 (與遊戲 Summon 選單的排序一致)
	local order = {}
	for k in pairs(req) do
		table.insert(order, k)
	end
	table.sort(order, function(a, b)
		if req[a] == req[b] then
			return tostring(a) < tostring(b)
		end
		return (req[a] or 0) < (req[b] or 0)
	end)
	local key = tostring(bannerId)
	for _, r in ipairs(order) do
		key = key .. "|" .. tostring(r) .. "=" .. tostring(req[r])
	end
	if key ~= PityKey then
		PityKey = key
		for _, e in pairs(PityBars) do
			pcall(function()
				e.Bar:Remove()
			end)
		end
		PityBars = {}
		if # order == 0 then
			PityBars["_none"] = {
				Bar = PityCanvas:Label({
					Text = L("label_no_pity")
				}),
				Req = 0,
				IsLabel = true
			}
		else
			for _, rarity in ipairs(order) do
				local reqN = req[rarity] or 0
				local curN = cur[rarity] or 0
				local ok, bar = pcall(function()
					return PityCanvas:SliderProgress({
						Label = tostring(rarity),
						Value = math.clamp(curN, 0, math.max(reqN, 1)),
						Minimum = 0,
						Maximum = math.max(reqN, 1),
						ReadOnly = true,
					})
				end)
				if ok and bar then
					PityBars[rarity] = {
						Bar = bar,
						Req = reqN
					}
				end
			end
		end
	end

    -- 更新數值
	for rarity, e in pairs(PityBars) do
		if not e.IsLabel then
			local curN = cur[rarity] or 0
			pcall(function()
				e.Bar:SetValue(math.clamp(curN, 0, math.max(e.Req, 1)))
				e.Bar:SetValueText(L("log_pity_slider", curN, e.Req))
			end)
		end
	end
end

-- ==================== [ 靜音結果彈窗 ] ====================
-- 「Obtained Rewards」那個要點一下才關的槽位介面, 是 PlayerScripts.MountPrompts 用**節點回呼**畫的:
--     Nodes.PROMPT_OBTAINED_REWARDS:Connect(promptObtainedRewards)
--     Nodes.PROMPT_OBTAINED_REWARD_SLOTS:Connect(function(rewards, unsorted, promptId) ... end)
--
--
-- 做法: Nodes[x].Signal:GetConnections() 拿到連線物件, 把它的 `_fn` 換成空函數。
local PopupNodes = {
	"PROMPT_OBTAINED_REWARD_SLOTS",
	"PROMPT_OBTAINED_REWARDS"
}
local SilencedConns = {} -- { {conn = c, fn = 原本的} }

function SetPopupSilenced(on)
	if on then
		if # SilencedConns > 0 then
			return # SilencedConns
		end
		for _, name in ipairs(PopupNodes) do
			pcall(function()
				for _, c in ipairs(Nodes[name].Signal:GetConnections()) do
					table.insert(SilencedConns, {
						conn = c,
						fn = c._fn
					})
					c._fn = function()
					end
				end
			end)
		end
		return # SilencedConns
	end
	for _, s in ipairs(SilencedConns) do
		pcall(function()
			s.conn._fn = s.fn
		end)
	end
	local n = # SilencedConns
	table.clear(SilencedConns)
	return n
end

-- ==================== [ 自動刪除設定 ] ====================
-- 協議  Nodes.CHANGE_AUTOSELL_SETTING:FireServer(banner, rarity, isShiny, value)
-- 讀取: PlayerData.Settings.AutoSell[banner][rarity]            <- 非閃亮
--       PlayerData.Settings.AutoSell[banner][rarity .. "Shiny"] <- 閃亮
local AUTOSELL_EXCLUDE = {
	Secret = true
}

local function GetAutoSellState(banner)
	local ok, t = pcall(function()
		local pd = peek(Dependencies.PlayerData) or {}
		local as = pd.Settings and pd.Settings.AutoSell
		return as and as[banner]
	end)
	return (ok and type(t) == "table") and t or {}
end

local function SetAutoSell(banner, rarity, isShiny, value)
	return pcall(function()
		Nodes.CHANGE_AUTOSELL_SETTING:FireServer(banner, rarity, isShiny, value)
	end)
end

-- 該卡池可自動賣的等級, 已排序
local function GetBannerRarities(banner)
	local list = {}
	pcall(function()
		local bd = peek(Dependencies.BannerData) or {}
		local b = bd[banner]
		local rates = b and b.BannerInfo and b.BannerInfo.Rates
		if type(rates) ~= "table" then
			return
		end
		for r in pairs(rates) do
			if not AUTOSELL_EXCLUDE[r] then
				table.insert(list, r)
			end
		end
	end)
	local order = {}
	for i, r in ipairs(Info.OrderedRarities or {}) do
		order[r] = i
	end
	table.sort(list, function(a, b)
		return (order[a] or 99) < (order[b] or 99)
	end)
	return list
end

local AutoSellHeader = Window:CollapsingHeader({
	Title = L("sep_auto_sell"),
	Collapsed = true
})
local AutoSellTable = AutoSellHeader:Table({
	RowBackground = true,
	Border = true
})
local AutoSellKey = nil -- 目前建好的 banner+等級 簽章

local function SyncAutoSellTable(banner)
	local rarities = GetBannerRarities(banner)
	local key = tostring(banner) .. "|" .. table.concat(rarities, ",")
	if key == AutoSellKey then
		return -- 卡池沒變就不重建 (重建會把使用者的展開狀態弄掉)
	end
	AutoSellKey = key
	pcall(function()
		AutoSellTable:ClearRows()
	end)
	local hdr = AutoSellTable:HeaderRow()
	hdr:Column():Label({
		Text = L("col_rarity")
	})
	hdr:Column():Label({
		Text = L("col_normal")
	})
	hdr:Column():Label({
		Text = L("col_shiny")
	})
	local state = GetAutoSellState(banner)
	for _, rarity in ipairs(rarities) do
		local row = AutoSellTable:Row()
		local color = RARITY_COLOR[rarity] or "#DDDDDD"
		row:Column():Label({
			Text = string.format("<font color='%s'>%s</font>", color, rarity),
			RichText = true,
		})

        -- 非閃亮 / 閃亮 兩欄
		for _, isShiny in ipairs({
			false,
			true
		}) do
			local settingKey = isShiny and (rarity .. "Shiny") or rarity
			local col = row:Column()
			local ready = false
			col:Checkbox({
				Label = "",
				Value = state[settingKey] == true,
				Callback = function(_, v)
                    -- ReGui 建立元件時會觸發一次 Callback, 擋掉免得一載入就回送設定
					if not ready then
						return
					end
					if SetAutoSell(banner, rarity, isShiny, v) then
						local shinyText = isShiny and L("log_auto_sell_shiny") or ""
						Log(L("log_auto_sell_updated", rarity, shinyText, tostring(v)))
					else
						Log(L("log_auto_sell_failed", settingKey))
					end
				end,
			})
			ready = true
		end
	end
end

-- ==================== [ 召喚結果 ] ====================
--     _updateNode.OnClientEvent(nodeName, 1, rewards, bool, id)
--     rewards = { { Asset = "Sasuke", Data = { Level=1, Shiny=?, StatPotential={...} } }, ... }
--
-- UNIT_ADD_TO_PLAYER 不是召喚結果，是伺服器廣播。
local RESULT_NODES = {
	PROMPT_OBTAINED_REWARDS = true,
	PROMPT_OBTAINED_REWARD_SLOTS = true,
}

local function PrintSummonResult(rewards)
	if type(rewards) ~= "table" then
		return
	end
	local n = # rewards
	if n == 0 then
		return
	end
	local soldCount = 0
	Log(L("log_summon_result_header", n))
	for i, entry in ipairs(rewards) do
		local asset = entry.Asset or (entry.Data and entry.Data.Asset)
		if asset then
			local info = ResolveName(asset)
			local color = RARITY_COLOR[info.Rarity] or "#DDDDDD"
			local shiny = (entry.Data and entry.Data.Shiny) and " <font color='#FFD700'>[Shiny]</font>" or ""
			local sold = ""
			if entry.Sold then
				sold = L("log_summon_result_sold")
				soldCount = soldCount + 1
			end
			Log("[%d] : <font color='%s'>%s</font>%s%s", i, color, info.Display, shiny, sold)
		else
			Log("[%d] : <font color='#888888'>%s</font>", i, L("log_summon_result_unresolved"))
		end
	end
	if soldCount > 0 then
		Log(L("log_summon_result_summary", soldCount, n, n - soldCount))
	end
end

do
	local updateNode = NetworkEvents and NetworkEvents:FindFirstChild("_updateNode")
	if updateNode then
		table.insert(Connections, updateNode.OnClientEvent:Connect(function(nodeName, _opType, rewards)
			if not RESULT_NODES[nodeName] then
				return
			end
			pcall(PrintSummonResult, rewards)
		end))
	else
		warn(L("warn_update_node_not_found"))
	end
end

task.spawn(function()
	while Running do
		if AutoLoop then
			if not RunOnce() then
				SetLoop(false)
			end
			task.wait(Interval)
		else
			task.wait(0.2)
		end
	end
end)

-- 狀態列即時更新
task.spawn(function()
	while Running do
		pcall(function()
			local meta = GetBannerMeta(SelectedBanner)
			local priceText = meta.Discounted and L("label_cost_format", meta.Cost, meta.BaseCost, math.round(GetBannerDiscount() * 100)) or tostring(meta.Cost)
			local maxTier = GetMaxTier()
			local tierNote = IsTierAllowed(SummonAmount) and "" or L("label_cost_tier_warning", SummonAmount, maxTier)
			BalanceLabel.Text = L("label_balance", GetBalance(meta.Currency), tostring(meta.Currency))
			CostLabel.Text = L("label_cost", meta.Cost * SummonAmount, priceText, tierNote)
			StatsLabel.Text = L("label_stats", TotalSummons, TotalSpent, maxTier)
		end)
		pcall(SyncPityBars, SelectedBanner)
		pcall(SyncAutoSellTable, SelectedBanner)
		task.wait(0.5)
	end
end)

-- 收乾淨: 背景迴圈 / 事件連線 / 翻譯探針 / 視窗
local Shutdown
Shutdown = function(keepWindow)
	Running = false
	AutoLoop = false
	pcall(function()
		SetPopupSilenced(false)
	end)
	for _, c in ipairs(Connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(Connections)
	if TransProbe then
		pcall(function()
			TransProbe:Destroy()
		end)
		TransProbe = nil
	end
	if not keepWindow then
		pcall(function()
			Window:Close()
		end)
	end
end

Window:UpdateConfig({
	CloseCallback = function()
		Shutdown(true)   -- 視窗自己會關, 不用再 Close 一次
		return true
	end,
})

getgenv().AutoSummon = {
	SummonOnce = SummonOnce,
	GetBannerMeta = GetBannerMeta,
	GetBalance = GetBalance,
	GetDiscount = GetBannerDiscount,
	Tiers = TIERS, -- {1, 10, 50}
	GetMaxTier = GetMaxTier, -- 目前伺服器認可的最大檔位
	IsTierAllowed = IsTierAllowed,
	GetSetting = GetSetting, -- ("SummonMax" / "FastSummon" / ...)
	SetSetting = SetSetting,
	GetAutoSell = GetAutoSellState, -- (banner) -> { Rare=true, RareShiny=false, ... }
	SetAutoSell = SetAutoSell, -- (banner, rarity, isShiny, value)
	GetBannerRarities = GetBannerRarities,
	SetPopupSilenced = SetPopupSilenced, -- (bool) 靜音/還原「Obtained Rewards」彈窗
	SetBanner = function(id)
		SelectedBanner = id
	end,
	SetAmount = function(n)
		SummonAmount = math.clamp(n, 1, ABSOLUTE_MAX)
	end,
	SetLoop = SetLoop,
	GetPity = GetPity,
	Stats = function()
		return {
			Summons = TotalSummons,
			Spent = TotalSpent,
			Looping = AutoLoop
		}
	end,
	Stop = function()
		SetLoop(false)
	end,
	_Shutdown = Shutdown,   -- 重跑腳本時由新實例呼叫, 關掉這一份
}

do
	local m = GetBannerMeta("Standard")
	Log(L("log_ready", m.Cost, m.BaseCost))
	Log(L("log_ready_tiers", GetMaxTier()))
	Log(L("log_ready_settings", tostring(GetSetting("FastSummon")), tostring(GetSetting("SummonMax"))))
end

UIReady = true

print(L("print_loaded"))