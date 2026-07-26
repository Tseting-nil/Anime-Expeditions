-- [[ 動漫遠征 (Anime Expedition) - 放置追蹤器 ]]

local Gametable = {
	RunService = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	Players = game:GetService("Players"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	HttpService = game:GetService("HttpService"),
	TweenService = game:GetService("TweenService"),
	ScriptContext = game:GetService("ScriptContext"),

	isMobile = false,
	gameSettings = {
		mapId = "Unknown",
		difficulty = "Unknown",
		modifier = "None",
		gamemode = "Story",
		actName = "Act 1",
	},
	isGameRunning = false,
	gameStartSession = nil,
	gameStartApprox = false,
	gameEndElapsed = nil,
	gameStartMapId = nil,
	mapTransitionLog = {},
	readyHooked = false,
	hookTaskQueue = {},
}

Gametable.isMobile = Gametable.UserInputService.TouchEnabled and not Gametable.UserInputService.KeyboardEnabled

local Scripttable = {
	UISizes = {
		mainFrame = Gametable.isMobile and UDim2.new(0, 320, 0, 350) or UDim2.new(0, 550, 0, 480),
		mainFrameMinimized = Gametable.isMobile and UDim2.new(0, 320, 0, 50) or UDim2.new(0, 550, 0, 50),
		mainFrameExpanded = Gametable.isMobile and UDim2.new(0, 320, 0, 350) or UDim2.new(0, 550, 0, 450),
		parameterFrame = Gametable.isMobile and UDim2.new(0, 280, 0, 350) or UDim2.new(0, 360, 0, 400),
		parameterFramePosition = Gametable.isMobile and UDim2.new(0.5, -140, 0.5, -175) or UDim2.new(0.5, -180, 0.5, -200),
		saveFrame = Gametable.isMobile and UDim2.new(0, 280, 0, 200) or UDim2.new(0, 350, 0, 230),
		saveFramePosition = Gametable.isMobile and UDim2.new(0.5, -140, 0.5, -100) or UDim2.new(0.5, -175, 0.5, -115),
		manageFrame = Gametable.isMobile and UDim2.new(0, 300, 0, 350) or UDim2.new(0, 400, 0, 450),
		manageFramePosition = Gametable.isMobile and UDim2.new(0.5, -150, 0.5, -175) or UDim2.new(0.5, -200, 0.5, -225),
		abilityFrame = Gametable.isMobile and UDim2.new(0, 300, 0, 400) or UDim2.new(0, 380, 0, 450),
	},
	Theme = {
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
	},
	ScriptSettings = {
		AutoReplay = true,
		CostMode = true,
		AutoSkipCheckpoint = true,
	},
	timeRoundUp = false,
	customComment = "",
	script_SpeedMultiplier = 1,
	autoScrollEnabled = true,
	SCRIPT_SAVE_PATH = "Tsetingnil_script/AnimeExpedition/Script",
	currentLang = "en",
	Lang = {
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
			lblAutoSkipCheckpoint = "自動跳過檢查點 (AutoSkipCheckpoint)",
			lblAutoSkipCheckpointDesc = "遠征 (Expedition) 模式下，出現中間檢查點彈窗時自動點擊繼續並前進下一個節點",
			logAutoSkipOn = "已啟用自動跳過波次",
			logAutoSkipOff = "已停用自動跳過波次",
			logAutoSkipRead = "讀取遊戲設定：自動跳波 = %s",
			lblFileName = "輸入腳本名稱:",
			phFileName = "輸入腳本名稱...",
			infoFmt = "模式: %s\n地圖: %s [%s]\n難易度: %s\n自動跳過波次: %s\n自動跳過檢查點: %s",
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
			logPlaceFmt = "放置 [#%d] [%s] [id=%s] [%s]",
			logUpgradeFmt = "升級 [%s] [#%s] [%s]",
			logSellFmt = "賣出 [%s] [#%s] [%s]",
			logGameStarted = "開始",
			logGameStart2 = "[遠征檢查點] 繼續 (AddGameStart2)",
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
			lblAutoSkipCheckpoint = "Auto Skip Checkpoint (AutoSkipCheckpoint)",
			lblAutoSkipCheckpointDesc = "In Expedition mode, automatically confirms and skips intermediate checkpoints to proceed to the next node",
			logAutoSkipOn = "Auto Skip Waves enabled",
			logAutoSkipOff = "Auto Skip Waves disabled",
			logAutoSkipRead = "Read game setting: Auto Skip = %s",
			lblFileName = "Script name:",
			phFileName = "Enter script name...",
			infoFmt = "Mode: %s\nMap: %s [%s]\nDifficulty: %s\nAuto Skip Waves: %s\nAuto Skip Checkpoint: %s",
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
			logGameStart2 = "[Expedition Checkpoint] Continue (AddGameStart2)",
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
	},
	i18nElements = {},
	i18nToggleBtns = {},
	infoLabel = nil,
	autoSkipToggle = nil,
	autoSkipState = {
		on = false,
	},
	opSeq = 0,
	nextOrder = 1,
	orderToInfo = {},
	idToOrder = {},
	upgradeLog = {},
	sellLog = {},
	skipWaveLog = {},
	speedChangeLog = {},
	abilityLog = {},
	gameSettingLog = {},
	gameStartLog = {},
	gameStart2Log = {},
	gameStartedLogged = false,
	gameStart2Logged = false,
	lastDetectedSpeed = 1,
	gameStartAutoSkipWave = false,
	_displayCache = nil,
	TowerAbilitiesData = {},
	TowersData = {},
	ABILITY_FALLBACK = {
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
	},
	abilityCache = {},
	towersWithAbility = {},
	abiNextOrder = 1,
	abiLiveTowers = {},
	abiTowerCards = {},
	abiModelByGameId = {},
	abiPendingGameIds = {},
	abiGameIdCooldownHint = {},
	abiEmptyLabel = nil,
	abiRemoteInFlight = {},
	abiGameClock = 0,
	uiVisible = true,
}

local Mainfunction = {}

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

function Mainfunction.DisarmErrorTraps()
	local n = 0
	for _, conn in ipairs(getconnections(Gametable.ScriptContext.Error)) do
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
	local ok, n = pcall(Mainfunction.DisarmErrorTraps)
	if not ok then
		warn("[放置追蹤器] 拆除錯誤陷阱失敗,  (繼續執行會可能被延遲踢出): " .. tostring(n))
	end
	print(string.format("[放置追蹤器] 已拆除 %d 個檢測", n))
end

task.spawn(function()
	while true do
		task.wait(5)
		pcall(Mainfunction.DisarmErrorTraps)
	end
end)

do
	local KEYSYSTEM_PATH = "Tsetingnil_script/keysystem.json"
	pcall(function()
		if isfile and isfile(KEYSYSTEM_PATH) and readfile then
			local raw = readfile(KEYSYSTEM_PATH)
			if raw and raw ~= "" then
				local ok, data = pcall(Gametable.HttpService.JSONDecode, Gametable.HttpService, raw)
				if ok and type(data) == "table" and data.script_language then
					local lang = tostring(data.script_language):lower()
					if lang:find("chinese") or lang:find("zh") then
						Scripttable.currentLang = "zh"
					elseif lang:find("english") or lang:find("en") then
						Scripttable.currentLang = "en"
					end
				else
					local lang = raw:match('"script_language"%s*:%s*"([^"]+)"')
					if lang then
						lang = lang:lower()
						if lang:find("chinese") or lang:find("zh") then
							Scripttable.currentLang = "zh"
						end
					end
				end
			end
		end
	end)
end

function Mainfunction.T(key)
	return Scripttable.Lang[Scripttable.currentLang][key] or key
end

function Mainfunction.bindText(obj, key, prop)
	prop = prop or "Text"
	obj[prop] = Mainfunction.T(key)
	table.insert(Scripttable.i18nElements, {
		obj = obj,
		key = key,
		prop = prop,
	})
end

function Mainfunction.readAutoSkipWave()
	return Scripttable.autoSkipState.on == true
end

function Mainfunction.updateInfoLabel()
	if Scripttable.infoLabel then
		local on = Mainfunction.readAutoSkipWave()
		local skipText = on and Mainfunction.T("toggleOn") or Mainfunction.T("toggleOff")
		local checkpointText = Scripttable.ScriptSettings.AutoSkipCheckpoint and Mainfunction.T("toggleOn") or Mainfunction.T("toggleOff")
		-- 模式 / 地圖 [地圖等級=ActName] / 難易度 / 自動跳過波次 / 自動跳過檢查點
		Scripttable.infoLabel.Text = Mainfunction.T("infoFmt"):format(
			Gametable.gameSettings.gamemode,
			Gametable.gameSettings.mapId,
			Gametable.gameSettings.actName,
			Gametable.gameSettings.difficulty,
			skipText,
			checkpointText
		)
	end
end

function Mainfunction.updateI18n()
	for _, b in ipairs(Scripttable.i18nElements) do
		b.obj[b.prop] = Mainfunction.T(b.key)
	end
	for _, tb in ipairs(Scripttable.i18nToggleBtns) do
		local isOn = tb.getState()
		tb.btn.Text = isOn and Mainfunction.T("toggleOn") or Mainfunction.T("toggleOff")
		tb.btn.TextColor3 = isOn and Scripttable.Theme.TextDark or Scripttable.Theme.TextDim
	end
	Mainfunction.updateInfoLabel()
end

function Mainfunction.nextSeq()
	Scripttable.opSeq = Scripttable.opSeq + 1
	return Scripttable.opSeq
end

function Mainfunction.getMutLabel(info)
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

function Mainfunction.displayName(asset)
	if not asset then
		return "?"
	end
	if Scripttable._displayCache == nil then
		Scripttable._displayCache = {}
		pcall(function()
			local U = require(Gametable.ReplicatedStorage.Shared.Information.Units)
			for k, v in pairs(U) do
				if type(v) == "table" and type(v.DisplayName) == "string" and v.DisplayName ~= "" then
					Scripttable._displayCache[k] = v.DisplayName
				end
			end
		end)
	end
	return Scripttable._displayCache[asset] or asset
end

function Mainfunction.getElapsed()
	if not Gametable.gameStartSession then
		return 0
	end
	local now = Mainfunction.getSessionTime and Mainfunction.getSessionTime() or nil
	if not now then
		return 0
	end
	return math.max(0, now - Gametable.gameStartSession)
end

function Mainfunction.elapsedFromPlacedAt(placedAt)
	if not placedAt or not Gametable.gameStartSession then
		return nil
	end
	return math.max(0, placedAt - Gametable.gameStartSession)
end

function Mainfunction.startGameTimer(mapId, startSession)
	if Gametable.isGameRunning then
		return false
	end
	Gametable.gameStartSession = startSession or (Mainfunction.getSessionTime and Mainfunction.getSessionTime()) or nil
	if not Gametable.gameStartSession then
		return false
	end
	Gametable.isGameRunning = true
	Gametable.gameStartMapId = mapId or Gametable.gameSettings.mapId
	Scripttable.gameStartAutoSkipWave = Mainfunction.readAutoSkipWave()
	return true
end

function Mainfunction.queueHookTask(fn)
	table.insert(Gametable.hookTaskQueue, fn)
end

function Mainfunction.flushHookTaskQueue()
	if #Gametable.hookTaskQueue == 0 then
		return
	end
	local queued = Gametable.hookTaskQueue
	Gametable.hookTaskQueue = {}
	for _, fn in ipairs(queued) do
		local ok, err = pcall(fn)
		if not ok then
			warn("[Queued Hook Error]", err)
		end
	end
end

function Mainfunction.getAbiData(key)
	return Scripttable.TowerAbilitiesData[key] or Scripttable.ABILITY_FALLBACK[key] or {
		Name = key,
		Cooldown = 30,
	}
end

function Mainfunction.fetchAbilityKeys(towerName)
	if Scripttable.abilityCache[towerName] then
		return Scripttable.abilityCache[towerName]
	end
	-- TODO[階段 3]: 依動漫遠征的單位資料 schema 取出能力 key
	local keys = {}
	Scripttable.abilityCache[towerName] = keys
	return keys
end

function Mainfunction.getAbilityRemaining(info, abilityKey, cooldown)
	local t0 = info and info.cooldowns and info.cooldowns[abilityKey]
	if not t0 then
		return 0
	end
	-- 以遊戲時間計: abiGameClock 已含速度倍率
	return math.max(0, cooldown - (Scripttable.abiGameClock - t0))
end

function Mainfunction.invokeTowerAbilitySafely(model, abilityKey, cooldown)
	Tracker.NotImplemented("invokeTowerAbilitySafely")
	return false
end

function Mainfunction.stopAbilityRemoteTriggers()
	Scripttable.abiRemoteInFlight = {}
	Scripttable.abiPendingGameIds = {}
	Scripttable.abiGameIdCooldownHint = {}
	Scripttable.abiModelByGameId = {}

	for _, info in pairs(Scripttable.abiLiveTowers) do
		info.gameId = nil
		info.cooldowns = {}
	end

	if Mainfunction.rebuildAllAbilityCards then
		Mainfunction.rebuildAllAbilityCards()
	end
end


Scripttable.guiParent = get_hidden_gui or gethui
Scripttable.screenGui = Instance.new("ScreenGui")
Scripttable.screenGui.Name = "NTDTrackerUI"
Scripttable.screenGui.IgnoreGuiInset = true
Scripttable.screenGui.ResetOnSpawn = false
Scripttable.screenGui.Parent = Scripttable.guiParent and Scripttable.guiParent() or game:GetService("CoreGui")

Scripttable.mainFrame = Instance.new("Frame")
Scripttable.mainFrame.Size = Scripttable.UISizes.mainFrame
Scripttable.mainFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
Scripttable.mainFrame.BackgroundColor3 = Scripttable.Theme.Background
Scripttable.mainFrame.BackgroundTransparency = 0.05
Scripttable.mainFrame.Active = true
Scripttable.mainFrame.BorderSizePixel = 0
Scripttable.mainFrame.ClipsDescendants = true
Scripttable.mainFrame.Parent = Scripttable.screenGui

do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.mainFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Scripttable.Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = Scripttable.mainFrame
end

-- 標題欄
Scripttable.titleBar = Instance.new("Frame")
Scripttable.titleBar.Size = UDim2.new(1, 0, 0, 45)
Scripttable.titleBar.BackgroundColor3 = Scripttable.Theme.Surface
Scripttable.titleBar.BorderSizePixel = 0
Scripttable.titleBar.Parent = Scripttable.mainFrame
Scripttable.titleBar.Name = "TitleBar"
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.titleBar
end

Scripttable.titleBarCover = Instance.new("Frame")
Scripttable.titleBarCover.Size = UDim2.new(1, 0, 0, 10)
Scripttable.titleBarCover.Position = UDim2.new(0, 0, 1, -10)
Scripttable.titleBarCover.BackgroundColor3 = Scripttable.Theme.Surface
Scripttable.titleBarCover.BorderSizePixel = 0
Scripttable.titleBarCover.Parent = Scripttable.titleBar

Scripttable.titleSeparator = Instance.new("Frame")
Scripttable.titleSeparator.Size = UDim2.new(1, 0, 0, 1)
Scripttable.titleSeparator.Position = UDim2.new(0, 0, 1, -1)
Scripttable.titleSeparator.BackgroundColor3 = Scripttable.Theme.Border
Scripttable.titleSeparator.BorderSizePixel = 0
Scripttable.titleSeparator.Parent = Scripttable.titleBar

Scripttable.title = Instance.new("TextLabel")
Scripttable.title.Size = UDim2.new(1, -90, 1, 0)
Scripttable.title.BackgroundTransparency = 1
Scripttable.title.TextColor3 = Scripttable.Theme.Accent
Scripttable.title.Font = Scripttable.Theme.FontBold
Scripttable.title.TextSize = Scripttable.Theme.SizeLarge
Scripttable.title.TextXAlignment = Enum.TextXAlignment.Left
Scripttable.title.Position = UDim2.new(0, 10, 0, 0)
Scripttable.title.Parent = Scripttable.titleBar
Mainfunction.bindText(Scripttable.title, "titleMain")

Scripttable.langBtn = Instance.new("TextButton")
Scripttable.langBtn.Size = UDim2.new(0, 35, 0, 35)
Scripttable.langBtn.Position = UDim2.new(1, -80, 0, 5)
Scripttable.langBtn.Text = Scripttable.currentLang == "zh" and "EN" or "中"
Scripttable.langBtn.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
Scripttable.langBtn.TextColor3 = Scripttable.Theme.Accent
Scripttable.langBtn.Font = Scripttable.Theme.FontBold
Scripttable.langBtn.TextSize = 13
Scripttable.langBtn.BorderSizePixel = 0
Scripttable.langBtn.Parent = Scripttable.titleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = Scripttable.langBtn
end

Scripttable.langBtn.MouseButton1Click:Connect(function()
	if Scripttable.currentLang == "zh" then
		Scripttable.currentLang = "en"
		Scripttable.langBtn.Text = "中"
	else
		Scripttable.currentLang = "zh"
		Scripttable.langBtn.Text = "EN"
	end
	Mainfunction.updateI18n()
	task.spawn(function()
		Mainfunction.rebuildAllAbilityCards()
	end)
end)

Scripttable.minimizeBtn = Instance.new("TextButton")
Scripttable.minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
Scripttable.minimizeBtn.Position = UDim2.new(1, -40, 0, 5)
Scripttable.minimizeBtn.Text = "—"
Scripttable.minimizeBtn.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
Scripttable.minimizeBtn.TextColor3 = Scripttable.Theme.Text
Scripttable.minimizeBtn.Font = Scripttable.Theme.FontBold
Scripttable.minimizeBtn.TextSize = 22
Scripttable.minimizeBtn.BorderSizePixel = 0
Scripttable.minimizeBtn.Parent = Scripttable.titleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = Scripttable.minimizeBtn
end

-- 滾動框架
Scripttable.scrollFrame = Instance.new("ScrollingFrame")
Scripttable.scrollFrame.Size = UDim2.new(1, -20, 1, -100)
Scripttable.scrollFrame.Position = UDim2.new(0, 10, 0, 50)
Scripttable.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
Scripttable.scrollFrame.ScrollBarThickness = 4
Scripttable.scrollFrame.BackgroundTransparency = 1
Scripttable.scrollFrame.ScrollBarImageColor3 = Scripttable.Theme.Border
Scripttable.scrollFrame.Parent = Scripttable.mainFrame

Scripttable.listLayout = Instance.new("UIListLayout")
Scripttable.listLayout.SortOrder = Enum.SortOrder.LayoutOrder
Scripttable.listLayout.Padding = UDim.new(0, 8)
Scripttable.listLayout.Parent = Scripttable.scrollFrame

Scripttable.listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Scripttable.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, Scripttable.listLayout.AbsoluteContentSize.Y + 10)
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if Scripttable.scrollFrame and Scripttable.autoScrollEnabled then
			pcall(function()
				Scripttable.scrollFrame.CanvasPosition = Vector2.new(0, Scripttable.scrollFrame.CanvasSize.Y.Offset)
			end)
		end
	end
