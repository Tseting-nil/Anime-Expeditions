-- [[ 動漫遠征 (Anime Expedition) - 放置追蹤器 ]]
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ScriptContext = game:GetService("ScriptContext")

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
		warn("[放置追蹤器] 拆除錯誤陷阱失敗,  (繼續執行會可能被延遲踢出): " .. tostring(n))
	end
	print(string.format("[放置追蹤器] 已拆除 %d 個檢測", n))
end

task.spawn(function()
	while true do
		task.wait(5)
		pcall(DisarmErrorTraps)
	end
end)

-- 前向宣告: GUI 層 (上方) 會呼叫到, 但實作在檔尾。
-- 欄位先列出來, 一方面當目錄, 一方面讓靜態檢查不會誤報 "Key not found"。
local Tracker = {
	_warned = {},
	NotImplemented = nil, -- (what) -> nil   只警告一次
	OnPlace = nil, -- (unitName, gameId, cframe, extra) -> order
	OnUpgrade = nil, -- (gameId, level)
	OnSell = nil, -- (gameId)
	OnAbility = nil, -- (gameId, abilityKey)
	OnGameStart = nil, -- (mapId)     關卡進入 InProgress (準備階段)
	OnGameStarted = nil, -- ()        玩家接受 "Start Game?" 投票 -> 波次真的開始
	OnSkipWave = nil, -- (title)      玩家接受跳波投票
	OnGameEnd = nil, -- ()
}

local Adapter = {
	Init = nil, -- () 掛勾 ReplicaSignal + Nodes
	ReadGameSettings = nil, -- () 回填 gameSettings / autoSkipState
	ScanPlacedUnits = nil, -- () -> {replica...}
	SetAutoSkipWaves = nil, -- (boolean) 改遊戲設定 (走 Nodes 層)
}

-- === 裝置檢測 ===
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local UISizes = {
	mainFrame = isMobile and UDim2.new(0, 320, 0, 350) or UDim2.new(0, 550, 0, 480),
	mainFrameMinimized = isMobile and UDim2.new(0, 320, 0, 50) or UDim2.new(0, 550, 0, 50),
	mainFrameExpanded = isMobile and UDim2.new(0, 320, 0, 350) or UDim2.new(0, 550, 0, 450),
	parameterFrame = isMobile and UDim2.new(0, 280, 0, 350) or UDim2.new(0, 360, 0, 400),
	parameterFramePosition = isMobile and UDim2.new(0.5, -140, 0.5, -175) or UDim2.new(0.5, -180, 0.5, -200),
	saveFrame = isMobile and UDim2.new(0, 280, 0, 200) or UDim2.new(0, 350, 0, 230),
	saveFramePosition = isMobile and UDim2.new(0.5, -140, 0.5, -100) or UDim2.new(0.5, -175, 0.5, -115),
	manageFrame = isMobile and UDim2.new(0, 300, 0, 350) or UDim2.new(0, 400, 0, 450),
	manageFramePosition = isMobile and UDim2.new(0.5, -150, 0.5, -175) or UDim2.new(0.5, -200, 0.5, -225),
	abilityFrame = isMobile and UDim2.new(0, 300, 0, 400) or UDim2.new(0, 380, 0, 450),
}

-- === UI 主題 ===
local Theme = {
	Background = Color3.fromRGB(25, 27, 30),
	Surface = Color3.fromRGB(35, 38, 42),
	SurfaceHighlight = Color3.fromRGB(45, 48, 52),
	Border = Color3.fromRGB(60, 65, 70),
	Text = Color3.fromRGB(230, 230, 230),
	TextDark = Color3.fromRGB(30, 30, 30),
	TextDim = Color3.fromRGB(160, 160, 160),
	Accent = Color3.fromRGB(60, 160, 255),
	AccentHover = Color3.fromRGB(90, 180, 255),
	Success = Color3.fromRGB(100, 220, 120),
	Warning = Color3.fromRGB(255, 180, 60),
	Error = Color3.fromRGB(255, 80, 80),
	Purple = Color3.fromRGB(180, 100, 255),
	CornerRadius = UDim.new(0, 10),
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	SizeLarge = 24,
	SizeMedium = 16,
	SizeNormal = 16,
}

-- === 遊戲資訊 ===
local gameSettings = {
	mapId = "Unknown",
	difficulty = "Unknown",
	modifier = "None",
	gamemode = "Story",
	actName = "Act 1",
}

-- === 腳本設定 ===
local ScriptSettings = {
	AutoReplay = true,
	CostMode = true,
	AutoSkipCheckpoint = true,
}

-- === 腳本生成設定 ===
local timeRoundUp = false
local customComment = ""
local script_SpeedMultiplier = 1
local autoScrollEnabled = true
local SCRIPT_SAVE_PATH = "Tsetingnil_script/AnimeExpedition/Script"

-- === 語言設定 ===
local currentLang = "en"
do
	local KEYSYSTEM_PATH = "Tsetingnil_script/keysystem.json"
	pcall(function()
		if isfile and isfile(KEYSYSTEM_PATH) and readfile then
			local raw = readfile(KEYSYSTEM_PATH)
			if raw and raw ~= "" then
				local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
				if ok and type(data) == "table" and data.script_language then
					local lang = tostring(data.script_language):lower()
					if lang:find("chinese") or lang:find("zh") then
						currentLang = "zh"
					elseif lang:find("english") or lang:find("en") then
						currentLang = "en"
					end
				else
					local lang = raw:match('"script_language"%s*:%s*"([^"]+)"')
					if lang then
						lang = lang:lower()
						if lang:find("chinese") or lang:find("zh") then
							currentLang = "zh"
						end
					end
				end
			end
		end
	end)
end

local Lang = {
	zh = {
		titleMain = "動漫遠征 | 排程追蹤器",
		titleParam = "  參數設定",
		titleSave = "  儲存腳本",
		titleManage = "  腳本管理",
		titleAbility = "  塔能力控制台",
		btnCopy = "複製",
		btnCopied = "已複製",
		btnSave = "儲存",
		btnParam = "參數",
		btnRefresh = "刷新",
		btnReset = "重置追蹤器",
		btnDebug = "塔追蹤清單",
		btnAbility = "能力",
		btnConfirmSave = "確認儲存",
		btnCancel = "取消",
		toggleOn = "開",
		toggleOff = "關",
		lblInterface = "介面設定",
		lblAutoScroll = "自動捲軸",
		lblGameInfo = "遊戲資訊",
		lblTrackerOp = "追蹤器操作",
		lblScriptParam = "腳本參數",
		lblAutoReplay = "自動重播 (AutoReplay)",
		lblCostMode = "成本版錄製（無時間）",
		lblCostModeDesc = "開啟後生成腳本用消耗($)當閘門、錢夠才動作；對收入/難度差異更穩，適合掛機重播",
		lblAutoSkipWaves = "自動跳過波次 (AutoSkipWaves)",
		lblAutoSkipWavesDesc = "直接改遊戲設定（走 Nodes 層）。生成的腳本會在開頭帶上這個設定，重播時自動套用",
		lblAutoSkipCheckpoint = "自動跳過檢查點 (SkipCheckpoint)",
		lblAutoSkipCheckpointDesc = "遠征 (Expedition) 模式下，出現中間檢查點彈窗時自動點擊繼續並前進下一個節點",
		logAutoSkipOn = "已啟用自動跳過波次",
		logAutoSkipOff = "已停用自動跳過波次",
		logAutoSkipRead = "讀取遊戲設定：自動跳波 = %s",
		lblFileName = "輸入腳本名稱:",
		phFileName = "輸入腳本名稱...",
		-- 模式 / 地圖[地圖等級] / 難易度 / 自動跳過
		infoFmt = "模式: %s\n地圖: %s [%s]\n難易度: %s\n自動跳過: %s",
		lblSaveMode = "儲存模式",
		saveMerged = "合併",
		saveSeparate = "分離",
		lblPhase2Name = "指定加載名稱（前綴）",
		logNoOps = "沒有可生成的操作記錄",
		logSaved = "已儲存: %s",
		logSavedPhase2 = "已儲存 Phase: %s",
		logSaveFailed = "儲存失敗: %s",
		logNoScripts = "尚無已儲存的腳本",
		logCopied = "已複製: %s",
		logDeleted = "已刪除: %s",
		logRunPhase1 = "執行 Phase1: %s",
		logRunFailed = "執行失敗: %s",
		logCopyOk = "腳本已複製到剪貼板",
		logCopyConsole = "腳本已輸出到控制台（F9查看）",
		logInvalidName = "請輸入有效的腳本名稱",
		logReset = "追蹤器已重置",
		logTowerListHdr = "=== 塔追蹤清單 ===",
		logNoRecord = "  (無記錄)",
		logWaitStart = "等待遊戲開始 ...",
		-- === 操作記錄 ===
		-- 放置 [腳本內標記ID] [塔名稱] [當局遊戲ID] [時間|金錢]
		logPlaceFmt = "放置 [#%d] [%s] [id=%s] [%s]",
		-- 升級 [塔名稱] [腳本內標記ID] [時間|金錢]
		logUpgradeFmt = "升級 [%s] [#%s] [%s]",
		logSellFmt = "賣出 [%s] [#%s] [%s]",
		logGameStarted = "開始",
		logSkipWaveFmt = "跳過關卡 [%s]",
		logGameEnd = "遊戲結束  總時間: %dm %ds (%.1fs)",
		logTowerItem = "  #%d %s [id=%s] +%.1fs",
		logUntracked = "未追蹤",
		logGameInfoLine = "當前模式: %s | 地圖: %s [%s] | 難易度: %s",
		logAdapterFailed = "❌ Adapter 啟動失敗: 找不到 ReplicaService",
		logHookFailed = "⚠️ hook 失敗: 只能記錄放置",
		logNotImplemented = "[未實作] %s",
		abilityFmt = "能力: %s / 冷卻: %ds",
		abilityReady = "就緒",
		abilityTimerFmt = "%.0fs",
		abilityAutoLabel = "自動",
		abilityFireFmt = "%s",
		abilityWaitId = "等待 ID",
		abilityNoTowers = "尚無擁有能力的塔",
	},
	en = {
		titleMain = "Anime-Expeditions | Tracker",
		titleParam = "  Parameters",
		titleSave = "  Save Script",
		titleManage = "  Script Manager",
		titleAbility = "  Tower Abilities",
		btnCopy = "Copy",
		btnCopied = "Copied",
		btnSave = "Save",
		btnParam = "Params",
		btnRefresh = "Refresh",
		btnReset = "Reset",
		btnDebug = "Tower List",
		btnAbility = "Ability",
		btnConfirmSave = "Confirm",
		btnCancel = "Cancel",
		toggleOn = "ON",
		toggleOff = "OFF",
		lblInterface = "Interface",
		lblAutoScroll = "Auto Scroll",
		lblGameInfo = "Game Info",
		lblTrackerOp = "Tracker Ops",
		lblScriptParam = "Script Params",
		lblAutoReplay = "Auto Replay",
		lblCostMode = "Cost-based recording (no time)",
		lblCostModeDesc = "Generated script gates by cost ($) instead of time; robust to income/difficulty differences, ideal for AFK replay",
		lblAutoSkipWaves = "Auto Skip Waves",
		lblAutoSkipWavesDesc = "Changes the in-game setting directly (via the Nodes layer). The generated script applies it on start",
		lblAutoSkipCheckpoint = "Auto Skip Checkpoint (SkipCheckpoint)",
		lblAutoSkipCheckpointDesc = "In Expedition mode, automatically confirms and skips intermediate checkpoints to proceed to the next node",
		logAutoSkipOn = "Auto Skip Waves enabled",
		logAutoSkipOff = "Auto Skip Waves disabled",
		logAutoSkipRead = "Read game setting: Auto Skip = %s",
		lblFileName = "Script name:",
		phFileName = "Enter script name...",
		infoFmt = "Mode: %s\nMap: %s [%s]\nDifficulty: %s\nAuto Skip: %s",
		lblSaveMode = "Save Mode",
		saveMerged = "Merged",
		saveSeparate = "Separate",
		lblPhase2Name = "Phase Load Name (prefix)",
		logNoOps = "No operations recorded",
		logSaved = "Saved: %s",
		logSavedPhase2 = "Saved Phase: %s",
		logSaveFailed = "Save failed: %s",
		logNoScripts = "No saved scripts",
		logCopied = "Copied: %s",
		logDeleted = "Deleted: %s",
		logRunPhase1 = "Run Phase1: %s",
		logRunFailed = "Run failed: %s",
		logCopyOk = "Script copied to clipboard",
		logCopyConsole = "Script printed to console (F9)",
		logInvalidName = "Please enter a valid script name",
		logReset = "Tracker reset",
		logTowerListHdr = "=== Tower List ===",
		logNoRecord = "  (empty)",
		logWaitStart = "Waiting for game start ...",
		logPlaceFmt = "Place [#%d] [%s] [id=%s] [%s]",
		logUpgradeFmt = "Upgrade [%s] [#%s] [%s]",
		logSellFmt = "Sell [%s] [#%s] [%s]",
		logGameStarted = "Started",
		logSkipWaveFmt = "Skip wave [%s]",
		logGameEnd = "Game ended  Total: %dm %ds (%.1fs)",
		logTowerItem = "  #%d %s [id=%s] +%.1fs",
		logUntracked = "untracked",
		logGameInfoLine = "Mode: %s | Map: %s [%s] | Difficulty: %s",
		logAdapterFailed = "❌ Adapter init failed: ReplicaService not found",
		logHookFailed = "⚠️ Hook failed: only placements can be recorded",
		logNotImplemented = "[Not Implemented] %s",
		abilityFmt = "Ability: %s / Cooldown: %ds",
		abilityReady = "Ready",
		abilityTimerFmt = "%.0fs",
		abilityAutoLabel = "Auto",
		abilityFireFmt = "%s",
		abilityWaitId = "Waiting ID",
		abilityNoTowers = "No towers with abilities",
	},
}

local function T(key)
	return Lang[currentLang][key] or key
end

-- === i18n  ===
local i18nElements = {}
local i18nToggleBtns = {}
local infoLabel
local autoSkipToggle
local autoSkipState = {
	on = false,
}

local function bindText(obj, key, prop)
	prop = prop or "Text"
	obj[prop] = T(key)
	table.insert(i18nElements, {
		obj = obj,
		key = key,
		prop = prop,
	})
end

local function readAutoSkipWave()
	return autoSkipState.on == true
end

