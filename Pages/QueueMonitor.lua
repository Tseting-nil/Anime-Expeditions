-- ============================================================
--                 動漫遠征 | 佇列監視器 GUI (Queue Monitor)
-- ============================================================
-- 說明：此腳本為獨立工具，透過讀取 AE.Scripttable.queue 的資料，
--       並掛鉤 Mainfunction 的執行函數，達到在不破壞/修改原先
--       重播核心邏輯的前提下，為使用者提供一個美觀且可即時追蹤進度的
--       佇列監視 GUI。
-- ============================================================

local Scripttable, Mainfunction = ...

-- === i18n 國際化設定 ===
local HttpService = game:GetService("HttpService")
local currentLang = "zh"
do
	local API_VAR_PATH = "Tsetingnil_script/keysystem.json"
	pcall(function()
		if isfile and isfile(API_VAR_PATH) and readfile then
			local raw = readfile(API_VAR_PATH)
			if raw and raw ~= "" then
				local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
				local scriptLang = nil
				if ok and type(data) == "table" then
					scriptLang = data.script_language or data.language
				else
					scriptLang = raw:match('"script_language"%s*:%s*"([^"]+)"') or raw:match('"language"%s*:%s*"([^"]+)"')
				end
				
				if scriptLang then
					local sl = tostring(scriptLang):lower()
					if sl:find("chinese") or sl:find("zh") then
						currentLang = "zh"
					elseif sl:find("english") or sl:find("en") then
						currentLang = "en"
					end
				end
			end
		end
	end)
end

local i18n = {
	zh = {
		warn_no_api = "[AE Monitor] ❌ 找不到 AE API，無法啟動監視器！",
		default_tower = "塔 #%d",
		title = "動漫遠征 | 佇列監視器",
		progress_wait = "進度：等待佇列啟動...",
		op_place = "放置 %s (#%d)",
		op_upgrade = "升級 %s (#%d)",
		op_sell = "售出 %s (#%d)",
		op_ability = "塔能力 %s (#%d)",
		op_sellall = "清除全部塔",
		op_skipwave = "手動跳波",
		op_autoskip_on = "設定自動跳波：開",
		op_autoskip_off = "設定自動跳波：關",
		op_speed = "設定速度：%dx",
		op_autoupgrade = "自動升級 %s (#%d)",
		op_end = "結束標記",
		op_setting = "設定 %s = %s",
		op_startgame = "投票：開始遊戲",
		op_vote = "投票：%s",
		gate_completed = "已完成",
		gate_failed = "失敗",
		gate_running = "執行中...",
		game_victory = "已結束 (勝利)",
		game_defeat = "已結束 (失敗)",
		game_unknown = "已結束 (未知)",
		time_countdown = "倒數：%.1fs",
		time_elapsed = "時間：%.1fs",
		summary_format = "進度：%d/%d (%.1f%%) | %s | 金錢：$%s",
		queue_empty = "佇列為空，請載入腳本...",
		log_new_game = "[AE Monitor] 🔄 偵測到新對局開始 (GameStartTime 改變)，重置佇列狀態！",
		log_game_ended = "[AE Monitor] ℹ️ 對局結束或回到大廳，重置佇列狀態",
		log_started = "[AE Monitor] ✅ 佇列監視器啟動完成，已成功掛鉤所有動作函數！",
	},
	en = {
		warn_no_api = "[AE Monitor] ❌ Cannot find AE API, failed to start monitor!",
		default_tower = "Tower #%d",
		title = "Anime-Expeditions | Queue Monitor",
		progress_wait = "Progress: Waiting for queue...",
		op_place = "Place %s (#%d)",
		op_upgrade = "Upgrade %s (#%d)",
		op_sell = "Sell %s (#%d)",
		op_ability = "Ability %s (#%d)",
		op_sellall = "Sell All Towers",
		op_skipwave = "Manual Skip Wave",
		op_autoskip_on = "Set Auto Skip: On",
		op_autoskip_off = "Set Auto Skip: Off",
		op_speed = "Set Speed: %dx",
		op_autoupgrade = "Auto Upgrade %s (#%d)",
		op_end = "End Marker",
		op_setting = "Set Setting %s = %s",
		op_startgame = "Vote: Start Game",
		op_vote = "Vote: %s",
		gate_completed = "Completed",
		gate_failed = "Failed",
		gate_running = "Running...",
		game_victory = "Finished (Victory)",
		game_defeat = "Finished (Defeat)",
		game_unknown = "Finished (Unknown)",
		time_countdown = "Countdown: %.1fs",
		time_elapsed = "Time: %.1fs",
		summary_format = "Progress: %d/%d (%.1f%%) | %s | Cash: $%s",
		queue_empty = "Queue is empty, please load script...",
		log_new_game = "[AE Monitor] 🔄 New game detected (GameStartTime changed), resetting queue status!",
		log_game_ended = "[AE Monitor] ℹ️ Game ended or back to lobby, resetting queue status",
		log_started = "[AE Monitor] ✅ Queue monitor started, successfully hooked all actions!",
	}
}