end)

-- 按鈕列
Scripttable.buttonContainer = Instance.new("Frame")
Scripttable.buttonContainer.Size = UDim2.new(1, -20, 0, 40)
Scripttable.buttonContainer.Position = UDim2.new(0, 10, 1, -45)
Scripttable.buttonContainer.BackgroundTransparency = 1
Scripttable.buttonContainer.Parent = Scripttable.mainFrame

Scripttable.buttonLayout = Instance.new("UIListLayout")
Scripttable.buttonLayout.FillDirection = Enum.FillDirection.Horizontal
Scripttable.buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
Scripttable.buttonLayout.Padding = UDim.new(0, 6)
Scripttable.buttonLayout.Parent = Scripttable.buttonContainer

Mainfunction.makeBtn = function(textKey, bgColor, txtColor, order, widthScale)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(widthScale or 0.25, -5, 1, 0)
	btn.BackgroundColor3 = bgColor
	btn.TextColor3 = txtColor
	btn.Font = Scripttable.Theme.FontBold
	btn.TextSize = Scripttable.Theme.SizeMedium
	btn.BorderSizePixel = 0
	btn.LayoutOrder = order
	btn.Parent = Scripttable.buttonContainer
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = btn
	Mainfunction.bindText(btn, textKey)
	return btn
end

Scripttable.copyBtn = Mainfunction.makeBtn("btnCopy", Scripttable.Theme.Success, Scripttable.Theme.TextDark, 1, 0.25)
Scripttable.saveBtn = Mainfunction.makeBtn("btnSave", Scripttable.Theme.Accent, Scripttable.Theme.Text, 2, 0.25)
Scripttable.Parameter = Mainfunction.makeBtn("btnParam", Scripttable.Theme.SurfaceHighlight, Scripttable.Theme.Text, 3, 0.25)
Scripttable.abilityBtn = Mainfunction.makeBtn("btnAbility", Scripttable.Theme.Purple, Scripttable.Theme.Text, 4, 0.25)

-- ============================================================
-- addLog 函數
-- ============================================================
Scripttable.logOrder = 1