local function updateInfoLabel()
	if infoLabel then
		local on = readAutoSkipWave()
		local skipText = on and T("toggleOn") or T("toggleOff")
		-- 模式 / 地圖 [地圖等級=ActName] / 難易度 / 自動跳過
		infoLabel.Text = T("infoFmt"):format(
			gameSettings.gamemode,
			gameSettings.mapId,
			gameSettings.actName,
			gameSettings.difficulty,
			skipText
		)
	end
end

local function updateI18n()
	for _, b in ipairs(i18nElements) do
		b.obj[b.prop] = T(b.key)
	end
	for _, tb in ipairs(i18nToggleBtns) do
		local isOn = tb.getState()
		tb.btn.Text = isOn and T("toggleOn") or T("toggleOff")
		tb.btn.TextColor3 = isOn and Theme.TextDark or Theme.TextDim
	end
	updateInfoLabel()
end

-- === 追蹤狀態 ===
local opSeq = 0
local function nextSeq()
	opSeq = opSeq + 1
	return opSeq
end

local nextOrder = 1
local orderToInfo = {}
local idToOrder = {}
local upgradeLog = {}
local sellLog = {}
local skipWaveLog = {}
local speedChangeLog = {}
local abilityLog = {}
local gameSettingLog = {}
local lastDetectedSpeed = 1

local gameStartAutoSkipWave = false

-- 動漫遠征Shiny / Trait 標籤:
local function getMutLabel(info)
	if type(info) ~= "table" then
		return ""
	end
	local parts = {}
	if info.Shiny == true then
		table.insert(parts, "Shiny")
	end
	if type(info.Trait) == "string" and info.Trait ~= "" then
		table.insert(parts, "Trait:" .. info.Trait)
	end
	return #parts > 0 and (" [" .. table.concat(parts, ", ") .. "]") or ""
end

-- 內部資產名 (Asset, 如 "Yuta") -> 玩家實際看到的顯示名稱 (UnitsInfo[asset].DisplayName, 如 "Cursed Student")。
-- ★ 只用於「顯示」(日誌 / 生成腳本註解)。API 呼叫的引數一律維持【資產名】——
--   slotOf / CanPlace / GetCost / EquipLoadout 全部以資產名為 key, 換成顯示名會查不到。
local _displayCache = nil
local function displayName(asset)
	if not asset then
		return "?"
	end
	if _displayCache == nil then
		_displayCache = {}
		pcall(function()
			local U = require(ReplicatedStorage.Shared.Information.Units)
			for k, v in pairs(U) do
				if type(v) == "table" and type(v.DisplayName) == "string" and v.DisplayName ~= "" then
					_displayCache[k] = v.DisplayName
				end
			end
		end)
	end
	return _displayCache[asset] or asset
end

-- === 遊戲狀態追蹤 ===
local isGameRunning = false
local gameStartSession = nil
local gameStartApprox = false
local gameEndElapsed = nil
local gameStartMapId = nil
local mapTransitionLog = {}
local readyHooked = false
local hookTaskQueue = {}

local uiVisible = true

local getSessionTime

local function getElapsed()
	if not gameStartSession then
		return 0
	end
	local now = getSessionTime and getSessionTime() or nil
	if not now then
		return 0
	end
	return math.max(0, now - gameStartSession)
end

-- SessionTime 換算局內秒數
local function elapsedFromPlacedAt(placedAt)
	if not placedAt or not gameStartSession then
		return nil
	end
	return math.max(0, placedAt - gameStartSession)
end

local function startGameTimer(mapId, startSession)
	if isGameRunning then
		return false
	end
	gameStartSession = startSession or (getSessionTime and getSessionTime()) or nil
	if not gameStartSession then
		return false
	end
	isGameRunning = true
	gameStartMapId = mapId or gameSettings.mapId
	gameStartAutoSkipWave = readAutoSkipWave()
	return true
end

local function queueHookTask(fn)
	table.insert(hookTaskQueue, fn)
end

local function flushHookTaskQueue()
	if #hookTaskQueue == 0 then
		return
	end
	local queued = hookTaskQueue
	hookTaskQueue = {}
	for _, fn in ipairs(queued) do
		local ok, err = pcall(fn)
		if not ok then
			warn("[Queued Hook Error]", err)
		end
	end
end

-- ============================================================
-- 塔能力系統 狀態
-- ============================================================
local TowerAbilitiesData = {}
local TowersData = {}

local ABILITY_FALLBACK = {
	Heal = {
		Name = "Heal",
		Cooldown = 15,
	},
	Rage = {
		Name = "Rage",
		Cooldown = 30,
	},
	Spin = {
		Name = "Spin",
		Cooldown = 45,
	},
	NoxGrenade = {
		Name = "Poison Grenade",
		Cooldown = 35,
	},
	PaintballerGrenade = {
		Name = "Paint Grenade",
		Cooldown = 40,
	},
	KingBoost = {
		Name = "Conquer",
		Cooldown = 30,
	},
	DoombringerHammer = {
		Name = "Hammer Stun",
		Cooldown = 30,
	},
}

local function getAbiData(key)
	return TowerAbilitiesData[key] or ABILITY_FALLBACK[key] or {
		Name = key,
		Cooldown = 30,
	}
end

-- === [待實作] 取得某單位有哪些能力 ===
-- 原 GTD 版讀自己的 TowersData 模組: getTowerData(name).Levels[].Stats.Ability 與 .Stats.Ability。
-- 動漫遠征沒有這個模組, 單位能力資料來源尚未偵察 -> 先回空陣列 (= 掃不到任何有能力的單位)。
-- 線索: Dependencies.Information.Abilities / GetUnitSkillInfo, 以及 Actions.ActivateUnitAbility。
-- 重建計畫見檔頭 [階段 3]。
local abilityCache = {}
local function fetchAbilityKeys(towerName)
	if abilityCache[towerName] then
		return abilityCache[towerName]
	end
	-- TODO[階段 3]: 依動漫遠征的單位資料 schema 取出能力 key
	local keys = {}
	abilityCache[towerName] = keys
	return keys
end

local towersWithAbility = {} -- { [towerName] = abilityKeys[] }

local abiNextOrder = 1
local abiLiveTowers = {} -- [model] = { name, order, abilityKeys, gameId, cooldowns, savedAutoStates }
local abiTowerCards = {} -- [model] = { container, widgets[] }
local abiModelByGameId = {} -- [gameId] = model
local abiPendingGameIds = {} -- { name, gameId, time }[]
local abiGameIdCooldownHint = {} -- [gameId][abilityKey] = abiGameClock（遊戲時間戳）
local abiEmptyLabel = nil
local abiRemoteInFlight = {} -- [gameId:abilityKey] = true

-- 遊戲時間時鐘：每幀累加 dt × 當前遊戲速度。能力冷卻是用「遊戲時間」算的，
-- x2/x3 速度下時鐘走得快 → 冷卻較快就緒。所有冷卻時間戳一律用這個時鐘（而非真實 tick()）。
local abiGameClock = 0

-- Forward declaration：在 langBtn / stopAbilityRemoteTriggers 中被呼叫
local rebuildAllAbilityCards

-- === [待實作] 能力冷卻計算 / 觸發 ===
-- 原 GTD 版: getAbilityRemaining 用 abiGameClock 算剩餘冷卻;
--            invokeTowerAbilitySafely 呼叫 TowerAbilityRemote:InvokeServer(gameId, abilityKey);
--            stopAbilityRemoteTriggers 在遊戲結束時清空所有 in-flight / gameId 綁定。
-- 動漫遠征的能力觸發管道尚未偵察 -> 先留下同簽章的樁, GUI 照常可跑 (按了不會有事)。
-- 重建計畫見檔頭 [階段 3]。

local function getAbilityRemaining(info, abilityKey, cooldown)
	local t0 = info and info.cooldowns and info.cooldowns[abilityKey]
	if not t0 then
		return 0
	end
	-- 以遊戲時間計: abiGameClock 已含速度倍率
	return math.max(0, cooldown - (abiGameClock - t0))
end

-- TODO[階段 3]: 接上動漫遠征的能力觸發 (可能也是 ReplicaSignal 的某個 signal)
local function invokeTowerAbilitySafely(model, abilityKey, cooldown)
	Tracker.NotImplemented("invokeTowerAbilitySafely")
	return false
end

-- TODO[階段 3]: 遊戲結束時清掉能力綁定
local function stopAbilityRemoteTriggers()
	abiRemoteInFlight = {}
	abiPendingGameIds = {}
	abiGameIdCooldownHint = {}
	abiModelByGameId = {}

	for _, info in pairs(abiLiveTowers) do
		info.gameId = nil
		info.cooldowns = {}
	end

	if rebuildAllAbilityCards then
		rebuildAllAbilityCards()
	end
end

-- ============================================================
-- UI 建立
-- ============================================================
local guiParent = get_hidden_gui or gethui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NTDTrackerUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent and guiParent() or game:GetService("CoreGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UISizes.mainFrame
mainFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Theme.Background
mainFrame.BackgroundTransparency = 0.05
mainFrame.Active = true
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = mainFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = mainFrame
end

-- 標題欄
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Theme.Surface
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
titleBar.Name = "TitleBar"
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = titleBar
end

local titleBarCover = Instance.new("Frame")
titleBarCover.Size = UDim2.new(1, 0, 0, 10)
titleBarCover.Position = UDim2.new(0, 0, 1, -10)
titleBarCover.BackgroundColor3 = Theme.Surface
titleBarCover.BorderSizePixel = 0
titleBarCover.Parent = titleBar

local titleSeparator = Instance.new("Frame")
titleSeparator.Size = UDim2.new(1, 0, 0, 1)
titleSeparator.Position = UDim2.new(0, 0, 1, -1)
titleSeparator.BackgroundColor3 = Theme.Border
titleSeparator.BorderSizePixel = 0
titleSeparator.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Theme.Accent
title.Font = Theme.FontBold
title.TextSize = Theme.SizeLarge
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.new(0, 10, 0, 0)
title.Parent = titleBar
bindText(title, "titleMain")

local langBtn = Instance.new("TextButton")
langBtn.Size = UDim2.new(0, 35, 0, 35)
langBtn.Position = UDim2.new(1, -80, 0, 5)
langBtn.Text = currentLang == "zh" and "EN" or "中"
langBtn.BackgroundColor3 = Theme.SurfaceHighlight
langBtn.TextColor3 = Theme.Accent
langBtn.Font = Theme.FontBold
langBtn.TextSize = 13
langBtn.BorderSizePixel = 0
langBtn.Parent = titleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = langBtn
end

langBtn.MouseButton1Click:Connect(function()
	if currentLang == "zh" then
		currentLang = "en"
		langBtn.Text = "中"
	else
		currentLang = "zh"
		langBtn.Text = "EN"
	end
	updateI18n()
	task.spawn(function()
		rebuildAllAbilityCards()
	end)
end)

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
minimizeBtn.Position = UDim2.new(1, -40, 0, 5)
minimizeBtn.Text = "—"
minimizeBtn.BackgroundColor3 = Theme.SurfaceHighlight
minimizeBtn.TextColor3 = Theme.Text
minimizeBtn.Font = Theme.FontBold
minimizeBtn.TextSize = 22
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = titleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = minimizeBtn
end

-- 滾動框架
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -100)
scrollFrame.Position = UDim2.new(0, 10, 0, 50)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarImageColor3 = Theme.Border
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollFrame

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if scrollFrame and autoScrollEnabled then
			pcall(function()
				scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
			end)
		end
	end
end)

-- 按鈕列
local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(1, -20, 0, 40)
buttonContainer.Position = UDim2.new(0, 10, 1, -45)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = mainFrame

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.Padding = UDim.new(0, 6)
buttonLayout.Parent = buttonContainer

local function makeBtn(textKey, bgColor, txtColor, order, widthScale)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(widthScale or 0.25, -5, 1, 0)
	btn.BackgroundColor3 = bgColor
	btn.TextColor3 = txtColor
	btn.Font = Theme.FontBold
	btn.TextSize = Theme.SizeMedium
	btn.BorderSizePixel = 0
	btn.LayoutOrder = order
	btn.Parent = buttonContainer
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = btn
	bindText(btn, textKey)
	return btn
end

local copyBtn = makeBtn("btnCopy", Theme.Success, Theme.TextDark, 1, 0.25)
local saveBtn = makeBtn("btnSave", Theme.Accent, Theme.Text, 2, 0.25)
local Parameter = makeBtn("btnParam", Theme.SurfaceHighlight, Theme.Text, 3, 0.25)
local abilityBtn = makeBtn("btnAbility", Theme.Purple, Theme.Text, 4, 0.25)

local resetBtn
local debugBtn

-- ============================================================
-- addLog 函數
-- ============================================================
local logOrder = 1