local L = i18n[currentLang] or i18n.zh

-- 1. 偵測並等待 AE 載入完成
if not Scripttable or not Mainfunction then
	repeat task.wait(0.5) until getgenv().AE and getgenv().AE.__loaded
	local AE = getgenv().AE
	Scripttable = AE.Scripttable
	Mainfunction = AE.Mainfunction
end

if not Scripttable or not Mainfunction then
	warn(L.warn_no_api)
	return
end

local function getAE()
	local AE = getgenv().AE
	if AE and AE.__loaded then
		return AE.Scripttable or Scripttable, AE.Mainfunction or Mainfunction
	end
	return Scripttable, Mainfunction
end

-- ============================================================
-- 服務與常數定義
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

-- === UI 主題 ===
local Theme = {
	Background = Color3.fromRGB(25, 27, 30),
	Surface = Color3.fromRGB(35, 38, 42),
	SurfaceHighlight = Color3.fromRGB(45, 48, 52),
	Border = Color3.fromRGB(60, 65, 70),
	Text = Color3.fromRGB(230, 230, 230),
	TextDim = Color3.fromRGB(150, 150, 150),
	TextDark = Color3.fromRGB(20, 20, 20),
	Accent = Color3.fromRGB(60, 160, 255),       -- 亮藍 (Running)
	Success = Color3.fromRGB(100, 220, 120),     -- 綠色 (Completed)
	SuccessBg = Color3.fromRGB(25, 45, 30),
	Warning = Color3.fromRGB(255, 180, 60),      -- 橘色
	Error = Color3.fromRGB(255, 80, 80),         -- 紅色 (Failed)
	ErrorBg = Color3.fromRGB(45, 25, 25),
	CornerRadius = UDim.new(0, 8),
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
}

-- === 執行狀態變數 ===
local current_index = 1
local uiRows = {}
local autoScrollEnabled = true
local isMinimized = false

-- ============================================================
-- 輔助函式：名稱解析、計時與讀錢
-- ============================================================
local _displayCache = nil
local function displayName(asset)
	if not asset then return "?" end
	if _displayCache == nil then
		_displayCache = {}
		pcall(function()
			local U = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Information"):WaitForChild("Units"))
			for k, v in pairs(U) do
				if type(v) == "table" and type(v.DisplayName) == "string" and v.DisplayName ~= "" then
					_displayCache[k] = v.DisplayName
				end
			end
		end)
	end
	return _displayCache[asset] or asset
end

local function formatNumber(amount)
	local formatted = tostring(amount)
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

local function readCash()
	local AE = getgenv().AE
	if AE and AE.GetYen then
		return AE.GetYen() or 0
	end
	-- Fallback
	local ok, val = pcall(function()
		local ReplicaClient = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ReplicaClient"))
		local reps = ReplicaClient.Test().Replicas
		for _, r in pairs(reps) do
			if r.Token == "GamePlayerData" and r.Data and r.Data.Yen then
				return r.Data.Yen
			end
		end
		return 0
	end)
	return ok and val or 0
end