Mainfunction.addLog = function(text, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Scripttable.Theme.Text
	label.Font = Scripttable.Theme.Font
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.LayoutOrder = Scripttable.logOrder
	label.Parent = Scripttable.scrollFrame
	Scripttable.logOrder = Scripttable.logOrder + 1
end

-- ============================================================
-- 參數面板 UI
-- ============================================================
Scripttable.parameterFrame = Instance.new("Frame")
Scripttable.parameterFrame.Size = Scripttable.UISizes.parameterFrame
Scripttable.parameterFrame.Position = Scripttable.UISizes.parameterFramePosition
Scripttable.parameterFrame.BackgroundColor3 = Scripttable.Theme.Background
Scripttable.parameterFrame.BackgroundTransparency = 0.05
Scripttable.parameterFrame.Active = true
Scripttable.parameterFrame.BorderSizePixel = 0
Scripttable.parameterFrame.ClipsDescendants = true
Scripttable.parameterFrame.Visible = false
Scripttable.parameterFrame.ZIndex = 10
Scripttable.parameterFrame.Parent = Scripttable.screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.parameterFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Scripttable.Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = Scripttable.parameterFrame
end

Scripttable.paramTitleBar = Instance.new("Frame")
Scripttable.paramTitleBar.Size = UDim2.new(1, 0, 0, 45)
Scripttable.paramTitleBar.BackgroundColor3 = Scripttable.Theme.Surface
Scripttable.paramTitleBar.BorderSizePixel = 0
Scripttable.paramTitleBar.ZIndex = 11
Scripttable.paramTitleBar.Parent = Scripttable.parameterFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.paramTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Scripttable.Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = Scripttable.paramTitleBar
end

Scripttable.paramTitle = Instance.new("TextLabel")
Scripttable.paramTitle.Size = UDim2.new(0.8, 0, 1, 0)
Scripttable.paramTitle.BackgroundTransparency = 1
Scripttable.paramTitle.TextColor3 = Scripttable.Theme.Text
Scripttable.paramTitle.Font = Scripttable.Theme.FontBold
Scripttable.paramTitle.TextSize = Scripttable.Theme.SizeLarge
Scripttable.paramTitle.TextXAlignment = Enum.TextXAlignment.Left
Scripttable.paramTitle.ZIndex = 12
Scripttable.paramTitle.Parent = Scripttable.paramTitleBar
Mainfunction.bindText(Scripttable.paramTitle, "titleParam")

Scripttable.closeBtn = Instance.new("TextButton")
Scripttable.closeBtn.Size = UDim2.new(0, 35, 0, 35)
Scripttable.closeBtn.Position = UDim2.new(1, -40, 0, 5)
Scripttable.closeBtn.Text = "×"
Scripttable.closeBtn.BackgroundColor3 = Scripttable.Theme.Error
Scripttable.closeBtn.TextColor3 = Scripttable.Theme.Text
Scripttable.closeBtn.Font = Scripttable.Theme.FontBold
Scripttable.closeBtn.TextSize = 24
Scripttable.closeBtn.BorderSizePixel = 0
Scripttable.closeBtn.ZIndex = 12
Scripttable.closeBtn.Parent = Scripttable.paramTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.closeBtn
end

Scripttable.paramScrollFrame = Instance.new("ScrollingFrame")
Scripttable.paramScrollFrame.Size = UDim2.new(1, -20, 1, -55)
Scripttable.paramScrollFrame.Position = UDim2.new(0, 10, 0, 50)
Scripttable.paramScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
Scripttable.paramScrollFrame.ScrollBarThickness = 4
Scripttable.paramScrollFrame.BackgroundTransparency = 1
Scripttable.paramScrollFrame.ZIndex = 11
Scripttable.paramScrollFrame.Parent = Scripttable.parameterFrame

Scripttable.paramListLayout = Instance.new("UIListLayout")
Scripttable.paramListLayout.SortOrder = Enum.SortOrder.LayoutOrder
Scripttable.paramListLayout.Padding = UDim.new(0, 8)
Scripttable.paramListLayout.Parent = Scripttable.paramScrollFrame

Scripttable.paramListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Scripttable.paramScrollFrame.CanvasSize = UDim2.new(0, 0, 0, Scripttable.paramListLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- 儲存面板 UI
-- ============================================================
Scripttable.saveFrame = Instance.new("Frame")
Scripttable.saveFrame.Size = Scripttable.UISizes.saveFrame
Scripttable.saveFrame.Position = Scripttable.UISizes.saveFramePosition
Scripttable.saveFrame.BackgroundColor3 = Scripttable.Theme.Background
Scripttable.saveFrame.BackgroundTransparency = 0.05
Scripttable.saveFrame.Active = true
Scripttable.saveFrame.BorderSizePixel = 0
Scripttable.saveFrame.ClipsDescendants = true
Scripttable.saveFrame.Visible = false
Scripttable.saveFrame.ZIndex = 10
Scripttable.saveFrame.Parent = Scripttable.screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.saveFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Scripttable.Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = Scripttable.saveFrame
end

Scripttable.saveTitleBar = Instance.new("Frame")
Scripttable.saveTitleBar.Size = UDim2.new(1, 0, 0, 45)
Scripttable.saveTitleBar.BackgroundColor3 = Scripttable.Theme.Surface
Scripttable.saveTitleBar.BorderSizePixel = 0
Scripttable.saveTitleBar.ZIndex = 11
Scripttable.saveTitleBar.Parent = Scripttable.saveFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.saveTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Scripttable.Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = Scripttable.saveTitleBar
end

Scripttable.saveTitle = Instance.new("TextLabel")
Scripttable.saveTitle.Size = UDim2.new(0.8, 0, 1, 0)
Scripttable.saveTitle.BackgroundTransparency = 1
Scripttable.saveTitle.TextColor3 = Scripttable.Theme.Text
Scripttable.saveTitle.Font = Scripttable.Theme.FontBold
Scripttable.saveTitle.TextSize = Scripttable.Theme.SizeLarge
Scripttable.saveTitle.TextXAlignment = Enum.TextXAlignment.Left
Scripttable.saveTitle.ZIndex = 12
Scripttable.saveTitle.Parent = Scripttable.saveTitleBar
Mainfunction.bindText(Scripttable.saveTitle, "titleSave")

Scripttable.saveCloseBtn = Instance.new("TextButton")
Scripttable.saveCloseBtn.Size = UDim2.new(0, 35, 0, 35)
Scripttable.saveCloseBtn.Position = UDim2.new(1, -40, 0, 5)
Scripttable.saveCloseBtn.Text = "×"
Scripttable.saveCloseBtn.BackgroundColor3 = Scripttable.Theme.Error
Scripttable.saveCloseBtn.TextColor3 = Scripttable.Theme.Text
Scripttable.saveCloseBtn.Font = Scripttable.Theme.FontBold
Scripttable.saveCloseBtn.TextSize = 24
Scripttable.saveCloseBtn.BorderSizePixel = 0
Scripttable.saveCloseBtn.ZIndex = 12
Scripttable.saveCloseBtn.Parent = Scripttable.saveTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.saveCloseBtn
end

Scripttable.fileNameLabel = Instance.new("TextLabel")
Scripttable.fileNameLabel.Size = UDim2.new(1, -20, 0, 20)
Scripttable.fileNameLabel.Position = UDim2.new(0, 10, 0, 55)
Scripttable.fileNameLabel.BackgroundTransparency = 1
Scripttable.fileNameLabel.TextColor3 = Scripttable.Theme.TextDim
Scripttable.fileNameLabel.Font = Scripttable.Theme.Font
Scripttable.fileNameLabel.TextSize = Scripttable.Theme.SizeNormal
Scripttable.fileNameLabel.TextXAlignment = Enum.TextXAlignment.Left
Scripttable.fileNameLabel.ZIndex = 12
Scripttable.fileNameLabel.Parent = Scripttable.saveFrame
Mainfunction.bindText(Scripttable.fileNameLabel, "lblFileName")

Scripttable.fileNameInput = Instance.new("TextBox")
Scripttable.fileNameInput.Size = UDim2.new(1, -20, 0, 35)
Scripttable.fileNameInput.Position = UDim2.new(0, 10, 0, 80)
Scripttable.fileNameInput.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
Scripttable.fileNameInput.PlaceholderColor3 = Scripttable.Theme.TextDim
Scripttable.fileNameInput.Text = ""
Scripttable.fileNameInput.TextColor3 = Scripttable.Theme.Text
Scripttable.fileNameInput.Font = Scripttable.Theme.Font
Scripttable.fileNameInput.TextSize = Scripttable.Theme.SizeNormal
Scripttable.fileNameInput.BorderSizePixel = 0
Scripttable.fileNameInput.ClearTextOnFocus = false
Scripttable.fileNameInput.ZIndex = 12
Scripttable.fileNameInput.Parent = Scripttable.saveFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = Scripttable.fileNameInput
end
Mainfunction.bindText(Scripttable.fileNameInput, "phFileName", "PlaceholderText")

-- 指定加載名稱（前綴）：僅雙地圖 + 分離模式顯示；生成的 Phase1 用它 AddMapWait("<前綴>")
Scripttable.phase2NameLabel = Instance.new("TextLabel")
Scripttable.phase2NameLabel.Size = UDim2.new(1, -20, 0, 20)
Scripttable.phase2NameLabel.Position = UDim2.new(0, 10, 0, 158)
Scripttable.phase2NameLabel.BackgroundTransparency = 1
Scripttable.phase2NameLabel.TextColor3 = Scripttable.Theme.TextDim
Scripttable.phase2NameLabel.Font = Scripttable.Theme.Font
Scripttable.phase2NameLabel.TextSize = Scripttable.Theme.SizeNormal
Scripttable.phase2NameLabel.TextXAlignment = Enum.TextXAlignment.Left
Scripttable.phase2NameLabel.Visible = false
Scripttable.phase2NameLabel.ZIndex = 12
Scripttable.phase2NameLabel.Parent = Scripttable.saveFrame
Mainfunction.bindText(Scripttable.phase2NameLabel, "lblPhase2Name")

Scripttable.phase2NameInput = Instance.new("TextBox")
Scripttable.phase2NameInput.Size = UDim2.new(1, -20, 0, 32)
Scripttable.phase2NameInput.Position = UDim2.new(0, 10, 0, 180)
Scripttable.phase2NameInput.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
Scripttable.phase2NameInput.PlaceholderColor3 = Scripttable.Theme.TextDim
Scripttable.phase2NameInput.Text = ""
Scripttable.phase2NameInput.TextColor3 = Scripttable.Theme.Text
Scripttable.phase2NameInput.Font = Scripttable.Theme.Font
Scripttable.phase2NameInput.TextSize = Scripttable.Theme.SizeNormal
Scripttable.phase2NameInput.BorderSizePixel = 0
Scripttable.phase2NameInput.ClearTextOnFocus = false
Scripttable.phase2NameInput.Visible = false
Scripttable.phase2NameInput.ZIndex = 12
Scripttable.phase2NameInput.Parent = Scripttable.saveFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = Scripttable.phase2NameInput
end

Scripttable.saveModeRow = Instance.new("Frame")
Scripttable.saveModeRow.Size = UDim2.new(1, -20, 0, 28)
Scripttable.saveModeRow.Position = UDim2.new(0, 10, 0, 122)
Scripttable.saveModeRow.BackgroundTransparency = 1
Scripttable.saveModeRow.Visible = false
Scripttable.saveModeRow.ZIndex = 12
Scripttable.saveModeRow.Parent = Scripttable.saveFrame

Scripttable.saveModeLbl = Instance.new("TextLabel")
Scripttable.saveModeLbl.Size = UDim2.new(0.45, 0, 1, 0)
Scripttable.saveModeLbl.BackgroundTransparency = 1
Scripttable.saveModeLbl.TextColor3 = Scripttable.Theme.TextDim
Scripttable.saveModeLbl.Font = Scripttable.Theme.Font
Scripttable.saveModeLbl.TextSize = Scripttable.Theme.SizeNormal
Scripttable.saveModeLbl.TextXAlignment = Enum.TextXAlignment.Left
Scripttable.saveModeLbl.ZIndex = 13
Scripttable.saveModeLbl.Parent = Scripttable.saveModeRow
Mainfunction.bindText(Scripttable.saveModeLbl, "lblSaveMode")

Scripttable.saveMergedBtn = Instance.new("TextButton")
Scripttable.saveMergedBtn.Size = UDim2.new(0.25, -4, 1, 0)
Scripttable.saveMergedBtn.Position = UDim2.new(0.45, 0, 0, 0)
Scripttable.saveMergedBtn.BackgroundColor3 = Scripttable.Theme.Accent
Scripttable.saveMergedBtn.TextColor3 = Scripttable.Theme.Text
Scripttable.saveMergedBtn.Font = Scripttable.Theme.FontBold
Scripttable.saveMergedBtn.TextSize = 14
Scripttable.saveMergedBtn.BorderSizePixel = 0
Scripttable.saveMergedBtn.ZIndex = 13
Scripttable.saveMergedBtn.Parent = Scripttable.saveModeRow
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = Scripttable.saveMergedBtn
end
Mainfunction.bindText(Scripttable.saveMergedBtn, "saveMerged")

Scripttable.saveSeparateBtn = Instance.new("TextButton")
Scripttable.saveSeparateBtn.Size = UDim2.new(0.28, -4, 1, 0)
Scripttable.saveSeparateBtn.Position = UDim2.new(0.72, 0, 0, 0)
Scripttable.saveSeparateBtn.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
Scripttable.saveSeparateBtn.TextColor3 = Scripttable.Theme.TextDim
Scripttable.saveSeparateBtn.Font = Scripttable.Theme.FontBold
Scripttable.saveSeparateBtn.TextSize = 14
Scripttable.saveSeparateBtn.BorderSizePixel = 0
Scripttable.saveSeparateBtn.ZIndex = 13
Scripttable.saveSeparateBtn.Parent = Scripttable.saveModeRow
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = Scripttable.saveSeparateBtn
end
Mainfunction.bindText(Scripttable.saveSeparateBtn, "saveSeparate")

Scripttable.currentSaveMode = "merged"

Mainfunction.updateSaveModeButtons = function()
	if Scripttable.currentSaveMode == "merged" then
		Scripttable.saveMergedBtn.BackgroundColor3 = Scripttable.Theme.Accent
		Scripttable.saveMergedBtn.TextColor3 = Scripttable.Theme.Text
		Scripttable.saveSeparateBtn.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
		Scripttable.saveSeparateBtn.TextColor3 = Scripttable.Theme.TextDim
	else
		Scripttable.saveMergedBtn.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
		Scripttable.saveMergedBtn.TextColor3 = Scripttable.Theme.TextDim
		Scripttable.saveSeparateBtn.BackgroundColor3 = Scripttable.Theme.Accent
		Scripttable.saveSeparateBtn.TextColor3 = Scripttable.Theme.Text
	end
end

Scripttable.saveMergedBtn.MouseButton1Click:Connect(function()
	Scripttable.currentSaveMode = "merged"
	Mainfunction.updateSaveModeButtons()
	if Mainfunction.relayoutSavePanel then Mainfunction.relayoutSavePanel() end
end)
Scripttable.saveSeparateBtn.MouseButton1Click:Connect(function()
	Scripttable.currentSaveMode = "separate"
	Mainfunction.updateSaveModeButtons()
	if Mainfunction.relayoutSavePanel then Mainfunction.relayoutSavePanel() end
end)

Scripttable.saveBtnContainer = Instance.new("Frame")
Scripttable.saveBtnContainer.Size = UDim2.new(1, -20, 0, 40)
Scripttable.saveBtnContainer.Position = UDim2.new(0, 10, 0, 130)
Scripttable.saveBtnContainer.BackgroundTransparency = 1
Scripttable.saveBtnContainer.ZIndex = 12
Scripttable.saveBtnContainer.Parent = Scripttable.saveFrame
do
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 10)
	l.Parent = Scripttable.saveBtnContainer
end

-- 動漫遠征只有單一地圖流程，存檔面板固定排版（無雙地圖 / 合併分離之分）
Mainfunction.relayoutSavePanel = function()
	Scripttable.saveModeRow.Visible = false
	Scripttable.phase2NameLabel.Visible = false
	Scripttable.phase2NameInput.Visible = false

	local y = 122
	Scripttable.saveBtnContainer.Position = UDim2.new(0, 10, 0, y)
	local wx = Scripttable.UISizes.saveFrame.X
	Scripttable.saveFrame.Size = UDim2.new(wx.Scale, wx.Offset, 0, y + 55)
end

Scripttable.confirmSaveBtn = Instance.new("TextButton")
Scripttable.confirmSaveBtn.Size = UDim2.new(0.5, -5, 1, 0)
Scripttable.confirmSaveBtn.BackgroundColor3 = Scripttable.Theme.Success
Scripttable.confirmSaveBtn.TextColor3 = Scripttable.Theme.TextDark
Scripttable.confirmSaveBtn.Font = Scripttable.Theme.FontBold
Scripttable.confirmSaveBtn.TextSize = Scripttable.Theme.SizeNormal
Scripttable.confirmSaveBtn.BorderSizePixel = 0
Scripttable.confirmSaveBtn.LayoutOrder = 1
Scripttable.confirmSaveBtn.ZIndex = 12
Scripttable.confirmSaveBtn.Parent = Scripttable.saveBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.confirmSaveBtn
end
Mainfunction.bindText(Scripttable.confirmSaveBtn, "btnConfirmSave")

Scripttable.cancelSaveBtn = Instance.new("TextButton")
Scripttable.cancelSaveBtn.Size = UDim2.new(0.5, -5, 1, 0)
Scripttable.cancelSaveBtn.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
Scripttable.cancelSaveBtn.TextColor3 = Scripttable.Theme.Text
Scripttable.cancelSaveBtn.Font = Scripttable.Theme.FontBold
Scripttable.cancelSaveBtn.TextSize = Scripttable.Theme.SizeNormal
Scripttable.cancelSaveBtn.BorderSizePixel = 0
Scripttable.cancelSaveBtn.LayoutOrder = 2
Scripttable.cancelSaveBtn.ZIndex = 12
Scripttable.cancelSaveBtn.Parent = Scripttable.saveBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.cancelSaveBtn
end
Mainfunction.bindText(Scripttable.cancelSaveBtn, "btnCancel")

-- ============================================================
-- 腳本管理面板
-- ============================================================
Scripttable.manageFrame = Instance.new("Frame")
Scripttable.manageFrame.Size = Scripttable.UISizes.manageFrame
Scripttable.manageFrame.Position = Scripttable.UISizes.manageFramePosition
Scripttable.manageFrame.BackgroundColor3 = Scripttable.Theme.Background
Scripttable.manageFrame.BackgroundTransparency = 0.05
Scripttable.manageFrame.Active = true
Scripttable.manageFrame.BorderSizePixel = 0
Scripttable.manageFrame.ClipsDescendants = true
Scripttable.manageFrame.Visible = false
Scripttable.manageFrame.ZIndex = 10
Scripttable.manageFrame.Parent = Scripttable.screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.manageFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Scripttable.Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = Scripttable.manageFrame
end

Scripttable.manageTitleBar = Instance.new("Frame")
Scripttable.manageTitleBar.Size = UDim2.new(1, 0, 0, 45)
Scripttable.manageTitleBar.BackgroundColor3 = Scripttable.Theme.Surface
Scripttable.manageTitleBar.BorderSizePixel = 0
Scripttable.manageTitleBar.ZIndex = 11
Scripttable.manageTitleBar.Parent = Scripttable.manageFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.manageTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Scripttable.Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = Scripttable.manageTitleBar
end

Scripttable.manageTitle = Instance.new("TextLabel")
Scripttable.manageTitle.Size = UDim2.new(0.6, 0, 1, 0)
Scripttable.manageTitle.BackgroundTransparency = 1
Scripttable.manageTitle.TextColor3 = Scripttable.Theme.Text
Scripttable.manageTitle.Font = Scripttable.Theme.FontBold
Scripttable.manageTitle.TextSize = Scripttable.Theme.SizeLarge
Scripttable.manageTitle.TextXAlignment = Enum.TextXAlignment.Left
Scripttable.manageTitle.ZIndex = 12
Scripttable.manageTitle.Parent = Scripttable.manageTitleBar
Mainfunction.bindText(Scripttable.manageTitle, "titleManage")

Scripttable.refreshScriptsBtn = Instance.new("TextButton")
Scripttable.refreshScriptsBtn.Size = UDim2.new(0, 80, 0, 30)
Scripttable.refreshScriptsBtn.Position = UDim2.new(1, -125, 0, 7)
Scripttable.refreshScriptsBtn.BackgroundColor3 = Scripttable.Theme.Accent
Scripttable.refreshScriptsBtn.TextColor3 = Scripttable.Theme.Text
Scripttable.refreshScriptsBtn.Font = Scripttable.Theme.Font
Scripttable.refreshScriptsBtn.TextSize = 14
Scripttable.refreshScriptsBtn.BorderSizePixel = 0
Scripttable.refreshScriptsBtn.ZIndex = 12
Scripttable.refreshScriptsBtn.Parent = Scripttable.manageTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = Scripttable.refreshScriptsBtn
end
Mainfunction.bindText(Scripttable.refreshScriptsBtn, "btnRefresh")

Scripttable.manageCloseBtn = Instance.new("TextButton")
Scripttable.manageCloseBtn.Size = UDim2.new(0, 35, 0, 35)
Scripttable.manageCloseBtn.Position = UDim2.new(1, -40, 0, 5)
Scripttable.manageCloseBtn.Text = "×"
Scripttable.manageCloseBtn.BackgroundColor3 = Scripttable.Theme.Error
Scripttable.manageCloseBtn.TextColor3 = Scripttable.Theme.Text
Scripttable.manageCloseBtn.Font = Scripttable.Theme.FontBold
Scripttable.manageCloseBtn.TextSize = 24
Scripttable.manageCloseBtn.BorderSizePixel = 0
Scripttable.manageCloseBtn.ZIndex = 12
Scripttable.manageCloseBtn.Parent = Scripttable.manageTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.manageCloseBtn
end

Scripttable.manageScrollFrame = Instance.new("ScrollingFrame")
Scripttable.manageScrollFrame.Size = UDim2.new(1, -20, 1, -55)
Scripttable.manageScrollFrame.Position = UDim2.new(0, 10, 0, 50)
Scripttable.manageScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
Scripttable.manageScrollFrame.ScrollBarThickness = 4
Scripttable.manageScrollFrame.BackgroundTransparency = 1
Scripttable.manageScrollFrame.ZIndex = 11
Scripttable.manageScrollFrame.Parent = Scripttable.manageFrame

Scripttable.manageListLayout = Instance.new("UIListLayout")
Scripttable.manageListLayout.SortOrder = Enum.SortOrder.LayoutOrder
Scripttable.manageListLayout.Padding = UDim.new(0, 6)
Scripttable.manageListLayout.Parent = Scripttable.manageScrollFrame

Scripttable.manageListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Scripttable.manageScrollFrame.CanvasSize = UDim2.new(0, 0, 0, Scripttable.manageListLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- 塔能力面板 UI
-- ============================================================
Scripttable.abilityFrame = Instance.new("Frame")
Scripttable.abilityFrame.Size = Scripttable.UISizes.abilityFrame
Scripttable.abilityFrame.Position = UDim2.new(0.5, 0, 0.5, -200)
Scripttable.abilityFrame.BackgroundColor3 = Scripttable.Theme.Background
Scripttable.abilityFrame.BackgroundTransparency = 0.05
Scripttable.abilityFrame.Active = true
Scripttable.abilityFrame.BorderSizePixel = 0
Scripttable.abilityFrame.ClipsDescendants = true
Scripttable.abilityFrame.Visible = false
Scripttable.abilityFrame.ZIndex = 10
Scripttable.abilityFrame.Parent = Scripttable.screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.abilityFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Scripttable.Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = Scripttable.abilityFrame
end

Scripttable.abilityTitleBar = Instance.new("Frame")
Scripttable.abilityTitleBar.Size = UDim2.new(1, 0, 0, 45)
Scripttable.abilityTitleBar.BackgroundColor3 = Scripttable.Theme.Surface
Scripttable.abilityTitleBar.BorderSizePixel = 0
Scripttable.abilityTitleBar.ZIndex = 11
Scripttable.abilityTitleBar.Parent = Scripttable.abilityFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.abilityTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Scripttable.Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = Scripttable.abilityTitleBar
end

Scripttable.abilityTitle = Instance.new("TextLabel")
Scripttable.abilityTitle.Size = UDim2.new(0.8, 0, 1, 0)
Scripttable.abilityTitle.BackgroundTransparency = 1
Scripttable.abilityTitle.TextColor3 = Scripttable.Theme.Purple
Scripttable.abilityTitle.Font = Scripttable.Theme.FontBold
Scripttable.abilityTitle.TextSize = Scripttable.Theme.SizeLarge
Scripttable.abilityTitle.TextXAlignment = Enum.TextXAlignment.Left
Scripttable.abilityTitle.ZIndex = 12
Scripttable.abilityTitle.Parent = Scripttable.abilityTitleBar
Mainfunction.bindText(Scripttable.abilityTitle, "titleAbility")

Scripttable.abilityCloseBtn = Instance.new("TextButton")
Scripttable.abilityCloseBtn.Size = UDim2.new(0, 35, 0, 35)
Scripttable.abilityCloseBtn.Position = UDim2.new(1, -40, 0, 5)
Scripttable.abilityCloseBtn.Text = "×"
Scripttable.abilityCloseBtn.BackgroundColor3 = Scripttable.Theme.Error
Scripttable.abilityCloseBtn.TextColor3 = Scripttable.Theme.Text
Scripttable.abilityCloseBtn.Font = Scripttable.Theme.FontBold
Scripttable.abilityCloseBtn.TextSize = 24
Scripttable.abilityCloseBtn.BorderSizePixel = 0
Scripttable.abilityCloseBtn.ZIndex = 12
Scripttable.abilityCloseBtn.Parent = Scripttable.abilityTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.abilityCloseBtn
end

Scripttable.abilityScrollFrame = Instance.new("ScrollingFrame")
Scripttable.abilityScrollFrame.Size = UDim2.new(1, -20, 1, -55)
Scripttable.abilityScrollFrame.Position = UDim2.new(0, 10, 0, 50)
Scripttable.abilityScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
Scripttable.abilityScrollFrame.ScrollBarThickness = 4
Scripttable.abilityScrollFrame.BackgroundTransparency = 1
Scripttable.abilityScrollFrame.ScrollBarImageColor3 = Scripttable.Theme.Border
Scripttable.abilityScrollFrame.ZIndex = 11
Scripttable.abilityScrollFrame.Parent = Scripttable.abilityFrame

Scripttable.abilityListLayout = Instance.new("UIListLayout")
Scripttable.abilityListLayout.SortOrder = Enum.SortOrder.LayoutOrder
Scripttable.abilityListLayout.Padding = UDim.new(0, 8)
Scripttable.abilityListLayout.Parent = Scripttable.abilityScrollFrame

Scripttable.abilityListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Scripttable.abilityScrollFrame.CanvasSize = UDim2.new(0, 0, 0, Scripttable.abilityListLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- 參數面板 Helper 函數
-- ============================================================
Mainfunction.createLabel = function(key, parent, order)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 25)
	label.BackgroundTransparency = 1
	label.TextColor3 = Scripttable.Theme.TextDim
	label.Font = Scripttable.Theme.FontBold
	label.TextSize = Scripttable.Theme.SizeNormal
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = order
	label.ZIndex = 13
	label.Parent = parent
	Mainfunction.bindText(label, key)
	return label
end

Mainfunction.createToggle = function(labelKey, parent, order, defaultValue, callback, descKey)
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
	lbl.TextColor3 = Scripttable.Theme.Text
	lbl.Font = Scripttable.Theme.Font
	lbl.TextSize = Scripttable.Theme.SizeNormal
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 13
	lbl.Parent = frame
	Mainfunction.bindText(lbl, labelKey)

	local isOn = defaultValue
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 55, 0, 28)
	btn.Position = UDim2.new(1, -60, 0, 6)
	btn.BackgroundColor3 = isOn and Scripttable.Theme.Success or Scripttable.Theme.SurfaceHighlight
	btn.Text = isOn and Mainfunction.T("toggleOn") or Mainfunction.T("toggleOff")
	btn.TextColor3 = isOn and Scripttable.Theme.TextDark or Scripttable.Theme.TextDim
	btn.Font = Scripttable.Theme.FontBold
	btn.TextSize = Scripttable.Theme.SizeNormal
	btn.BorderSizePixel = 0
	btn.ZIndex = 13
	btn.Parent = frame
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 14)
		c.Parent = btn
	end

	local function paint()
		btn.BackgroundColor3 = isOn and Scripttable.Theme.Success or Scripttable.Theme.SurfaceHighlight
		btn.Text = isOn and Mainfunction.T("toggleOn") or Mainfunction.T("toggleOff")
		btn.TextColor3 = isOn and Scripttable.Theme.TextDark or Scripttable.Theme.TextDim
	end

	table.insert(Scripttable.i18nToggleBtns, {
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
		descLabel.Font = Scripttable.Theme.Font
		descLabel.TextSize = 14
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.ZIndex = 13
		descLabel.Parent = frame
		Mainfunction.bindText(descLabel, descKey)
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
Mainfunction.createLabel("lblInterface", Scripttable.paramScrollFrame, 1)
Mainfunction.createToggle("lblAutoScroll", Scripttable.paramScrollFrame, 2, true, function(v)
	Scripttable.autoScrollEnabled = v
end)

Mainfunction.createLabel("lblGameInfo", Scripttable.paramScrollFrame, 3)

Scripttable.infoLabel = Instance.new("TextLabel")
Scripttable.infoLabel.Size = UDim2.new(1, 0, 0, 120)
Scripttable.infoLabel.BackgroundColor3 = Scripttable.Theme.Surface
Scripttable.infoLabel.BackgroundTransparency = 0.5
Scripttable.infoLabel.TextColor3 = Scripttable.Theme.Success
Scripttable.infoLabel.Font = Scripttable.Theme.Font
Scripttable.infoLabel.TextSize = 15
Scripttable.infoLabel.TextWrapped = true
Scripttable.infoLabel.LayoutOrder = 9
Scripttable.infoLabel.ZIndex = 13
Scripttable.infoLabel.Parent = Scripttable.paramScrollFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = Scripttable.infoLabel
end
Mainfunction.updateInfoLabel()

Mainfunction.createLabel("lblTrackerOp", Scripttable.paramScrollFrame, 11)

Scripttable.trackerBtnContainer = Instance.new("Frame")
Scripttable.trackerBtnContainer.Size = UDim2.new(1, 0, 0, 40)
Scripttable.trackerBtnContainer.BackgroundTransparency = 1
Scripttable.trackerBtnContainer.LayoutOrder = 12
Scripttable.trackerBtnContainer.ZIndex = 12
Scripttable.trackerBtnContainer.Parent = Scripttable.paramScrollFrame
do
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 8)
	l.Parent = Scripttable.trackerBtnContainer
end

Scripttable.resetBtn = Instance.new("TextButton")
Scripttable.resetBtn.Size = UDim2.new(0.5, -4, 1, 0)
Scripttable.resetBtn.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
Scripttable.resetBtn.TextColor3 = Scripttable.Theme.Warning
Scripttable.resetBtn.Font = Scripttable.Theme.FontBold
Scripttable.resetBtn.TextSize = Scripttable.Theme.SizeNormal
Scripttable.resetBtn.BorderSizePixel = 0
Scripttable.resetBtn.LayoutOrder = 1
Scripttable.resetBtn.ZIndex = 13
Scripttable.resetBtn.Parent = Scripttable.trackerBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.resetBtn
end
Mainfunction.bindText(Scripttable.resetBtn, "btnReset")

Scripttable.debugBtn = Instance.new("TextButton")
Scripttable.debugBtn.Size = UDim2.new(0.5, -4, 1, 0)
Scripttable.debugBtn.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
Scripttable.debugBtn.TextColor3 = Scripttable.Theme.TextDim
Scripttable.debugBtn.Font = Scripttable.Theme.FontBold
Scripttable.debugBtn.TextSize = Scripttable.Theme.SizeNormal
Scripttable.debugBtn.BorderSizePixel = 0
Scripttable.debugBtn.LayoutOrder = 2
Scripttable.debugBtn.ZIndex = 13
Scripttable.debugBtn.Parent = Scripttable.trackerBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Scripttable.Theme.CornerRadius
	c.Parent = Scripttable.debugBtn
end
Mainfunction.bindText(Scripttable.debugBtn, "btnDebug")

Mainfunction.createLabel("lblScriptParam", Scripttable.paramScrollFrame, 13)
Mainfunction.createToggle("lblAutoReplay", Scripttable.paramScrollFrame, 14, Scripttable.ScriptSettings.AutoReplay, function(v)
	Scripttable.ScriptSettings.AutoReplay = v
end)
Mainfunction.createToggle("lblCostMode", Scripttable.paramScrollFrame, 16, Scripttable.ScriptSettings.CostMode, function(v)
	Scripttable.ScriptSettings.CostMode = v
end, "lblCostModeDesc")

-- 自動跳過波次：直接改遊戲設定 (走 Nodes 層的 CLIENT_CHANGE_SETTING)。
Scripttable.autoSkipToggle = Mainfunction.createToggle("lblAutoSkipWaves", Scripttable.paramScrollFrame, 17, Scripttable.autoSkipState.on, function(v)
	pcall(function()
		Adapter.SetAutoSkipWaves(v)
	end)
end, "lblAutoSkipWavesDesc")

Mainfunction.createToggle("lblAutoSkipCheckpoint", Scripttable.paramScrollFrame, 18, Scripttable.ScriptSettings.AutoSkipCheckpoint, function(v)
	Scripttable.ScriptSettings.AutoSkipCheckpoint = v
	pcall(Mainfunction.updateInfoLabel)
end, "lblAutoSkipCheckpointDesc")

-- ============================================================

-- ============================================================
-- 拖移功能
-- ============================================================
Mainfunction.makeDraggable = function(uiElement)
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
		local delta = Gametable.UserInputService:GetMouseLocation() - state.dragStart
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
			state.dragStart = Gametable.UserInputService:GetMouseLocation()
			state.startPos = uiElement.Position
			if not renderConn then
				renderConn = Gametable.RunService.RenderStepped:Connect(update)
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

Mainfunction.makeDraggable(Scripttable.parameterFrame)
Mainfunction.makeDraggable(Scripttable.saveFrame)
Mainfunction.makeDraggable(Scripttable.manageFrame)
Mainfunction.makeDraggable(Scripttable.abilityFrame)

Scripttable.tbDrag = {
	dragging = false,
}
Scripttable.tbConn = nil
Scripttable.titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Scripttable.tbDrag.dragging = true
		Scripttable.tbDrag.dragStart = Gametable.UserInputService:GetMouseLocation()
		Scripttable.tbDrag.startPos = Scripttable.mainFrame.Position
		if not Scripttable.tbConn then
			Scripttable.tbConn = Gametable.RunService.RenderStepped:Connect(function()
				if not Scripttable.tbDrag.dragging then
					return
				end
				local d = Gametable.UserInputService:GetMouseLocation() - Scripttable.tbDrag.dragStart
				Scripttable.mainFrame.Position = UDim2.new(
					Scripttable.tbDrag.startPos.X.Scale,
					Scripttable.tbDrag.startPos.X.Offset + d.X,
					Scripttable.tbDrag.startPos.Y.Scale,
					Scripttable.tbDrag.startPos.Y.Offset + d.Y
				)
			end)
		end
	end
end)
Scripttable.titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Scripttable.tbDrag.dragging = false
		if Scripttable.tbConn then
			Scripttable.tbConn:Disconnect()
			Scripttable.tbConn = nil
		end
	end