local function addLog(text, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Theme.Text
	label.Font = Theme.Font
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.LayoutOrder = logOrder
	label.Parent = scrollFrame
	logOrder = logOrder + 1
end

-- ============================================================
-- 參數面板 UI
-- ============================================================
local parameterFrame = Instance.new("Frame")
parameterFrame.Size = UISizes.parameterFrame
parameterFrame.Position = UISizes.parameterFramePosition
parameterFrame.BackgroundColor3 = Theme.Background
parameterFrame.BackgroundTransparency = 0.05
parameterFrame.Active = true
parameterFrame.BorderSizePixel = 0
parameterFrame.ClipsDescendants = true
parameterFrame.Visible = false
parameterFrame.ZIndex = 10
parameterFrame.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = parameterFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parameterFrame
end

local paramTitleBar = Instance.new("Frame")
paramTitleBar.Size = UDim2.new(1, 0, 0, 45)
paramTitleBar.BackgroundColor3 = Theme.Surface
paramTitleBar.BorderSizePixel = 0
paramTitleBar.ZIndex = 11
paramTitleBar.Parent = parameterFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = paramTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = paramTitleBar
end

local paramTitle = Instance.new("TextLabel")
paramTitle.Size = UDim2.new(0.8, 0, 1, 0)
paramTitle.BackgroundTransparency = 1
paramTitle.TextColor3 = Theme.Text
paramTitle.Font = Theme.FontBold
paramTitle.TextSize = Theme.SizeLarge
paramTitle.TextXAlignment = Enum.TextXAlignment.Left
paramTitle.ZIndex = 12
paramTitle.Parent = paramTitleBar
bindText(paramTitle, "titleParam")

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.Text = "×"
closeBtn.BackgroundColor3 = Theme.Error
closeBtn.TextColor3 = Theme.Text
closeBtn.Font = Theme.FontBold
closeBtn.TextSize = 24
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 12
closeBtn.Parent = paramTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = closeBtn
end

local paramScrollFrame = Instance.new("ScrollingFrame")
paramScrollFrame.Size = UDim2.new(1, -20, 1, -55)
paramScrollFrame.Position = UDim2.new(0, 10, 0, 50)
paramScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
paramScrollFrame.ScrollBarThickness = 4
paramScrollFrame.BackgroundTransparency = 1
paramScrollFrame.ZIndex = 11
paramScrollFrame.Parent = parameterFrame

local paramListLayout = Instance.new("UIListLayout")
paramListLayout.SortOrder = Enum.SortOrder.LayoutOrder
paramListLayout.Padding = UDim.new(0, 8)
paramListLayout.Parent = paramScrollFrame

paramListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	paramScrollFrame.CanvasSize = UDim2.new(0, 0, 0, paramListLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- 儲存面板 UI
-- ============================================================
local saveFrame = Instance.new("Frame")
saveFrame.Size = UISizes.saveFrame
saveFrame.Position = UISizes.saveFramePosition
saveFrame.BackgroundColor3 = Theme.Background
saveFrame.BackgroundTransparency = 0.05
saveFrame.Active = true
saveFrame.BorderSizePixel = 0
saveFrame.ClipsDescendants = true
saveFrame.Visible = false
saveFrame.ZIndex = 10
saveFrame.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = saveFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = saveFrame
end

local saveTitleBar = Instance.new("Frame")
saveTitleBar.Size = UDim2.new(1, 0, 0, 45)
saveTitleBar.BackgroundColor3 = Theme.Surface
saveTitleBar.BorderSizePixel = 0
saveTitleBar.ZIndex = 11
saveTitleBar.Parent = saveFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = saveTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = saveTitleBar
end

local saveTitle = Instance.new("TextLabel")
saveTitle.Size = UDim2.new(0.8, 0, 1, 0)
saveTitle.BackgroundTransparency = 1
saveTitle.TextColor3 = Theme.Text
saveTitle.Font = Theme.FontBold
saveTitle.TextSize = Theme.SizeLarge
saveTitle.TextXAlignment = Enum.TextXAlignment.Left
saveTitle.ZIndex = 12
saveTitle.Parent = saveTitleBar
bindText(saveTitle, "titleSave")

local saveCloseBtn = Instance.new("TextButton")
saveCloseBtn.Size = UDim2.new(0, 35, 0, 35)
saveCloseBtn.Position = UDim2.new(1, -40, 0, 5)
saveCloseBtn.Text = "×"
saveCloseBtn.BackgroundColor3 = Theme.Error
saveCloseBtn.TextColor3 = Theme.Text
saveCloseBtn.Font = Theme.FontBold
saveCloseBtn.TextSize = 24
saveCloseBtn.BorderSizePixel = 0
saveCloseBtn.ZIndex = 12
saveCloseBtn.Parent = saveTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = saveCloseBtn
end

local fileNameLabel = Instance.new("TextLabel")
fileNameLabel.Size = UDim2.new(1, -20, 0, 20)
fileNameLabel.Position = UDim2.new(0, 10, 0, 55)
fileNameLabel.BackgroundTransparency = 1
fileNameLabel.TextColor3 = Theme.TextDim
fileNameLabel.Font = Theme.Font
fileNameLabel.TextSize = Theme.SizeNormal
fileNameLabel.TextXAlignment = Enum.TextXAlignment.Left
fileNameLabel.ZIndex = 12
fileNameLabel.Parent = saveFrame
bindText(fileNameLabel, "lblFileName")

local fileNameInput = Instance.new("TextBox")
fileNameInput.Size = UDim2.new(1, -20, 0, 35)
fileNameInput.Position = UDim2.new(0, 10, 0, 80)
fileNameInput.BackgroundColor3 = Theme.SurfaceHighlight
fileNameInput.PlaceholderColor3 = Theme.TextDim
fileNameInput.Text = ""
fileNameInput.TextColor3 = Theme.Text
fileNameInput.Font = Theme.Font
fileNameInput.TextSize = Theme.SizeNormal
fileNameInput.BorderSizePixel = 0
fileNameInput.ClearTextOnFocus = false
fileNameInput.ZIndex = 12
fileNameInput.Parent = saveFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = fileNameInput
end
bindText(fileNameInput, "phFileName", "PlaceholderText")

-- 指定加載名稱（前綴）：僅雙地圖 + 分離模式顯示；生成的 Phase1 用它 AddMapWait("<前綴>")
local phase2NameLabel = Instance.new("TextLabel")
phase2NameLabel.Size = UDim2.new(1, -20, 0, 20)
phase2NameLabel.Position = UDim2.new(0, 10, 0, 158)
phase2NameLabel.BackgroundTransparency = 1
phase2NameLabel.TextColor3 = Theme.TextDim
phase2NameLabel.Font = Theme.Font
phase2NameLabel.TextSize = Theme.SizeNormal
phase2NameLabel.TextXAlignment = Enum.TextXAlignment.Left
phase2NameLabel.Visible = false
phase2NameLabel.ZIndex = 12
phase2NameLabel.Parent = saveFrame
bindText(phase2NameLabel, "lblPhase2Name")

local phase2NameInput = Instance.new("TextBox")
phase2NameInput.Size = UDim2.new(1, -20, 0, 32)
phase2NameInput.Position = UDim2.new(0, 10, 0, 180)
phase2NameInput.BackgroundColor3 = Theme.SurfaceHighlight
phase2NameInput.PlaceholderColor3 = Theme.TextDim
phase2NameInput.Text = ""
phase2NameInput.TextColor3 = Theme.Text
phase2NameInput.Font = Theme.Font
phase2NameInput.TextSize = Theme.SizeNormal
phase2NameInput.BorderSizePixel = 0
phase2NameInput.ClearTextOnFocus = false
phase2NameInput.Visible = false
phase2NameInput.ZIndex = 12
phase2NameInput.Parent = saveFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = phase2NameInput
end

local saveModeRow = Instance.new("Frame")
saveModeRow.Size = UDim2.new(1, -20, 0, 28)
saveModeRow.Position = UDim2.new(0, 10, 0, 122)
saveModeRow.BackgroundTransparency = 1
saveModeRow.Visible = false
saveModeRow.ZIndex = 12
saveModeRow.Parent = saveFrame

local saveModeLbl = Instance.new("TextLabel")
saveModeLbl.Size = UDim2.new(0.45, 0, 1, 0)
saveModeLbl.BackgroundTransparency = 1
saveModeLbl.TextColor3 = Theme.TextDim
saveModeLbl.Font = Theme.Font
saveModeLbl.TextSize = Theme.SizeNormal
saveModeLbl.TextXAlignment = Enum.TextXAlignment.Left
saveModeLbl.ZIndex = 13
saveModeLbl.Parent = saveModeRow
bindText(saveModeLbl, "lblSaveMode")

local saveMergedBtn = Instance.new("TextButton")
saveMergedBtn.Size = UDim2.new(0.25, -4, 1, 0)
saveMergedBtn.Position = UDim2.new(0.45, 0, 0, 0)
saveMergedBtn.BackgroundColor3 = Theme.Accent
saveMergedBtn.TextColor3 = Theme.Text
saveMergedBtn.Font = Theme.FontBold
saveMergedBtn.TextSize = 14
saveMergedBtn.BorderSizePixel = 0
saveMergedBtn.ZIndex = 13
saveMergedBtn.Parent = saveModeRow
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = saveMergedBtn
end
bindText(saveMergedBtn, "saveMerged")

local saveSeparateBtn = Instance.new("TextButton")
saveSeparateBtn.Size = UDim2.new(0.28, -4, 1, 0)
saveSeparateBtn.Position = UDim2.new(0.72, 0, 0, 0)
saveSeparateBtn.BackgroundColor3 = Theme.SurfaceHighlight
saveSeparateBtn.TextColor3 = Theme.TextDim
saveSeparateBtn.Font = Theme.FontBold
saveSeparateBtn.TextSize = 14
saveSeparateBtn.BorderSizePixel = 0
saveSeparateBtn.ZIndex = 13
saveSeparateBtn.Parent = saveModeRow
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = saveSeparateBtn
end
bindText(saveSeparateBtn, "saveSeparate")

local currentSaveMode = "merged"
local relayoutSavePanel -- forward declaration（在 saveBtnContainer 建立後賦值）

local function updateSaveModeButtons()
	if currentSaveMode == "merged" then
		saveMergedBtn.BackgroundColor3 = Theme.Accent
		saveMergedBtn.TextColor3 = Theme.Text
		saveSeparateBtn.BackgroundColor3 = Theme.SurfaceHighlight
		saveSeparateBtn.TextColor3 = Theme.TextDim
	else
		saveMergedBtn.BackgroundColor3 = Theme.SurfaceHighlight
		saveMergedBtn.TextColor3 = Theme.TextDim
		saveSeparateBtn.BackgroundColor3 = Theme.Accent
		saveSeparateBtn.TextColor3 = Theme.Text
	end
end

saveMergedBtn.MouseButton1Click:Connect(function()
	currentSaveMode = "merged"
	updateSaveModeButtons()
	if relayoutSavePanel then relayoutSavePanel() end
end)
saveSeparateBtn.MouseButton1Click:Connect(function()
	currentSaveMode = "separate"
	updateSaveModeButtons()
	if relayoutSavePanel then relayoutSavePanel() end
end)

local saveBtnContainer = Instance.new("Frame")
saveBtnContainer.Size = UDim2.new(1, -20, 0, 40)
saveBtnContainer.Position = UDim2.new(0, 10, 0, 130)
saveBtnContainer.BackgroundTransparency = 1
saveBtnContainer.ZIndex = 12
saveBtnContainer.Parent = saveFrame
do
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 10)
	l.Parent = saveBtnContainer
end

-- 動漫遠征只有單一地圖流程，存檔面板固定排版（無雙地圖 / 合併分離之分）
relayoutSavePanel = function()
	saveModeRow.Visible = false
	phase2NameLabel.Visible = false
	phase2NameInput.Visible = false

	local y = 122
	saveBtnContainer.Position = UDim2.new(0, 10, 0, y)
	local wx = UISizes.saveFrame.X
	saveFrame.Size = UDim2.new(wx.Scale, wx.Offset, 0, y + 55)
end

local confirmSaveBtn = Instance.new("TextButton")
confirmSaveBtn.Size = UDim2.new(0.5, -5, 1, 0)
confirmSaveBtn.BackgroundColor3 = Theme.Success
confirmSaveBtn.TextColor3 = Theme.TextDark
confirmSaveBtn.Font = Theme.FontBold
confirmSaveBtn.TextSize = Theme.SizeNormal
confirmSaveBtn.BorderSizePixel = 0
confirmSaveBtn.LayoutOrder = 1
confirmSaveBtn.ZIndex = 12
confirmSaveBtn.Parent = saveBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = confirmSaveBtn
end
bindText(confirmSaveBtn, "btnConfirmSave")

local cancelSaveBtn = Instance.new("TextButton")
cancelSaveBtn.Size = UDim2.new(0.5, -5, 1, 0)
cancelSaveBtn.BackgroundColor3 = Theme.SurfaceHighlight
cancelSaveBtn.TextColor3 = Theme.Text
cancelSaveBtn.Font = Theme.FontBold
cancelSaveBtn.TextSize = Theme.SizeNormal
cancelSaveBtn.BorderSizePixel = 0
cancelSaveBtn.LayoutOrder = 2
cancelSaveBtn.ZIndex = 12
cancelSaveBtn.Parent = saveBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = cancelSaveBtn
end
bindText(cancelSaveBtn, "btnCancel")

-- ============================================================
-- 腳本管理面板
-- ============================================================
local refreshScriptList

local manageFrame = Instance.new("Frame")
manageFrame.Size = UISizes.manageFrame
manageFrame.Position = UISizes.manageFramePosition
manageFrame.BackgroundColor3 = Theme.Background
manageFrame.BackgroundTransparency = 0.05
manageFrame.Active = true
manageFrame.BorderSizePixel = 0
manageFrame.ClipsDescendants = true
manageFrame.Visible = false
manageFrame.ZIndex = 10
manageFrame.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = manageFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = manageFrame
end

local manageTitleBar = Instance.new("Frame")
manageTitleBar.Size = UDim2.new(1, 0, 0, 45)
manageTitleBar.BackgroundColor3 = Theme.Surface
manageTitleBar.BorderSizePixel = 0
manageTitleBar.ZIndex = 11
manageTitleBar.Parent = manageFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = manageTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = manageTitleBar
end

local manageTitle = Instance.new("TextLabel")
manageTitle.Size = UDim2.new(0.6, 0, 1, 0)
manageTitle.BackgroundTransparency = 1
manageTitle.TextColor3 = Theme.Text
manageTitle.Font = Theme.FontBold
manageTitle.TextSize = Theme.SizeLarge
manageTitle.TextXAlignment = Enum.TextXAlignment.Left
manageTitle.ZIndex = 12
manageTitle.Parent = manageTitleBar
bindText(manageTitle, "titleManage")

local refreshScriptsBtn = Instance.new("TextButton")
refreshScriptsBtn.Size = UDim2.new(0, 80, 0, 30)
refreshScriptsBtn.Position = UDim2.new(1, -125, 0, 7)
refreshScriptsBtn.BackgroundColor3 = Theme.Accent
refreshScriptsBtn.TextColor3 = Theme.Text
refreshScriptsBtn.Font = Theme.Font
refreshScriptsBtn.TextSize = 14
refreshScriptsBtn.BorderSizePixel = 0
refreshScriptsBtn.ZIndex = 12
refreshScriptsBtn.Parent = manageTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = refreshScriptsBtn
end
bindText(refreshScriptsBtn, "btnRefresh")

local manageCloseBtn = Instance.new("TextButton")
manageCloseBtn.Size = UDim2.new(0, 35, 0, 35)
manageCloseBtn.Position = UDim2.new(1, -40, 0, 5)
manageCloseBtn.Text = "×"
manageCloseBtn.BackgroundColor3 = Theme.Error
manageCloseBtn.TextColor3 = Theme.Text
manageCloseBtn.Font = Theme.FontBold
manageCloseBtn.TextSize = 24
manageCloseBtn.BorderSizePixel = 0
manageCloseBtn.ZIndex = 12
manageCloseBtn.Parent = manageTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = manageCloseBtn
end

local manageScrollFrame = Instance.new("ScrollingFrame")
manageScrollFrame.Size = UDim2.new(1, -20, 1, -55)
manageScrollFrame.Position = UDim2.new(0, 10, 0, 50)
manageScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
manageScrollFrame.ScrollBarThickness = 4
manageScrollFrame.BackgroundTransparency = 1
manageScrollFrame.ZIndex = 11
manageScrollFrame.Parent = manageFrame

local manageListLayout = Instance.new("UIListLayout")
manageListLayout.SortOrder = Enum.SortOrder.LayoutOrder
manageListLayout.Padding = UDim.new(0, 6)
manageListLayout.Parent = manageScrollFrame

manageListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	manageScrollFrame.CanvasSize = UDim2.new(0, 0, 0, manageListLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- 塔能力面板 UI
-- ============================================================
local abilityFrame = Instance.new("Frame")
abilityFrame.Size = UISizes.abilityFrame
abilityFrame.Position = UDim2.new(0.5, 0, 0.5, -200)
abilityFrame.BackgroundColor3 = Theme.Background
abilityFrame.BackgroundTransparency = 0.05
abilityFrame.Active = true
abilityFrame.BorderSizePixel = 0
abilityFrame.ClipsDescendants = true
abilityFrame.Visible = false
abilityFrame.ZIndex = 10
abilityFrame.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = abilityFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = abilityFrame
end

local abilityTitleBar = Instance.new("Frame")
abilityTitleBar.Size = UDim2.new(1, 0, 0, 45)
abilityTitleBar.BackgroundColor3 = Theme.Surface
abilityTitleBar.BorderSizePixel = 0
abilityTitleBar.ZIndex = 11
abilityTitleBar.Parent = abilityFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = abilityTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = abilityTitleBar
end

local abilityTitle = Instance.new("TextLabel")
abilityTitle.Size = UDim2.new(0.8, 0, 1, 0)
abilityTitle.BackgroundTransparency = 1
abilityTitle.TextColor3 = Theme.Purple
abilityTitle.Font = Theme.FontBold
abilityTitle.TextSize = Theme.SizeLarge
abilityTitle.TextXAlignment = Enum.TextXAlignment.Left
abilityTitle.ZIndex = 12
abilityTitle.Parent = abilityTitleBar
bindText(abilityTitle, "titleAbility")

local abilityCloseBtn = Instance.new("TextButton")
abilityCloseBtn.Size = UDim2.new(0, 35, 0, 35)
abilityCloseBtn.Position = UDim2.new(1, -40, 0, 5)
abilityCloseBtn.Text = "×"
abilityCloseBtn.BackgroundColor3 = Theme.Error
abilityCloseBtn.TextColor3 = Theme.Text
abilityCloseBtn.Font = Theme.FontBold
abilityCloseBtn.TextSize = 24
abilityCloseBtn.BorderSizePixel = 0
abilityCloseBtn.ZIndex = 12
abilityCloseBtn.Parent = abilityTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = abilityCloseBtn
end

local abilityScrollFrame = Instance.new("ScrollingFrame")
abilityScrollFrame.Size = UDim2.new(1, -20, 1, -55)
abilityScrollFrame.Position = UDim2.new(0, 10, 0, 50)
abilityScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
abilityScrollFrame.ScrollBarThickness = 4
abilityScrollFrame.BackgroundTransparency = 1
abilityScrollFrame.ScrollBarImageColor3 = Theme.Border
abilityScrollFrame.ZIndex = 11
abilityScrollFrame.Parent = abilityFrame

local abilityListLayout = Instance.new("UIListLayout")
abilityListLayout.SortOrder = Enum.SortOrder.LayoutOrder
abilityListLayout.Padding = UDim.new(0, 8)
abilityListLayout.Parent = abilityScrollFrame

abilityListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	abilityScrollFrame.CanvasSize = UDim2.new(0, 0, 0, abilityListLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- 參數面板 Helper 函數
-- ============================================================
local function createLabel(key, parent, order)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 25)
	label.BackgroundTransparency = 1
	label.TextColor3 = Theme.TextDim
	label.Font = Theme.FontBold
	label.TextSize = Theme.SizeNormal
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = order
	label.ZIndex = 13
	label.Parent = parent
	bindText(label, key)
	return label
end

local function createToggle(labelKey, parent, order, defaultValue, callback, descKey)
	local frameH = descKey and 65 or 40
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, frameH)
	frame.BackgroundTransparency = 1
	frame.LayoutOrder = order
	frame.ZIndex = 12
	frame.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.75, 0, 0, 40)
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Theme.Text
	lbl.Font = Theme.Font
	lbl.TextSize = Theme.SizeNormal
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 13
	lbl.Parent = frame
	bindText(lbl, labelKey)

	local isOn = defaultValue
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 55, 0, 28)
	btn.Position = UDim2.new(1, -60, 0, 6)
	btn.BackgroundColor3 = isOn and Theme.Success or Theme.SurfaceHighlight
	btn.Text = isOn and T("toggleOn") or T("toggleOff")
	btn.TextColor3 = isOn and Theme.TextDark or Theme.TextDim
	btn.Font = Theme.FontBold
	btn.TextSize = Theme.SizeNormal
	btn.BorderSizePixel = 0
	btn.ZIndex = 13
	btn.Parent = frame
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 14)
		c.Parent = btn
	end

	local function paint()
		btn.BackgroundColor3 = isOn and Theme.Success or Theme.SurfaceHighlight
		btn.Text = isOn and T("toggleOn") or T("toggleOff")
		btn.TextColor3 = isOn and Theme.TextDark or Theme.TextDim
	end

	table.insert(i18nToggleBtns, {
		btn = btn,
		getState = function()
			return isOn
		end,
	})

	btn.MouseButton1Click:Connect(function()
		isOn = not isOn
		paint()
		if callback then
			callback(isOn)
		end
	end)

	if descKey then
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -8, 0, 22)
		descLabel.Position = UDim2.new(0, 4, 0, 41)
		descLabel.BackgroundTransparency = 1
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.Font = Theme.Font
		descLabel.TextSize = 14
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.ZIndex = 13
		descLabel.Parent = frame
		bindText(descLabel, descKey)
	end

	-- 回傳控制代碼: 外部要能「不觸發 callback」地校正顯示狀態。
	-- 用途: 開關的真實狀態來自遊戲 (載入時才讀得到), 或被遊戲自己的 UI 改掉。
	return {
		btn = btn,
		set = function(v)
			v = v == true
			if v == isOn then
				return
			end
			isOn = v
			paint()
		end,
		get = function()
			return isOn
		end,
	}