local function getElapsed()
	local AE = getgenv().AE
	if AE and AE.__loaded then
		local ok, el = pcall(function() return AE.GetQueueElapsed() end)
		if ok and el then return el end
	end
	local gst = workspace:GetAttribute("GameStartTime")
	if type(gst) == "number" and gst > 0 then
		return workspace:GetServerTimeNow() - gst
	end
	return 0
end

-- 依 order 尋找對應放置塔的顯示名稱
local function getTowerNameForOrder(order)
	if not order then return "Unknown" end
	local Scripttable, Mainfunction = getAE()
	for _, item in ipairs(Scripttable.queue or {}) do
		if (item.kind == "place" or item.type == "place") and item.order == order then
			return displayName(item.unitName or item.unitId)
		end
	end
	return string.format(L.default_tower, order)
end

-- ============================================================
-- 狀態管理與進度更新
-- ============================================================
local function moveToNextOp()
	local Scripttable, Mainfunction = getAE()
	for i = current_index + 1, #Scripttable.queue do
		local op = Scripttable.queue[i]
		if op.kind ~= "autoupgrade" and op.type ~= "autoupgrade" then
			op.status = "running"
			current_index = i
			return
		end
	end
	current_index = #Scripttable.queue + 1
end

local function resetStatuses()
	local Scripttable, Mainfunction = getAE()
	current_index = 1
	for _, op in ipairs(Scripttable.queue or {}) do
		op.status = "pending"
	end
	
	for _, op in ipairs(Scripttable.queue or {}) do
		if op.kind == "autoupgrade" or op.type == "autoupgrade" then
			op.status = "running"
		end
	end

	for idx, op in ipairs(Scripttable.queue or {}) do
		if op.kind ~= "autoupgrade" and op.type ~= "autoupgrade" then
			op.status = "running"
			current_index = idx
			break
		end
	end
end

-- 熱重載或中途開啟時的狀態自癒恢復機制
local function syncRunningQueue()
	local Scripttable, Mainfunction = getAE()
	if Scripttable.currentRunningIndex then
		current_index = Scripttable.currentRunningIndex
		return
	end
	for _, op in ipairs(Scripttable.queue or {}) do
		op.status = "pending"
	end

	local max_completed_idx = 0
	for idx, op in ipairs(Scripttable.queue or {}) do
		if (op.kind == "place" or op.type == "place") and Scripttable.orderToTower and Scripttable.orderToTower[op.order] then
			op.status = "completed"
			max_completed_idx = idx
		end
	end

	for i = 1, max_completed_idx do
		local op = Scripttable.queue[i]
		if op.kind ~= "autoupgrade" and op.type ~= "autoupgrade" then
			op.status = "completed"
		end
	end

	current_index = max_completed_idx + 1
	local found_running = false
	for i = current_index, #Scripttable.queue do
		local op = Scripttable.queue[i]
		if op.kind ~= "autoupgrade" and op.type ~= "autoupgrade" then
			op.status = "running"
			current_index = i
			found_running = true
			break
		end
	end
	if not found_running then
		current_index = #Scripttable.queue + 1
	end

	for _, op in ipairs(Scripttable.queue or {}) do
		if op.kind == "autoupgrade" or op.type == "autoupgrade" then
			op.status = "running"
		end
	end
end

-- ============================================================
-- GUI 界面建立與佈局
-- ============================================================
local guiParent = get_hidden_gui or gethui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AEQueueMonitorUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent and guiParent() or game:GetService("CoreGui")

local oldUI = screenGui.Parent:FindFirstChild(screenGui.Name)
if oldUI and oldUI ~= screenGui then
	oldUI:Destroy()
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 330, 0, 420)
mainFrame.Position = UDim2.new(0.72, 0, 0.25, 0)
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

-- === 標題欄 ===
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
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = L.title
title.Parent = titleBar

-- === 拖拽功能實作 ===
local dragging = false
local dragStart = nil
local startPos = nil
local dragConn = nil

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = UserInputService:GetMouseLocation()
		startPos = mainFrame.Position
		if not dragConn then
			dragConn = RunService.RenderStepped:Connect(function()
				if not dragging then return end
				local delta = UserInputService:GetMouseLocation() - dragStart
				mainFrame.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end)
		end
	end
end)

titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
		if dragConn then
			dragConn:Disconnect()
			dragConn = nil
		end
	end
end)

-- === 展開 / 折疊 按鈕 ===
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -75, 0, 7)
minimizeBtn.BackgroundColor3 = Theme.SurfaceHighlight
minimizeBtn.TextColor3 = Theme.Text
minimizeBtn.Font = Theme.FontBold
minimizeBtn.TextSize = 14
minimizeBtn.Text = "[-]"
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = titleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = minimizeBtn
end

-- === 關閉 按鈕 ===
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeBtn.TextColor3 = Theme.Text
closeBtn.Font = Theme.FontBold
closeBtn.TextSize = 14
closeBtn.Text = "X"
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = closeBtn
end

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- === 滾動容器 ===
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -16, 1, -85)
scrollFrame.Position = UDim2.new(0, 8, 0, 50)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarImageColor3 = Theme.Border
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollFrame

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 5)
end)

-- === 狀態摘要欄 ===
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, 0, 0, 30)
statusBar.Position = UDim2.new(0, 0, 1, -30)
statusBar.BackgroundColor3 = Theme.Surface
statusBar.BorderSizePixel = 0
statusBar.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 1, 0)
statusLabel.Position = UDim2.new(0, 10, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Theme.TextDim
statusLabel.Font = Theme.Font
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = L.progress_wait
statusLabel.Parent = statusBar

-- 自動折疊與展開處理
minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		mainFrame.Size = UDim2.new(0, 330, 0, 45)
		scrollFrame.Visible = false
		statusBar.Visible = false
		minimizeBtn.Text = "[+]"
	else
		mainFrame.Size = UDim2.new(0, 330, 0, 420)
		scrollFrame.Visible = true
		statusBar.Visible = true
		minimizeBtn.Text = "[-]"
	end
end)