end)

-- ============================================================
-- 收合功能
-- ============================================================
Scripttable.minimized = false
Mainfunction.toggleMinimize = function()
	Scripttable.minimized = not Scripttable.minimized
	Scripttable.scrollFrame.Visible = not Scripttable.minimized
	Scripttable.copyBtn.Visible = not Scripttable.minimized
	Scripttable.saveBtn.Visible = not Scripttable.minimized
	Scripttable.Parameter.Visible = not Scripttable.minimized
	Scripttable.abilityBtn.Visible = not Scripttable.minimized
	Scripttable.minimizeBtn.Text = Scripttable.minimized and "+" or "—"
	Gametable.TweenService:Create(Scripttable.mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Size = Scripttable.minimized and Scripttable.UISizes.mainFrameMinimized or Scripttable.UISizes.mainFrameExpanded,
	}):Play()
end
Scripttable.minimizeBtn.MouseButton1Click:Connect(Mainfunction.toggleMinimize)

-- ============================================================
-- 面板互斥
-- ============================================================
Mainfunction.closeAllPanels = function()
	Scripttable.parameterFrame.Visible = false
	Scripttable.saveFrame.Visible = false
	Scripttable.manageFrame.Visible = false
	Scripttable.abilityFrame.Visible = false
end

Mainfunction.closeBlockingPanels = function()
	Scripttable.saveFrame.Visible = false
	Scripttable.manageFrame.Visible = false
end

Mainfunction.positionAbilityFrame = function()
	if Scripttable.parameterFrame.Visible then
		Scripttable.abilityFrame.Position = UDim2.new(
			Scripttable.parameterFrame.Position.X.Scale,
			Scripttable.parameterFrame.Position.X.Offset + Scripttable.parameterFrame.AbsoluteSize.X + 10,
			Scripttable.parameterFrame.Position.Y.Scale,
			Scripttable.parameterFrame.Position.Y.Offset
		)
	else
		Scripttable.abilityFrame.Position = UDim2.new(
			Scripttable.mainFrame.Position.X.Scale,
			Scripttable.mainFrame.Position.X.Offset + Scripttable.mainFrame.AbsoluteSize.X + 10,
			Scripttable.mainFrame.Position.Y.Scale,
			Scripttable.mainFrame.Position.Y.Offset
		)
	end
end