end

-- ============================================================
-- 參數面板控件
-- ============================================================
createLabel("lblInterface", paramScrollFrame, 1)
createToggle("lblAutoScroll", paramScrollFrame, 2, true, function(v)
	autoScrollEnabled = v
end)

createLabel("lblGameInfo", paramScrollFrame, 3)

infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 120)
infoLabel.BackgroundColor3 = Theme.Surface
infoLabel.BackgroundTransparency = 0.5
infoLabel.TextColor3 = Theme.Success
infoLabel.Font = Theme.Font
infoLabel.TextSize = 15
infoLabel.TextWrapped = true
infoLabel.LayoutOrder = 9
infoLabel.ZIndex = 13
infoLabel.Parent = paramScrollFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = infoLabel
end
updateInfoLabel()

createLabel("lblTrackerOp", paramScrollFrame, 11)

local trackerBtnContainer = Instance.new("Frame")
trackerBtnContainer.Size = UDim2.new(1, 0, 0, 40)
trackerBtnContainer.BackgroundTransparency = 1
trackerBtnContainer.LayoutOrder = 12
trackerBtnContainer.ZIndex = 12
trackerBtnContainer.Parent = paramScrollFrame
do
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 8)
	l.Parent = trackerBtnContainer
end

resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.5, -4, 1, 0)
resetBtn.BackgroundColor3 = Theme.SurfaceHighlight
resetBtn.TextColor3 = Theme.Warning
resetBtn.Font = Theme.FontBold
resetBtn.TextSize = Theme.SizeNormal
resetBtn.BorderSizePixel = 0
resetBtn.LayoutOrder = 1
resetBtn.ZIndex = 13
resetBtn.Parent = trackerBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = resetBtn
end
bindText(resetBtn, "btnReset")

debugBtn = Instance.new("TextButton")
debugBtn.Size = UDim2.new(0.5, -4, 1, 0)
debugBtn.BackgroundColor3 = Theme.SurfaceHighlight
debugBtn.TextColor3 = Theme.TextDim
debugBtn.Font = Theme.FontBold
debugBtn.TextSize = Theme.SizeNormal
debugBtn.BorderSizePixel = 0
debugBtn.LayoutOrder = 2
debugBtn.ZIndex = 13
debugBtn.Parent = trackerBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = debugBtn
end
bindText(debugBtn, "btnDebug")

createLabel("lblScriptParam", paramScrollFrame, 13)
createToggle("lblAutoReplay", paramScrollFrame, 14, ScriptSettings.AutoReplay, function(v)
	ScriptSettings.AutoReplay = v
end)
createToggle("lblCostMode", paramScrollFrame, 16, ScriptSettings.CostMode, function(v)
	ScriptSettings.CostMode = v
end, "lblCostModeDesc")

-- 自動跳過波次：直接改遊戲設定 (走 Nodes 層的 CLIENT_CHANGE_SETTING)。
autoSkipToggle = createToggle("lblAutoSkipWaves", paramScrollFrame, 17, autoSkipState.on, function(v)
	pcall(function()
		Adapter.SetAutoSkipWaves(v)
	end)
end, "lblAutoSkipWavesDesc")

createToggle("lblAutoSkipCheckpoint", paramScrollFrame, 18, ScriptSettings.AutoSkipCheckpoint, function(v)
	ScriptSettings.AutoSkipCheckpoint = v
end, "lblAutoSkipCheckpointDesc")

-- ============================================================
-- 拖移功能
-- ============================================================
local function makeDraggable(uiElement)
	local state = {
		dragging = false,
		dragStart = nil,
		startPos = nil,
	}
	local renderConn = nil

	local function update()
		if not state.dragging then
			return
		end
		local delta = UserInputService:GetMouseLocation() - state.dragStart
		uiElement.Position = UDim2.new(
			state.startPos.X.Scale,
			state.startPos.X.Offset + delta.X,
			state.startPos.Y.Scale,
			state.startPos.Y.Offset + delta.Y
		)
	end

	uiElement.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			state.dragging = true
			state.dragStart = UserInputService:GetMouseLocation()
			state.startPos = uiElement.Position
			if not renderConn then
				renderConn = RunService.RenderStepped:Connect(update)
			end
		end
	end)

	uiElement.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			state.dragging = false
			if renderConn then
				renderConn:Disconnect()
				renderConn = nil
			end
		end
	end)
end

makeDraggable(parameterFrame)
makeDraggable(saveFrame)
makeDraggable(manageFrame)
makeDraggable(abilityFrame)

local tbDrag = {
	dragging = false,
}
local tbConn = nil
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		tbDrag.dragging = true
		tbDrag.dragStart = UserInputService:GetMouseLocation()
		tbDrag.startPos = mainFrame.Position
		if not tbConn then
			tbConn = RunService.RenderStepped:Connect(function()
				if not tbDrag.dragging then
					return
				end
				local d = UserInputService:GetMouseLocation() - tbDrag.dragStart
				mainFrame.Position = UDim2.new(
					tbDrag.startPos.X.Scale,
					tbDrag.startPos.X.Offset + d.X,
					tbDrag.startPos.Y.Scale,
					tbDrag.startPos.Y.Offset + d.Y
				)
			end)
		end
	end
end)
titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		tbDrag.dragging = false
		if tbConn then
			tbConn:Disconnect()
			tbConn = nil
		end
	end
end)

-- ============================================================
-- 收合功能
-- ============================================================
local minimized = false
local function toggleMinimize()
	minimized = not minimized
	scrollFrame.Visible = not minimized
	copyBtn.Visible = not minimized
	saveBtn.Visible = not minimized
	Parameter.Visible = not minimized
	abilityBtn.Visible = not minimized
	minimizeBtn.Text = minimized and "+" or "—"
	TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Size = minimized and UISizes.mainFrameMinimized or UISizes.mainFrameExpanded,
	}):Play()
end
minimizeBtn.MouseButton1Click:Connect(toggleMinimize)

-- ============================================================
-- 面板互斥
-- ============================================================
local function closeAllPanels()
	parameterFrame.Visible = false
	saveFrame.Visible = false
	manageFrame.Visible = false
	abilityFrame.Visible = false
end

local function closeBlockingPanels()
	saveFrame.Visible = false
	manageFrame.Visible = false
end

local function positionAbilityFrame()
	if parameterFrame.Visible then
		abilityFrame.Position = UDim2.new(
			parameterFrame.Position.X.Scale,
			parameterFrame.Position.X.Offset + parameterFrame.AbsoluteSize.X + 10,
			parameterFrame.Position.Y.Scale,
			parameterFrame.Position.Y.Offset
		)
	else
		abilityFrame.Position = UDim2.new(
			mainFrame.Position.X.Scale,
			mainFrame.Position.X.Offset + mainFrame.AbsoluteSize.X + 10,
			mainFrame.Position.Y.Scale,
			mainFrame.Position.Y.Offset
		)
	end
end

local function openSavePanel()
	closeAllPanels()
	-- 檔名格式: 模式_地圖名稱_地圖等級_時間
	local defaultName = string.format(
		"%s_%s_%s_%s",
		gameSettings.gamemode or "Mode",
		gameStartMapId or gameSettings.mapId or "Map",
		gameSettings.actName or "Act",
		os.date("%Y%m%d_%H%M%S")
	)
	defaultName = defaultName:gsub("[^%w_%-]", "_")
	fileNameInput.Text = defaultName

	currentSaveMode = "merged"
	updateSaveModeButtons()
	relayoutSavePanel()

	saveFrame.Visible = true
end

-- ============================================================
-- 檔案操作
-- ============================================================
local function listScripts()
	local scripts = {}
	pcall(function()
		if listfiles then
			for _, fp in ipairs(listfiles(SCRIPT_SAVE_PATH)) do
				if fp:match("%.lua$") then
					local name = fp:match("([^/\\]+)%.lua$")
					if name then
						table.insert(scripts, {
							name = name,
							path = fp,
						})
					end
				end
			end
		end
	end)
	table.sort(scripts, function(a, b)
		return a.name > b.name
	end)
	return scripts
end

local function saveScriptToFile(fileName, content)
	local fullPath = SCRIPT_SAVE_PATH .. "/" .. fileName .. ".lua"
	local ok, err = pcall(function()
		if writefile then
			writefile(fullPath, content)
		else
			error("writefile unavailable")
		end
	end)
	if ok then
		addLog(T("logSaved"):format(fileName), Theme.Success)
		return true, fullPath
	else
		addLog(T("logSaveFailed"):format(tostring(err)), Theme.Error)
		return false, err
	end