-- ============================================================
-- UI 渲染生成器
-- ============================================================
local function initUIList()
	local Scripttable, Mainfunction = getAE()
	for _, row in pairs(uiRows) do
		row:Destroy()
	end
	uiRows = {}

	local queue = Scripttable.queue or {}
	for idx, op in ipairs(queue) do
		local rowFrame = Instance.new("Frame")
		rowFrame.Size = UDim2.new(1, -4, 0, 38)
		rowFrame.BackgroundColor3 = Theme.Surface
		rowFrame.BorderSizePixel = 0
		rowFrame.LayoutOrder = idx
		rowFrame.Parent = scrollFrame

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 5)
		rowCorner.Parent = rowFrame

		local rowStroke = Instance.new("UIStroke")
		rowStroke.Thickness = 1
		rowStroke.Color = Theme.Border
		rowStroke.Transparency = 0.5
		rowStroke.Parent = rowFrame

		-- 狀態符號 (Icon)
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(0, 25, 1, 0)
		iconLbl.Position = UDim2.new(0, 6, 0, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.TextColor3 = Theme.Text
		iconLbl.Font = Theme.FontBold
		iconLbl.TextSize = 14
		iconLbl.Text = "⏳"
		iconLbl.Parent = rowFrame
		iconLbl.Name = "Icon"

		-- 操作詳情 (Text)
		local detailLbl = Instance.new("TextLabel")
		detailLbl.Size = UDim2.new(1, -120, 1, 0)
		detailLbl.Position = UDim2.new(0, 36, 0, 0)
		detailLbl.BackgroundTransparency = 1
		detailLbl.TextColor3 = Theme.Text
		detailLbl.Font = Theme.Font
		detailLbl.TextSize = 13
		detailLbl.TextXAlignment = Enum.TextXAlignment.Left
		detailLbl.TextTruncate = Enum.TextTruncate.AtEnd
		detailLbl.Parent = rowFrame
		detailLbl.Name = "Detail"

		-- 建立各類型靜態文字
		local detailStr = ""
		local opKind = op.kind or op.type
		if opKind == "place" then
			local tName = displayName(op.unitName or op.unitId)
			detailStr = string.format(L.op_place, tName, op.order)
		elseif opKind == "upgrade" then
			local tName = getTowerNameForOrder(op.order)
			detailStr = string.format(L.op_upgrade, tName, op.order)
		elseif opKind == "sell" then
			local tName = getTowerNameForOrder(op.order)
			detailStr = string.format(L.op_sell, tName, op.order)
		elseif opKind == "ability" then
			local tName = getTowerNameForOrder(op.order)
			detailStr = string.format(L.op_ability, tName, op.order)
		elseif opKind == "sellall" then
			detailStr = L.op_sellall
		elseif opKind == "skipwave" then
			detailStr = L.op_skipwave
		elseif opKind == "autoskip" then
			detailStr = op.value and L.op_autoskip_on or L.op_autoskip_off
		elseif opKind == "speed" then
			detailStr = string.format(L.op_speed, op.speed)
		elseif opKind == "autoupgrade" then
			local tName = getTowerNameForOrder(op.order)
			detailStr = string.format(L.op_autoupgrade, tName, op.order)
		elseif opKind == "end" then
			detailStr = L.op_end
		elseif opKind == "setting" then
			detailStr = string.format(L.op_setting, tostring(op.name), tostring(op.value))
		elseif opKind == "vote" then
			if op.titleMatch == "Start Game?" then
				detailStr = L.op_startgame
			else
				detailStr = string.format(L.op_vote, tostring(op.titleMatch))
			end
		end
		detailLbl.Text = string.format("#%d %s", idx, detailStr)

		-- 閘門條件 / 進度顯示
		local gateLbl = Instance.new("TextLabel")
		gateLbl.Size = UDim2.new(0, 80, 1, 0)
		gateLbl.Position = UDim2.new(1, -85, 0, 0)
		gateLbl.BackgroundTransparency = 1
		gateLbl.TextColor3 = Theme.TextDim
		gateLbl.Font = Theme.Font
		gateLbl.TextSize = 11
		gateLbl.TextXAlignment = Enum.TextXAlignment.Right
		gateLbl.Parent = rowFrame
		gateLbl.Name = "Gate"

		uiRows[idx] = rowFrame
	end
end

-- ============================================================
-- UI 自動滾動聚焦
-- ============================================================
local function scrollToActiveOp()
	if not autoScrollEnabled or isMinimized then return end
	local activeRow = uiRows[current_index]
	if activeRow and scrollFrame then
		pcall(function()
			local relativeY = activeRow.AbsolutePosition.Y - scrollFrame.AbsolutePosition.Y + scrollFrame.CanvasPosition.Y
			local frameHeight = scrollFrame.AbsoluteSize.Y
			local targetY = relativeY - (frameHeight / 2)
			targetY = math.clamp(targetY, 0, scrollFrame.CanvasSize.Y.Offset)
			
			TweenService:Create(scrollFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CanvasPosition = Vector2.new(0, targetY)
			}):Play()
		end)
	end
end

-- ============================================================
-- UI 定時更新循環 (1秒多次更新)
-- ============================================================
local lastLocalGameStart = nil