Mainfunction.openSavePanel = function()
	Mainfunction.closeAllPanels()
	-- 檔名格式: 模式_地圖名稱_地圖等級_時間
	local defaultName = string.format(
		"%s_%s_%s_%s",
		Gametable.gameSettings.gamemode or "Mode",
		Gametable.gameStartMapId or Gametable.gameSettings.mapId or "Map",
		Gametable.gameSettings.actName or "Act",
		os.date("%Y%m%d_%H%M%S")
	)
	defaultName = defaultName:gsub("[^%w_%-]", "_")
	Scripttable.fileNameInput.Text = defaultName

	Scripttable.currentSaveMode = "merged"
	Mainfunction.updateSaveModeButtons()
	Mainfunction.relayoutSavePanel()

	Scripttable.saveFrame.Visible = true
end

-- ============================================================
-- 檔案操作
-- ============================================================
Mainfunction.listScripts = function()
	local scripts = {}
	pcall(function()
		if listfiles then
			for _, fp in ipairs(listfiles(Scripttable.SCRIPT_SAVE_PATH)) do
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

Mainfunction.saveScriptToFile = function(fileName, content)
	local fullPath = Scripttable.SCRIPT_SAVE_PATH .. "/" .. fileName .. ".lua"
	local ok, err = pcall(function()
		if writefile then
			writefile(fullPath, content)
		else
			error("writefile unavailable")
		end
	end)
	if ok then
		Mainfunction.addLog(Mainfunction.T("logSaved"):format(fileName), Scripttable.Theme.Success)
		return true, fullPath
	else
		Mainfunction.addLog(Mainfunction.T("logSaveFailed"):format(tostring(err)), Scripttable.Theme.Error)
		return false, err
	end
end

Mainfunction.refreshScriptList = function()
	for _, child in pairs(Scripttable.manageScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local scripts = Mainfunction.listScripts()
	if #scripts == 0 then
		local el = Instance.new("TextLabel")
		el.Size = UDim2.new(1, -10, 0, 40)
		el.BackgroundTransparency = 1
		el.Text = Mainfunction.T("logNoScripts")
		el.TextColor3 = Scripttable.Theme.TextDim
		el.Font = Scripttable.Theme.Font
		el.TextSize = Scripttable.Theme.SizeNormal
		el.ZIndex = 12
		el.Parent = Scripttable.manageScrollFrame
		return
	end
	for i, script in ipairs(scripts) do
		local item = Instance.new("Frame")
		item.Size = UDim2.new(1, -5, 0, 45)
		item.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
		item.BackgroundTransparency = 0.3
		item.BorderSizePixel = 0
		item.LayoutOrder = i
		item.ZIndex = 12
		item.Parent = Scripttable.manageScrollFrame
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
		nl.TextColor3 = Scripttable.Theme.Text
		nl.Font = Scripttable.Theme.Font
		nl.TextSize = 14
		nl.TextXAlignment = Enum.TextXAlignment.Left
		nl.TextTruncate = Enum.TextTruncate.AtEnd
		nl.ZIndex = 13
		nl.Parent = item

		local runBtn = Instance.new("TextButton")
		runBtn.Size = UDim2.new(0, 35, 0, 30)
		runBtn.Position = UDim2.new(1, -130, 0, 7)
		runBtn.Text = "▶"
		runBtn.BackgroundColor3 = Scripttable.Theme.Success
		runBtn.TextColor3 = Scripttable.Theme.TextDark
		runBtn.Font = Scripttable.Theme.FontBold
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
		cpBtn.BackgroundColor3 = Scripttable.Theme.Accent
		cpBtn.TextColor3 = Scripttable.Theme.Text
		cpBtn.Font = Scripttable.Theme.FontBold
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
		dlBtn.BackgroundColor3 = Scripttable.Theme.Error
		dlBtn.TextColor3 = Scripttable.Theme.Text
		dlBtn.Font = Scripttable.Theme.FontBold
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
				Mainfunction.addLog(Mainfunction.T("logRunFailed"):format(sname), Scripttable.Theme.Error)
				return
			end
			local loadedFn, loadErr = loadstring(content)
			if not loadedFn then
				Mainfunction.addLog(Mainfunction.T("logRunFailed"):format(tostring(loadErr)), Scripttable.Theme.Error)
				return
			end
			Mainfunction.addLog(Mainfunction.T("logRunPhase1"):format(sname), Scripttable.Theme.Success)
			Scripttable.manageFrame.Visible = false
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
				Mainfunction.addLog(Mainfunction.T("logCopied"):format(sname), Scripttable.Theme.Accent)
			end
		end)
		dlBtn.MouseButton1Click:Connect(function()
			pcall(function()
				if delfile then
					delfile(fp)
				end
			end)
			Mainfunction.addLog(Mainfunction.T("logDeleted"):format(sname), Scripttable.Theme.Warning)
			Mainfunction.refreshScriptList()
		end)
	end
end

-- 生成腳本的 API 加載行
Scripttable.API_LOADER_LINE = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Anime-Expeditions/refs/heads/main/%E5%AF%86%E9%91%B0%E7%B3%BB%E7%B5%B1.lua"))()'

-- 生成腳本表頭要標的「這支追蹤器」的來源, 之後上線時換成實際 raw URL。
Scripttable.TRACKER_URL_LINE = 'https://raw.githubusercontent.com/Tseting-nil/Anime-Expeditions/refs/heads/main/Tool/%E6%94%BE%E7%BD%AE%E8%BF%BD%E8%B9%A4%E5%99%A8.lua")()'

-- 取這個操作的消耗 (成本版閘門用)。★ UpgradeInfo 的索引是【目標等級】。
Mainfunction.gateCost = function(op)
	if not op.unitName then
		return 0
	end
	local ok, cost = pcall(function()
		local U = require(Gametable.ReplicatedStorage.Shared.Information.Units)
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
Mainfunction.cfToArgs = function(cf)
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
Mainfunction.buildOperations = function()
	local ops = {}

	for order, info in pairs(Scripttable.orderToInfo) do
		table.insert(ops, {
			kind = "place",
			order = order,
			elapsed = info.Elapsed or 0,
			seq = info.Seq or 0,
			unitName = info.UnitType,
			slot = info.Slot,
			cframe = info.CFrame,
			target = 0, -- 放置 = 達到 0 等
			mut = Mainfunction.getMutLabel(info), -- " [Shiny]" / " [Shiny, Trait:X]" / ""
			backfilled = info.Backfilled,
			shiny = info.Shiny,
			trait = info.Trait,
		})
	end

	for _, e in ipairs(Scripttable.upgradeLog) do
		local order = Scripttable.idToOrder[e.GameID]
		if order then
			table.insert(ops, {
				kind = "upgrade",
				order = order,
				elapsed = e.Elapsed or 0,
				seq = e.Seq or 0,
				unitName = Scripttable.orderToInfo[order] and Scripttable.orderToInfo[order].UnitType,
				target = e.Level, -- 目標等級 = 成本索引
			})
		end
	end

	for _, e in ipairs(Scripttable.sellLog) do
		local order = Scripttable.idToOrder[e.GameID]
		if order then
			table.insert(ops, {
				kind = "sell",
				order = order,
				elapsed = e.Elapsed or 0,
				seq = e.Seq or 0,
				unitName = Scripttable.orderToInfo[order] and Scripttable.orderToInfo[order].UnitType,
			})
		end
	end

	for _, e in ipairs(Scripttable.skipWaveLog) do
		table.insert(ops, {
			kind = "skipwave",
			elapsed = e.Elapsed or 0,
			seq = e.Seq or 0,
			title = e.Title,
		})
	end

	local hasGameStartOp = false
	for _, e in ipairs(Scripttable.gameStartLog or {}) do
		hasGameStartOp = true
		table.insert(ops, {
			kind = "gamestart",
			elapsed = e.Elapsed or 0,
			seq = e.Seq or 0,
		})
	end

	for _, e in ipairs(Scripttable.gameStart2Log or {}) do
		hasGameStartOp = true
		table.insert(ops, {
			kind = "gamestart2",
			elapsed = e.Elapsed or 0,
			seq = e.Seq or 0,
		})
	end

	table.sort(ops, function(a, b)
		return a.seq < b.seq
	end)
	return ops, hasGameStartOp
end

Mainfunction.fmtDuration = function(sec)
	sec = math.max(0, math.floor(sec or 0))
	return string.format("%dm %ds", math.floor(sec / 60), sec % 60)
end

-- 用過的塔清單 (依首次放置順序, 去重), 附閃亮/天賦註記
-- 顯示成「顯示名稱 (資產名)」: 註解給人看要玩家名, 但保留資產名對照 (腳本 EquipLoadout/AddPlaceUnit 用的是資產名)。
Mainfunction.usedUnits = function(ops)
	local seen, list = {}, {}
	for _, op in ipairs(ops) do
		if op.kind == "place" and op.unitName then
			local key = tostring(op.unitName) .. (op.mut or "")
			if not seen[key] then
				seen[key] = true
				local asset = tostring(op.unitName)
				local disp = Mainfunction.displayName(op.unitName)
				local label = (disp ~= asset) and string.format("%s (%s)", disp, asset) or asset
				table.insert(list, label .. (op.mut or ""))
			end
		end
	end
	return list
end

-- 生成腳本
Mainfunction.generateScript = function()
	local ops, hasGameStartOp = Mainfunction.buildOperations()
	if #ops == 0 then
		return nil
	end

	local spd = (Scripttable.script_SpeedMultiplier and Scripttable.script_SpeedMultiplier > 0) and Scripttable.script_SpeedMultiplier or 1
	local costMode = Scripttable.ScriptSettings.CostMode == true
	local totalSec = (Gametable.gameEndElapsed or Mainfunction.getElapsed() or 0) / spd
	local units = Mainfunction.usedUnits(ops)

	local backfilled = 0
	for _, op in ipairs(ops) do
		if op.backfilled then
			backfilled = backfilled + 1
		end
	end

	local skipAtStart = (Gametable.isGameRunning or Gametable.gameEndElapsed) and Gametable.gameStartAutoSkipWave or Scripttable.autoSkipState.on

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
	b(string.format("Map: %s [%s] |  Difficulty: %s  |  Mode: %s", Gametable.gameSettings.mapId, Gametable.gameSettings.actName, Gametable.gameSettings.difficulty, Gametable.gameSettings.gamemode))
	b(string.format("Time: %s (%.1fs)", Mainfunction.fmtDuration(totalSec), totalSec))
	if Scripttable.customComment and Scripttable.customComment ~= "" then
		b("Note: " .. tostring(Scripttable.customComment))
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
		if Scripttable.gameStartApprox then
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
	b("\t" .. Scripttable.API_LOADER_LINE)
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
				local item = Mainfunction.displayName(op.unitName)
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
		Gametable.gameSettings.mapId,
		Gametable.gameSettings.difficulty,
		Gametable.gameSettings.gamemode,
		Gametable.gameSettings.actName
	))
	b("\treturn")
	b("end")
	b("")
	b("if AE.IsInGame() then")
	b("\t-- initialization")
	b("\tAE.DisplayEndRewards(false)")
	if Scripttable.ScriptSettings.AutoReplay then
		b("\tAE.AutoReplay(true)")
	end
  b("\tAE.AutoStartgameui(true)")
	if Scripttable.ScriptSettings.AutoSkipCheckpoint or Gametable.gameSettings.gamemode == "Expedition" then
		b("\tAE.AutoSkipcheckpoint(true)")
	end
	b(string.format("\tAE.AddSetSetting(%q, %s, 0)", "AutoSkipWaves", tostring(skipAtStart == true)))
	local gameStartWritten = false
	local gameStart2Written = false
	if not hasGameStartOp then
		gameStartWritten = true
		b("\tAE.AddGameStart()")
	end
	b("\t-- Start")

	for _, op in ipairs(ops) do
		local uName = op.unitName and Mainfunction.displayName(op.unitName) or ""
		local nameTag = (uName ~= "") and (uName .. " ") or ""

		-- 閘門: 成本版 = 消耗字串 (API 等 Yen 夠才動作); 時間版 = 開局後秒數
		local gate, tail
		if costMode then
			local cost = Mainfunction.gateCost(op)
			gate = (op.kind == "sell" or op.kind == "sellall") and "0" or string.format("%q", tostring(cost))
			tail = string.format(" -- #%d %s$%s", op.order or 0, nameTag, tostring(cost))
		else
			local t = (op.elapsed or 0) / spd
			if Scripttable.timeRoundUp then
				t = math.ceil(t)
			end
			gate = string.format("%.2f", t)
			tail = string.format(" -- #%d %s+%.1fs", op.order or 0, nameTag, t)
		end

		if op.kind == "gamestart" then
			if not gameStartWritten then
				gameStartWritten = true
				b("\tAE.AddGameStart()")
			end
		elseif op.kind == "gamestart2" then
			if not gameStart2Written then
				gameStart2Written = true
				b("\tAE.AddGameStart2()")
			end
		elseif op.kind == "place" then
			local placeTail = costMode and string.format(" -- #%d $%s", op.order or 0, tostring(Mainfunction.gateCost(op))) or string.format(" -- #%d +%.1fs", op.order or 0, (Scripttable.timeRoundUp and math.ceil((op.elapsed or 0) / spd) or ((op.elapsed or 0) / spd)))
			b(string.format(
				"\tAE.AddPlaceUnit(%q, %s, %s)%s%s%s",
				tostring(op.unitName),
				gate,
				Mainfunction.cfToArgs(op.cframe),
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
	w("  URL: " .. Scripttable.TRACKER_URL_LINE)
	w(string.format("  Map: %s [%s] |  Difficulty: %s | Mode: %s", Gametable.gameSettings.mapId, Gametable.gameSettings.actName, Gametable.gameSettings.difficulty, Gametable.gameSettings.gamemode))
	w(string.format("  Time: %s", Mainfunction.fmtDuration(totalSec)))
	w("]]")
	w("")
	w("local fullScript = [=[")
	w(inner)
	w("]=]")
	w("")
	w("local AE = getgenv().AE")
	w("if not AE or not AE.ExecuteQueue then")
	w("\t" .. Scripttable.API_LOADER_LINE)
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
-- abiCardOrder is in Scripttable.abiCardOrder

Mainfunction.buildAbilityCard = function(model)
	if Scripttable.abiTowerCards[model] then
		return
	end
	local info = Scripttable.abiLiveTowers[model]
	if not info or not info.abilityKeys or #info.abilityKeys == 0 then
		return
	end

	if Scripttable.abiEmptyLabel then
		Scripttable.abiEmptyLabel.Visible = false
	end

	Scripttable.abiCardOrder = Scripttable.abiCardOrder + 1
	local hasId = info.gameId ~= nil
	local idStr = hasId and tostring(info.gameId) or "?"

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -4, 0, 0)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.BackgroundColor3 = Scripttable.Theme.Surface
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.LayoutOrder = Scripttable.abiCardOrder
	container.ZIndex = 12
	container.Parent = Scripttable.abilityScrollFrame
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
		local abi = Mainfunction.getAbiData(key)
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
			Mainfunction.T("abilityFmt"):format(abi.Name, abi.Cooldown)
		)
		abiLabel.TextColor3 = Scripttable.Theme.Accent
		abiLabel.Font = Scripttable.Theme.FontBold
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
		barBg.BackgroundColor3 = Scripttable.Theme.SurfaceHighlight
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
		barFill.BackgroundColor3 = Scripttable.Theme.Success
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
		barText.Text = hasId and Mainfunction.T("abilityReady") or Mainfunction.T("abilityWaitId")
		barText.TextColor3 = Scripttable.Theme.Text
		barText.Font = Scripttable.Theme.FontBold
		barText.TextSize = 12
		barText.ZIndex = 16
		barText.Parent = barBg

		local fireBtn = Instance.new("TextButton")
		fireBtn.Size = UDim2.new(0.65, -4, 1, 0)
		fireBtn.Position = UDim2.new(0, 0, 0, 0)
		fireBtn.BackgroundTransparency = 1
		fireBtn.Text = ""
		fireBtn.TextColor3 = hasId and Scripttable.Theme.Text or Scripttable.Theme.TextDim
		fireBtn.Font = Scripttable.Theme.FontBold
		fireBtn.TextSize = 13
		fireBtn.BorderSizePixel = 0
		fireBtn.ZIndex = 17
		fireBtn.Parent = btnRow

		fireBtn.MouseButton1Click:Connect(function()
			Mainfunction.invokeTowerAbilitySafely(model, capturedKey, capturedCd)
		end)

		local autoState = {
			enabled = autoEnabled,
		}
		local autoBtn = Instance.new("TextButton")
		autoBtn.Size = UDim2.new(0.35, -4, 1, 0)
		autoBtn.Position = UDim2.new(0.65, 4, 0, 0)
		autoBtn.BackgroundColor3 = autoState.enabled and Scripttable.Theme.Success or Scripttable.Theme.SurfaceHighlight
		autoBtn.Text = Mainfunction.T("abilityAutoLabel") .. (autoState.enabled and " ✓" or "")
		autoBtn.TextColor3 = autoState.enabled and Scripttable.Theme.TextDark or Scripttable.Theme.TextDim
		autoBtn.Font = Scripttable.Theme.FontBold
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
			autoBtn.BackgroundColor3 = autoState.enabled and Scripttable.Theme.Success or Scripttable.Theme.SurfaceHighlight
			autoBtn.Text = Mainfunction.T("abilityAutoLabel") .. (autoState.enabled and " ✓" or "")
			autoBtn.TextColor3 = autoState.enabled and Scripttable.Theme.TextDark or Scripttable.Theme.TextDim
		end)

		if idx < #info.abilityKeys then
			local sep = Instance.new("Frame")
			sep.Size = UDim2.new(1, 0, 0, 1)
			sep.BackgroundColor3 = Scripttable.Theme.Border
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
	Scripttable.abiTowerCards[model] = {
		container = container,
		widgets = widgets,
	}