end

function refreshScriptList()
	for _, child in pairs(manageScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local scripts = listScripts()
	if #scripts == 0 then
		local el = Instance.new("TextLabel")
		el.Size = UDim2.new(1, -10, 0, 40)
		el.BackgroundTransparency = 1
		el.Text = T("logNoScripts")
		el.TextColor3 = Theme.TextDim
		el.Font = Theme.Font
		el.TextSize = Theme.SizeNormal
		el.ZIndex = 12
		el.Parent = manageScrollFrame
		return
	end
	for i, script in ipairs(scripts) do
		local item = Instance.new("Frame")
		item.Size = UDim2.new(1, -5, 0, 45)
		item.BackgroundColor3 = Theme.SurfaceHighlight
		item.BackgroundTransparency = 0.3
		item.BorderSizePixel = 0
		item.LayoutOrder = i
		item.ZIndex = 12
		item.Parent = manageScrollFrame
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = item
		end

		local nl = Instance.new("TextLabel")
		nl.Size = UDim2.new(1, -140, 1, 0)
		nl.Position = UDim2.new(0, 10, 0, 0)
		nl.BackgroundTransparency = 1
		nl.Text = script.name
		nl.TextColor3 = Theme.Text
		nl.Font = Theme.Font
		nl.TextSize = 14
		nl.TextXAlignment = Enum.TextXAlignment.Left
		nl.TextTruncate = Enum.TextTruncate.AtEnd
		nl.ZIndex = 13
		nl.Parent = item

		local runBtn = Instance.new("TextButton")
		runBtn.Size = UDim2.new(0, 35, 0, 30)
		runBtn.Position = UDim2.new(1, -130, 0, 7)
		runBtn.Text = "▶"
		runBtn.BackgroundColor3 = Theme.Success
		runBtn.TextColor3 = Theme.TextDark
		runBtn.Font = Theme.FontBold
		runBtn.TextSize = 16
		runBtn.BorderSizePixel = 0
		runBtn.ZIndex = 13
		runBtn.Parent = item
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = runBtn
		end

		local cpBtn = Instance.new("TextButton")
		cpBtn.Size = UDim2.new(0, 35, 0, 30)
		cpBtn.Position = UDim2.new(1, -90, 0, 7)
		cpBtn.Text = "📋"
		cpBtn.BackgroundColor3 = Theme.Accent
		cpBtn.TextColor3 = Theme.Text
		cpBtn.Font = Theme.FontBold
		cpBtn.TextSize = 16
		cpBtn.BorderSizePixel = 0
		cpBtn.ZIndex = 13
		cpBtn.Parent = item
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = cpBtn
		end

		local dlBtn = Instance.new("TextButton")
		dlBtn.Size = UDim2.new(0, 35, 0, 30)
		dlBtn.Position = UDim2.new(1, -50, 0, 7)
		dlBtn.Text = "🗑️"
		dlBtn.BackgroundColor3 = Theme.Error
		dlBtn.TextColor3 = Theme.Text
		dlBtn.Font = Theme.FontBold
		dlBtn.TextSize = 16
		dlBtn.BorderSizePixel = 0
		dlBtn.ZIndex = 13
		dlBtn.Parent = item
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = dlBtn
		end

		local fp = script.path
		local sname = script.name

		runBtn.MouseButton1Click:Connect(function()
			local ok2, content = pcall(function()
				return readfile and readfile(fp) or nil
			end)
			if not ok2 or not content or content == "" then
				addLog(T("logRunFailed"):format(sname), Theme.Error)
				return
			end
			local loadedFn, loadErr = loadstring(content)
			if not loadedFn then
				addLog(T("logRunFailed"):format(tostring(loadErr)), Theme.Error)
				return
			end
			addLog(T("logRunPhase1"):format(sname), Theme.Success)
			manageFrame.Visible = false
			task.spawn(loadedFn)
		end)
		cpBtn.MouseButton1Click:Connect(function()
			local ok2, content = pcall(function()
				return readfile and readfile(fp) or nil
			end)
			if ok2 and content then
				pcall(function()
					setclipboard(content)
				end)
				addLog(T("logCopied"):format(sname), Theme.Accent)
			end
		end)
		dlBtn.MouseButton1Click:Connect(function()
			pcall(function()
				if delfile then
					delfile(fp)
				end
			end)
			addLog(T("logDeleted"):format(sname), Theme.Warning)
			refreshScriptList()
		end)
	end
end

-- 生成腳本的 API 加載行
local API_LOADER_LINE = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Anime-Expeditions/refs/heads/main/%E5%AF%86%E9%91%B0%E7%B3%BB%E7%B5%B1.lua"))()'

-- 生成腳本表頭要標的「這支追蹤器」的來源, 之後上線時換成實際 raw URL。
local TRACKER_URL_LINE = 'https://raw.githubusercontent.com/Tseting-nil/Anime-Expeditions/refs/heads/main/Tool/%E6%94%BE%E7%BD%AE%E8%BF%BD%E8%B9%A4%E5%99%A8.lua")()'

-- 取這個操作的消耗 (成本版閘門用)。★ UpgradeInfo 的索引是【目標等級】。
local function gateCost(op)
	if not op.unitName then
		return 0
	end
	local ok, cost = pcall(function()
		local U = require(ReplicatedStorage.Shared.Information.Units)
		local u = U[op.unitName]
		local e = u and u.UpgradeInfo and u.UpgradeInfo[op.target or 0]
		if not e then
			local uEvo = U[op.unitName .. "EVO"]
			e = uEvo and uEvo.UpgradeInfo and uEvo.UpgradeInfo[op.target or 0]
		end
		return e and e.Cost or 0
	end)
	return (ok and cost) or 0
end

-- 把 CFrame 拆成「x, y, z, yaw(角度)」四個數字。
--  API 端的 AE.AddPlaceUnit 會用 CFrame.new(Vector3.new(x,y,z)) * CFrame.Angles(0, rad(yaw), 0) 組回去。
local function cfToArgs(cf)
	if typeof(cf) ~= "CFrame" then
		return "0, 0, 0, 0"
	end
	local _, yawRad = cf:ToOrientation()
	local yawDeg = math.deg(yawRad)
	if math.abs(yawDeg) < 0.01 then
		yawDeg = 0
	end
	return string.format("%.3f, %.3f, %.3f, %g", cf.X, cf.Y, cf.Z, yawDeg)
end

-- 把三個 log 合併成一條依時間排序的操作序列
local function buildOperations()
	local ops = {}

	for order, info in pairs(orderToInfo) do
		table.insert(ops, {
			kind = "place",
			order = order,
			elapsed = info.Elapsed or 0,
			seq = info.Seq or 0,
			unitName = info.UnitType,
			slot = info.Slot,
			cframe = info.CFrame,
			target = 0, -- 放置 = 達到 0 等
			mut = getMutLabel(info), -- " [Shiny]" / " [Shiny, Trait:X]" / ""
			backfilled = info.Backfilled,
			shiny = info.Shiny,
			trait = info.Trait,
		})
	end

	for _, e in ipairs(upgradeLog) do
		local order = idToOrder[e.GameID]
		if order then
			table.insert(ops, {
				kind = "upgrade",
				order = order,
				elapsed = e.Elapsed or 0,
				seq = e.Seq or 0,
				unitName = orderToInfo[order] and orderToInfo[order].UnitType,
				target = e.Level, -- 目標等級 = 成本索引
			})
		end
	end

	for _, e in ipairs(sellLog) do
		local order = idToOrder[e.GameID]
		if order then
			table.insert(ops, {
				kind = "sell",
				order = order,
				elapsed = e.Elapsed or 0,
				seq = e.Seq or 0,
				unitName = orderToInfo[order] and orderToInfo[order].UnitType,
			})
		end
	end

	for _, e in ipairs(skipWaveLog) do
		table.insert(ops, {
			kind = "skipwave",
			elapsed = e.Elapsed or 0,
			seq = e.Seq or 0,
			title = e.Title,
		})
	end

	table.sort(ops, function(a, b)
		return a.seq < b.seq
	end)
	return ops
end

local function fmtDuration(sec)
	sec = math.max(0, math.floor(sec or 0))
	return string.format("%dm %ds", math.floor(sec / 60), sec % 60)
end

-- 用過的塔清單 (依首次放置順序, 去重), 附閃亮/天賦註記
-- 顯示成「顯示名稱 (資產名)」: 註解給人看要玩家名, 但保留資產名對照 (腳本 EquipLoadout/AddPlaceUnit 用的是資產名)。
local function usedUnits(ops)
	local seen, list = {}, {}
	for _, op in ipairs(ops) do
		if op.kind == "place" and op.unitName then
			local key = tostring(op.unitName) .. (op.mut or "")
			if not seen[key] then
				seen[key] = true
				local asset = tostring(op.unitName)
				local disp = displayName(op.unitName)
				local label = (disp ~= asset) and string.format("%s (%s)", disp, asset) or asset
				table.insert(list, label .. (op.mut or ""))
			end
		end
	end
	return list
end

-- 生成腳本
local function generateScript()
	local ops = buildOperations()
	if #ops == 0 then
		return nil
	end

	local spd = (script_SpeedMultiplier and script_SpeedMultiplier > 0) and script_SpeedMultiplier or 1
	local costMode = ScriptSettings.CostMode == true
	local totalSec = (gameEndElapsed or getElapsed() or 0) / spd
	local units = usedUnits(ops)

	local backfilled = 0
	for _, op in ipairs(ops) do
		if op.backfilled then
			backfilled = backfilled + 1
		end
	end

	local skipAtStart = (isGameRunning or gameEndElapsed) and gameStartAutoSkipWave or autoSkipState.on

	local L = {}
	local function w(s)
		table.insert(L, s)
	end

	-- ===== 內層腳本 =====
	local B = {}
	local function b(s)
		table.insert(B, s)
	end

	b("--[[")
	b("")
	b(string.format("Map: %s [%s] |  Difficulty: %s  |  Mode: %s", gameSettings.mapId, gameSettings.actName, gameSettings.difficulty, gameSettings.gamemode))
	b(string.format("Time: %s (%.1fs)", fmtDuration(totalSec), totalSec))
	if customComment and customComment ~= "" then
		b("Note: " .. tostring(customComment))
	end
	b("")
	b("Towers used:")
	for _, u in ipairs(units) do
		b("  - " .. u)
	end
	if backfilled > 0 then
		b("")
		b(string.format("註: 其中 %d 座塔是「追蹤器載入前就已在場上」的補記資料 (標記 backfill)。", backfilled))
		b("   順序與相對時間取自伺服器記的 PlacedAt, 是可信的。")
		if gameStartApprox then
			b("   ★ 但開局時刻 (T0) 是【推估值】: 以最早那座塔的放置時刻當 0 秒,")
			b("     真正的開局可能更早 -> 所有時間會整體偏移。要精確請在開局前就載入追蹤器。")
		end
	end
	b("")
	b("]]")
	b("")
	b("-- AE_API")
	b("local AE = getgenv().AE")
	b("if not AE or not AE.ExecuteQueue then")
	b("\t" .. API_LOADER_LINE)
	b("\tAE = getgenv().AE")
	b("end")
	b("")
	b("-- Lobby")
	b("if AE.IsLobby() then")
	b("\tAE.EquipLoadout({ " .. (function()
		-- 依【資產名】去重, 但輸出【顯示名稱|特徵】(API 端會依此裝備正確特徵的塔)
		local seen, q = {}, {}
		for _, op in ipairs(ops) do
			if op.kind == "place" and op.unitName and not seen[op.unitName] then
				seen[op.unitName] = true
				local item = displayName(op.unitName)
				if op.trait and op.trait ~= "" then
					item = item .. "|" .. op.trait
				end
				if op.shiny then
					item = item .. "|Shiny"
				end
				table.insert(q, string.format("%q", item))
			end
		end
		return table.concat(q, ", ")
	end)() .. " })")
	b(string.format(
		"\tAE.SelectMap(%q, %q, %q, %q)",
		gameSettings.mapId,
		gameSettings.difficulty,
		gameSettings.gamemode,
		gameSettings.actName
	))
	b("\treturn")
	b("end")
	b("")
	b("if AE.IsInGame() then")
	b("\t-- initialization")
	b("\tAE.DisplayEndRewards(false)")
	if ScriptSettings.AutoReplay then
		b("\tAE.AutoReplay(true)")
	end
	if ScriptSettings.AutoSkipCheckpoint or gameSettings.gamemode == "Expedition" then
		b("\tAE.Skipcheckpoint(true)")
	end
	b(string.format("\tAE.AddSetSetting(%q, %s, 0)", "AutoSkipWaves", tostring(skipAtStart == true)))
	b("\tAE.AddGameStart()")
	b("\t-- Start")

	for _, op in ipairs(ops) do
		local uName = op.unitName and displayName(op.unitName) or ""
		local nameTag = (uName ~= "") and (uName .. " ") or ""

		-- 閘門: 成本版 = 消耗字串 (API 等 Yen 夠才動作); 時間版 = 開局後秒數
		local gate, tail
		if costMode then
			local cost = gateCost(op)
			gate = (op.kind == "sell" or op.kind == "sellall") and "0" or string.format("%q", tostring(cost))
			tail = string.format(" -- #%d %s$%s", op.order or 0, nameTag, tostring(cost))
		else
			local t = (op.elapsed or 0) / spd
			if timeRoundUp then
				t = math.ceil(t)
			end
			gate = string.format("%.2f", t)
			tail = string.format(" -- #%d %s+%.1fs", op.order or 0, nameTag, t)
		end

		if op.kind == "place" then
			local placeTail = costMode and string.format(" -- #%d $%s", op.order or 0, tostring(gateCost(op))) or string.format(" -- #%d +%.1fs", op.order or 0, (timeRoundUp and math.ceil((op.elapsed or 0) / spd) or ((op.elapsed or 0) / spd)))
			b(string.format(
				"\tAE.AddPlaceUnit(%q, %s, %s)%s%s%s",
				displayName(op.unitName),
				gate,
				cfToArgs(op.cframe),
				placeTail,
				op.mut ~= "" and op.mut or "",
				op.backfilled and " [backfill]" or ""
			))
		elseif op.kind == "upgrade" then
			b(string.format(
				"\tAE.AddUpgradeUnit(%d, %s)%s -> Lv%s",
				op.order,
				gate,
				tail,
				tostring(op.target)
			))
		elseif op.kind == "sell" then
			b(string.format("\tAE.AddSellUnit(%d, %s)%s", op.order, gate, tail))
		elseif op.kind == "skipwave" then
			local titleArg = op.title and string.format("%q", op.title) or "nil"
			b(string.format("\tAE.AddSkipWave(nil, %s) -- +%.1fs", titleArg, (op.elapsed or 0) / spd))
		end
	end

	b("")
	b(string.format("\tAE.AddEnd(%.1f)", totalSec))
	b("\tAE.ExecuteQueue()")
	b('\tprint("[AE] Queue loaded wait start!!")')
	b("end")

	local inner = table.concat(B, "\n")

	-- ===== 外層 =====
	w("--[[")
	w("  Script By: AE(Anime Expeditions) Place Tracker script")
	w("  URL: " .. TRACKER_URL_LINE)
	w(string.format("  Map: %s [%s] |  Difficulty: %s | Mode: %s", gameSettings.mapId, gameSettings.actName, gameSettings.difficulty, gameSettings.gamemode))
	w(string.format("  Time: %s", fmtDuration(totalSec)))
	w("]]")
	w("")
	w("local fullScript = [=[")
	w(inner)
	w("]=]")
	w("")
	w("local AE = getgenv().AE")
	w("if not AE or not AE.ExecuteQueue then")
	w("\t" .. API_LOADER_LINE)
	w("\tAE = getgenv().AE")
	w("end")
	w("")
	w("-- Start")
	w("AE.SaveLocalScript(fullScript)")
	w("loadstring(fullScript)()")

	return table.concat(L, "\n")
end
-- ============================================================
-- 塔能力面板 卡片建構 / 管理函數
-- ============================================================
local abiCardOrder = 0

local function buildAbilityCard(model)
	if abiTowerCards[model] then
		return
	end
	local info = abiLiveTowers[model]
	if not info or not info.abilityKeys or #info.abilityKeys == 0 then
		return
	end

	if abiEmptyLabel then
		abiEmptyLabel.Visible = false
	end

	abiCardOrder = abiCardOrder + 1
	local hasId = info.gameId ~= nil
	local idStr = hasId and tostring(info.gameId) or "?"

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -4, 0, 0)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.BackgroundColor3 = Theme.Surface
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.LayoutOrder = abiCardOrder
	container.ZIndex = 12
	container.Parent = abilityScrollFrame
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = container
	end

	local cardLayout = Instance.new("UIListLayout")
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardLayout.Padding = UDim.new(0, 4)
	cardLayout.Parent = container

	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingTop = UDim.new(0, 8)
	cardPadding.PaddingBottom = UDim.new(0, 8)
	cardPadding.PaddingLeft = UDim.new(0, 8)
	cardPadding.PaddingRight = UDim.new(0, 8)
	cardPadding.Parent = container

	local widgets = {}
	local saved = info.savedAutoStates or {}

	for idx, key in ipairs(info.abilityKeys) do
		local abi = getAbiData(key)
		local capturedKey = key
		local capturedCd = abi.Cooldown
		local autoEnabled = saved[key] == true

		local abiLabel = Instance.new("TextLabel")
		abiLabel.Size = UDim2.new(1, 0, 0, 22)
		abiLabel.BackgroundTransparency = 1
		abiLabel.Text = string.format(
			"#%d  %s  [ID: %s]    %s",
			info.order,
			info.name,
			idStr,
			T("abilityFmt"):format(abi.Name, abi.Cooldown)
		)
		abiLabel.TextColor3 = Theme.Accent
		abiLabel.Font = Theme.FontBold
		abiLabel.TextSize = 14
		abiLabel.TextXAlignment = Enum.TextXAlignment.Left
		abiLabel.TextTruncate = Enum.TextTruncate.AtEnd
		abiLabel.LayoutOrder = idx * 10
		abiLabel.ZIndex = 13
		abiLabel.Parent = container

		local btnRow = Instance.new("Frame")
		btnRow.Size = UDim2.new(1, 0, 0, 30)
		btnRow.BackgroundTransparency = 1
		btnRow.LayoutOrder = idx * 10 + 1
		btnRow.ZIndex = 13
		btnRow.Parent = container

		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(0.65, -4, 1, 0)
		barBg.Position = UDim2.new(0, 0, 0, 0)
		barBg.BackgroundColor3 = Theme.SurfaceHighlight
		barBg.BorderSizePixel = 0
		barBg.ZIndex = 14
		barBg.ClipsDescendants = true
		barBg.Parent = btnRow
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = barBg
		end

		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.new(1, 0, 1, 0)
		barFill.BackgroundColor3 = Theme.Success
		barFill.BorderSizePixel = 0
		barFill.ZIndex = 15
		barFill.Parent = barBg
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = barFill
		end

		local barText = Instance.new("TextLabel")
		barText.Size = UDim2.new(1, 0, 1, 0)
		barText.BackgroundTransparency = 1
		barText.Text = hasId and T("abilityReady") or T("abilityWaitId")
		barText.TextColor3 = Theme.Text
		barText.Font = Theme.FontBold
		barText.TextSize = 12
		barText.ZIndex = 16
		barText.Parent = barBg

		local fireBtn = Instance.new("TextButton")
		fireBtn.Size = UDim2.new(0.65, -4, 1, 0)
		fireBtn.Position = UDim2.new(0, 0, 0, 0)
		fireBtn.BackgroundTransparency = 1
		fireBtn.Text = ""
		fireBtn.TextColor3 = hasId and Theme.Text or Theme.TextDim
		fireBtn.Font = Theme.FontBold
		fireBtn.TextSize = 13
		fireBtn.BorderSizePixel = 0
		fireBtn.ZIndex = 17
		fireBtn.Parent = btnRow

		fireBtn.MouseButton1Click:Connect(function()
			invokeTowerAbilitySafely(model, capturedKey, capturedCd)
		end)

		local autoState = {
			enabled = autoEnabled,
		}
		local autoBtn = Instance.new("TextButton")
		autoBtn.Size = UDim2.new(0.35, -4, 1, 0)
		autoBtn.Position = UDim2.new(0.65, 4, 0, 0)
		autoBtn.BackgroundColor3 = autoState.enabled and Theme.Success or Theme.SurfaceHighlight
		autoBtn.Text = T("abilityAutoLabel") .. (autoState.enabled and " ✓" or "")
		autoBtn.TextColor3 = autoState.enabled and Theme.TextDark or Theme.TextDim
		autoBtn.Font = Theme.FontBold
		autoBtn.TextSize = 13
		autoBtn.BorderSizePixel = 0
		autoBtn.ZIndex = 17
		autoBtn.Parent = btnRow
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = autoBtn
		end

		autoBtn.MouseButton1Click:Connect(function()
			autoState.enabled = not autoState.enabled
			autoBtn.BackgroundColor3 = autoState.enabled and Theme.Success or Theme.SurfaceHighlight
			autoBtn.Text = T("abilityAutoLabel") .. (autoState.enabled and " ✓" or "")
			autoBtn.TextColor3 = autoState.enabled and Theme.TextDark or Theme.TextDim
		end)

		if idx < #info.abilityKeys then
			local sep = Instance.new("Frame")
			sep.Size = UDim2.new(1, 0, 0, 1)
			sep.BackgroundColor3 = Theme.Border
			sep.BackgroundTransparency = 0.5
			sep.BorderSizePixel = 0
			sep.LayoutOrder = idx * 10 + 3
			sep.ZIndex = 13
			sep.Parent = container
		end

		table.insert(widgets, {
			barFill = barFill,
			barText = barText,
			fireBtn = fireBtn,
			autoBtn = autoBtn,
			autoState = autoState,
			autoFiredAt = nil,
			key = capturedKey,
			cd = capturedCd,
			abiName = abi.Name,
			abiLabel = abiLabel,
		})
	end

	info.savedAutoStates = nil
	abiTowerCards[model] = {
		container = container,
		widgets = widgets,
	}
