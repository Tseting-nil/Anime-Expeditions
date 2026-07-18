-- 側邊通知模組
if not getgenv().NotificationModule then
	pcall(function()
		loadstring(game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/08653e6aa9fc12a9f097bfb10e6654e7/raw/00001d614d928fc5dafce59133a012dd78419afd/%25E5%2581%25B4%25E9%2582%258A%25E9%2580%259A%25E7%259F%25A5%25E6%25A8%25A1%25E7%25B5%2584.lua"))()
	end)
end

-- i18n
local HttpService = game:GetService("HttpService")
local currentLang = "zh"
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
				end
			end
		end
	end)
end

local i18n = {
	zh = {
		windowTitle    = "遊戲內介面",
		tab_main       = "Main",
		tab_playinfo   = "玩家資訊",
		tab_localscript = "本地腳本",
		tab_settings   = "設置",
		tab_stats      = "統計",
		sectionStatus  = "當前狀態",
		envChecking    = "環境檢查中...",
		gameState      = "遊戲當前狀態",
		autoReplay     = "重開",
		sectionControl = "控制按鈕",
		btnToggleAutoReplay = "控制自動重開",
		btnManualReplay     = "手動重開",
		btnLobby            = "回大廳",
		noEnv          = "無環境",
		stateLobby     = "當前遊戲狀態：大廳",
		stateCombat    = "當前遊戲狀態：戰鬥中",
		stateGameOver  = "當前遊戲狀態：結束",
		stateUnknown   = "當前遊戲狀態：未知",
		envExist       = "環境檢查：本地環境存在",
		envNotExist    = "環境檢查：本地環境不存在",
		autoReplayOn   = "自動重新戰鬥：已開啟",
		autoReplayOff  = "自動重新戰鬥：未開啟",
		queueRemaining = "佇列剩餘：",
		queueNA        = "---",
		queueOvertime  = "（超時）",
		localscript_path           = "路徑: ",
		localscript_list           = "腳本列表",
		localscript_refresh        = "重新整理",
		localscript_run            = "執行",
		localscript_no_scripts     = "目錄中無腳本",
		localscript_done           = "執行完成",
		localscript_error          = "執行錯誤",
		localscript_refreshed      = "清單已重新整理",
		localscript_delete         = "刪除",
		localscript_confirm_title  = "確認刪除?",
		localscript_confirm_title2 = "⚠ 此操作無法復原",
		localscript_confirm_yes    = "確認",
		localscript_confirm_no     = "取消",
		localscript_delete_final   = "永久刪除",
		localscript_deleted        = "已刪除",
		localscript_delete_error   = "刪除失敗",
		localscript_info           = "i",
		localscript_info_no_block  = "（無資訊區塊）",
		localscript_info_read_fail = "讀取失敗",
		localscript_info_close     = "關閉",
		localscript_info_copy      = "複製",
		localscript_info_copied    = "已複製到剪貼簿",
		localscript_save_running   = "儲存正在運行的腳本",
		localscript_save           = "儲存",
		localscript_save_name_title = "輸入儲存名稱",
		localscript_save_name_ph    = "腳本名稱...",
		localscript_save_success   = "已儲存",
		localscript_save_error     = "儲存失敗",
		localscript_save_no_running = "無正在運行的腳本",
		replayConfirm_title    = "確認手動重開?",
		playCoinInit           = "金幣 (Gold)：---",
		playGemInit            = "寶石 (Gem)：---",
		playYenInit            = "金幣 (Yen)：---",
		playCurrencyNotFound   = "找不到玩家貨幣資料，請確認已進入遊戲",
		playCoinFmt            = "金幣 (Gold)：%d",
		playGemFmt             = "寶石 (Gem)：%d",
		playYenFmt             = "金幣 (Yen)：%d",
		keyTimeLabel              = "密鑰剩餘時間：",
		keyTimePerm               = "永久",
		keyExpired                = "已過期",
		unitDay = "天", unitHour = "時", unitMin = "分",
		instantUpdate             = "自動更新",
		onText = "開", offText = "關",
		instantUpdateConfirmTitle = "確認關閉自動更新？",
		instantUpdateConfirmDesc  = "關閉後主腳本只會在『大廳』更新，掛機中途不會被打斷。",
		stats_section          = "累計統計",
		stats_wins             = "勝：",
		stats_losses           = "輸：",
		stats_total            = "總場：",
		stats_winrate          = "勝率：",
		stats_lastReset        = "上次重置：",
		stats_reset            = "重置統計",
		stats_reset_confirm    = "確認重置統計？",
		stats_never_reset      = "從未重置",
	},
	en = {
		windowTitle    = "In-Game UI",
		tab_main       = "Main",
		tab_playinfo   = "Info",
		tab_localscript = "Script",
		tab_settings   = "Settings",
		tab_stats      = "Stats",
		sectionStatus  = "Current Status",
		envChecking    = "Checking environment...",
		gameState      = "Game State",
		autoReplay     = "Auto Replay",
		sectionControl = "Control Buttons",
		btnToggleAutoReplay = "Toggle Auto Replay",
		btnManualReplay     = "Replay",
		btnLobby            = "To Lobby",
		noEnv          = "No Environment",
		stateLobby     = "Game State: Lobby",
		stateCombat    = "Game State: In Combat",
		stateGameOver  = "Game State: Game Over",
		stateUnknown   = "Game State: Unknown",
		envExist       = "Environment: Local env exists",
		envNotExist    = "Environment: Local env missing",
		autoReplayOn   = "Auto Replay: Enabled",
		autoReplayOff  = "Auto Replay: Disabled",
		queueRemaining = "Queue Remaining: ",
		queueNA        = "---",
		queueOvertime  = " (overtime)",
		localscript_path           = "Path: ",
		localscript_list           = "Script List",
		localscript_refresh        = "Refresh",
		localscript_run            = "Run",
		localscript_no_scripts     = "No scripts in directory",
		localscript_done           = "Executed",
		localscript_error          = "Error",
		localscript_refreshed      = "List refreshed",
		localscript_delete         = "Delete",
		localscript_confirm_title  = "Confirm Delete?",
		localscript_confirm_title2 = "⚠ This cannot be undone",
		localscript_confirm_yes    = "Confirm",
		localscript_confirm_no     = "Cancel",
		localscript_delete_final   = "Delete Forever",
		localscript_deleted        = "Deleted",
		localscript_delete_error   = "Delete failed",
		localscript_info           = "i",
		localscript_info_no_block  = "(No info block)",
		localscript_info_read_fail = "Read failed",
		localscript_info_close     = "Close",
		localscript_info_copy      = "Copy",
		localscript_info_copied    = "Copied to clipboard",
		localscript_save_running   = "Save Running Script",
		localscript_save           = "Save",
		localscript_save_name_title = "Enter Save Name",
		localscript_save_name_ph    = "Script name...",
		localscript_save_success   = "Saved",
		localscript_save_error     = "Save failed",
		localscript_save_no_running = "No running script",
		replayConfirm_title    = "Confirm Replay?",
		playCoinInit           = "Gold: ---",
		playGemInit            = "Gems: ---",
		playYenInit            = "Yen: ---",
		playCurrencyNotFound   = "Player currency data not found, please confirm you have entered the game",
		playCoinFmt            = "Gold: %d",
		playGemFmt             = "Gems: %d",
		playYenFmt             = "Yen: %d",
		keyTimeLabel              = "Key time left: ",
		keyTimePerm               = "Permanent",
		keyExpired                = "Expired",
		unitDay = "d", unitHour = "h", unitMin = "m",
		instantUpdate             = "Auto Update",
		onText = "ON", offText = "OFF",
		instantUpdateConfirmTitle = "Disable auto update?",
		instantUpdateConfirmDesc  = "When off, the main script only updates in the LOBBY — farming won't be interrupted.",
		stats_section          = "Cumulative Stats",
		stats_wins             = "Wins: ",
		stats_losses           = "Losses: ",
		stats_total            = "Total: ",
		stats_winrate          = "Win Rate: ",
		stats_lastReset        = "Last Reset: ",
		stats_reset            = "Reset Stats",
		stats_reset_confirm    = "Confirm Reset?",
		stats_never_reset      = "Never reset",
	},
}