local function updateUIList()
	local Scripttable, Mainfunction = getAE()
	if Scripttable then
		local localGst = Scripttable.gameStartTime
		if localGst and localGst ~= lastLocalGameStart then
			lastLocalGameStart = localGst
			resetStatuses()
		end
		if Scripttable.currentRunningIndex then
			current_index = Scripttable.currentRunningIndex
		end
	end
	local queue = Scripttable.queue or {}
	if #uiRows ~= #queue then
		initUIList()
	end

	local completedCount = 0
	local elapsed = getElapsed()
	local cash = readCash()

	for idx, op in ipairs(queue) do
		local row = uiRows[idx]
		if row then
			local icon = row:FindFirstChild("Icon")
			local detail = row:FindFirstChild("Detail")
			local gate = row:FindFirstChild("Gate")
			local stroke = row:FindFirstChild("UIStroke")

			local status = op.status or "pending"

			if status == "completed" then
				completedCount = completedCount + 1
				row.BackgroundColor3 = Theme.SuccessBg
				if icon then icon.Text = "✅" icon.TextColor3 = Theme.Success end
				if detail then detail.TextColor3 = Theme.Text end
				if gate then gate.Text = L.gate_completed gate.TextColor3 = Theme.Success end
				if stroke then stroke.Color = Theme.Success stroke.Transparency = 0.6 end
			elseif status == "failed" then
				row.BackgroundColor3 = Theme.ErrorBg
				if icon then icon.Text = "❌" icon.TextColor3 = Theme.Error end
				if detail then detail.TextColor3 = Theme.Text end
				if gate then gate.Text = L.gate_failed gate.TextColor3 = Theme.Error end
				if stroke then stroke.Color = Theme.Error stroke.Transparency = 0.6 end
			elseif status == "running" then
				row.BackgroundColor3 = Theme.SurfaceHighlight
				if icon then icon.Text = "▶️" icon.TextColor3 = Theme.Accent end
				if detail then detail.TextColor3 = Theme.Accent end
				if stroke then stroke.Color = Theme.Accent stroke.Transparency = 0.3 end

				local gateText = ""
				if type(op.gate) == "number" then
					local targetTime = op.gate
					gateText = string.format("%.1fs / %.1fs", elapsed, targetTime)
				elseif type(op.gate) == "string" then
					local targetCash = tonumber((op.gate:gsub("[^%d%-]", ""))) or 0
					gateText = string.format("$%d / $%d", cash, targetCash)
				else
					gateText = L.gate_running
				end
				if gate then gate.Text = gateText gate.TextColor3 = Theme.Accent end
			else -- pending
				row.BackgroundColor3 = Theme.Surface
				if icon then icon.Text = "⏳" icon.TextColor3 = Theme.TextDim end
				if detail then detail.TextColor3 = Theme.TextDim end
				if stroke then stroke.Color = Theme.Border stroke.Transparency = 0.8 end

				local gateText = ""
				if type(op.gate) == "number" then
					gateText = string.format("[⏳ %.1fs]", op.gate)
				elseif type(op.gate) == "string" then
					gateText = "[" .. op.gate .. "]"
				end
				if gate then gate.Text = gateText gate.TextColor3 = Theme.TextDim end
			end
		end
	end

	local total = #queue
	if total > 0 then
		local pct = (completedCount / total) * 100
		
		local isOver = false
		local resultText = ""
		local AE = getgenv().AE
		if AE and AE.IsGameOver and AE.IsGameOver() then
			isOver = true
			local res = AE.GetGameResult and AE.GetGameResult() or "unknown"
			if res == "victory" then
				resultText = L.game_victory
			elseif res == "defeat" then
				resultText = L.game_defeat
			else
				resultText = L.game_unknown
			end
		end

		local timeStr = ""
		if isOver then
			timeStr = resultText
		elseif Scripttable.queueEndElapsed then
			local remaining = Scripttable.queueEndElapsed - elapsed
			timeStr = string.format(L.time_countdown, remaining)
		else
			timeStr = string.format(L.time_elapsed, elapsed)
		end
		statusLabel.Text = string.format(L.summary_format, 
			completedCount, total, pct, timeStr, formatNumber(cash))
	else
		statusLabel.Text = L.queue_empty
	end
end