end

local function removeAbilityCard(model)
	local card = abiTowerCards[model]
	if not card then
		return
	end
	if abiLiveTowers[model] then
		local saved = {}
		for _, w in ipairs(card.widgets) do
			saved[w.key] = w.autoState.enabled
		end
		abiLiveTowers[model].savedAutoStates = saved
	end
	card.container:Destroy()
	abiTowerCards[model] = nil

	if not next(abiTowerCards) and abiEmptyLabel then
		abiEmptyLabel.Visible = true
	end
end

-- 實作 forward-declared rebuildAllAbilityCards
rebuildAllAbilityCards = function()
	for model in pairs(abiTowerCards) do
		removeAbilityCard(model)
	end
	for model in pairs(abiLiveTowers) do
		buildAbilityCard(model)
	end
end

local function abiBindGameId(model, gameId)
	local info = abiLiveTowers[model]
	if not info or info.gameId ~= nil then
		return
	end
	info.gameId = gameId
	abiModelByGameId[gameId] = model
	if abiGameIdCooldownHint[gameId] then
		for k, t0 in pairs(abiGameIdCooldownHint[gameId]) do
			info.cooldowns[k] = t0
		end
		abiGameIdCooldownHint[gameId] = nil
	end
	if abiTowerCards[model] then
		removeAbilityCard(model)
		buildAbilityCard(model)
	end
end

-- 空提示標籤
abiEmptyLabel = Instance.new("TextLabel")
abiEmptyLabel.Size = UDim2.new(1, -10, 0, 40)
abiEmptyLabel.BackgroundTransparency = 1
abiEmptyLabel.Text = T("abilityNoTowers")
abiEmptyLabel.TextColor3 = Theme.TextDim
abiEmptyLabel.Font = Theme.Font
abiEmptyLabel.TextSize = Theme.SizeNormal
abiEmptyLabel.ZIndex = 12
abiEmptyLabel.LayoutOrder = 9999
abiEmptyLabel.Parent = abilityScrollFrame

-- ============================================================
-- [已移除] 塔能力回調
-- ============================================================
-- 原 GTD 版的 onAbilityPlaceTower / onAbilitySellTower / onAbilityTowerAbility,
-- 由 namecall hook 在攔到 PlaceTower / SellTower / TowerAbility 時呼叫,
-- 負責把 remote 回傳的 gameId 綁到掃描器找到的塔模型上 (abiModelByGameId)。
--
-- 動漫遠征沒有這些 remote -> 移除。等效邏輯改由檔尾的 Tracker.On* 提供,
-- 由未來的 ReplicaSignal Adapter 呼叫。見檔頭 [階段 2/3]。
-- ============================================================
-- 按鈕事件
-- ============================================================
copyBtn.MouseButton1Click:Connect(function()
	local s = generateScript()
	if s then
		local ok = pcall(setclipboard, s)
		if ok then
			addLog(T("logCopyOk"), Color3.fromRGB(100, 255, 100))
			copyBtn.Text = T("btnCopied")
			copyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
			print("\n========== Generated Script ==========")
			print(s)
			print("=======================================\n")
			task.wait(2)
			copyBtn.Text = T("btnCopy")
			copyBtn.BackgroundColor3 = Theme.Success
		else
			addLog(T("logCopyConsole"), Theme.Warning)
			print(s)
		end
	end
end)

saveBtn.MouseButton1Click:Connect(openSavePanel)

confirmSaveBtn.MouseButton1Click:Connect(function()
	local fileName = fileNameInput.Text:gsub("[^%w_%-]", "_")
	if fileName == "" or fileName:match("^_+$") then
		addLog(T("logInvalidName"), Theme.Warning)
		return
	end
	local s = generateScript()
	if s then
		local ok = saveScriptToFile(fileName, s)
		if ok then
			saveFrame.Visible = false
		end
	end
end)

cancelSaveBtn.MouseButton1Click:Connect(function()
	saveFrame.Visible = false
end)
saveCloseBtn.MouseButton1Click:Connect(function()
	saveFrame.Visible = false
end)
manageCloseBtn.MouseButton1Click:Connect(function()
	manageFrame.Visible = false
end)
closeBtn.MouseButton1Click:Connect(function()
	parameterFrame.Visible = false
end)
abilityCloseBtn.MouseButton1Click:Connect(function()
	abilityFrame.Visible = false
end)
refreshScriptsBtn.MouseButton1Click:Connect(function()
	refreshScriptList()
end)

Parameter.MouseButton1Click:Connect(function()
	if not parameterFrame.Visible then
		closeBlockingPanels()
		parameterFrame.Position = UDim2.new(
			mainFrame.Position.X.Scale,
			mainFrame.Position.X.Offset + mainFrame.AbsoluteSize.X + 10,
			mainFrame.Position.Y.Scale,
			mainFrame.Position.Y.Offset
		)
		parameterFrame.Visible = true
		if abilityFrame.Visible then
			positionAbilityFrame()
		end
	else
		parameterFrame.Visible = false
		if abilityFrame.Visible then
			positionAbilityFrame()
		end
	end
end)

abilityBtn.MouseButton1Click:Connect(function()
	if not abilityFrame.Visible then
		closeBlockingPanels()
		positionAbilityFrame()
		abilityFrame.Visible = true
	else
		abilityFrame.Visible = false
	end
end)

resetBtn.MouseButton1Click:Connect(function()
	nextOrder = 1
	orderToInfo = {}
	idToOrder = {}
	upgradeLog = {}
	sellLog = {}
	skipWaveLog = {}
	speedChangeLog = {}
	abilityLog = {}
	gameSettingLog = {}
	gameStartAutoSkipWave = false
	lastDetectedSpeed = 1
	local sessTime = getSessionTime and getSessionTime() or nil
	if sessTime then
		isGameRunning = true
		gameStartSession = sessTime
	else
		isGameRunning = false
		gameStartSession = nil
	end
	gameStartApprox = false
	gameEndElapsed = nil
	gameStartMapId = nil
	mapTransitionLog = {}
	readyHooked = false

	-- 重置能力面板
	for model in pairs(abiTowerCards) do
		removeAbilityCard(model)
	end
	abiLiveTowers = {}
	abiModelByGameId = {}
	abiPendingGameIds = {}
	abiGameIdCooldownHint = {}
	abiRemoteInFlight = {}
	abiNextOrder = 1
	abiCardOrder = 0
	if abiEmptyLabel then
		abiEmptyLabel.Visible = true
	end

	-- 改由 Adapter 從 GameState replica 回填。
	pcall(function()
		Adapter.ReadGameSettings()
	end)

	for _, child in pairs(scrollFrame:GetChildren()) do
		child:Destroy()
	end
	listLayout:Destroy()
	listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = scrollFrame
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
	logOrder = 1

	updateInfoLabel()
	addLog(T("logReset"), Color3.fromRGB(100, 200, 255))
end)