local L = i18n[currentLang]
local fontSize = currentLang == "en" and 14 or nil

local Msg = getgenv().NotificationModule or {
	Success = function(_, txt) print("[Success]", txt) end,
	Warning = function(_, txt) warn("[Warning]", txt) end,
}

-- ========================================================================== --
-- Replica 讀取 (用來讀取貨幣)
local ReplicaClient
pcall(function()
	ReplicaClient = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ReplicaClient"))
end)

local function reps()
	local ok, t = pcall(function()
		return ReplicaClient.Test().Replicas
	end)
	return (ok and type(t) == "table") and t or {}
end

local function findReplica(token, pred)
	for _, r in pairs(reps()) do
		if r.Token == token and r.Data and (not pred or pred(r)) then
			return r
		end
	end
	return nil
end

local function GetBalance(currency)
	local pd = findReplica("PlayerData")
	if pd then
		local item = (pd.Data.ItemData or {})[currency]
		return item and item.Amount or 0
	end
	return 0
end

local function GetYen()
	local gpd = findReplica("GamePlayerData")
	return gpd and gpd.Data.Yen or 0
end

-- ========================================================================== --
-- GUI

local ReGui = loadstring(game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/169b7303e1418cb301bad5ab427e9351/raw/93e90190f628387b545eef62b49e4ce146d1dad8/GUI:ReGui"))()

local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local windowSize = currentLang == "en" and UDim2.new(0, 300, 0, 220) or UDim2.new(0, 300, 0, 250)

local TabsWindow = ReGui:TabsWindow({
	Title = L.windowTitle,
	Size = windowSize,
	NoScroll = true,
})

local Tabs = {}

for _, Name in ipairs({
	L.tab_main,
	L.tab_playinfo,
	L.tab_localscript,
	L.tab_settings,
	L.tab_stats
}) do
	local Tab = TabsWindow:CreateTab({
		Name = Name
	})
	table.insert(Tabs, Tab)
end

-- 修改 Tab 字體和大小
task.spawn(function()
	task.wait(0.1)
	for _, tab in ipairs(Tabs) do
		local tabButton = tab.TabButton.Button
		local label = tabButton:FindFirstChildWhichIsA("TextLabel")
		if label then
			label.TextSize = currentLang == "en" and 14 or 18
			label.Font = Enum.Font.Ubuntu
		end
	end
end)

local Tab_main = Tabs[1]:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

local Tab_playinfo = Tabs[2]:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

local Tab_Localscript = Tabs[3]:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

local Tab_settings = Tabs[4]:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

local Tab_stats = Tabs[5]:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

-- ===== 設置分頁：密鑰剩餘時間 =====
local SETTINGS_API_VAR = "Tsetingnil_script/keysystem.json"

local function readApiVarTable()
	local ok, data = pcall(function()
		if isfile and readfile and isfile(SETTINGS_API_VAR) then
			return HttpService:JSONDecode(readfile(SETTINGS_API_VAR))
		end
	end)
	return (ok and type(data) == "table") and data or {}
end

-- 由 loader 寫入 keysystem 的 expires_at(秒) 計算剩餘時間文字
local function fmtKeyRemaining()
	local exp = tonumber(readApiVarTable().expires_at)
	if not exp then return L.keyTimeLabel .. L.keyTimePerm end
	if exp > 1e10 then exp = math.floor(exp / 1000) end -- 毫秒→秒
	local left = exp - os.time()
	if left <= 0 then return L.keyTimeLabel .. L.keyExpired end
	local d = math.floor(left / 86400)
	local h = math.floor((left % 86400) / 3600)
	local m = math.floor((left % 3600) / 60)
	return string.format("%s%d%s %d%s %d%s", L.keyTimeLabel, d, L.unitDay, h, L.unitHour, m, L.unitMin)
end

Tab_settings:Separator({ Text = L.tab_settings })

local KeyTime_Label = Tab_settings:Label({
	Text = fmtKeyRemaining(),
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

Tab_main:Separator({
	Text = L.sectionStatus
})

local API_Check_Label = Tab_main:Label({
	Text = L.envChecking,
	TextSize = fontSize or 18,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local GameState_Label = Tab_main:Label({
	Text = L.gameState,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local AutoReplay_Label = Tab_main:Label({
	Text = L.autoReplay,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local QueueRemaining_Label = Tab_main:Label({
	Text = L.queueRemaining .. L.queueNA,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

Tab_main:Separator({
	Text = L.sectionControl
})

local ROW_QK = Tab_main:Row()

ROW_QK:Button({
	Text = L.btnToggleAutoReplay,
	TextSize = fontSize or 18,
	Callback = function()
		local AE = getgenv().AE
		if AE and AE.Scripttable then
			AE.AutoReplay(not AE.Scripttable.autoReplay)
		else
			Msg:Warning(L.noEnv)
		end
	end,
	DoubleClick = false,
})

ROW_QK:Button({
	Text = L.btnManualReplay,
	TextSize = fontSize or 18,
	Callback = function(btn)
		local AE = getgenv().AE
		if AE then
			local Popup = Tab_main:PopupModal({ RelativeTo = btn })
			Popup:Separator({ Text = L.replayConfirm_title })
			local PopupRow = Popup:Row({ Expanded = true })
			PopupRow:Button({
				Text = L.localscript_confirm_yes,
				Callback = function()
					Popup:ClosePopup()
					pcall(function()
						if AE.Restart then
							AE.Restart()
						end
					end)
				end,
			})
			PopupRow:Button({
				Text = L.localscript_confirm_no,
				Callback = function()
					Popup:ClosePopup()
				end,
			})
		else
			Msg:Warning(L.noEnv)
		end
	end,
	DoubleClick = false,
})

ROW_QK:Button({
	Text = L.btnLobby,
	TextSize = fontSize or 18,
	Callback = function()
		local TeleportService = game:GetService("TeleportService")
		TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
	end,
	DoubleClick = false,
})

task.spawn(function()
	while true do
		local AE = getgenv().AE
		if AE then
			API_Check_Label.Text = L.envExist
			if AE.Scripttable and AE.Scripttable.autoReplay then
				AutoReplay_Label.Text = L.autoReplayOn
			else
				AutoReplay_Label.Text = L.autoReplayOff
			end

			-- 狀態檢測
			if AE.IsLobby and AE.IsLobby() then
				GameState_Label.Text = L.stateLobby
			elseif AE.IsGameOver and AE.IsGameOver() then
				GameState_Label.Text = L.stateGameOver
			elseif AE.IsRunning and AE.IsRunning() then
				GameState_Label.Text = L.stateCombat
			else
				GameState_Label.Text = L.stateUnknown
			end

			-- 佇列剩餘
			if AE.GetQueueRemaining then
				local remaining = AE.GetQueueRemaining()
				if remaining then
					if remaining < 0 then
						QueueRemaining_Label.Text = L.queueRemaining .. string.format("%d s", -remaining) .. L.queueOvertime
					else
						QueueRemaining_Label.Text = L.queueRemaining .. string.format("%d s", remaining)
					end
				else
					QueueRemaining_Label.Text = L.queueRemaining .. L.queueNA
				end
			else
				QueueRemaining_Label.Text = L.queueRemaining .. L.queueNA
			end
		else
			API_Check_Label.Text = L.envNotExist
			AutoReplay_Label.Text = L.noEnv
			GameState_Label.Text = L.stateUnknown
			QueueRemaining_Label.Text = L.queueRemaining .. L.queueNA
		end
		pcall(function() KeyTime_Label.Text = fmtKeyRemaining() end)
		task.wait(1)
	end
end)

-- ========================================================================== --
-- Tab_playinfo
local play_coin = Tab_playinfo:Label({
	Text = L.playCoinInit,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local play_gem = Tab_playinfo:Label({
	Text = L.playGemInit,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local play_yen = Tab_playinfo:Label({
	Text = L.playYenInit,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

task.spawn(function()
	while true do
		pcall(function()
			play_gem.Text = string.format(L.playGemFmt, GetBalance("Gem"))
			play_coin.Text = string.format(L.playCoinFmt, GetBalance("Gold"))
			play_yen.Text = string.format(L.playYenFmt, GetYen())
		end)
		task.wait(1)
	end
end)

-- ========================================================================== --
-- Tab_Localscript
local Localscript = {
	path = "Tsetingnil_script/AnimeExpedition/Script", -- 用正斜線相容所有平台
	ScriptListTable = nil,
	Excluded = {"_Venus", "_Saturn", "_Mars"},
}

local BuildScriptList
BuildScriptList = function()
	Localscript.ScriptListTable:ClearRows()
	local path = Localscript.path
	local ok, files = pcall(listfiles, path)
	local scripts = {}
	if ok and files then
		for _, filePath in ipairs(files) do
			local name = filePath:match("([^/\\]+)$") or filePath
			if name:match("%.lua$") or name:match("%.txt$") then
				local excluded = false
				for _, suffix in ipairs(Localscript.Excluded) do
					if name:match(suffix .. "%.lua$") or name:match(suffix .. "%.txt$") then
						excluded = true; break
					end
				end
				if not excluded then
					scripts[#scripts + 1] = { name = name, path = filePath }
				end
			end
		end
	end
	if #scripts == 0 then
		local EmptyRow = Localscript.ScriptListTable:NextRow()
		EmptyRow:Column():Label({ Text = L.localscript_no_scripts })
		return
	end
	for _, script in ipairs(scripts) do
		local Row = Localscript.ScriptListTable:NextRow()

		local NameCol = Row:Column()
		NameCol:Label({ Text = script.name })

		local ActionsCol = Row:Column()
		local actionsFrame = ActionsCol.RawObject
		local actionsFlex = Instance.new("UIFlexItem", actionsFrame)
		actionsFlex.FlexMode = Enum.UIFlexMode.None
		actionsFrame.Size = UDim2.new(0, 80, 1, 0)

		local ActionRow = ActionsCol:Row({ Expanded = true })

		ActionRow:SmallButton({
			Text = L.localscript_info,
			Callback = function()
				local content
				local ok3, raw = pcall(readfile, script.path)
				if ok3 and raw then
					local map, diff, mode, timeStr
					local towers = {}
					local inTowers = false
					for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
						line = line:gsub("\r", "")
						local m, d, mo = line:match("Map:%s*(.-)%s*|%s*Difficulty:%s*(.-)%s*|%s*Mode:%s*(.-)%s*$")
						if m then
							map, diff, mode = m, d, mo
						end
						local t = line:match("Time:%s*(.-)%s*$")
						if t and not timeStr then
							timeStr = t:match("(.-)%s*%(") or t
						end
						if line:find("Towers used:") then
							inTowers = true
						elseif inTowers then
							if line:find("]]") or line:match("^%s*$") then
								inTowers = false
							else
								local tower = line:match("%-%s*(.-)%s*$")
								if tower and tower ~= "" then
									table.insert(towers, tower)
								end
							end
						end
					end
					local out = {}
					if map then
						out[#out + 1] = "Map: " .. map
					end
					if diff then
						out[#out + 1] = "Difficulty: " .. diff
					end
					if timeStr then
						out[#out + 1] = "Time: " .. timeStr
					end
					if mode and mode ~= "" then
						out[#out + 1] = "<font color='#FFB347'>Mode: " .. mode .. "</font>"
					end
					if #towers > 0 then
						out[#out + 1] = "<font color='#5BC8F5'>Towers used:</font>"
						for _, t in ipairs(towers) do
							out[#out + 1] = "  - " .. t
						end
					end
					content = #out > 0 and table.concat(out, "\n") or L.localscript_info_no_block
				else
					content = L.localscript_info_read_fail
				end
				local InfoModal = TabsWindow:PopupModal({ Title = script.name })
				local BtnRow = InfoModal:Row({ Expanded = true })
				BtnRow:Button({
					Text     = L.localscript_info_close,
					Callback = function() InfoModal:ClosePopup() end,
				})
				BtnRow:Button({
					Text     = L.localscript_info_copy,
					Callback = function()
						if raw and pcall(setclipboard, raw) then
							Msg:Success(L.localscript_info_copied)
						end
					end,
				})
				InfoModal:Console({
					Value    = content,
					ReadOnly = true,
					RichText = true,
					Border   = true,
					Size     = UDim2.new(1, 0, 0, isMobile and 110 or 150),
				})
			end,
		})

		ActionRow:SmallButton({
			Text = L.localscript_delete,
			Callback = function(delBtn)
				local Popup1 = Tab_Localscript:PopupModal({
					RelativeTo = delBtn,
				})
				Popup1:Separator({ Text = L.localscript_confirm_title })
				Popup1:Label({ Text = script.name, TextWrapped = true })
				local Row1 = Popup1:Row({ Expanded = true })
				Row1:Button({
					Text = L.localscript_confirm_yes,
					Callback = function()
						Popup1:ClosePopup()
						local Popup2 = Tab_Localscript:PopupModal({
							RelativeTo = delBtn,
						})
						Popup2:Separator({ Text = L.localscript_confirm_title2 })
						local Row2 = Popup2:Row({ Expanded = true })
						Row2:Button({
							Text = L.localscript_delete_final,
							Callback = function()
								Popup2:ClosePopup()
								local ok2, err = pcall(delfile, script.path)
								if ok2 then
									Msg:Success(L.localscript_deleted .. ": " .. script.name)
									BuildScriptList()
								else
									Msg:Warning(L.localscript_delete_error .. ": " .. tostring(err))
								end
							end,
						})
						Row2:Button({
							Text = L.localscript_confirm_no,
							Callback = function()
								Popup2:ClosePopup()
							end,
						})
					end,
				})
				Row1:Button({
					Text = L.localscript_confirm_no,
					Callback = function()
						Popup1:ClosePopup()
					end,
				})
			end,
		})
	end
end

Tab_Localscript:Label({
	Text = L.localscript_path .. Localscript.path,
	TextSize = fontSize,
})

Tab_Localscript:Separator({ Text = L.localscript_list })

local HeaderRow = Tab_Localscript:Row()

HeaderRow:Button({
	Text = L.localscript_refresh,
	Callback = function()
		BuildScriptList()
		Msg:Success(L.localscript_refreshed)
	end,
})

HeaderRow:Button({
	Text = L.localscript_save_running,
	Callback = function()
		local userId = tostring(game.Players.LocalPlayer.UserId)
		local mainPathBS = "Tsetingnil_script\\AnimeExpedition\\main_" .. userId .. ".lua"
		local mainPathFW = "Tsetingnil_script/AnimeExpedition/main_" .. userId .. ".lua"
		local useFW = isfile and isfile(mainPathFW) and not isfile(mainPathBS)
		local mainPath = useFW and mainPathFW or mainPathBS
		local ok3, raw = pcall(readfile, mainPath)
		if not ok3 or not raw or raw == "" then
			ok3, raw = pcall(readfile, useFW and mainPathBS or mainPathFW)
		end
		if not ok3 or not raw or raw == "" then
			Msg:Warning(L.localscript_save_no_running)
			return
		end
		local content
		local map, diff, mode, timeStr
		local towers = {}
		local inTowers = false
		for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
			line = line:gsub("\r", "")
			local m, d, mo = line:match("Map:%s*(.-)%s*|%s*Difficulty:%s*(.-)%s*|%s*Mode:%s*(.-)%s*$")
			if m then
				map, diff, mode = m, d, mo
			end
			local t = line:match("Time:%s*(.-)%s*$")
			if t and not timeStr then
				timeStr = t:match("(.-)%s*%(") or t
			end
			if line:find("Towers used:") then
				inTowers = true
			elseif inTowers then
				if line:find("]]") or line:match("^%s*$") then
					inTowers = false
				else
					local tower = line:match("%-%s*(.-)%s*$")
					if tower and tower ~= "" then table.insert(towers, tower) end
				end
			end
		end
		local out = {}
		if map then
			out[#out + 1] = "Map: " .. map
		end
		if diff then
			out[#out + 1] = "Difficulty: " .. diff
		end
		if timeStr then
			out[#out + 1] = "Time: " .. timeStr
		end
		if mode and mode ~= "" then
			out[#out + 1] = "<font color='#FFB347'>Mode: " .. mode .. "</font>"
		end
		if #towers > 0 then
			out[#out + 1] = "<font color='#5BC8F5'>Towers used:</font>"
			for _, t in ipairs(towers) do out[#out + 1] = "  - " .. t end
		end
		content = #out > 0 and table.concat(out, "\n") or L.localscript_info_no_block
		local scriptTitle = "main_" .. userId
		local InfoModal = TabsWindow:PopupModal({ Title = scriptTitle })
		local BtnRow = InfoModal:Row({ Expanded = true })
		BtnRow:Button({
			Text = L.localscript_save,
			Callback = function()
				local inputName = ""
				local NameModal = TabsWindow:PopupModal({ Title = L.localscript_save_name_title })
				NameModal:InputText({
					Placeholder = L.localscript_save_name_ph,
					Value = "",
					Callback = function(_, text)
						inputName = text
					end,
				})
				local NRow = NameModal:Row({ Expanded = true })
				NRow:Button({
					Text = L.localscript_confirm_yes,
					Callback = function()
						local name = inputName:match("^%s*(.-)%s*$")
						if name == "" then return end
						local sep = useFW and "/" or "\\"
						local savePath = "Tsetingnil_script" .. sep .. "AnimeExpedition" .. sep .. "Script" .. sep .. name .. ".lua"
						local outerBlock = raw:match("%-%-%[%[(.-)%]%]") or ""
						local wrappedContent = "--[[\n" .. outerBlock .. "\n]]\n\n" ..
							"-- ========== FULL SCRIPT ==========\n" ..
							"local fullScript = [=[\n" ..
							raw ..
							"\n]=]\n\n" ..
							"-- ========== Start ==========\n" ..
							"local AE = getgenv().AE\n" ..
							"if not AE or not AE.ExecuteQueue then\n" ..
							"\tloadstring(game:HttpGet(\"https://raw.githubusercontent.com/Tseting-nil/Anime-Expeditions/refs/heads/main/%E5%AF%86%E9%91%B0%E7%B3%BB%E7%B5%B1.lua\"))()\n" ..
							"\tAE = getgenv().AE\n" ..
							"end\n\n" ..
							"AE.SaveLocalScript(fullScript)\n" ..
							"loadstring(fullScript)()\n"
						if not isfolder("Tsetingnil_script") then makefolder("Tsetingnil_script") end
						if not (isfolder("Tsetingnil_script\\AnimeExpedition") or isfolder("Tsetingnil_script/AnimeExpedition")) then makefolder("Tsetingnil_script" .. sep .. "AnimeExpedition") end
						if not (isfolder("Tsetingnil_script\\AnimeExpedition\\Script") or isfolder("Tsetingnil_script/AnimeExpedition/Script")) then makefolder("Tsetingnil_script" .. sep .. "AnimeExpedition" .. sep .. "Script") end
						local ok4, err = pcall(writefile, savePath, wrappedContent)
						if ok4 then
							Msg:Success(L.localscript_save_success .. ": " .. name)
							NameModal:ClosePopup()
							InfoModal:ClosePopup()
							BuildScriptList()
						else
							Msg:Warning(L.localscript_save_error .. ": " .. tostring(err))
						end
					end,
				})
				NRow:Button({
					Text = L.localscript_confirm_no,
					Callback = function()
						NameModal:ClosePopup()
					end,
				})
			end,
		})
		BtnRow:Button({
			Text = L.localscript_info_close,
			Callback = function() InfoModal:ClosePopup() end,
		})
		InfoModal:Console({
			Value    = content,
			ReadOnly = true,
			RichText = true,
			Border   = true,
			Size     = UDim2.new(1, 0, 0, isMobile and 110 or 150),
		})
	end,
})

Localscript.ScriptListTable = Tab_Localscript:Table({
	RowBackground = true,
	Border = true,
})

BuildScriptList()

-- ========================================================================== --
-- Tab_stats
-- ========================================================================== --
local STATS_DATA_PATH = "Tsetingnil_script/AnimeExpedition/Config/Ingame_Data_Config.json"
local Stats_LocalPlayer = game:GetService("Players").LocalPlayer
local Stats_playerId    = tostring(Stats_LocalPlayer.UserId)

local function statsEnsureFolder()
	pcall(function()
		if not isfolder or not makefolder then return end
		if not isfolder("Tsetingnil_script") then makefolder("Tsetingnil_script") end
		if not isfolder("Tsetingnil_script/AnimeExpedition") then makefolder("Tsetingnil_script/AnimeExpedition") end
		if not isfolder("Tsetingnil_script/AnimeExpedition/Config") then makefolder("Tsetingnil_script/AnimeExpedition/Config") end
	end)
end

local function statsReadAll()
	local ok, data = pcall(function()
		if not (isfile and isfile(STATS_DATA_PATH) and readfile) then return {} end
		return HttpService:JSONDecode(readfile(STATS_DATA_PATH))
	end)
	return (ok and type(data) == "table") and data or {}
end

local function statsWriteAll(allData)
	pcall(function()
		if not writefile then return end
		statsEnsureFolder()
		writefile(STATS_DATA_PATH, HttpService:JSONEncode(allData))
	end)
end

local function statsGetOrInit(allData)
	if not allData[Stats_playerId] then
		allData[Stats_playerId] = {
			lastReset = os.time(),
			wins      = 0,
			losses    = 0,
		}
		statsWriteAll(allData)
	end
	return allData[Stats_playerId]
end

local function statsSave(isWin)
	local allData = statsReadAll()
	local pd = statsGetOrInit(allData)
	if isWin then
		pd.wins = pd.wins + 1
	else
		pd.losses = pd.losses + 1
	end
	allData[Stats_playerId] = pd
	statsWriteAll(allData)
	return pd
end

local function statsReset()
	local allData = statsReadAll()
	allData[Stats_playerId] = {
		lastReset = os.time(),
		wins      = 0,
		losses    = 0,
	}
	statsWriteAll(allData)
	return allData[Stats_playerId]
end

local function statsFmtWinRate(wins, losses)
	local total = wins + losses
	if total == 0 then return "0.0%" end
	return string.format("%.1f%%", wins / total * 100)
end

local function statsFmtTime(ts)
	if not ts or ts == 0 then return L.stats_never_reset end
	return os.date("%Y-%m-%d %H:%M:%S", ts)
end

-- 初始載入
local _statsAllData = statsReadAll()
local _statsPd      = statsGetOrInit(_statsAllData)

-- UI
Tab_stats:Separator({ Text = L.stats_section })

local statsLabel_wins = Tab_stats:Label({
	Text = L.stats_wins .. _statsPd.wins,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local statsLabel_losses = Tab_stats:Label({
	Text = L.stats_losses .. _statsPd.losses,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local statsLabel_total = Tab_stats:Label({
	Text = L.stats_total .. (_statsPd.wins + _statsPd.losses),
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local statsLabel_winrate = Tab_stats:Label({
	Text = L.stats_winrate .. statsFmtWinRate(_statsPd.wins, _statsPd.losses),
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local statsLabel_lastReset = Tab_stats:Label({
	Text = L.stats_lastReset .. statsFmtTime(_statsPd.lastReset),
	TextSize = fontSize or 14,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(180, 180, 180),
})

local function refreshStatsUI(pd)
	statsLabel_wins.Text      = L.stats_wins      .. pd.wins
	statsLabel_losses.Text    = L.stats_losses    .. pd.losses
	statsLabel_total.Text     = L.stats_total     .. (pd.wins + pd.losses)
	statsLabel_winrate.Text   = L.stats_winrate   .. statsFmtWinRate(pd.wins, pd.losses)
	statsLabel_lastReset.Text = L.stats_lastReset .. statsFmtTime(pd.lastReset)
end

Tab_stats:Button({
	Text = L.stats_reset,
	TextSize = fontSize or 16,
	Callback = function(btn)
		local Popup = Tab_stats:PopupModal({ RelativeTo = btn })
		Popup:Separator({ Text = L.stats_reset_confirm })
		local PopupRow = Popup:Row({ Expanded = true })
		PopupRow:Button({
			Text = L.localscript_confirm_yes,
			Callback = function()
				Popup:ClosePopup()
				local pd = statsReset()
				refreshStatsUI(pd)
			end
		})
		PopupRow:Button({
			Text = L.localscript_confirm_no,
			Callback = function()
				Popup:ClosePopup()
			end
		})
	end,
})

-- GameOver 偵測
task.spawn(function()
	local hasRecorded = false
	while true do
		task.wait(1)
		local AE = getgenv().AE
		if AE then
			if AE.IsGameOver and AE.IsGameOver() then
				if not hasRecorded then
					hasRecorded = true
					if AE.GetGameResult then
						local result = AE.GetGameResult()
						if result == "victory" or result == "defeat" then
							local isWin = (result == "victory")
							local pd = statsSave(isWin)
							refreshStatsUI(pd)
						end
					end
				end
			else
				hasRecorded = false
			end
		end
	end
end)