end

Mainfunction.removeAbilityCard = function(model)
	local card = Scripttable.abiTowerCards[model]
	if not card then
		return
	end
	if Scripttable.abiLiveTowers[model] then
		local saved = {}
		for _, w in ipairs(card.widgets) do
			saved[w.key] = w.autoState.enabled
		end
		Scripttable.abiLiveTowers[model].savedAutoStates = saved
	end
	card.container:Destroy()
	Scripttable.abiTowerCards[model] = nil

	if not next(Scripttable.abiTowerCards) and Scripttable.abiEmptyLabel then
		Scripttable.abiEmptyLabel.Visible = true
	end
end

-- 實作 forward-declared rebuildAllAbilityCards
Mainfunction.rebuildAllAbilityCards = function()
	for model in pairs(Scripttable.abiTowerCards) do
		Mainfunction.removeAbilityCard(model)
	end
	for model in pairs(Scripttable.abiLiveTowers) do
		Mainfunction.buildAbilityCard(model)
	end
end

Mainfunction.abiBindGameId = function(model, gameId)
	local info = Scripttable.abiLiveTowers[model]
	if not info or info.gameId ~= nil then
		return
	end
	info.gameId = gameId
	Scripttable.abiModelByGameId[gameId] = model
	if Scripttable.abiGameIdCooldownHint[gameId] then
		for k, t0 in pairs(Scripttable.abiGameIdCooldownHint[gameId]) do
			info.cooldowns[k] = t0
		end
		Scripttable.abiGameIdCooldownHint[gameId] = nil
	end
	if Scripttable.abiTowerCards[model] then
		Mainfunction.removeAbilityCard(model)
		Mainfunction.buildAbilityCard(model)
	end
end

-- 空提示標籤
Scripttable.abiEmptyLabel = Instance.new("TextLabel")
Scripttable.abiEmptyLabel.Size = UDim2.new(1, -10, 0, 40)
Scripttable.abiEmptyLabel.BackgroundTransparency = 1
Scripttable.abiEmptyLabel.Text = Mainfunction.T("abilityNoTowers")
Scripttable.abiEmptyLabel.TextColor3 = Scripttable.Theme.TextDim
Scripttable.abiEmptyLabel.Font = Scripttable.Theme.Font
Scripttable.abiEmptyLabel.TextSize = Scripttable.Theme.SizeNormal
Scripttable.abiEmptyLabel.ZIndex = 12
Scripttable.abiEmptyLabel.LayoutOrder = 9999
Scripttable.abiEmptyLabel.Parent = Scripttable.abilityScrollFrame

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
Scripttable.copyBtn.MouseButton1Click:Connect(function()
	local s = Mainfunction.generateScript()
	if s then
		local ok = pcall(setclipboard, s)
		if ok then
			Mainfunction.addLog(Mainfunction.T("logCopyOk"), Color3.fromRGB(100, 255, 100))
			Scripttable.copyBtn.Text = Mainfunction.T("btnCopied")
			Scripttable.copyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
			print("\n========== Generated Script ==========")
			print(s)
			print("=======================================\n")
			task.wait(2)
			Scripttable.copyBtn.Text = Mainfunction.T("btnCopy")
			Scripttable.copyBtn.BackgroundColor3 = Scripttable.Theme.Success
		else
			Mainfunction.addLog(Mainfunction.T("logCopyConsole"), Scripttable.Theme.Warning)
			print(s)
		end
	end
end)

Scripttable.saveBtn.MouseButton1Click:Connect(Mainfunction.openSavePanel)

Scripttable.confirmSaveBtn.MouseButton1Click:Connect(function()
	local fileName = Scripttable.fileNameInput.Text:gsub("[^%w_%-]", "_")
	if fileName == "" or fileName:match("^_+$") then
		Mainfunction.addLog(Mainfunction.T("logInvalidName"), Scripttable.Theme.Warning)
		return
	end
	local s = Mainfunction.generateScript()
	if s then
		local ok = Mainfunction.saveScriptToFile(fileName, s)
		if ok then
			Scripttable.saveFrame.Visible = false
		end
	end
end)

Scripttable.cancelSaveBtn.MouseButton1Click:Connect(function()
	Scripttable.saveFrame.Visible = false
end)
Scripttable.saveCloseBtn.MouseButton1Click:Connect(function()
	Scripttable.saveFrame.Visible = false
end)
Scripttable.manageCloseBtn.MouseButton1Click:Connect(function()
	Scripttable.manageFrame.Visible = false
end)
Scripttable.closeBtn.MouseButton1Click:Connect(function()
	Scripttable.parameterFrame.Visible = false
end)
Scripttable.abilityCloseBtn.MouseButton1Click:Connect(function()
	Scripttable.abilityFrame.Visible = false
end)
Scripttable.refreshScriptsBtn.MouseButton1Click:Connect(function()
	Mainfunction.refreshScriptList()
end)

Scripttable.Parameter.MouseButton1Click:Connect(function()
	if not Scripttable.parameterFrame.Visible then
		Mainfunction.closeBlockingPanels()
		Scripttable.parameterFrame.Position = UDim2.new(
			Scripttable.mainFrame.Position.X.Scale,
			Scripttable.mainFrame.Position.X.Offset + Scripttable.mainFrame.AbsoluteSize.X + 10,
			Scripttable.mainFrame.Position.Y.Scale,
			Scripttable.mainFrame.Position.Y.Offset
		)
		Scripttable.parameterFrame.Visible = true
		if Scripttable.abilityFrame.Visible then
			Mainfunction.positionAbilityFrame()
		end
	else
		Scripttable.parameterFrame.Visible = false
		if Scripttable.abilityFrame.Visible then
			Mainfunction.positionAbilityFrame()
		end
	end
end)

Scripttable.abilityBtn.MouseButton1Click:Connect(function()
	if not Scripttable.abilityFrame.Visible then
		Mainfunction.closeBlockingPanels()
		Mainfunction.positionAbilityFrame()
		Scripttable.abilityFrame.Visible = true
	else
		Scripttable.abilityFrame.Visible = false
	end
end)

Scripttable.resetBtn.MouseButton1Click:Connect(function()
	Scripttable.nextOrder = 1
	Scripttable.orderToInfo = {}
	Scripttable.idToOrder = {}
	Scripttable.upgradeLog = {}
	Scripttable.sellLog = {}
	Scripttable.skipWaveLog = {}
	Scripttable.speedChangeLog = {}
	Scripttable.abilityLog = {}
	Scripttable.gameSettingLog = {}
	Scripttable.gameStartLog = {}
	Scripttable.gameStart2Log = {}
	Gametable.gameStartAutoSkipWave = false
	Gametable.lastDetectedSpeed = 1
	local sessTime = Mainfunction.getSessionTime and Mainfunction.getSessionTime() or nil
	if sessTime then
		Gametable.isGameRunning = true
		Gametable.gameStartSession = sessTime
	else
		Gametable.isGameRunning = false
		Gametable.gameStartSession = nil
	end
	Gametable.gameStartApprox = false
	Gametable.gameEndElapsed = nil
	Gametable.gameStartMapId = nil
	Scripttable.mapTransitionLog = {}
	Scripttable.readyHooked = false
	Gametable.gameStartedLogged = false
	Gametable.gameStart2Logged = false

	-- 重置能力面板
	for model in pairs(Scripttable.abiTowerCards) do
		Mainfunction.removeAbilityCard(model)
	end
	Scripttable.abiLiveTowers = {}
	Scripttable.abiModelByGameId = {}
	Scripttable.abiPendingGameIds = {}
	Scripttable.abiGameIdCooldownHint = {}
	Scripttable.abiRemoteInFlight = {}
	Scripttable.abiNextOrder = 1
	Scripttable.abiCardOrder = 0
	if Scripttable.abiEmptyLabel then
		Scripttable.abiEmptyLabel.Visible = true
	end

	-- 改由 Adapter 從 GameState replica 回填。
	pcall(function()
		Adapter.ReadGameSettings()
	end)

	for _, child in pairs(Scripttable.scrollFrame:GetChildren()) do
		child:Destroy()
	end
	Scripttable.listLayout:Destroy()
	Scripttable.listLayout = Instance.new("UIListLayout")
	Scripttable.listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	Scripttable.listLayout.Padding = UDim.new(0, 8)
	Scripttable.listLayout.Parent = Scripttable.scrollFrame
	Scripttable.listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Scripttable.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, Scripttable.listLayout.AbsoluteContentSize.Y + 10)
	end)
	Scripttable.logOrder = 1

	Mainfunction.updateInfoLabel()
	Mainfunction.addLog(Mainfunction.T("logReset"), Color3.fromRGB(100, 200, 255))
end)