debugBtn.MouseButton1Click:Connect(function()
	addLog(T("logTowerListHdr"), Color3.fromRGB(100, 200, 255))
	if nextOrder <= 1 then
		addLog(T("logNoRecord"), Theme.TextDim)
	else
		for order = 1, nextOrder - 1 do
			local info = orderToInfo[order]
			if info then
				addLog(
					T("logTowerItem"):format(
						info.order,
						displayName(info.UnitType) .. getMutLabel(info),
						tostring(info.GameID),
						info.Elapsed or 0
					),
					Color3.fromRGB(200, 200, 200)
				)
			end
		end
	end
end)

-- F8 切換顯示
UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.F8 and not gp then
		uiVisible = not uiVisible
		mainFrame.Visible = uiVisible
		if not uiVisible then
			closeAllPanels()
		end
	end
end)

-- ============================================================
-- Tracker API  --  GUI 與遊戲之間的唯一接縫
-- ============================================================
-- 設計: Adapter (偵測遊戲事件) --呼叫--> Tracker.On* (寫資料模型 + 驅動 GUI)
-- GUI 只讀資料模型, 不直接碰任何 remote。要接動漫遠征只需實作 Adapter + 填好 Tracker.On*。
--
-- 資料模型 (已保留, 目前不會被寫入):
--   nextOrder / orderToInfo / idToOrder  -- 放置記錄, orderToInfo[order] = {order, UnitType, GameID, UUID, Elapsed, ...}
--   upgradeLog / sellLog / skipWaveLog / speedChangeLog / abilityLog / gameSettingLog
--   isGameRunning / gameStartTime / gameStartMapId / mapTransitionLog
--   abiLiveTowers / abiTowerCards / abiModelByGameId / abiPendingGameIds

-- 日誌尾巴的 [時間|金錢]。兩個都顯示: 成本版與時間版看的是不同軸, 錄製時兩邊都想知道。
local function fmtGate(elapsed, unitName, targetLevel)
	local cost
	pcall(function()
		local U = require(ReplicatedStorage.Shared.Information.Units)
		local u = U[unitName]
		local e = u and u.UpgradeInfo and u.UpgradeInfo[targetLevel or 0]
		if not e then
			local uEvo = U[unitName .. "EVO"]
			e = uEvo and uEvo.UpgradeInfo and uEvo.UpgradeInfo[targetLevel or 0]
		end
		cost = e and e.Cost
	end)
	if cost then
		return string.format("+%.1fs | $%d", elapsed or 0, cost)
	end
	return string.format("+%.1fs", elapsed or 0)
end

function Tracker.NotImplemented(what)
	if not Tracker._warned[what] then
		Tracker._warned[what] = true
		warn(string.format("[放置追蹤器] %s 尚未接上動漫遠征, 見檔頭計畫", what))
		pcall(addLog, T("logNotImplemented"):format(what), Theme.Warning)
	end
	return nil
end

-- Adapter 偵測到放置時呼叫 (來源: ReplicaClient.OnNew GameUnit/GamePhantom)
-- unitName: 單位內部名; gameId: 伺服器建立的實例 id; cframe: 伺服器吸附後的位置
function Tracker.OnPlace(unitName, gameId, cframe, extra)
	if not isGameRunning then
		startGameTimer(gameSettings.mapId)
	end
	local order = nextOrder
	nextOrder = nextOrder + 1
	local elapsed = elapsedFromPlacedAt(extra and extra.placedAt) or getElapsed()
	orderToInfo[order] = {
		order = order,
		UnitType = unitName,
		GameID = gameId,
		UUID = extra and extra.uuid or nil,
		CFrame = cframe,
		Elapsed = elapsed,
		PlacedAt = extra and extra.placedAt or nil,
		Seq = nextSeq(),
		Shiny = extra and extra.shiny or nil,
		Trait = extra and extra.trait or nil,
		Backfilled = extra and extra.backfilled or nil,
	}
	if gameId then
		idToOrder[gameId] = order
	end
	-- 放置 [腳本內標記ID] [塔名稱] [當局遊戲ID] [時間|金錢]
	addLog(
		T("logPlaceFmt"):format(
			order,
			displayName(unitName) .. getMutLabel(orderToInfo[order]),
			tostring(gameId),
			fmtGate(elapsed, unitName, 0) -- 放置 = 達到 0 等 (成本查表用資產名)
		),
		Theme.Success
	)
	return order
end

-- 來源: aeWatchUpgrades 的 replica:OnChange (伺服器自動升級不送封包)
function Tracker.OnUpgrade(gameId, level)
	local elapsed = getElapsed()
	table.insert(upgradeLog, { GameID = gameId, Level = level, Elapsed = elapsed, Seq = nextSeq() })
	-- 升級 [塔名稱] [腳本內標記ID] [時間|金錢]
	local order = idToOrder[gameId]
	local info = order and orderToInfo[order]
	local name = (info and info.UnitType) or "?"
	addLog(
		T("logUpgradeFmt"):format(
			displayName(name) .. (info and getMutLabel(info) or ""),
			tostring(order or T("logUntracked")),
			fmtGate(elapsed, name, level) -- 成本索引 = 目標等級 (查表用資產名 name)
		),
		Theme.Accent
	)
end

-- SellGameUnit / SellAllGameUnits
function Tracker.OnSell(gameId)
	local elapsed = getElapsed()
	table.insert(sellLog, { GameID = gameId, Elapsed = elapsed, Seq = nextSeq() })
	local order = idToOrder[gameId]
	local info = order and orderToInfo[order]
	addLog(
		T("logSellFmt"):format(
			displayName((info and info.UnitType) or "?") .. (info and getMutLabel(info) or ""),
			tostring(order or T("logUntracked")),
			string.format("+%.1fs", elapsed) -- 賣出不花錢
		),
		Theme.Warning
	)
end

-- 玩家接受了 "Start Game?" 投票 -> 波次開始 (wave 0->1, GameTime 開始走)
function Tracker.OnGameStarted()
	addLog(T("logGameStarted"), Theme.Success)
end

-- 玩家接受了跳波投票。title = 該投票的 Title (實機抓到後可用來精確比對)
function Tracker.OnSkipWave(title)
	local elapsed = getElapsed()
	table.insert(skipWaveLog, { Elapsed = elapsed, Seq = nextSeq(), Title = title })
	addLog(T("logSkipWaveFmt"):format(string.format("+%.1fs", elapsed)), Theme.Purple)
end

-- ⚠ 目前【沒有任何地方會呼叫這個】: 能力偵測 (階段 3) 尚未接上, 見檔頭。
function Tracker.OnAbility(gameId, abilityKey)
	table.insert(abilityLog, { GameID = gameId, Ability = abilityKey, Elapsed = getElapsed() })
end

-- 來源: GameState 的 CurrentGameState 變化 (★ 不看 Data.Active -- 準備階段它也是 false)
function Tracker.OnGameStart(mapId)
	startGameTimer(mapId)
	updateInfoLabel()
	-- ★ 準備階段的「遊戲開始」不顯示 (只默默啟動計時器);
	--   真正對玩家有意義的「開始」由 OnGameStarted (接受 Start Game? 投票) 記一次即可。
end

function Tracker.OnGameEnd()
	if not isGameRunning then
		return
	end
	gameEndElapsed = getElapsed()
	isGameRunning = false
	gameStartSession = nil
	stopAbilityRemoteTriggers()
	local el = gameEndElapsed or 0
	addLog(T("logGameEnd"):format(math.floor(el / 60), math.floor(el % 60), el), Theme.Warning)
end

-- ============================================================
-- Adapter  --  動漫遠征專用
-- ============================================================
--   關卡內操作走 ReplicaService: ReplicaSignal:FireServer(replicaId, signalName, ...args)
--     arg1 = replica id (每局重生)   arg2 = signal 名   arg3+ = 參數
--   remote 位置: ReplicatedStorage.RemoteEvents.ReplicaSignal
--   相關模組:    ReplicatedStorage.Shared.ReplicaClient / UnitUtils / Information.*
local AE = {
	pending = {}, -- 送出 PlaceGameUnit 後、等待伺服器建立 replica 的佇列
	seenId = {}, -- gameId -> true      已記錄過的塔, 防重複
	seenSpot = {}, -- 位置key -> order   幽靈實體化時用來認出「同一座塔」
	watched = {}, -- replica -> true    已掛上升級監聽, 防重複掛
	voteTitles = {}, -- voteId -> Title  投票回應後 replica 會被 AutoDestroy, 要先記下 Title
	hooked = false,
	backfilling = nil, -- true 時代表正在補記「載入前就在場上的塔」(時間/順序不可信)
}

-- 執行器跑 identity 8, require 遊戲模組前要降到 2
local function aeRequire(inst)
	if not inst then
		return nil
	end
	local prev = getthreadidentity and getthreadidentity() or nil
	if setthreadidentity then
		setthreadidentity(2)
	end
	local ok, mod = pcall(require, inst)
	if setthreadidentity and prev then
		setthreadidentity(prev)
	end
	if not ok then
		warn("[放置追蹤器] require 失敗: " .. tostring(inst) .. " -> " .. tostring(mod))
		return nil
	end
	return mod
end

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local ReplicaClient = Shared and aeRequire(Shared:FindFirstChild("ReplicaClient"))
local SettingsDefault = Shared
	and aeRequire(
		Shared:FindFirstChild("Information")
			and Shared.Information:FindFirstChild("Settings")
			and Shared.Information.Settings:FindFirstChild("Default")
	)
local ReplicaSignal = (function()
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	return re and re:FindFirstChild("ReplicaSignal")
end)()

local LocalPlayer = Players.LocalPlayer

-- Nodes 層 (只有「改遊戲設定」會用到, 其餘操作都走 ReplicaService)
local aeNodes = nil
local function aeGetNodes()
	if aeNodes == nil then
		aeNodes = aeRequire(ReplicatedStorage:FindFirstChild("Nodes")) or false
	end
	return aeNodes or nil
end

-- === Replica 查詢小工具 ===
local function aeReplicas()
	if not ReplicaClient then
		return {}
	end
	local ok, t = pcall(function()
		return ReplicaClient.Test().Replicas
	end)
	return (ok and type(t) == "table") and t or {}
end

local function aeFind(token, pred)
	for _, r in pairs(aeReplicas()) do
		if r.Token == token and r.Data and (not pred or pred(r)) then
			return r
		end
	end
	return nil
end

-- 緩存中有兩個 HotbarData, 作用中的是 PlacementAllowed == true 的那個
local function aeHotbar()
	return aeFind("HotbarData", function(r)
		return r.Data.PlacementAllowed == true
	end)
end

-- UnitID 格式為 "Luffy#78d90e32-..." -> 取出塔名
local function aeAssetOf(unitID)
	return unitID and tostring(unitID):match("^([^#]+)") or nil
end

-- 塔名。GameUnit 與 GamePhantom 的 Data.UnitData.Asset 都有 (已實測),
-- 但 UnitID 一定存在且格式固定, 拿它當主要來源最保險。
local function aeUnitName(replica)
	local d = replica.Data
	return aeAssetOf(d.UnitID) or (d.UnitData and d.UnitData.Asset) or "Unknown"
end

-- 閃亮 / 天賦。
-- 主要來源是塔自己的 UnitData (實測閃亮塔放下去後 UnitData.Shiny = true),
-- 背包 (PlayerData.UnitData[UnitID]) 當後備 -- 兩邊都查, 對 GameUnit 與 GamePhantom 都成立。
local function aeMutationsOf(replica)
	local d = replica.Data
	local ud = d.UnitData or {}
	local shiny, trait = ud.Shiny, ud.Trait
	if shiny == nil or trait == nil then
		local pd = aeFind("PlayerData")
		local e = pd and (pd.Data.UnitData or {})[tostring(d.UnitID)]
		if e then
			if shiny == nil then
				shiny = e.Shiny
			end
			if trait == nil then
				trait = e.Trait
			end
		end
	end
	return shiny == true, (type(trait) == "string" and trait ~= "") and trait or nil
end

local function aeSlotAsset(slot)
	local hb = aeHotbar()
	if not hb then
		return nil
	end
	local s = hb.Data.Slots and hb.Data.Slots[slot]
	return s and aeAssetOf(s.ID) or nil
end

local function aeSpotKey(name, cf)
	if not cf then
		return nil
	end
	local p = cf.Position
	-- 忽略 Y 軸：避免 GamePhantom (幽靈塔) 轉實體 GameUnit 時因地形/碰撞箱微調 (如 Y 軸差 0.5) 導致去重 Key 不相符而重複錄製
	return string.format("%s@%.1f,%.1f", tostring(name), p.X, p.Z)
end

-- === 升級偵測 ===
local function aeWatchUpgrades(replica)
	if AE.watched[replica] then
		return
	end
	AE.watched[replica] = true
	local last = replica.Data and replica.Data.Upgrade or 0
	pcall(function()
		replica:OnChange(function()
			local d = replica.Data
			if not d then
				return
			end
			local now = d.Upgrade
			if now == last or type(now) ~= "number" then
				return
			end
			last = now
			queueHookTask(function()
				Tracker.OnUpgrade(tostring(d.ID), now)
			end)
		end)
	end)
end