-- ============================================================
-- 掛鉤重播主入口與 API 函數
-- ============================================================
local function hookMainfunctions()
	local Scripttable, Mainfunction = getAE()
	local ExecuteQueue = Mainfunction.ExecuteQueue or (getgenv().AE and getgenv().AE.ExecuteQueue)
	local function hookedExecuteQueue(...)
		resetStatuses()
		pcall(updateUIList)
		return ExecuteQueue(...)
	end

	if Mainfunction.ExecuteQueue then
		Mainfunction.ExecuteQueue = hookedExecuteQueue
	end
	if getgenv().AE and getgenv().AE.ExecuteQueue then
		getgenv().AE.ExecuteQueue = hookedExecuteQueue
	end

	-- 掛鉤主要執行 API
	local RawPlaceUnit = Mainfunction.PlaceUnit
	Mainfunction.PlaceUnit = function(...)
		local id, r = RawPlaceUnit(...)
		local Scripttable, Mainfunction = getAE()
		local op = Scripttable.queue[current_index]
		if op and (op.kind == "place" or op.type == "place") then
			op.status = id and "completed" or "failed"
			moveToNextOp()
			scrollToActiveOp()
		end
		return id, r
	end

	local RawUpgrade = Mainfunction.UpgradeUnit
	Mainfunction.UpgradeUnit = function(...)
		local success = RawUpgrade(...)
		local Scripttable, Mainfunction = getAE()
		local op = Scripttable.queue[current_index]
		if op and (op.kind == "upgrade" or op.type == "upgrade") then
			op.status = success and "completed" or "failed"
			moveToNextOp()
			scrollToActiveOp()
		end
		return success
	end

	local RawSell = Mainfunction.SellUnit
	Mainfunction.SellUnit = function(...)
		local success = RawSell(...)
		local Scripttable, Mainfunction = getAE()
		local op = Scripttable.queue[current_index]
		if op and (op.kind == "sell" or op.type == "sell") then
			op.status = success and "completed" or "failed"
			moveToNextOp()
			scrollToActiveOp()
		end
		return success
	end

	local RawActivateAbility = Mainfunction.ActivateAbility
	if RawActivateAbility then
		Mainfunction.ActivateAbility = function(...)
			local success = RawActivateAbility(...)
			local Scripttable, Mainfunction = getAE()
			local op = Scripttable.queue[current_index]
			if op and (op.kind == "ability" or op.type == "ability") then
				op.status = success and "completed" or "failed"
				moveToNextOp()
				scrollToActiveOp()
			end
			return success
		end
	end

	local RawSellAll = Mainfunction.SellAll
	if RawSellAll then
		Mainfunction.SellAll = function(...)
			local success = RawSellAll(...)
			local Scripttable, Mainfunction = getAE()
			local op = Scripttable.queue[current_index]
			if op and (op.kind == "sellall" or op.type == "sellall") then
				op.status = "completed"
				moveToNextOp()
				scrollToActiveOp()
			end
			return success
		end
	end

	local RawAnswerVote = Mainfunction.AnswerVote
	if RawAnswerVote then
		Mainfunction.AnswerVote = function(...)
			local success = RawAnswerVote(...)
			local Scripttable, Mainfunction = getAE()
			local op = Scripttable.queue[current_index]
			if op and (op.kind == "vote" or op.type == "skipwave") then
				op.status = success and "completed" or "failed"
				moveToNextOp()
				scrollToActiveOp()
			end
			return success
		end
	end

	local RawSetSetting = Mainfunction.SetSetting
	if RawSetSetting then
		Mainfunction.SetSetting = function(...)
			local success = RawSetSetting(...)
			local Scripttable, Mainfunction = getAE()
			local op = Scripttable.queue[current_index]
			if op and (op.kind == "setting" or op.kind == "autoskip") then
				op.status = success and "completed" or "failed"
				moveToNextOp()
				scrollToActiveOp()
			end
			return success
		end
	end
end

-- 執行掛鉤
hookMainfunctions()

-- === 自動重製與新局偵測 ===
local lastGameStart = workspace:GetAttribute("GameStartTime")

local function onGameStartTimeChanged()
	local Scripttable, Mainfunction = getAE()
	local gst = workspace:GetAttribute("GameStartTime")
	if type(gst) == "number" and gst > 0 then
		if gst ~= lastGameStart then
			lastGameStart = gst
			print(L.log_new_game)
			resetStatuses()
			pcall(updateUIList)
			pcall(scrollToActiveOp)
		end
	else
		if lastGameStart ~= nil then
			lastGameStart = nil
			print(L.log_game_ended)
			resetStatuses()
			pcall(updateUIList)
		end
	end
end

workspace:GetAttributeChangedSignal("GameStartTime"):Connect(onGameStartTimeChanged)

-- 初始化 UI 清單與同步
initUIList()
local Scripttable, Mainfunction = getAE()
if Scripttable then
	lastLocalGameStart = Scripttable.gameStartTime
end

if getElapsed() > 0 then
	syncRunningQueue()
else
	resetStatuses()
end

-- === UI 刷新背景循環 ===
task.spawn(function()
	while screenGui.Parent do
		pcall(updateUIList)
		task.wait(0.2)
	end
end)

print(L.log_started)