Scripttable.debugBtn.MouseButton1Click:Connect(function()
	Mainfunction.addLog(Mainfunction.T("logTowerListHdr"), Color3.fromRGB(100, 200, 255))
	if Scripttable.nextOrder <= 1 then
		Mainfunction.addLog(Mainfunction.T("logNoRecord"), Scripttable.Theme.TextDim)
	else
		for order = 1, Scripttable.nextOrder - 1 do
			local info = Scripttable.orderToInfo[order]
			if info then
				Mainfunction.addLog(
					Mainfunction.T("logTowerItem"):format(
						info.order,
						Mainfunction.displayName(info.UnitType) .. Mainfunction.getMutLabel(info),
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
Gametable.UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.F8 and not gp then
		Scripttable.uiVisible = not Scripttable.uiVisible
		Scripttable.mainFrame.Visible = Scripttable.uiVisible
		if not Scripttable.uiVisible then
			Mainfunction.closeAllPanels()
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
Mainfunction.fmtGate = function(elapsed, unitName, targetLevel)
	local cost
	pcall(function()
		local U = require(Gametable.ReplicatedStorage.Shared.Information.Units)
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
		pcall(Mainfunction.addLog, Mainfunction.T("logNotImplemented"):format(what), Scripttable.Theme.Warning)
	end
	return nil
end

Gametable.CollectionService = game:GetService("CollectionService")

Mainfunction.getPayloadInstance = function()
	for _, inst in ipairs(Gametable.CollectionService:GetTagged("Payload")) do
		if inst and inst:IsA("PVInstance") then return inst end
	end
	for _, inst in ipairs(Gametable.CollectionService:GetTagged("Cart")) do
		if inst and inst:IsA("PVInstance") then return inst end
	end
	local map = workspace:FindFirstChild("Map")
	if map then
		local payload = map:FindFirstChild("Payload", true) or map:FindFirstChild("Cart", true)
		if payload and payload:IsA("PVInstance") then return payload end
	end
	local payload = workspace:FindFirstChild("Payload", true) or workspace:FindFirstChild("Cart", true)
	if payload and payload:IsA("PVInstance") then return payload end
	return nil
end

Mainfunction.getPayloadCFrame = function()
	local inst = Mainfunction.getPayloadInstance()
	if inst then
		if inst:IsA("Model") then
			local primary = inst.PrimaryPart
			if primary then return primary.CFrame end
			return inst:GetPivot()
		elseif inst:IsA("BasePart") then
			return inst.CFrame
		end
	end
	local r = (type(Mainfunction.aeFind) == "function") and Mainfunction.aeFind("PayloadData") or nil
	if r and r.Data then
		if typeof(r.Data.CFrame) == "CFrame" then
			return r.Data.CFrame
		elseif typeof(r.Data.Position) == "Vector3" then
			return CFrame.new(r.Data.Position)
		end
	end
	return nil
end

-- Adapter 偵測到放置時呼叫 (來源: ReplicaClient.OnNew GameUnit/GamePhantom)
-- unitName: 單位內部名; gameId: 伺服器建立的實例 id; cframe: 伺服器吸附後的位置
function Tracker.OnPlace(unitName, gameId, cframe, extra)
	if not Gametable.isGameRunning then
		Mainfunction.startGameTimer(Gametable.gameSettings.mapId)
	end
	local order = Scripttable.nextOrder
	Scripttable.nextOrder = Scripttable.nextOrder + 1
	local elapsed = Mainfunction.elapsedFromPlacedAt(extra and extra.placedAt) or Mainfunction.getElapsed()

	local payloadCF = Mainfunction.getPayloadCFrame()
	local recCF = cframe
	if payloadCF and cframe then
		recCF = payloadCF:ToObjectSpace(cframe)
	end

	Scripttable.orderToInfo[order] = {
		order = order,
		UnitType = unitName,
		GameID = gameId,
		UUID = extra and extra.uuid or nil,
		CFrame = recCF,
		RawCFrame = cframe,
		HasPayload = (payloadCF ~= nil),
		Elapsed = elapsed,
		PlacedAt = extra and extra.placedAt or nil,
		Seq = Mainfunction.nextSeq(),
		Shiny = extra and extra.shiny or nil,
		Trait = extra and extra.trait or nil,
		Backfilled = extra and extra.backfilled or nil,
	}
	if gameId then
		Scripttable.idToOrder[gameId] = order
	end
	-- 放置 [腳本內標記ID] [塔名稱] [當局遊戲ID] [時間|金錢]
	Mainfunction.addLog(
		Mainfunction.T("logPlaceFmt"):format(
			order,
			Mainfunction.displayName(unitName) .. Mainfunction.getMutLabel(Scripttable.orderToInfo[order]),
			tostring(gameId),
			Mainfunction.fmtGate(elapsed, unitName, 0) -- 放置 = 達到 0 等 (成本查表用資產名)
		),
		Scripttable.Theme.Success
	)
	return order
end

-- 來源: aeWatchUpgrades 的 replica:OnChange (伺服器自動升級不送封包)
function Tracker.OnUpgrade(gameId, level)
	local elapsed = Mainfunction.getElapsed()
	table.insert(Scripttable.upgradeLog, { GameID = gameId, Level = level, Elapsed = elapsed, Seq = Mainfunction.nextSeq() })
	-- 升級 [塔名稱] [腳本內標記ID] [時間|金錢]
	local order = Scripttable.idToOrder[gameId]
	local info = order and Scripttable.orderToInfo[order]
	local name = (info and info.UnitType) or "?"
	Mainfunction.addLog(
		Mainfunction.T("logUpgradeFmt"):format(
			Mainfunction.displayName(name) .. (info and Mainfunction.getMutLabel(info) or ""),
			tostring(order or Mainfunction.T("logUntracked")),
			Mainfunction.fmtGate(elapsed, name, level) -- 成本索引 = 目標等級 (查表用資產名 name)
		),
		Scripttable.Theme.Accent
	)
end

-- SellGameUnit / SellAllGameUnits
function Tracker.OnSell(gameId)
	local elapsed = Mainfunction.getElapsed()
	table.insert(Scripttable.sellLog, { GameID = gameId, Elapsed = elapsed, Seq = Mainfunction.nextSeq() })
	local order = Scripttable.idToOrder[gameId]
	local info = order and Scripttable.orderToInfo[order]
	Mainfunction.addLog(
		Mainfunction.T("logSellFmt"):format(
			Mainfunction.displayName((info and info.UnitType) or "?") .. (info and Mainfunction.getMutLabel(info) or ""),
			tostring(order or Mainfunction.T("logUntracked")),
			string.format("+%.1fs", elapsed) -- 賣出不花錢
		),
		Scripttable.Theme.Warning
	)
end

-- 玩家接受了 "Start Game?" 投票或遠征開始 -> 波次開始 (wave 0->1, GameTime 開始走)
function Tracker.OnGameStarted()
	if Gametable.gameStartedLogged then
		return
	end
	Gametable.gameStartedLogged = true
	local elapsed = Mainfunction.getElapsed()
	table.insert(Scripttable.gameStartLog, { Elapsed = elapsed, Seq = Mainfunction.nextSeq() })
	Mainfunction.addLog(Mainfunction.T("logGameStarted"), Scripttable.Theme.Success)
end

-- 玩家按下遠征 Checkpoint 繼續 (Continue)
function Tracker.OnGameStart2()
	if Gametable.gameStart2Logged then
		return
	end
	Gametable.gameStart2Logged = true
	local elapsed = Mainfunction.getElapsed()
	table.insert(Scripttable.gameStart2Log, { Elapsed = elapsed, Seq = Mainfunction.nextSeq() })
	Mainfunction.addLog(Mainfunction.T("logGameStart2"), Scripttable.Theme.Success)
end

-- 玩家接受了跳波投票。title = 該投票的 Title (實機抓到後可用來精確比對)
function Tracker.OnSkipWave(title)
	local elapsed = Mainfunction.getElapsed()
	table.insert(Scripttable.skipWaveLog, { Elapsed = elapsed, Seq = Mainfunction.nextSeq(), Title = title })
	Mainfunction.addLog(Mainfunction.T("logSkipWaveFmt"):format(string.format("+%.1fs", elapsed)), Scripttable.Theme.Purple)
end

-- ⚠ 目前【沒有任何地方會呼叫這個】: 能力偵測 (階段 3) 尚未接上, 見檔頭。
function Tracker.OnAbility(gameId, abilityKey)
	table.insert(Scripttable.abilityLog, { GameID = gameId, Ability = abilityKey, Elapsed = Mainfunction.getElapsed() })
end

-- 來源: GameState 的 CurrentGameState 變化 (★ 不看 Data.Active -- 準備階段它也是 false)
function Tracker.OnGameStart(mapId)
	Mainfunction.startGameTimer(mapId)
	Mainfunction.updateInfoLabel()
	-- ★ 準備階段默默啟動計時器；「開始」日誌在玩家點擊開場按鈕/第一隻放置/投票時紀錄
end

function Tracker.OnGameEnd()
	if not Gametable.isGameRunning then
		return
	end
	Gametable.gameEndElapsed = Mainfunction.getElapsed()
	Gametable.isGameRunning = false
	Gametable.gameStartSession = nil
	Mainfunction.stopAbilityRemoteTriggers()
	local el = Gametable.gameEndElapsed or 0
	Mainfunction.addLog(Mainfunction.T("logGameEnd"):format(math.floor(el / 60), math.floor(el % 60), el), Scripttable.Theme.Warning)
end

-- ============================================================
-- Adapter  --  動漫遠征專用
-- ============================================================
--   關卡內操作走 ReplicaService: ReplicaSignal:FireServer(replicaId, signalName, ...args)
--     arg1 = replica id (每局重生)   arg2 = signal 名   arg3+ = 參數
--   remote 位置: ReplicatedStorage.RemoteEvents.ReplicaSignal
--   相關模組:    ReplicatedStorage.Shared.ReplicaClient / UnitUtils / Information.*
Gametable.AE = {
	pending = {}, -- 送出 PlaceGameUnit 後、等待伺服器建立 replica 的佇列
	seenId = {}, -- gameId -> true      已記錄過的塔, 防重複
	seenSpot = {}, -- 位置key -> order   幽靈實體化時用來認出「同一座塔」
	watched = {}, -- replica -> true    已掛上升級監聽, 防重複掛
	voteTitles = {}, -- voteId -> Title  投票回應後 replica 會被 AutoDestroy, 要先記下 Title
	hooked = false,
	backfilling = nil, -- true 時代表正在補記「載入前就在場上的塔」(時間/順序不可信)
}

-- 執行器跑 identity 8, require 遊戲模組前要降到 2
Mainfunction.aeRequire = function(inst)
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

Gametable.Shared = Gametable.ReplicatedStorage:FindFirstChild("Shared")
Gametable.ReplicaClient = Gametable.Shared and Mainfunction.aeRequire(Gametable.Shared:FindFirstChild("ReplicaClient"))
Gametable.SettingsDefault = Gametable.Shared
	and Mainfunction.aeRequire(
		Gametable.Shared:FindFirstChild("Information")
			and Gametable.Shared.Information:FindFirstChild("Settings")
			and Gametable.Shared.Information.Settings:FindFirstChild("Default")
	)
Gametable.ReplicaSignal = (function()
	local re = Gametable.ReplicatedStorage:FindFirstChild("RemoteEvents")
	return re and re:FindFirstChild("ReplicaSignal")
end)()

Gametable.LocalPlayer = Gametable.Players.LocalPlayer

-- Nodes 層 (只有「改遊戲設定」會用到, 其餘操作都走 ReplicaService)
Gametable.aeNodes = nil
Mainfunction.aeGetNodes = function()
	if Gametable.aeNodes == nil then
		Gametable.aeNodes = Mainfunction.aeRequire(Gametable.ReplicatedStorage:FindFirstChild("Nodes")) or false
	end
	return Gametable.aeNodes or nil
end

-- === Replica 查詢小工具 ===
Mainfunction.aeReplicas = function()
	if not Gametable.ReplicaClient then
		return {}
	end
	local ok, t = pcall(function()
		return Gametable.ReplicaClient.Test().Replicas
	end)
	return (ok and type(t) == "table") and t or {}
end

Mainfunction.aeFind = function(token, pred)
	for _, r in pairs(Mainfunction.aeReplicas()) do
		if r.Token == token and r.Data and (not pred or pred(r)) then
			return r
		end
	end
	return nil
end

-- 緩存中有兩個 HotbarData, 作用中的是 PlacementAllowed == true 的那個
Mainfunction.aeHotbar = function()
	return Mainfunction.aeFind("HotbarData", function(r)
		return r.Data.PlacementAllowed == true
	end)
end

-- UnitID 格式為 "Luffy#78d90e32-..." -> 取出塔名
Mainfunction.aeAssetOf = function(unitID)
	return unitID and tostring(unitID):match("^([^#]+)") or nil
end

-- 塔名。GameUnit 與 GamePhantom 的 Data.UnitData.Asset 都有 (已實測),
-- 但 UnitID 一定存在且格式固定, 拿它當主要來源最保險。
Mainfunction.aeUnitName = function(replica)
	local d = replica.Data
	return Mainfunction.aeAssetOf(d.UnitID) or (d.UnitData and d.UnitData.Asset) or "Unknown"
end

-- 閃亮 / 天賦。
-- 主要來源是塔自己的 UnitData (實測閃亮塔放下去後 UnitData.Shiny = true),
-- 背包 (PlayerData.UnitData[UnitID]) 當後備 -- 兩邊都查, 對 GameUnit 與 GamePhantom 都成立。
Mainfunction.aeMutationsOf = function(replica)
	local d = replica.Data
	local ud = d.UnitData or {}
	local shiny, trait = ud.Shiny, ud.Trait
	if shiny == nil or trait == nil then
		local pd = Mainfunction.aeFind("PlayerData")
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

Mainfunction.aeSlotAsset = function(slot)
	local hb = Mainfunction.aeHotbar()
	if not hb then
		return nil
	end
	local s = hb.Data.Slots and hb.Data.Slots[slot]
	return s and Mainfunction.aeAssetOf(s.ID) or nil
end

Mainfunction.aeSpotKey = function(name, cf)
	if not cf then
		return nil
	end
	local p = cf.Position
	-- 忽略 Y 軸：避免 GamePhantom (幽靈塔) 轉實體 GameUnit 時因地形/碰撞箱微調 (如 Y 軸差 0.5) 導致去重 Key 不相符而重複錄製
	return string.format("%s@%.1f,%.1f", tostring(name), p.X, p.Z)
end

-- === 升級偵測 ===
Mainfunction.aeWatchUpgrades = function(replica)
	if Gametable.AE.watched[replica] then
		return
	end
	Gametable.AE.watched[replica] = true
	local last = 0

	local function processUpgrade(now)
		local d = replica.Data
		if not d or type(now) ~= "number" or now <= last then
			return
		end
		local gid = tostring(d.ID)
		if not gid or gid == "" or gid == "nil" then
			return
		end
		local startLvl = last + 1
		last = now
		for lvl = startLvl, now do
			Tracker.OnUpgrade(gid, lvl)
		end
	end

	-- 初始等級檢查 (處理中途載入/Backfill 或新建時已提升等級的情況)
	local initUpgrade = replica.Data and replica.Data.Upgrade
	if type(initUpgrade) == "number" and initUpgrade > 0 then
		Mainfunction.queueHookTask(function()
			processUpgrade(initUpgrade)
		end)
	end

	pcall(function()
		replica:OnChange(function()
			local d = replica.Data
			if not d then
				return
			end
			local now = d.Upgrade
			if type(now) == "number" and now > last then
				Mainfunction.queueHookTask(function()
					processUpgrade(now)
				end)
			end
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
Mainfunction.aeIsClone = function(d)
	if d.IsClone == true then
		return true
	end
	-- ⚠ 只有 UnitID 與 UnitData.Asset【兩者都有值】且確實不同才算召喚物。
	--   OnNew 當下 UnitID 常常還沒填 -> idAsset=nil；此時絕不能因「Asset≠nil」把真身誤判成召喚物
	--   (那會把所有塔都濾掉、追蹤器一個塔都顯示不出來)。IsClone 那條才是主判準。
	local realAsset = d.UnitData and d.UnitData.Asset
	local idAsset = Mainfunction.aeAssetOf(d.UnitID)
	if type(realAsset) == "string" and type(idAsset) == "string" and realAsset ~= idAsset and realAsset ~= idAsset .. "EVO" then
		return true
	end
	return false
end

Mainfunction.aeOnNewUnit = function(replica)
	local d = replica.Data
	if not d or d.Owner ~= Gametable.LocalPlayer then
		return
	end
	-- 召喚物/分身不是玩家放置 -> 完全略過 (不記錄、也不掛升級監聽)
	if Mainfunction.aeIsClone(d) then
		return
	end

	Mainfunction.aeWatchUpgrades(replica)

	local gid = tostring(d.ID)
	if Gametable.AE.seenId[gid] then
		return -- 同一顆 replica 重複觸發
	end

	local name = Mainfunction.aeUnitName(replica)
	local key = Mainfunction.aeSpotKey(name, d.CFrame)

	-- 幽靈實體化(幽靈轉實體時 replica 會換一顆, ID 可能改變 -> 把新 ID 指回原本的 order)
	local prevOrder = key and Gametable.AE.seenSpot[key]
	if prevOrder then
		Gametable.AE.seenId[gid] = true
		Scripttable.idToOrder[gid] = prevOrder
		local info = Scripttable.orderToInfo[prevOrder]
		if info then
			info.GameID = gid
			info.IsPhantom = (replica.Token == "GamePhantom") or nil
		end
		return
	end

	Gametable.AE.seenId[gid] = true

	-- 配對出這座塔是從哪個槽位放的 (取最舊的同名待決放置)
	local slot
	for i, p in ipairs(Gametable.AE.pending) do
		if p.unitName == name then
			slot = p.slot
			table.remove(Gametable.AE.pending, i)
			break
		end
	end

	local shiny, trait = Mainfunction.aeMutationsOf(replica)
	local order = Tracker.OnPlace(name, gid, d.CFrame, {
		uuid = d.UnitID,
		slot = slot,
		isPhantom = replica.Token == "GamePhantom",
		shiny = shiny,
		trait = trait,
		-- 伺服器記的放置時刻 (SessionTime 時鐘)。補記時靠它還原真實時間與順序。
		placedAt = tonumber(d.PlacedAt),
		backfilled = Gametable.AE.backfilling or nil,
	})

	if order then
		if key then
			Gametable.AE.seenSpot[key] = order
		end
		local info = Scripttable.orderToInfo[order]
		if info then
			info.Slot = slot
			info.IsPhantom = (replica.Token == "GamePhantom") or nil
		end
	end
end

-- === 送出封包的解析 ===
Mainfunction.aeHandleSignal = function(args)
	local signalName = args[2]
	if type(signalName) ~= "string" then
		return
	end

	if signalName == "PlaceGameUnit" then
		local slot, cf = args[3], args[4]
		table.insert(Gametable.AE.pending, {
			slot = slot,
			cframe = cf,
			unitName = Mainfunction.aeSlotAsset(slot),
			t = tick(),
		})
		-- 逾時清理: 放置被伺服器拒絕 (座標不合法/超過上限) 時不會有 replica 進來
		for i = #Gametable.AE.pending, 1, -1 do
			if tick() - Gametable.AE.pending[i].t > 10 then
				table.remove(Gametable.AE.pending, i)
			end
		end
	elseif signalName == "Response" then
		local title = Gametable.AE.voteTitles[tostring(args[1])] or "?"
		if args[3] == true then
			if title:lower():find("start game") or title == "?" then
				Tracker.OnGameStarted()
			else
				Tracker.OnSkipWave(title)
			end
		end
	elseif signalName == "Continue" then
		Tracker.OnGameStart2()
	elseif signalName == "SellGameUnit" then
		Tracker.OnSell(tostring(args[3]))
	elseif signalName == "SellAllGameUnits" then
		for _, r in pairs(Mainfunction.aeReplicas()) do
			if r.Token == "GameUnit" and r.Data and r.Data.Owner == Gametable.LocalPlayer and not Mainfunction.aeIsClone(r.Data) then
				Tracker.OnSell(tostring(r.Data.ID))
			end
		end
	end
	-- SelectSlot: 純 UI 選取, 伺服器放置只讀參數裡的槽位 (已實證) -> 不記錄
end

Mainfunction.getSessionTime = function()
	local g = Mainfunction.aeFind("GameState")
	return g and tonumber(g.Data.SessionTime) or nil
end

Scripttable.AE_GAME_OVER_STATES = { Victory = true, Lose = true, Defeat = true }

-- === 關卡狀態 ===
Mainfunction.aeApplyGameState = function(r)
	local d = r and r.Data
	if not d then
		return
	end
	local p = d.Parameters or {}
	Gametable.gameSettings.mapId = tostring(p.MapName or "Unknown")
	Gametable.gameSettings.difficulty = tostring(p.Difficulty or "Unknown")
	Gametable.gameSettings.gamemode = tostring(p.Gamemode or "Story")
	Gametable.gameSettings.actName = tostring(p.ActName or "Act 1")
	Gametable.gameSettings.modifier = string.format("%s / %s", Gametable.gameSettings.gamemode, Gametable.gameSettings.actName)

	local state = d.CurrentGameState
	if state == "InProgress" then
		if not Gametable.isGameRunning then
			Tracker.OnGameStart(Gametable.gameSettings.mapId)
		end
	elseif Gametable.isGameRunning and Scripttable.AE_GAME_OVER_STATES[tostring(state)] then
		Tracker.OnGameEnd()
	end
	pcall(Mainfunction.updateInfoLabel)
end

function Adapter.Init()
	if not Gametable.ReplicaClient or not Gametable.ReplicaSignal then
		warn("[放置追蹤器] 找不到 ReplicaClient / ReplicaSignal, Adapter 未啟動")
		pcall(Mainfunction.addLog, Mainfunction.T("logAdapterFailed"), Scripttable.Theme.Error)
		return
	end
	if Gametable.AE.hooked then
		return
	end
	Gametable.AE.hooked = true

	-- 1) 監聽伺服器建立的塔 (實體 + 幽靈)
	pcall(function()
		Gametable.ReplicaClient.OnNew("GameUnit", function(r)
			Mainfunction.queueHookTask(function()
				Mainfunction.aeOnNewUnit(r)
			end)
		end)
		Gametable.ReplicaClient.OnNew("GamePhantom", function(r)
			Mainfunction.queueHookTask(function()
				Mainfunction.aeOnNewUnit(r)
			end)
		end)
	end)

	-- 2) 關卡狀態
	pcall(function()
		Gametable.ReplicaClient.OnNew("GameState", function(r)
			Mainfunction.queueHookTask(function()
				Mainfunction.aeApplyGameState(r)
			end)
			pcall(function()
				r:OnChange(function()
					Mainfunction.queueHookTask(function()
						Mainfunction.aeApplyGameState(r)
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
			if self == Gametable.ReplicaSignal and getnamecallmethod() == "FireServer" then
				local args = table.pack(...)
				Mainfunction.queueHookTask(function()
					pcall(Mainfunction.aeHandleSignal, args)
				end)
			end
			return oldNamecall(self, ...)
		end)
		setreadonly(mt, true)
	end)
	if not ok then
		warn("[放置追蹤器] __namecall hook 失敗, 升級/賣出/槽位將記錄不到")
		pcall(Mainfunction.addLog, Mainfunction.T("logHookFailed"), Scripttable.Theme.Warning)
	end

	-- 4) 監聽伺服器回傳的設定變更 (Nodes 層)
	-- 線路格式: _updateNode.OnClientEvent("PLAYER_SETTING_CHANGED", 1, Player, 設定名, 值)
	pcall(function()
		local net = Gametable.ReplicatedStorage:FindFirstChild("Nodes")
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
			if player ~= Gametable.LocalPlayer or settingName ~= "AutoSkipWaves" then
				return
			end
			Mainfunction.queueHookTask(function()
				Scripttable.autoSkipState.on = (value == true)
				pcall(Mainfunction.updateInfoLabel)
				-- 校正面板開關 (不觸發 callback, 否則會把設定再送一次回去形成迴圈)
				if Scripttable.autoSkipToggle then
					pcall(Scripttable.autoSkipToggle.set, value == true)
				end
				Mainfunction.addLog(value and Mainfunction.T("logAutoSkipOn") or Mainfunction.T("logAutoSkipOff"), value and Scripttable.Theme.Success or Scripttable.Theme.TextDim)
			end)
		end)
	end)

	-- 5) 投票偵測 (開始遊戲 / 跳波) 投票 UI 是【共用】的: 開始遊戲、跳波…都走同一個 VotePrompt token,
	--   遊戲自己的 MountNotifications 也是靠 ReplicaClient.OnNew("VotePrompt") 掛 UI。
	pcall(function()
		Gametable.ReplicaClient.OnNew("VotePrompt", function(r)
			Mainfunction.queueHookTask(function()
				Gametable.AE.voteTitles[tostring(r.Id)] = tostring(((r.Data or {}).Parameters or {}).Title or "?")
			end)
		end)
	end)

	-- 6) 遠征開場 / Checkpoint 點擊 Continue 按鈕時觸發「開始」日誌
	pcall(function()
		local playerGui = Gametable.LocalPlayer and Gametable.LocalPlayer:FindFirstChild("PlayerGui")
		if playerGui then
			local function hookBottomHud(hud)
				for _, desc in ipairs(hud:GetDescendants()) do
					if desc:IsA("TextLabel") or desc:IsA("TextBox") then
						local txt = tostring(desc.Text or "")
						if txt == "Continue" or txt == "繼續" or txt:find("Continue") or txt:find("繼續") then
							local btn = desc.Parent
							while btn and btn ~= hud and not (btn:IsA("GuiButton") or btn:IsA("TextButton") or btn:IsA("ImageButton") or btn.Name:find("Button")) do
								btn = btn.Parent
							end
							if btn and (btn:IsA("GuiButton") or btn:IsA("TextButton") or btn:IsA("ImageButton") or btn.Name:find("Button")) then
								btn.MouseButton1Click:Connect(function()
									Mainfunction.queueHookTask(function()
										if not Gametable.gameStartedLogged then
											Tracker.OnGameStarted()
										end
									end)
								end)
							end
						end
					end
				end
			end
			local bh = playerGui:FindFirstChild("BottomHUD")
			if bh then hookBottomHud(bh) end
			playerGui.ChildAdded:Connect(function(child)
				if child.Name == "BottomHUD" then
					hookBottomHud(child)
				end
			end)
		end
	end)

	-- 7) 補記已經在場上的塔 (腳本中途載入)
	--   靠塔的 Data.PlacedAt (= 放置當下的 SessionTime) 還原真實順序與時間。
	--   先依 PlacedAt 排序再補記 -- pairs() 掃 replica 是無序的, 不排就會得到隨機順序。
	pcall(function()
		local mine = {}
		for _, r in pairs(Mainfunction.aeReplicas()) do
			if (r.Token == "GameUnit" or r.Token == "GamePhantom") and r.Data and r.Data.Owner == Gametable.LocalPlayer then
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
		if first and (not Gametable.gameStartSession or first < Gametable.gameStartSession) then
			Gametable.gameStartSession = first
			Gametable.gameStartApprox = true
			Gametable.isGameRunning = true
			Gametable.gameStartMapId = Gametable.gameStartMapId or Gametable.gameSettings.mapId
		end

		Gametable.AE.backfilling = true
		for _, r in ipairs(mine) do
			Mainfunction.aeOnNewUnit(r)
		end
		Gametable.AE.backfilling = nil
	end)
end

Mainfunction.aeGetSetting = function(name)
	local pd = Mainfunction.aeFind("PlayerData")
	local v = pd and (pd.Data.Settings or {})[name]
	if v ~= nil then
		return v
	end
	return Gametable.SettingsDefault and Gametable.SettingsDefault[name]
end

-- ★ 設定走 Nodes 層 (CLIENT_CHANGE_SETTING)
function Adapter.SetAutoSkipWaves(v)
	local Nodes = Mainfunction.aeGetNodes()
	if not Nodes then
		warn("[放置追蹤器] 找不到 Nodes, 無法改設定")
		return false
	end
	local ok = pcall(function()
		Nodes["CLIENT_CHANGE_SETTING"]:FireServer("AutoSkipWaves", v == true)
	end)
	if ok then
		-- 樂觀更新; 伺服器的 PLAYER_SETTING_CHANGED 回來時會再校正一次
		Scripttable.autoSkipState.on = (v == true)
		pcall(Mainfunction.updateInfoLabel)
	end
	return ok
end

function Adapter.ReadGameSettings()
	local gs = Mainfunction.aeFind("GameState")
	if gs then
		Mainfunction.aeApplyGameState(gs)
	end
	-- 回填自動跳波狀態
	pcall(function()
		Scripttable.autoSkipState.on = (Mainfunction.aeGetSetting("AutoSkipWaves") == true)
	end)
end

function Adapter.ScanPlacedUnits()
	local list = {}
	for _, r in pairs(Mainfunction.aeReplicas()) do
		if (r.Token == "GameUnit" or r.Token == "GamePhantom") and r.Data and r.Data.Owner == Gametable.LocalPlayer then
			table.insert(list, r)
		end
	end
	return list
end

-- 啟動
pcall(Adapter.ReadGameSettings)
if Scripttable.autoSkipToggle then
	pcall(Scripttable.autoSkipToggle.set, Scripttable.autoSkipState.on)
end
Mainfunction.updateInfoLabel()

-- 當前遊戲資訊
Mainfunction.addLog(
	Mainfunction.T("logGameInfoLine"):format(
		Gametable.gameSettings.gamemode,
		Gametable.gameSettings.mapId,
		Gametable.gameSettings.actName,
		Gametable.gameSettings.difficulty
	),
	Scripttable.Theme.Accent
)
Mainfunction.addLog(string.format(Mainfunction.T("logAutoSkipRead"), Scripttable.autoSkipState.on and "ON" or "OFF"), Scripttable.Theme.Accent)
Mainfunction.addLog(Mainfunction.T("logWaitStart"), Scripttable.Theme.TextDim)

pcall(Adapter.Init)
Mainfunction.updateInfoLabel()

-- ============================================================
-- Heartbeat: 能力冷卻條更新
-- ============================================================
-- 原 GTD 版這裡還有一個掃描器, 每 0.5s 掃 workspace.Map.Towers 找出有能力的塔並建卡片。
-- 動漫遠征的單位容器尚未偵察 -> 掃描器移除, 只留冷卻條更新 (目前沒有卡片, 等同空跑)。
-- 重建計畫見檔頭 [階段 3]。
Scripttable.abiUpdateTimer = 0

Gametable.RunService.Heartbeat:Connect(function(dt)
	Mainfunction.flushHookTaskQueue()
	Scripttable.abiGameClock = Scripttable.abiGameClock + dt * (Gametable.lastDetectedSpeed > 0 and Gametable.lastDetectedSpeed or 1)

	Scripttable.abiUpdateTimer = Scripttable.abiUpdateTimer + dt
	if Scripttable.abiUpdateTimer < 0.1 then
		return
	end
	Scripttable.abiUpdateTimer = 0

	for model, info in pairs(Scripttable.abiLiveTowers) do
		local card = Scripttable.abiTowerCards[model]
		if card then
			local canUseAbility = Gametable.isGameRunning and info.gameId ~= nil
			for _, w in ipairs(card.widgets) do
				local t0 = info.cooldowns[w.key]
				if not t0 then
					w.barFill.Size = UDim2.new(1, 0, 1, 0)
					w.barFill.BackgroundColor3 = canUseAbility and Scripttable.Theme.Success or Scripttable.Theme.SurfaceHighlight
					w.barText.Text = canUseAbility and Mainfunction.T("abilityReady") or Mainfunction.T("abilityWaitId")
					w.fireBtn.TextColor3 = canUseAbility and Scripttable.Theme.Text or Scripttable.Theme.TextDim
				else
					local elapsed = Scripttable.abiGameClock - t0
					local remaining = math.max(0, w.cd - elapsed)
					local fillPct = math.min(elapsed / w.cd, 1)
					local dispRemaining = remaining / (Gametable.lastDetectedSpeed > 0 and Gametable.lastDetectedSpeed or 1)

					w.barFill.Size = UDim2.new(fillPct, 0, 1, 0)
					w.barFill.BackgroundColor3 = remaining > 0 and Scripttable.Theme.Accent or Scripttable.Theme.Success
					w.barText.Text = remaining > 0 and Mainfunction.T("abilityTimerFmt"):format(dispRemaining) or Mainfunction.T("abilityReady")
					w.fireBtn.TextColor3 = (canUseAbility and remaining == 0) and Scripttable.Theme.Text or Scripttable.Theme.TextDim
				end
			end
		end
	end
end)

print("[放置追蹤器] 已載入 (動漫遠征) -- 記錄玩家操作, 按 Copy/Save 產生自動化腳本")