-- === 放置偵測 ===
-- ★ 過濾「召喚物 / 分身」: 母體技能召喚的單位 (如 Cursed Student=Yuta 的 YutaBatSpirit) 也是
--   Owner=自己的 GameUnit, 而且【沿用母體的 UnitID 與 GameID】-> 只看 UnitID/名稱會被誤記成新放置,
--   錄出來的塔數就會超過放置上限 (實機: PlacementCounts[Yuta]=1 但冒出 3 個 UnitID=Yuta# 的 GameUnit)。
--   實機驗證兩個乾淨判準 (真身兩者皆否 / 召喚物兩者皆是), 取 OR 最保險:
--     ① d.IsClone == true               (召喚物專有旗標)
--     ② UnitData.Asset ~= UnitID 的資產名 (母體 Asset=Yuta; 召喚物 Asset=YutaBatSpirit)
local function aeIsClone(d)
	if d.IsClone == true then
		return true
	end
	-- ⚠ 只有 UnitID 與 UnitData.Asset【兩者都有值】且確實不同才算召喚物。
	--   OnNew 當下 UnitID 常常還沒填 -> idAsset=nil；此時絕不能因「Asset≠nil」把真身誤判成召喚物
	--   (那會把所有塔都濾掉、追蹤器一個塔都顯示不出來)。IsClone 那條才是主判準。
	local realAsset = d.UnitData and d.UnitData.Asset
	local idAsset = aeAssetOf(d.UnitID)
	if type(realAsset) == "string" and type(idAsset) == "string" and realAsset ~= idAsset and realAsset ~= idAsset .. "EVO" then
		return true
	end
	return false
end

local function aeOnNewUnit(replica)
	local d = replica.Data
	if not d or d.Owner ~= LocalPlayer then
		return
	end
	-- 召喚物/分身不是玩家放置 -> 完全略過 (不記錄、也不掛升級監聽)
	if aeIsClone(d) then
		return
	end

	aeWatchUpgrades(replica)

	local gid = tostring(d.ID)
	if AE.seenId[gid] then
		return -- 同一顆 replica 重複觸發
	end

	local name = aeUnitName(replica)
	local key = aeSpotKey(name, d.CFrame)

	-- 幽靈實體化(幽靈轉實體時 replica 會換一顆, ID 可能改變 -> 把新 ID 指回原本的 order)
	local prevOrder = key and AE.seenSpot[key]
	if prevOrder then
		AE.seenId[gid] = true
		idToOrder[gid] = prevOrder
		local info = orderToInfo[prevOrder]
		if info then
			info.GameID = gid
			info.IsPhantom = (replica.Token == "GamePhantom") or nil
		end
		return
	end

	AE.seenId[gid] = true

	-- 配對出這座塔是從哪個槽位放的 (取最舊的同名待決放置)
	local slot
	for i, p in ipairs(AE.pending) do
		if p.unitName == name then
			slot = p.slot
			table.remove(AE.pending, i)
			break
		end
	end

	local shiny, trait = aeMutationsOf(replica)
	local order = Tracker.OnPlace(name, gid, d.CFrame, {
		uuid = d.UnitID,
		slot = slot,
		isPhantom = replica.Token == "GamePhantom",
		shiny = shiny,
		trait = trait,
		-- 伺服器記的放置時刻 (SessionTime 時鐘)。補記時靠它還原真實時間與順序。
		placedAt = tonumber(d.PlacedAt),
		backfilled = AE.backfilling or nil,
	})

	if order then
		if key then
			AE.seenSpot[key] = order
		end
		local info = orderToInfo[order]
		if info then
			info.Slot = slot
			info.IsPhantom = (replica.Token == "GamePhantom") or nil
		end
	end
end

-- === 送出封包的解析 ===
local function aeHandleSignal(args)
	local signalName = args[2]
	if type(signalName) ~= "string" then
		return
	end

	if signalName == "PlaceGameUnit" then
		local slot, cf = args[3], args[4]
		table.insert(AE.pending, {
			slot = slot,
			cframe = cf,
			unitName = aeSlotAsset(slot),
			t = tick(),
		})
		-- 逾時清理: 放置被伺服器拒絕 (座標不合法/超過上限) 時不會有 replica 進來
		for i = #AE.pending, 1, -1 do
			if tick() - AE.pending[i].t > 10 then
				table.remove(AE.pending, i)
			end
		end
	elseif signalName == "Response" then
		-- 投票回應。用 Title 區分: 同一個 VotePrompt token 承載「開始遊戲」「跳波」等多種投票,
		--  不分辨就會把兩者混為一談。Title 是 OnNew 時記下來的 (回應後 replica 會被 AutoDestroy)。
		local title = AE.voteTitles[tostring(args[1])] or "?"
		if args[3] == true then
			if title:lower():find("start game") then
				Tracker.OnGameStarted()
			else
				Tracker.OnSkipWave(title)
			end
		end
	elseif signalName == "SellGameUnit" then
		Tracker.OnSell(tostring(args[3]))
	elseif signalName == "SellAllGameUnits" then
		for _, r in pairs(aeReplicas()) do
			if r.Token == "GameUnit" and r.Data and r.Data.Owner == LocalPlayer and not aeIsClone(r.Data) then
				Tracker.OnSell(tostring(r.Data.ID))
			end
		end
	end
	-- SelectSlot: 純 UI 選取, 伺服器放置只讀參數裡的槽位 (已實證) -> 不記錄
end

function getSessionTime()
	local g = aeFind("GameState")
	return g and tonumber(g.Data.SessionTime) or nil
end

local AE_GAME_OVER_STATES = { Victory = true, Lose = true, Defeat = true }

-- === 關卡狀態 ===
local function aeApplyGameState(r)
	local d = r and r.Data
	if not d then
		return
	end
	local p = d.Parameters or {}
	gameSettings.mapId = tostring(p.MapName or "Unknown")
	gameSettings.difficulty = tostring(p.Difficulty or "Unknown")
	gameSettings.gamemode = tostring(p.Gamemode or "Story")
	gameSettings.actName = tostring(p.ActName or "Act 1")
	gameSettings.modifier = string.format("%s / %s", gameSettings.gamemode, gameSettings.actName)

	local state = d.CurrentGameState
	if state == "InProgress" then
		if not isGameRunning then
			Tracker.OnGameStart(gameSettings.mapId)
		end
	elseif isGameRunning and AE_GAME_OVER_STATES[tostring(state)] then
		Tracker.OnGameEnd()
	end
	pcall(updateInfoLabel)
end

function Adapter.Init()
	if not ReplicaClient or not ReplicaSignal then
		warn("[放置追蹤器] 找不到 ReplicaClient / ReplicaSignal, Adapter 未啟動")
		pcall(addLog, T("logAdapterFailed"), Theme.Error)
		return
	end
	if AE.hooked then
		return
	end
	AE.hooked = true

	-- 1) 監聽伺服器建立的塔 (實體 + 幽靈)
	pcall(function()
		ReplicaClient.OnNew("GameUnit", function(r)
			queueHookTask(function()
				aeOnNewUnit(r)
			end)
		end)
		ReplicaClient.OnNew("GamePhantom", function(r)
			queueHookTask(function()
				aeOnNewUnit(r)
			end)
		end)
	end)

	-- 2) 關卡狀態
	pcall(function()
		ReplicaClient.OnNew("GameState", function(r)
			queueHookTask(function()
				aeApplyGameState(r)
			end)
			pcall(function()
				r:OnChange(function()
					queueHookTask(function()
						aeApplyGameState(r)
					end)
				end)
			end)
		end)
	end)

	-- 3) 攔送出的 ReplicaSignal
	local ok = pcall(function()
		local mt = getrawmetatable(game)
		local oldNamecall = mt.__namecall
		setreadonly(mt, false)
		mt.__namecall = newcclosure(function(self, ...)
			if self == ReplicaSignal and getnamecallmethod() == "FireServer" then
				local args = table.pack(...)
				queueHookTask(function()
					pcall(aeHandleSignal, args)
				end)
			end
			return oldNamecall(self, ...)
		end)
		setreadonly(mt, true)
	end)
	if not ok then
		warn("[放置追蹤器] __namecall hook 失敗, 升級/賣出/槽位將記錄不到")
		pcall(addLog, T("logHookFailed"), Theme.Warning)
	end

	-- 4) 監聽伺服器回傳的設定變更 (Nodes 層)
	-- 線路格式: _updateNode.OnClientEvent("PLAYER_SETTING_CHANGED", 1, Player, 設定名, 值)
	pcall(function()
		local net = ReplicatedStorage:FindFirstChild("Nodes")
		net = net and net:FindFirstChild("Network")
		net = net and net:FindFirstChild("NetworkEvents")
		local updateNode = net and net:FindFirstChild("_updateNode")
		if not updateNode then
			warn("[放置追蹤器] 找不到 _updateNode, 設定變更不會即時反映")
			return
		end
		updateNode.OnClientEvent:Connect(function(node, _seq, player, settingName, value)
			if node ~= "PLAYER_SETTING_CHANGED" then
				return
			end
			if player ~= LocalPlayer or settingName ~= "AutoSkipWaves" then
				return
			end
			queueHookTask(function()
				autoSkipState.on = (value == true)
				pcall(updateInfoLabel)
				-- 校正面板開關 (不觸發 callback, 否則會把設定再送一次回去形成迴圈)
				if autoSkipToggle then
					pcall(autoSkipToggle.set, value == true)
				end
				addLog(value and T("logAutoSkipOn") or T("logAutoSkipOff"), value and Theme.Success or Theme.TextDim)
			end)
		end)
	end)

	-- 5) 投票偵測 (開始遊戲 / 跳波) 投票 UI 是【共用】的: 開始遊戲、跳波…都走同一個 VotePrompt token,
	--   遊戲自己的 MountNotifications 也是靠 ReplicaClient.OnNew("VotePrompt") 掛 UI。
	pcall(function()
		ReplicaClient.OnNew("VotePrompt", function(r)
			queueHookTask(function()
				AE.voteTitles[tostring(r.Id)] = tostring(((r.Data or {}).Parameters or {}).Title or "?")
			end)
		end)
	end)

	-- 6) 補記已經在場上的塔 (腳本中途載入)
	--   靠塔的 Data.PlacedAt (= 放置當下的 SessionTime) 還原真實順序與時間。
	--   先依 PlacedAt 排序再補記 -- pairs() 掃 replica 是無序的, 不排就會得到隨機順序。
	pcall(function()
		local mine = {}
		for _, r in pairs(aeReplicas()) do
			if (r.Token == "GameUnit" or r.Token == "GamePhantom") and r.Data and r.Data.Owner == LocalPlayer then
				table.insert(mine, r)
			end
		end
		if #mine == 0 then
			return
		end
		table.sort(mine, function(a, b)
			return (tonumber(a.Data.PlacedAt) or 0) < (tonumber(b.Data.PlacedAt) or 0)
		end)

		-- 校正
		local first = tonumber(mine[1].Data.PlacedAt)
		if first and (not gameStartSession or first < gameStartSession) then
			gameStartSession = first
			gameStartApprox = true
			isGameRunning = true
			gameStartMapId = gameStartMapId or gameSettings.mapId
		end

		AE.backfilling = true
		for _, r in ipairs(mine) do
			aeOnNewUnit(r)
		end
		AE.backfilling = nil
	end)
end

local function aeGetSetting(name)
	local pd = aeFind("PlayerData")
	local v = pd and (pd.Data.Settings or {})[name]
	if v ~= nil then
		return v
	end
	return SettingsDefault and SettingsDefault[name]
end

-- ★ 設定走 Nodes 層 (CLIENT_CHANGE_SETTING)
function Adapter.SetAutoSkipWaves(v)
	local Nodes = aeGetNodes()
	if not Nodes then
		warn("[放置追蹤器] 找不到 Nodes, 無法改設定")
		return false
	end
	local ok = pcall(function()
		Nodes["CLIENT_CHANGE_SETTING"]:FireServer("AutoSkipWaves", v == true)
	end)
	if ok then
		-- 樂觀更新; 伺服器的 PLAYER_SETTING_CHANGED 回來時會再校正一次
		autoSkipState.on = (v == true)
		pcall(updateInfoLabel)
	end
	return ok
end

function Adapter.ReadGameSettings()
	local gs = aeFind("GameState")
	if gs then
		aeApplyGameState(gs)
	end
	-- 回填自動跳波狀態
	pcall(function()
		autoSkipState.on = (aeGetSetting("AutoSkipWaves") == true)
	end)
end

function Adapter.ScanPlacedUnits()
	local list = {}
	for _, r in pairs(aeReplicas()) do
		if (r.Token == "GameUnit" or r.Token == "GamePhantom") and r.Data and r.Data.Owner == LocalPlayer then
			table.insert(list, r)
		end
	end
	return list
end

-- 啟動
pcall(Adapter.ReadGameSettings)
if autoSkipToggle then
	pcall(autoSkipToggle.set, autoSkipState.on)
end
updateInfoLabel()

-- 當前遊戲資訊
addLog(
	T("logGameInfoLine"):format(
		gameSettings.gamemode,
		gameSettings.mapId,
		gameSettings.actName,
		gameSettings.difficulty
	),
	Theme.Accent
)
addLog(string.format(T("logAutoSkipRead"), autoSkipState.on and "ON" or "OFF"), Theme.Accent)

-- Adapter 要在「等待遊戲開始」之前掛好: 它會補記場上既有的塔, 那些日誌該排在等待訊息之前
pcall(Adapter.Init)
updateInfoLabel()

addLog(T("logWaitStart"), Theme.TextDim)
pcall(Adapter.Init)

-- ============================================================
-- Heartbeat: 能力冷卻條更新
-- ============================================================
-- 原 GTD 版這裡還有一個掃描器, 每 0.5s 掃 workspace.Map.Towers 找出有能力的塔並建卡片。
-- 動漫遠征的單位容器尚未偵察 -> 掃描器移除, 只留冷卻條更新 (目前沒有卡片, 等同空跑)。
-- 重建計畫見檔頭 [階段 3]。
local abiUpdateTimer = 0

RunService.Heartbeat:Connect(function(dt)
	flushHookTaskQueue()
	abiGameClock = abiGameClock + dt * (lastDetectedSpeed > 0 and lastDetectedSpeed or 1)

	abiUpdateTimer = abiUpdateTimer + dt
	if abiUpdateTimer < 0.1 then
		return
	end
	abiUpdateTimer = 0

	for model, info in pairs(abiLiveTowers) do
		local card = abiTowerCards[model]
		if card then
			local canUseAbility = isGameRunning and info.gameId ~= nil
			for _, w in ipairs(card.widgets) do
				local t0 = info.cooldowns[w.key]
				if not t0 then
					w.barFill.Size = UDim2.new(1, 0, 1, 0)
					w.barFill.BackgroundColor3 = canUseAbility and Theme.Success or Theme.SurfaceHighlight
					w.barText.Text = canUseAbility and T("abilityReady") or T("abilityWaitId")
					w.fireBtn.TextColor3 = canUseAbility and Theme.Text or Theme.TextDim
				else
					local elapsed = abiGameClock - t0
					local remaining = math.max(0, w.cd - elapsed)
					local fillPct = math.min(elapsed / w.cd, 1)
					local dispRemaining = remaining / (lastDetectedSpeed > 0 and lastDetectedSpeed or 1)

					w.barFill.Size = UDim2.new(fillPct, 0, 1, 0)
					w.barFill.BackgroundColor3 = remaining > 0 and Theme.Accent or Theme.Success
					w.barText.Text = remaining > 0 and T("abilityTimerFmt"):format(dispRemaining) or T("abilityReady")
					w.fireBtn.TextColor3 = (canUseAbility and remaining == 0) and Theme.Text or Theme.TextDim
				end
			end
		end
	end
end)

print("[放置追蹤器] 已載入 (動漫遠征) -- 記錄玩家操作, 按 Copy/Save 產生自動化腳本")
