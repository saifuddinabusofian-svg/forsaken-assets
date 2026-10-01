-- LOADSTRING READY: upload this file to your repo as ForsakenChase.lua (main branch), then run the 1-line loader below.
-- Loader: loadstring(game:HttpGet("https://raw.githubusercontent.com/saifuddinabusofian-svg/forsaken-assets/main/ForsakenChase.lua"))()
-- Forsaken Chase System v2.5p (renamed-loadstring-ready)
-- Base: v2.5o Venice-polish-fix | Changes: aint-got-a-mouth + lets-get-this-show renamed (no ? no apostrophe), SmartAsset hardened, loadstring-ready (no getcustomasset path dependency)
-- Base: v2.5n Venice polished | Fixes: heartbeat-survive-silence, eye-singles scale/pos, EYE_FINAL download, theme-clamp, GUI leak, respawn drag
-- Features: IDLE+HEARTBEAT, WALK SPEED, CROUCH, RESPAWN SFX, VISUALIZER, EYES, BACKWARD ANIM

print("[Chase] Initializing v2.5p (renamed-loadstring-ready)...")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Player Setup
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players.PlayerAdded:Wait()
	LocalPlayer = Players.LocalPlayer
end

-- Random Seed
math.randomseed(os.clock() * 1000)

-- Configuration
local CONFIG = {
	-- Distances
	LAYER_DISTANCES = {116, 75, 57},
	LAST_CHANCE_LAYER_DISTANCES = {121, 80, 61},
	CHASE_DISTANCE = 45,
	CHASE_ONLY_BONUS = 10,
	LAST_CHANCE_DISTANCE = 50,
	
	-- Health Thresholds
	HEARTBEAT_HEALTH = 0.35,
	FINAL_CHANCE_HP = 10,
	
	-- Volumes
	VOLUME_LAYERS = 0.6,
	VOLUME_CHASE = 1.0,
	VOLUME_HEARTBEAT = 0.5,
	VOLUME_IDLE = 0.3,
	VOLUME_LAST_CHANCE = 1.0,
	VOLUME_FINAL_CHANCE = 1.0,
	
	-- Timing
	CROSSFADE_FACTOR = 0.5,
	CHASE_EXIT_DELAY = 2,
	
	-- State
	IS_ACTIVE = false,
	CURRENT_THEME = 1,
	TEAM_MODE = "any",
	TARGET_TEAMS = {},
	
	-- Eye Settings
	EYE_ENABLED = true,
	EYE_SCALE = 0.45,
	EYE_POS_X = 0.5,
	EYE_POS_Y = 0.06,
	EYE_SHAKE_ENABLED = true,
	EYE_SHAKE_AMOUNT = 6,
	EYE_CHASE_SINGLE = "frame_0_delay-0.06schas.png",
	EYE_LAST_SINGLE = "frame_00_delay-0.06s.png",
	EYE_FINAL_SINGLE = "frame_00_delay-0.06s.png",
	EYE_INDIVIDUAL_ENABLED = true,
	
	-- Visualizer
	VISUALIZER_ENABLED = true,
	VISUALIZER_SCALE = 0.6,
	VISUALIZER_BARS = 12,
	
	-- Layer Images
	LAYER1_FILE = "Layer1vi.PNG",
	LAYER2_FILE = "Layer2vi.PNG",
	LAYER3_FILE = "Layer3vi.PNG",
	TRANSITION_FILE = "TransitionLayer.PNG",
	LAYER1_ENABLED = true,
	LAYER2_ENABLED = true,
	LAYER3_ENABLED = true,
	TRANSITION_ENABLED = true,
	TRANSITION_DURATION = 0.6,
	LAYER_SIZE = UDim2.new(0, 380, 0, 380),
	LAYER_POS = UDim2.new(0.5, -190, 0.5, -220),
	
	-- Close Death Vignette
	CLOSE_FILE = "Your-feel-close-to-death.PNG",
	CLOSE_ENABLED = true,
	CLOSE_LAST_TRANS = 0.1,
	CLOSE_FINAL_TRANS = 0.05,
	
	-- Backward Animation
	BACKWARD_ANIM_ENABLED = true,
	BACKWARD_ANIM_THRESHOLD = -0.2,
	BACKWARD_ANIM_SPEED = 1.0,
	
	-- Acceleration (regular walk only, crouch excluded)
	ACCEL_ENABLED = true,
	ACCEL_RATE = 32,
	ACCEL_MIN = 4,
	
	-- Crouch System
	CROUCH_ENABLED = true,
	CROUCH_ANIM_ID = "rbxassetid://127566268742002",
	CROUCH_WALK_ID = "rbxassetid://105035775376167",
	CROUCH_SPEED = 5,
	CROUCH_BREAK_SPEED = 7,
	CROUCH_COOLDOWN = 5,
	CROUCH_SHOW_BUTTON = true,
	CROUCH_BTN_DRAGGABLE = false,
	CROUCH_IMAGE_FILE = "Crouch.PNG",
	CROUCH_CD_FILES = {
		"Crouch-cd-1.PNG", "Crouch-cd-2.PNG", "Crouch-cd-3.PNG",
		"Crouch-cd-4.PNG", "Crouch-cd-5.PNG"
	},
	CROUCH_KEY = "C",
	
	-- Speed System (starts OFF every execute for safety)
	SPEED_ENABLED = false,
	SPEED_VALUE = 16,
	SPEED_BREAK_CROUCH = 7,
	SPEED_BREAK_ENABLED = true,
	SPEED_BREAK_LIMIT = 30,
	SPEED_BREAK_AUTO_RESUME = true,
	SPEED_BREAK_RESUME_DELAY = 0.5,
	SPEED_BREAK_HYSTERESIS = 2,
	SPEED_SHOW_BUTTON = true,
	SPEED_BTN_DRAGGABLE = false,
	SPEED_KEY = "X",
	
	-- Respawn SFX (GitHub .ogg dual)
	RESPAWN_ENABLED = true,
	RESPAWN_VOLUME = 1.0,
	RESPAWN_MODE = "random",
	RESPAWN_FILE_1 = "respawn-sound-cause-why-not.ogg",
	RESPAWN_FILE_2 = "respawn-sound-cause-why-not-2.ogg",
}

-- Asset Management
local GITHUB_BASE = "https://raw.githubusercontent.com/saifuddinabusofian-svg/forsaken-assets/main/"
local ASSET_FOLDER = "ForsakenTheme/"
local CONFIG_FILE = ASSET_FOLDER .. "chase_config.json"

local SAVE_KEYS = {
	"LAYER_DISTANCES", "LAST_CHANCE_LAYER_DISTANCES", "CHASE_DISTANCE",
	"CHASE_ONLY_BONUS", "LAST_CHANCE_DISTANCE", "HEARTBEAT_HEALTH", "FINAL_CHANCE_HP",
	"VOLUME_LAYERS", "VOLUME_CHASE", "VOLUME_HEARTBEAT", "VOLUME_IDLE",
	"VOLUME_LAST_CHANCE", "VOLUME_FINAL_CHANCE", "CROSSFADE_FACTOR", "CHASE_EXIT_DELAY",
	"CURRENT_THEME", "EYE_ENABLED", "EYE_SCALE", "EYE_POS_X", "EYE_POS_Y",
	"EYE_SHAKE_ENABLED", "EYE_SHAKE_AMOUNT", "EYE_INDIVIDUAL_ENABLED",
	"EYE_CHASE_SINGLE", "EYE_LAST_SINGLE", "EYE_FINAL_SINGLE",
	"VISUALIZER_ENABLED", "VISUALIZER_SCALE", "VISUALIZER_BARS",
	"LAYER1_FILE", "LAYER2_FILE", "LAYER3_FILE", "TRANSITION_FILE",
	"LAYER1_ENABLED", "LAYER2_ENABLED", "LAYER3_ENABLED", "TRANSITION_ENABLED",
	"TRANSITION_DURATION", "CLOSE_FILE", "CLOSE_ENABLED", "CLOSE_LAST_TRANS",
	"CLOSE_FINAL_TRANS", "BACKWARD_ANIM_ENABLED", "BACKWARD_ANIM_THRESHOLD",
	"BACKWARD_ANIM_SPEED", "ACCEL_ENABLED", "ACCEL_RATE", "ACCEL_MIN",
	"CROUCH_ENABLED", "CROUCH_ANIM_ID", "CROUCH_WALK_ID", "CROUCH_SPEED",
	"CROUCH_BREAK_SPEED", "CROUCH_COOLDOWN", "CROUCH_SHOW_BUTTON",
	"CROUCH_BTN_DRAGGABLE", "CROUCH_IMAGE_FILE", "CROUCH_KEY",
	"SPEED_VALUE", "SPEED_SHOW_BUTTON", "SPEED_BTN_DRAGGABLE", "SPEED_KEY",
	"SPEED_BREAK_ENABLED", "SPEED_BREAK_LIMIT", "SPEED_BREAK_AUTO_RESUME",
	"SPEED_BREAK_RESUME_DELAY", "SPEED_BREAK_HYSTERESIS",
	"RESPAWN_ENABLED", "RESPAWN_VOLUME", "RESPAWN_MODE",
	"RESPAWN_FILE_1", "RESPAWN_FILE_2",
	"TEAM_MODE",
}

-- State Variables
local Sounds = {
	layers = {}, lastLayers = {},
	chase = nil, idle = nil, heartbeat = nil,
	lastChance = nil, finalChance = nil
}
local IsDead = false
local IsCrouching = false
local chaseExitTimer = 0
local isChaseActive = false
local CurrentLastChanceVariant = 1
local CurrentFinalVariant = 1
local FinalCC = nil
local CloseImg = nil
local ClosePulse = 0
local LastUncrouchAt = 0
local IsSpeeding = false
local SpeedAutoBroken = false
local SpeedBreakBelowTime = 0
local WasSpeedBeforeCrouch = false
local SpeedBtn = nil
local OrigWalkSpeed = 16
local NormalWalkSpeed = 16
local AccelCur = nil

-- Animation Tracking
local CrouchIdleTrack, CrouchWalkTrack
local CrouchIdleObj, CrouchWalkObj

-- UI References
local CrouchBtn, CrouchBtnImg
local CrouchCdImgs = {}
local EyeGui, EyeHolder, EyeUnits = nil, nil, {}
local EyeSingleHolder, ChaseEyeImg, LastEyeImg, FinalEyeImg
local L1Img, L2Img, L3Img, TransImg
local VisFrame, VisBars, VisLabel = nil, {}, nil
local TransTimer = 0
local LastLayerKey = "none"
local VisTime = 0

-- Forward Declarations
local SafePcall, SaveConfig, LoadConfig, EnterSpeed, ExitSpeed, UpdateSpeed
local PlayRespawnSfx, RefreshThemeAssets

-- Utility Functions
SafePcall = function(func, ...)
	local success, result = pcall(func, ...)
	if not success then
		warn("[Chase] Error: " .. tostring(result))
	end
	return success, result
end

-- Config Functions
function SaveConfig(silent)
	SafePcall(function()
		if typeof(writefile) ~= "function" then return end
		
		local data = {}
		for _, k in ipairs(SAVE_KEYS) do
			local v = CONFIG[k]
			if typeof(v) == "number" or typeof(v) == "string" or typeof(v) == "boolean" then
				data[k] = v
			elseif typeof(v) == "table" then
				local ok, _ = pcall(function() return #v end)
				if ok then
					local arr = {}
					for i, n in ipairs(v) do
						if typeof(n) == "number" or typeof(n) == "string" or typeof(n) == "boolean" then
							arr[i] = n
						end
					end
					data[k] = arr
				end
			end
		end
		
		data.SPEED_ENABLED_SAVED = false
		local js = HttpService:JSONEncode(data)
		writefile(CONFIG_FILE, js)
		if not silent then print("[Chase] Config saved") end
	end)
end

function LoadConfig()
	SafePcall(function()
		if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then return end
		if not isfile(CONFIG_FILE) then return end
		
		local raw = readfile(CONFIG_FILE)
		if not raw or raw == "" then return end
		
		local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok or typeof(data) ~= "table" then return end
		
		for _, k in ipairs(SAVE_KEYS) do
			if data[k] ~= nil then
				if k == "LAYER_DISTANCES" or k == "LAST_CHANCE_LAYER_DISTANCES" then
					if typeof(data[k]) == "table" and #data[k] >= 3 then
						CONFIG[k] = {
							tonumber(data[k][1]) or CONFIG[k][1],
							tonumber(data[k][2]) or CONFIG[k][2],
							tonumber(data[k][3]) or CONFIG[k][3]
						}
					end
				else
					CONFIG[k] = data[k]
				end
			end
		end
		
		CONFIG.SPEED_ENABLED = false
		SafePcall(function()
			local idx = tonumber(CONFIG.CURRENT_THEME) or 1
			CONFIG.CURRENT_THEME = math.clamp(math.floor(idx), 1, 8)
		end)
		print("[Chase] Config loaded")
	end)
end

-- Load config immediately
SafePcall(LoadConfig)

-- Asset Functions
local function EncodeName(name)
	return (name:gsub("[^%w%-%_%.%~]", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

local function SafeAsset(path)
	if typeof(getcustomasset) == "function" then
		local ok, r = pcall(getcustomasset, path)
		if ok and r and r ~= "" then return r end
	end
	if typeof(getasset) == "function" then
		local ok, r = pcall(getasset, path)
		if ok and r and r ~= "" then return r end
	end
	return ""
end

local function TryAssets(names)
	for _, n in ipairs(names) do
		local a = SafeAsset(ASSET_FOLDER .. n)
		if a and a ~= "" then return a end
	end
	return ""
end

local function CandidateNames(fname)
	local f0 = tostring(fname or "")
	local out, seen = {}, {}
	local function push(s)
		if s and s ~= "" and not seen[s] then seen[s]=true table.insert(out,s) end
	end
	push(f0)
	local c1 = f0:gsub("’","'"):gsub("‘","'"):gsub("`","'")
	push(c1)
	local noApo = c1:gsub("'","")
	push(noApo)
	push((noApo:gsub("[%?%*%:%<%>%|%"%!…]","")))
	push((f0:gsub("%?","_QM_")))
	push((noApo:gsub("%?","_QM_")))
	return out
end

local function SanitizedName(fname)
	local c = CandidateNames(fname)
	if #c >= 3 then return c[3] end
	return tostring(fname or "")
end

local function SmartAsset(fname)
	for _, v in ipairs(CandidateNames(fname)) do
		local a = SafeAsset(ASSET_FOLDER .. v)
		if a and a ~= "" then return a end
	end
	return ""
end

local function SmartTryAssets(names)
	for _, n in ipairs(names) do
		local a = SmartAsset(n)
		if a and a ~= "" then return a end
	end
	return ""
end

function RefreshThemeAssets(theme)
	if not theme then return end
	if not theme.hasLastLayers then return end
	
	if not theme.lastLayer1 or theme.lastLayer1 == "" then
		theme.lastLayer1 = SmartAsset("tell-me-buddy-layer1.mp3")
	end
	if not theme.lastLayer2 or theme.lastLayer2 == "" then
		theme.lastLayer2 = SmartAsset("tell-me-buddy-layer2.mp3")
	end
	if not theme.lastLayer3 or theme.lastLayer3 == "" then
		theme.lastLayer3 = SmartAsset("tell-me-buddy-layer3.mp3")
	end
	if not theme.lastChase or theme.lastChase == "" then
		theme.lastChase = SmartTryAssets({
			"tell-me-my-friend….mp3", "tell-me-my-friend....mp3", "tell-me-my-friend-chase.mp3"
		})
	end
	if theme.hasFinalCustom and (not theme.finalCustom or theme.finalCustom == "") then
		theme.finalCustom = SmartTryAssets({
			"ONE-LAST-TIME-friend….mp3", "ONE-LAST-TIME-friend....mp3", "ONE-LAST-TIME-friend-chase.mp3"
		})
	end
	if not theme.layer1 or theme.layer1 == "" then
		theme.layer1 = SmartTryAssets({"friend?-layer1.mp3", "friend-layer1.mp3"})
	end
	if not theme.layer2 or theme.layer2 == "" then
		theme.layer2 = SmartTryAssets({"friend?-layer2.mp3", "friend-layer2.mp3"})
	end
	if not theme.layer3 or theme.layer3 == "" then
		theme.layer3 = SmartTryAssets({"friend?-layer3.mp3", "friend-layer3.mp3"})
	end
	if not theme.chase or theme.chase == "" then
		theme.chase = SmartTryAssets({"friend?-chase.mp3", "friend-chase.mp3"})
	end
	if not theme.idle or theme.idle == "" then
		theme.idle = SmartTryAssets({"friend?-layer1.mp3", "friend-layer1.mp3"})
	end
end

-- Character Functions
local function GetHumanoid()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
	local hum = GetHumanoid()
	if not hum then return nil end
	return hum.RootPart or LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- Asset Downloading
local function EnsureAssets()
	local needed = {
		"CHAOS-CAROUSEL.mp3", "IN-MY-WAY.mp3", "Still-My-Call-Fools.mp3",
		"autophobia-chase.mp3", "autophobia-layer1.mp3", "autophobia-layer2.mp3", "autophobia-layer3.mp3", "autophobia-layer4.mp3",
		"fourfold-massacre-milestone-IV-chase.mp3", "fourfold-massacre-milestone-IV-layer1.mp3",
		"fourfold-massacre-milestone-IV-layer2.mp3", "fourfold-massacre-milestone-IV-layer3.mp3",
		"resentment-chase.mp3", "resentment-layer1.mp3", "resentment-layer2.mp3", "resentment-layer3.mp3",
		"paper-cut-chase.mp3", "paper-cut-layer1.mp3", "paper-cut-layer2.mp3", "paper-cut-layer3.mp3",
		"B-to-fail?-layer1.mp3", "C-to-fail?-layer2.mp3", "D-to-fail?-layer3.mp3",
		"fleeting-failure-chase.mp3", "Caine?-layer1.mp3", "lets-get-this-show-on-the-road-layer2.mp3",
		"what-a-goddamn-shame?-layer3.mp3", "aint-got-a-mouth-chase.mp3",
		"YOUR-FUTILITY.mp3", "last deathrun.mp3", "your-last-DEATHRUN.mp3",
		"Idle.mp3", "Heartbeat.mp3", "idle.mp3", "heartbeat.mp3",
		"Layer1vi.PNG", "Layer2vi.PNG", "Layer3vi.PNG", "TransitionLayer.PNG",
		"Your-feel-close-to-death.PNG",
		CONFIG.EYE_CHASE_SINGLE, CONFIG.EYE_LAST_SINGLE, CONFIG.EYE_FINAL_SINGLE,
		"friend?-layer1.mp3", "friend?-layer2.mp3", "friend?-layer3.mp3", "friend?-chase.mp3",
		"tell-me-buddy-layer1.mp3", "tell-me-buddy-layer2.mp3", "tell-me-buddy-layer3.mp3",
		"tell-me-my-friend….mp3", "ONE-LAST-TIME-friend….mp3",
		"tell-me-my-friend-chase.mp3", "ONE-LAST-TIME-friend-chase.mp3",
		CONFIG.CROUCH_IMAGE_FILE,
		"respawn-sound-cause-why-not.ogg", "respawn-sound-cause-why-not-2.ogg"
	}
	
	for _, f in ipairs(CONFIG.CROUCH_CD_FILES) do
		table.insert(needed, f)
	end
	
	-- Remove duplicates
	local seen, uniq = {}, {}
	for _, v in ipairs(needed) do
		if not seen[v] then
			seen[v] = true
			table.insert(uniq, v)
		end
	end
	
	-- Create folder
	SafePcall(function()
		if typeof(makefolder) == "function" and not isfolder(ASSET_FOLDER) then
			makefolder(ASSET_FOLDER)
		end
	end)
	
	if typeof(isfile) ~= "function" then return end
	
	-- Download missing assets
	for _, fname in ipairs(uniq) do
		local lp = ASSET_FOLDER .. fname
		local miss = true
		SafePcall(function() miss = not isfile(lp) end)
		
		if miss then
			local url = GITHUB_BASE .. EncodeName(fname)
			local ok, data = pcall(function()
				return request({Url = url, Method = "GET"}).Body
			end)
			if not ok or not data or #data < 500 then
				ok, data = pcall(function() return game:HttpGet(url) end)
			end
			if ok and data and #data > 500 then
				SafePcall(function() writefile(lp, data) end)
				SafePcall(function()
					local sn = tostring(fname):gsub("%?", "_QM_")
					if sn ~= fname then
						writefile(ASSET_FOLDER .. sn, data)
					end
				end)
			end
		end
	end
end

SafePcall(EnsureAssets)

-- Theme Definitions
local FINAL_CHASE_1 = SafeAsset(ASSET_FOLDER .. "YOUR-FUTILITY.mp3")
local FINAL_CHASE_2 = SafeAsset(ASSET_FOLDER .. "your-last-DEATHRUN.mp3")

local THEMES = {
	{
		name = "Autophobia",
		hasLayers = true, hasLastChance = true,
		lastChase = SafeAsset(ASSET_FOLDER .. "autophobia-layer4.mp3"),
		layer1 = SafeAsset(ASSET_FOLDER .. "autophobia-layer1.mp3"),
		layer2 = SafeAsset(ASSET_FOLDER .. "autophobia-layer2.mp3"),
		layer3 = SafeAsset(ASSET_FOLDER .. "autophobia-layer3.mp3"),
		chase = SafeAsset(ASSET_FOLDER .. "autophobia-chase.mp3"),
		idle = SafeAsset(ASSET_FOLDER .. "autophobia-layer1.mp3")
	},
	{
		name = "Resentment",
		hasLayers = true, hasLastChance = true,
		lastChase = SafeAsset(ASSET_FOLDER .. "resentment-chase.mp3"),
		layer1 = SafeAsset(ASSET_FOLDER .. "resentment-layer1.mp3"),
		layer2 = SafeAsset(ASSET_FOLDER .. "resentment-layer2.mp3"),
		layer3 = SafeAsset(ASSET_FOLDER .. "resentment-layer3.mp3"),
		chase = SafeAsset(ASSET_FOLDER .. "resentment-chase.mp3"),
		idle = SafeAsset(ASSET_FOLDER .. "resentment-layer1.mp3")
	},
	{
		name = "Fourfold Massacre IV",
		hasLayers = true, hasLastChance = true,
		lastChase = SafeAsset(ASSET_FOLDER .. "fourfold-massacre-milestone-IV-chase.mp3"),
		layer1 = SafeAsset(ASSET_FOLDER .. "fourfold-massacre-milestone-IV-layer1.mp3"),
		layer2 = SafeAsset(ASSET_FOLDER .. "fourfold-massacre-milestone-IV-layer2.mp3"),
		layer3 = SafeAsset(ASSET_FOLDER .. "fourfold-massacre-milestone-IV-layer3.mp3"),
		chase = SafeAsset(ASSET_FOLDER .. "fourfold-massacre-milestone-IV-chase.mp3"),
		idle = SafeAsset(ASSET_FOLDER .. "fourfold-massacre-milestone-IV-layer1.mp3")
	},
	{
		name = "CHAOS CAROUSEL",
		hasLayers = false, hasLastChance = true, lastChaseRandom = true,
		lastChase1 = SafeAsset(ASSET_FOLDER .. "IN-MY-WAY.mp3"),
		lastChase2 = SafeAsset(ASSET_FOLDER .. "Still-My-Call-Fools.mp3"),
		chase = SafeAsset(ASSET_FOLDER .. "CHAOS-CAROUSEL.mp3"),
		idle = ""
	},
	{
		name = "Paper Cut",
		hasLayers = true, hasLastChance = true,
		lastChase = SafeAsset(ASSET_FOLDER .. "last deathrun.mp3"),
		layer1 = SafeAsset(ASSET_FOLDER .. "paper-cut-layer1.mp3"),
		layer2 = SafeAsset(ASSET_FOLDER .. "paper-cut-layer2.mp3"),
		layer3 = SafeAsset(ASSET_FOLDER .. "paper-cut-layer3.mp3"),
		chase = SafeAsset(ASSET_FOLDER .. "paper-cut-chase.mp3"),
		idle = SafeAsset(ASSET_FOLDER .. "paper-cut-layer1.mp3")
	},
	{
		name = "Fleeting Failure",
		parentName = "Paper Cut", isSubTheme = true,
		hasLayers = true, hasLastChance = true, lastChaseRandom = true,
		lastChase1 = SafeAsset(ASSET_FOLDER .. "last deathrun.mp3"),
		lastChase2 = SafeAsset(ASSET_FOLDER .. "your-last-DEATHRUN.mp3"),
		layer1 = SmartAsset("B-to-fail?-layer1.mp3"),
		layer2 = SmartAsset("C-to-fail?-layer2.mp3"),
		layer3 = SmartAsset("D-to-fail?-layer3.mp3"),
		chase = SafeAsset(ASSET_FOLDER .. "fleeting-failure-chase.mp3"),
		idle = SmartAsset("B-to-fail?-layer1.mp3")
	},
	{
		name = "ain't got a mouth",
		hasLayers = true, hasLastChance = false,
		layer1 = SmartTryAssets({"Caine?-layer1.mp3", "Caine_QM_-layer1.mp3", "Caine-layer1.mp3"}),
		layer2 = SmartTryAssets({"lets-get-this-show-on-the-road-layer2.mp3", "let's-get-this-show-on-the-road-layer2.mp3", "lets-get-this-show-on-the-road-layer2_QM_.mp3"}),
		layer3 = SmartAsset("what-a-goddamn-shame?-layer3.mp3"),
		chase = SmartTryAssets({"aint-got-a-mouth-chase.mp3", "ain't-got-a-mouth?-chase.mp3", "aint-got-a-mouth_QM_-chase.mp3"}),
		idle = SmartTryAssets({"Caine?-layer1.mp3", "Caine_QM_-layer1.mp3", "Caine-layer1.mp3"})
	},
	{
		name = "Geometry",
		hasLayers = true, hasLastChance = true, hasLastLayers = true, hasFinalCustom = true,
		layer1 = SmartTryAssets({"friend?-layer1.mp3", "friend-layer1.mp3"}),
		layer2 = SmartTryAssets({"friend?-layer2.mp3", "friend-layer2.mp3"}),
		layer3 = SmartTryAssets({"friend?-layer3.mp3", "friend-layer3.mp3"}),
		chase = SmartTryAssets({"friend?-chase.mp3", "friend-chase.mp3"}),
		idle = SmartTryAssets({"friend?-layer1.mp3", "friend-layer1.mp3"}),
		lastLayer1 = SmartAsset("tell-me-buddy-layer1.mp3"),
		lastLayer2 = SmartAsset("tell-me-buddy-layer2.mp3"),
		lastLayer3 = SmartAsset("tell-me-buddy-layer3.mp3"),
		lastChase = SmartTryAssets({"tell-me-my-friend….mp3", "tell-me-my-friend....mp3", "tell-me-my-friend-chase.mp3"}),
		finalCustom = SmartTryAssets({"ONE-LAST-TIME-friend….mp3", "ONE-LAST-TIME-friend....mp3", "ONE-LAST-TIME-friend-chase.mp3"})
	}
}

-- Movement Systems
local function IsMovingBackward()
	local hum = GetHumanoid()
	local hrp = GetRootPart()
	if not hum or not hrp then return false end
	if hum.MoveDirection.Magnitude < 0.1 then return false end
	
	local st = hum:GetState()
	if st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.FallingDown then
		return false
	end
	
	local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	if look.Magnitude < 0.01 then return false end
	look = look.Unit
	
	local mv = Vector3.new(hum.MoveDirection.X, 0, hum.MoveDirection.Z)
	if mv.Magnitude < 0.1 then return false end
	mv = mv.Unit
	
	return mv:Dot(look) < (CONFIG.BACKWARD_ANIM_THRESHOLD or -0.2)
end

local function UpdateBackwardAnim()
	local hum = GetHumanoid()
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then return end
	
	local backward = IsMovingBackward()
	local mult = CONFIG.BACKWARD_ANIM_SPEED or 1
	
	SafePcall(function()
		for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
			local n = string.lower(tr.Name or "")
			local isJumpFall = string.find(n, "jump", 1, true) or string.find(n, "fall", 1, true)
			local sp = tr.Speed
			
			if isJumpFall then
				if sp < -0.01 then tr:AdjustSpeed(math.abs(sp)) end
			else
				if not CONFIG.BACKWARD_ANIM_ENABLED then
					if sp < -0.01 then tr:AdjustSpeed(math.abs(sp)) end
				else
					if backward then
						if sp > 0.01 then tr:AdjustSpeed(-math.abs(sp) * mult) end
					else
						if sp < -0.01 then tr:AdjustSpeed(math.abs(sp)) end
					end
				end
			end
		end
	end)
end

local function UpdateAccel(dt)
	if not CONFIG.ACCEL_ENABLED then
		AccelCur = nil
		return
	end
	if IsCrouching or IsSpeeding then
		AccelCur = nil
		return
	end
	
	local hum = GetHumanoid()
	if not hum or hum.Health <= 0 then
		AccelCur = nil
		return
	end
	if hum.MoveDirection.Magnitude < 0.1 then
		AccelCur = nil
		return
	end
	
	local rate = CONFIG.ACCEL_RATE or 32
	local minSp = CONFIG.ACCEL_MIN or 4
	
	if AccelCur == nil then
		local cur = hum.WalkSpeed
		if cur and cur > 1 and cur < 100 then
			NormalWalkSpeed = cur
		end
		AccelCur = math.min(minSp, NormalWalkSpeed)
		SafePcall(function() hum.WalkSpeed = AccelCur end)
	else
		local cur = hum.WalkSpeed
		if cur and math.abs(cur - AccelCur) > 2 and math.abs(cur - NormalWalkSpeed) < 30 then
			if math.abs(cur - AccelCur) > (rate * dt + 1) then
				NormalWalkSpeed = cur
			end
		end
		
		if AccelCur < NormalWalkSpeed then
			AccelCur = math.min(NormalWalkSpeed, AccelCur + rate * dt)
			SafePcall(function() hum.WalkSpeed = AccelCur end)
		else
			if math.abs((cur or 0) - NormalWalkSpeed) > 0.5 then
				SafePcall(function() hum.WalkSpeed = NormalWalkSpeed end)
			end
			AccelCur = NormalWalkSpeed
		end
	end
end

-- Crouch System
local function CooldownLeft()
	local elapsed = os.clock() - LastUncrouchAt
	return math.max(0, (CONFIG.CROUCH_COOLDOWN or 5) - elapsed)
end

local function NormalizeId(s)
	s = tostring(s or "")
	if s == "" then return "" end
	if tonumber(s) then return "rbxassetid://" .. s end
	return s
end

local function StopCrouchTracks()
	SafePcall(function() if CrouchIdleTrack then CrouchIdleTrack:Stop(0.15) end end)
	SafePcall(function() if CrouchWalkTrack then CrouchWalkTrack:Stop(0.15) end end)
	SafePcall(function() if CrouchIdleObj then CrouchIdleObj:Destroy() end end)
	SafePcall(function() if CrouchWalkObj then CrouchWalkObj:Destroy() end end)
	CrouchIdleTrack, CrouchWalkTrack = nil, nil
	CrouchIdleObj, CrouchWalkObj = nil, nil
	
	SafePcall(function()
		local hum = GetHumanoid()
		if hum then
			local an = hum:FindFirstChildOfClass("Animator")
			if an then
				for _, tr in ipairs(an:GetPlayingAnimationTracks()) do
					if tr.Name == "CrouchIdle" or tr.Name == "CrouchWalk" then
						tr:Stop(0.15)
					end
				end
			end
		end
	end)
end

local function ExitCrouch(forced, keepSpeed)
	if not IsCrouching then return end
	IsCrouching = false
	StopCrouchTracks()
	
	SafePcall(function()
		local hum = GetHumanoid()
		if hum then
			hum.WalkSpeed = OrigWalkSpeed
			NormalWalkSpeed = OrigWalkSpeed
			AccelCur = nil
		end
	end)
	
	local _returnToSpeed = WasSpeedBeforeCrouch and CONFIG.SPEED_ENABLED
	WasSpeedBeforeCrouch = false
	LastUncrouchAt = os.clock()
	
	if _returnToSpeed then
		SafePcall(function()
			local hum2 = GetHumanoid()
			local target = CONFIG.SPEED_VALUE or 28
			if hum2 then
				hum2.WalkSpeed = target
				NormalWalkSpeed = target
				OrigWalkSpeed = target
				IsSpeeding = true
				AccelCur = nil
				if SpeedBtn then
					SpeedBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 200)
					SpeedBtn.Text = "SPEED: ON"
				end
			end
		end)
	end
	
	SafePcall(function()
		if CrouchBtn then
			CrouchBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			CrouchBtn.Text = "CROUCH"
		end
	end)
end

local function EnterCrouch()
	if IsCrouching then
		ExitCrouch(false)
		return
	end
	if not CONFIG.CROUCH_ENABLED then return end
	
	WasSpeedBeforeCrouch = IsSpeeding
	if IsSpeeding then ExitSpeed() end
	if CooldownLeft() > 0.05 then return end
	
	local hum = GetHumanoid()
	if not hum or hum.Health <= 0 then return end
	
	OrigWalkSpeed = hum.WalkSpeed
	NormalWalkSpeed = hum.WalkSpeed
	if OrigWalkSpeed > (CONFIG.CROUCH_BREAK_SPEED or 7) + 5 or OrigWalkSpeed < 1 then
		OrigWalkSpeed = 16
		NormalWalkSpeed = 16
	end
	
	IsCrouching = true
	SafePcall(function() hum.WalkSpeed = CONFIG.CROUCH_SPEED or 5 end)
	
	SafePcall(function()
		local an = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 2)
		local idleId = NormalizeId(CONFIG.CROUCH_ANIM_ID)
		local walkId = NormalizeId(CONFIG.CROUCH_WALK_ID)
		
		if idleId ~= "" then
			local a1 = Instance.new("Animation")
			a1.AnimationId = idleId
			local t1 = an:LoadAnimation(a1)
			t1.Name = "CrouchIdle"
			t1.Priority = Enum.AnimationPriority.Action
			t1.Looped = true
			CrouchIdleObj, CrouchIdleTrack = a1, t1
			t1:Play(0.15)
		end
		
		if walkId ~= "" then
			local a2 = Instance.new("Animation")
			a2.AnimationId = walkId
			local t2 = an:LoadAnimation(a2)
			t2.Name = "CrouchWalk"
			t2.Priority = Enum.AnimationPriority.Movement
			t2.Looped = true
			CrouchWalkObj, CrouchWalkTrack = a2, t2
			t2:Play(0.15)
		end
	end)
	
	SafePcall(function()
		if CrouchBtn then
			CrouchBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
			CrouchBtn.Text = "UNCROUCH"
		end
	end)
end

local function UpdateCrouch(dt)
	local hum = GetHumanoid()
	if not hum then
		if IsCrouching then
			IsCrouching = false
			StopCrouchTracks()
		end
		return
	end
	
	if not CONFIG.CROUCH_ENABLED and IsCrouching then
		ExitCrouch(true)
		return
	end
	
	if IsSpeeding and IsCrouching then
		ExitCrouch(true)
		return
	end
	
	if IsCrouching then
		local brk = CONFIG.CROUCH_BREAK_SPEED or 7
		local vel = 0
		SafePcall(function()
			vel = hum.RootPart and hum.RootPart.AssemblyLinearVelocity.Magnitude or 0
		end)
		
		if hum.WalkSpeed > brk + 0.5 or vel > brk + 1.5 then
			ExitCrouch(true)
			return
		end
		
		if math.abs(hum.WalkSpeed - (CONFIG.CROUCH_SPEED or 5)) > 0.1 then
			SafePcall(function() hum.WalkSpeed = CONFIG.CROUCH_SPEED or 5 end)
		end
		
		SafePcall(function()
			local moving = hum.MoveDirection.Magnitude > 0.1
			if CrouchIdleTrack then
				if moving then
					CrouchIdleTrack:AdjustWeight(0.05)
				else
					CrouchIdleTrack:AdjustWeight(1)
					if math.abs(CrouchIdleTrack.Speed - 1) > 0.1 then
						CrouchIdleTrack:AdjustSpeed(1)
					end
				end
			end
			
			if CrouchWalkTrack then
				if moving then
					CrouchWalkTrack:AdjustWeight(1)
					local backward = IsMovingBackward()
					local mult = CONFIG.BACKWARD_ANIM_SPEED or 1
					local cur = CrouchWalkTrack.Speed
					if backward then
						if cur > 0 then CrouchWalkTrack:AdjustSpeed(-math.abs(cur) * mult) end
					else
						if cur < 0 then CrouchWalkTrack:AdjustSpeed(math.abs(cur)) end
					end
				else
					CrouchWalkTrack:AdjustWeight(0.05)
				end
			end
		end)
	end
end

-- Speed System
function ExitSpeed(silent, isAutoBreak)
	if not IsSpeeding then
		if not isAutoBreak then
			SpeedAutoBroken = false
			SpeedBreakBelowTime = 0
		end
		return
	end
	
	IsSpeeding = false
	if not isAutoBreak then
		SpeedAutoBroken = false
		SpeedBreakBelowTime = 0
	end
	AccelCur = nil
	
	SafePcall(function()
		local hum = GetHumanoid()
		if hum then
			local back = OrigWalkSpeed
			if not back or back < 1 or back > 60 then back = 16 end
			hum.WalkSpeed = back
			NormalWalkSpeed = back
		end
	end)
	
	SafePcall(function()
		if SpeedBtn then
			SpeedBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			SpeedBtn.Text = "SPEED: OFF"
		end
	end)
end

function EnterSpeed()
	if IsSpeeding then
		ExitSpeed()
		return
	end
	
	if SpeedAutoBroken then
		SpeedAutoBroken = false
		SpeedBreakBelowTime = 0
	end
	if not CONFIG.SPEED_ENABLED then return end
	
	local hum = GetHumanoid()
	if not hum or hum.Health <= 0 then return end
	
	if IsCrouching then ExitCrouch(true) end
	
	local cur = hum.WalkSpeed
	if cur and cur >= 1 and cur <= 60 and cur < (CONFIG.SPEED_VALUE or 28) then
		OrigWalkSpeed = cur
	elseif not OrigWalkSpeed or OrigWalkSpeed < 1 or OrigWalkSpeed > 60 then
		OrigWalkSpeed = 16
	end
	
	local target = CONFIG.SPEED_VALUE or 28
	NormalWalkSpeed = target
	AccelCur = nil
	IsSpeeding = true
	
	SafePcall(function() hum.WalkSpeed = target end)
	SafePcall(function()
		if SpeedBtn then
			SpeedBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 200)
			SpeedBtn.Text = "SPEED: ON"
		end
	end)
end

function UpdateSpeed(dt)
	local hum = GetHumanoid()
	
	if SpeedAutoBroken then
		if not CONFIG.SPEED_BREAK_ENABLED then
			SpeedAutoBroken = false
			SpeedBreakBelowTime = 0
			return
		end
		if not CONFIG.SPEED_BREAK_AUTO_RESUME then return end
		if not CONFIG.SPEED_ENABLED then
			SpeedAutoBroken = false
			SpeedBreakBelowTime = 0
			return
		end
		if IsCrouching then
			SpeedBreakBelowTime = 0
			return
		end
		if not hum or hum.Health <= 0 then
			SpeedBreakBelowTime = 0
			return
		end
		
		local limit = CONFIG.SPEED_BREAK_LIMIT or 30
		local hyst = CONFIG.SPEED_BREAK_HYSTERESIS or 2
		local resumeUnder = limit - hyst
		local vel = 0
		
		SafePcall(function()
			vel = hum.RootPart and hum.RootPart.AssemblyLinearVelocity.Magnitude or 0
		end)
		
		local cur = hum.WalkSpeed or 0
		if cur <= resumeUnder and vel <= resumeUnder + 1.5 then
			SpeedBreakBelowTime = SpeedBreakBelowTime + (dt or 0.016)
			if SpeedBreakBelowTime >= (CONFIG.SPEED_BREAK_RESUME_DELAY or 0.5) then
				SpeedAutoBroken = false
				SpeedBreakBelowTime = 0
				SafePcall(function() EnterSpeed() end)
				if not IsSpeeding and CONFIG.SPEED_ENABLED then
					SpeedAutoBroken = true
					SpeedBreakBelowTime = 0
				end
			end
		else
			SpeedBreakBelowTime = 0
		end
		return
	end
	
	if not IsSpeeding then return end
	if not CONFIG.SPEED_ENABLED then
		ExitSpeed()
		return
	end
	if not hum or hum.Health <= 0 then
		IsSpeeding = false
		AccelCur = nil
		return
	end
	if IsCrouching then
		ExitSpeed()
		return
	end
	
	local target = CONFIG.SPEED_VALUE or 28
	NormalWalkSpeed = target
	
	if CONFIG.SPEED_BREAK_ENABLED then
		local limit = CONFIG.SPEED_BREAK_LIMIT or 30
		local vel = 0
		SafePcall(function()
			vel = hum.RootPart and hum.RootPart.AssemblyLinearVelocity.Magnitude or 0
		end)
		
		local cur = hum.WalkSpeed or target
		local pushedOver = (cur > limit + 0.5 and (cur - target) > 1.5)
		local velOver = (vel > limit + 1.5)
		
		if pushedOver or velOver then
			SafePcall(function() ExitSpeed() end)
			SpeedAutoBroken = true
			SpeedBreakBelowTime = 0
			warn("[Chase] SPEED BREAK: spike over LIMIT " .. tostring(limit))
			return
		end
	end
	
	if math.abs(hum.WalkSpeed - target) > 0.5 then
		SafePcall(function() hum.WalkSpeed = target end)
	end
end

_G.ChaseSpeedIsAutoBroken = function() return SpeedAutoBroken end

-- Button Setup
local function RefreshSpeedBtn()
	if not SpeedBtn then return end
	SafePcall(function()
		if IsSpeeding then
			SpeedBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 200)
			SpeedBtn.Text = "SPEED: ON"
		else
			SpeedBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			SpeedBtn.Text = "SPEED: OFF"
		end
		SpeedBtn.Visible = CONFIG.SPEED_SHOW_BUTTON
	end)
end

local function SetupSpeedButton()
	SafePcall(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
		if pg:FindFirstChild("SpeedBtnGui") then
			pg.SpeedBtnGui:Destroy()
		end
		
		local scr = Instance.new("ScreenGui")
		scr.Name = "SpeedBtnGui"
		scr.ResetOnSpawn = false
		scr.DisplayOrder = 1002
		scr.IgnoreGuiInset = true
		scr.Parent = pg
		
		local btn = Instance.new("TextButton")
		btn.Name = "Btn"
		btn.Size = UDim2.new(0, 72, 0, 40)
		btn.Position = UDim2.new(1, -82, 1, -210)
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		btn.BackgroundTransparency = 0.15
		btn.Text = "SPEED: OFF"
		btn.TextSize = 11
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Active = true
		btn.Visible = CONFIG.SPEED_SHOW_BUTTON
		btn.Parent = scr
		
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 10)
		bc.Parent = btn
		
		SpeedBtn = btn
		
		local dragging, dragStart, startPos
		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if CONFIG.SPEED_BTN_DRAGGABLE then
					dragging = true
					dragStart = input.Position
					startPos = btn.Position
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
						end
					end)
				end
			end
		end)
		
		UserInputService.InputChanged:Connect(function(input)
			if dragging and CONFIG.SPEED_BTN_DRAGGABLE and
			   (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
										 startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
		
		btn.Activated:Connect(function()
			if CONFIG.SPEED_BTN_DRAGGABLE then return end
			EnterSpeed()
		end)
		
		RefreshSpeedBtn()
	end)
end

local function RefreshCrouchBtn()
	if not CrouchBtn then return end
	SafePcall(function()
		local cd = CooldownLeft()
		if IsCrouching then
			CrouchBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
			if CrouchBtnImg and CrouchBtnImg.Visible and CrouchBtnImg.Image ~= "" then
				CrouchBtn.Text = ""
			else
				CrouchBtn.Text = "UNCROUCH"
			end
			for _, im in ipairs(CrouchCdImgs) do im.Visible = false end
			if CrouchBtnImg then CrouchBtnImg.Visible = CrouchBtnImg.Image ~= "" end
		else
			if cd > 0.05 then
				local total = CONFIG.CROUCH_COOLDOWN or 5
				local frac = cd / total
				local idx = math.clamp(math.ceil(frac * 5), 1, 5)
				for i, im in ipairs(CrouchCdImgs) do
					im.Visible = (i == idx)
				end
				if CrouchBtnImg then CrouchBtnImg.Visible = false end
				CrouchBtn.Text = ""
				CrouchBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
			else
				for _, im in ipairs(CrouchCdImgs) do im.Visible = false end
				if CrouchBtnImg and CrouchBtnImg.Image ~= "" then
					CrouchBtnImg.Visible = true
					CrouchBtn.Text = ""
				else
					if CrouchBtnImg then CrouchBtnImg.Visible = false end
					CrouchBtn.Text = "CROUCH"
				end
				CrouchBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			end
		end
		CrouchBtn.Visible = CONFIG.CROUCH_SHOW_BUTTON and CONFIG.CROUCH_ENABLED
	end)
end

local function SetupCrouchButton()
	SafePcall(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
		if pg:FindFirstChild("CrouchBtnGui") then
			pg.CrouchBtnGui:Destroy()
		end
		
		CrouchCdImgs = {}
		local scr = Instance.new("ScreenGui")
		scr.Name = "CrouchBtnGui"
		scr.ResetOnSpawn = false
		scr.DisplayOrder = 1002
		scr.IgnoreGuiInset = true
		scr.Parent = pg
		
		local btn = Instance.new("TextButton")
		btn.Name = "Btn"
		btn.Size = UDim2.new(0, 72, 0, 72)
		btn.Position = UDim2.new(1, -82, 1, -160)
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		btn.BackgroundTransparency = 0.15
		btn.Text = "CROUCH"
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Active = true
		btn.Visible = CONFIG.CROUCH_SHOW_BUTTON
		btn.Parent = scr
		
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 14)
		bc.Parent = btn
		
		local img = Instance.new("ImageLabel")
		img.Name = "Icon"
		img.BackgroundTransparency = 1
		img.Size = UDim2.new(1, -10, 1, -10)
		img.Position = UDim2.new(0, 5, 0, 5)
		img.ScaleType = Enum.ScaleType.Fit
		img.Visible = false
		img.Image = ""
		img.Parent = btn
		
		SafePcall(function()
			local a = SafeAsset(ASSET_FOLDER .. CONFIG.CROUCH_IMAGE_FILE)
			if a and a ~= "" then
				img.Image = a
				img.Visible = true
				btn.Text = ""
			end
		end)
		
		for i, fname in ipairs(CONFIG.CROUCH_CD_FILES) do
			local cim = Instance.new("ImageLabel")
			cim.Name = "CD" .. i
			cim.BackgroundTransparency = 1
			cim.Size = UDim2.new(1, -10, 1, -10)
			cim.Position = UDim2.new(0, 5, 0, 5)
			cim.ScaleType = Enum.ScaleType.Fit
			cim.Visible = false
			cim.Image = ""
			cim.Parent = btn
			
			SafePcall(function()
				local a = SafeAsset(ASSET_FOLDER .. fname)
				if a and a ~= "" then cim.Image = a end
			end)
			
			table.insert(CrouchCdImgs, cim)
		end
		
		CrouchBtn, CrouchBtnImg = btn, img
		
		local dragging, dragStart, startPos
		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if CONFIG.CROUCH_BTN_DRAGGABLE then
					dragging = true
					dragStart = input.Position
					startPos = btn.Position
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
						end
					end)
				end
			end
		end)
		
		UserInputService.InputChanged:Connect(function(input)
			if dragging and CONFIG.CROUCH_BTN_DRAGGABLE and
			   (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
										 startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
		
		btn.Activated:Connect(function()
			if CONFIG.CROUCH_BTN_DRAGGABLE then return end
			EnterCrouch()
		end)
		
		RefreshCrouchBtn()
	end)
end

-- Keybindings
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	
	SafePcall(function()
		local swant = tostring(CONFIG.SPEED_KEY or "X"):upper()
		if input.KeyCode == Enum.KeyCode[swant] then
			EnterSpeed()
		end
	end)
	
	local want = tostring(CONFIG.CROUCH_KEY or "C"):upper()
	SafePcall(function()
		if input.KeyCode == Enum.KeyCode[want] then
			EnterCrouch()
		end
	end)
end)

-- Chase System Functions
local function GetChaseDist(theme)
	if not theme then return CONFIG.CHASE_DISTANCE end
	if not theme.hasLayers then
		return CONFIG.CHASE_DISTANCE + (CONFIG.CHASE_ONLY_BONUS or 10)
	end
	return CONFIG.CHASE_DISTANCE
end

local function SetupFinalOverlay()
	SafePcall(function()
		if Lighting:FindFirstChild("FinalChanceCC") then
			Lighting.FinalChanceCC:Destroy()
		end
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "FinalChanceCC"
		cc.Enabled = false
		cc.Saturation = -0.75
		cc.Contrast = 0.15
		cc.Brightness = -0.08
		cc.Parent = Lighting
		FinalCC = cc
	end)
end

local function SetFinalFX(on)
	SafePcall(function()
		if FinalCC then FinalCC.Enabled = on end
	end)
end

local function IsTeamSelected(tn)
	if CONFIG.TEAM_MODE == "any" then return true end
	if next(CONFIG.TARGET_TEAMS) == nil then return true end
	if not tn then return false end
	return CONFIG.TARGET_TEAMS[tn] == true
end

local function GetClosestTarget()
	local char = LocalPlayer.Character
	if not char then return nil, math.huge end
	
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil, math.huge end
	
	local myPos = hrp.Position
	local best, bestDist = nil, math.huge
	
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local tname = plr.Team and plr.Team.Name or nil
			if IsTeamSelected(tname) then
				local c = plr.Character
				if c and c:FindFirstChild("HumanoidRootPart") then
					local d = (myPos - c.HumanoidRootPart.Position).Magnitude
					if d < bestDist then
						best, bestDist = plr, d
					end
				end
			end
		end
	end
	
	return best, bestDist
end

-- Visual Effects Setup
local function SetupCloseVignette()
	SafePcall(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
		if pg:FindFirstChild("CloseDeathFX") then
			pg.CloseDeathFX:Destroy()
		end
		
		local s = Instance.new("ScreenGui")
		s.Name = "CloseDeathFX"
		s.ResetOnSpawn = false
		s.DisplayOrder = 990
		s.IgnoreGuiInset = true
		s.Parent = pg
		
		local im = Instance.new("ImageLabel")
		im.Name = "Vignette"
		im.Size = UDim2.new(1, 0, 1, 0)
		im.BackgroundTransparency = 1
		im.Visible = false
		im.ScaleType = Enum.ScaleType.Stretch
		im.Image = ""
		im.Parent = s
		
		local a = SafeAsset(ASSET_FOLDER .. CONFIG.CLOSE_FILE)
		if a and a ~= "" then im.Image = a end
		CloseImg = im
	end)
end

local function UpdateCloseVignette(dt, state)
	if not CloseImg then return end
	
	local isLF = (state == "lastchance" or state == "final" or state == "lastlayer")
	local show = CONFIG.CLOSE_ENABLED and CONFIG.IS_ACTIVE and not IsDead and isLF and CloseImg.Image ~= ""
	
	SafePcall(function() CloseImg.Visible = show end)
	if not show then
		ClosePulse = 0
		return
	end
	
	local t = CONFIG.CLOSE_LAST_TRANS
	if state == "final" then t = CONFIG.CLOSE_FINAL_TRANS end
	
	ClosePulse += dt * 5
	SafePcall(function()
		CloseImg.ImageTransparency = math.clamp(t + math.sin(ClosePulse) * 0.05, 0, 1)
	end)
end

-- Eye System
local function EyeSingleRect()
	local s = CONFIG.EYE_SCALE or 0.45
	local w, h = math.floor(440 * s), math.floor(260 * s)
	local px, py = CONFIG.EYE_POS_X or 0.5, CONFIG.EYE_POS_Y or 0.06
	local vp = Vector2.new(1000, 700)
	SafePcall(function() vp = workspace.CurrentCamera.ViewportSize end)
	local x = math.floor(vp.X * px - w / 2)
	local y = math.floor(vp.Y * py)
	return w, h, x, y
end
local function ApplyEyeTransform()
	SafePcall(function()
		if EyeHolder then
			local s = CONFIG.EYE_SCALE or 0.45
			EyeHolder.Size = UDim2.new(0, 320 * s, 0, 70 * s)
			EyeHolder.Position = UDim2.new(CONFIG.EYE_POS_X, -160 * s, CONFIG.EYE_POS_Y, 0)
			for _, r in ipairs(EyeUnits) do
				r.Size = UDim2.new(0, 82 * s, 0, 50 * s)
			end
		end
		if EyeSingleHolder then
			local w, h, x, y = EyeSingleRect()
			for _, im in ipairs({ChaseEyeImg, LastEyeImg, FinalEyeImg}) do
				if im then
					im.Size = UDim2.new(0, w, 0, h)
					im.Position = UDim2.new(0, x, 0, y)
				end
			end
		end
	end)
end

local function SetupEyes()
	SafePcall(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
		if pg:FindFirstChild("ChaseEyes") then
			pg.ChaseEyes:Destroy()
		end
		
		EyeUnits = {}
		local s = Instance.new("ScreenGui")
		s.Name = "ChaseEyes"
		s.ResetOnSpawn = false
		s.DisplayOrder = 996
		s.IgnoreGuiInset = true
		s.Parent = pg
		
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Active = true
		holder.Parent = s
		
		local l = Instance.new("UIListLayout")
		l.FillDirection = Enum.FillDirection.Horizontal
		l.HorizontalAlignment = Enum.HorizontalAlignment.Center
		l.VerticalAlignment = Enum.VerticalAlignment.Center
		l.Padding = UDim.new(0, 18)
		l.Parent = holder
		
		for i = 1, 3 do
			local root = Instance.new("Frame")
			root.Name = "Eye" .. i
			root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			root.BackgroundTransparency = 0.25
			root.BorderSizePixel = 0
			root.Visible = false
			root.Parent = holder
			
			local rc = Instance.new("UICorner")
			rc.CornerRadius = UDim.new(0.5, 0)
			rc.Parent = root
			
			table.insert(EyeUnits, root)
		end
		
		EyeGui, EyeHolder = s, holder
		ApplyEyeTransform()
	end)
end

local function UpdateEyes(state, layerNum, singleOn)
	if not EyeGui then return end
	if not CONFIG.EYE_ENABLED then
		SafePcall(function() EyeGui.Enabled = false end)
		return
	end
	
	SafePcall(function() EyeGui.Enabled = true end)
	
	if singleOn then
		for _, r in ipairs(EyeUnits) do
			SafePcall(function() r.Visible = false end)
		end
		return
	end
	
	local sc = 0
	if state == "layer" or state == "lastlayer" then
		sc = math.clamp(layerNum or 0, 1, 3)
	end
	if not CONFIG.IS_ACTIVE or IsDead then sc = 0 end
	
	for i, r in ipairs(EyeUnits) do
		SafePcall(function() r.Visible = (i <= sc) end)
	end
end

local function RefreshEyeSingles()
	SafePcall(function()
		if ChaseEyeImg then
			local a = SafeAsset(ASSET_FOLDER .. CONFIG.EYE_CHASE_SINGLE)
			if a and a ~= "" then ChaseEyeImg.Image = a end
		end
		if LastEyeImg then
			local a = SafeAsset(ASSET_FOLDER .. CONFIG.EYE_LAST_SINGLE)
			if a and a ~= "" then LastEyeImg.Image = a end
		end
		if FinalEyeImg then
			local a = SafeAsset(ASSET_FOLDER .. CONFIG.EYE_FINAL_SINGLE)
			if a and a ~= "" then FinalEyeImg.Image = a end
		end
	end)
end

local function SetupEyeSingles()
	SafePcall(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
		if pg:FindFirstChild("EyeSingles") then
			pg.EyeSingles:Destroy()
		end
		
		local s = Instance.new("ScreenGui")
		s.Name = "EyeSingles"
		s.ResetOnSpawn = false
		s.DisplayOrder = 997
		s.IgnoreGuiInset = true
		s.Parent = pg
		
		local holder = Instance.new("Frame")
		holder.Name = "Holder"
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.new(1, 0, 1, 0)
		holder.Position = UDim2.new(0, 0, 0, 0)
		holder.Parent = s
		
		local function mk(n, fname)
			local im = Instance.new("ImageLabel")
			im.Name = n
			im.BackgroundTransparency = 1
			im.Visible = false
			local w0, h0, x0, y0 = EyeSingleRect()
			im.Size = UDim2.new(0, w0, 0, h0)
			im.Position = UDim2.new(0, x0, 0, y0)
			im.ScaleType = Enum.ScaleType.Stretch
			im.Image = ""
			im.Parent = holder
			
			local a = SafeAsset(ASSET_FOLDER .. fname)
			if a and a ~= "" then im.Image = a end
			return im
		end
		
		ChaseEyeImg = mk("Chase", CONFIG.EYE_CHASE_SINGLE)
		LastEyeImg = mk("Last", CONFIG.EYE_LAST_SINGLE)
		FinalEyeImg = mk("Final", CONFIG.EYE_FINAL_SINGLE)
		EyeSingleHolder = holder
		ApplyEyeTransform()
	end)
end

local function UpdateEyeSingles(dt, state)
	if not EyeSingleHolder then return false end
	
	local on = CONFIG.EYE_INDIVIDUAL_ENABLED and CONFIG.EYE_ENABLED and CONFIG.IS_ACTIVE and not IsDead
	local want = "none"
	
	if on then
		if state == "chase" then want = "chase"
		elseif state == "lastchance" or state == "lastlayer" then want = "last"
		elseif state == "final" then want = "final" end
	end
	
	local activeImg = nil
	SafePcall(function()
		if ChaseEyeImg then
			ChaseEyeImg.Visible = (want == "chase" and ChaseEyeImg.Image ~= "")
			if ChaseEyeImg.Visible then activeImg = ChaseEyeImg end
		end
		if LastEyeImg then
			LastEyeImg.Visible = (want == "last" and LastEyeImg.Image ~= "")
			if LastEyeImg.Visible then activeImg = LastEyeImg end
		end
		if FinalEyeImg then
			FinalEyeImg.Visible = (want == "final" and FinalEyeImg.Image ~= "")
			if FinalEyeImg.Visible then activeImg = FinalEyeImg end
		end
	end)
	
	local bw, bh, bx, by = EyeSingleRect()
	if activeImg then
		if CONFIG.EYE_SHAKE_ENABLED then
			local amt = CONFIG.EYE_SHAKE_AMOUNT or 6
			local ox = math.random(-amt, amt)
			local oy = math.random(-amt, amt)
			SafePcall(function()
				activeImg.Size = UDim2.new(0, bw, 0, bh)
				activeImg.Position = UDim2.new(0, bx + ox, 0, by + oy)
			end)
		else
			SafePcall(function()
				activeImg.Size = UDim2.new(0, bw, 0, bh)
				activeImg.Position = UDim2.new(0, bx, 0, by)
			end)
		end
		SafePcall(function() ApplyEyeTransform() end)
	else
		SafePcall(function()
			local w, h, x, y = EyeSingleRect()
				if ChaseEyeImg then ChaseEyeImg.Position = UDim2.new(0, x, 0, y); ChaseEyeImg.Size = UDim2.new(0, w, 0, h) end
				if LastEyeImg then LastEyeImg.Position = UDim2.new(0, x, 0, y); LastEyeImg.Size = UDim2.new(0, w, 0, h) end
				if FinalEyeImg then FinalEyeImg.Position = UDim2.new(0, x, 0, y); FinalEyeImg.Size = UDim2.new(0, w, 0, h) end
			end)
	end
	
	return want ~= "none"
end

-- Layer Statics
local function MakeStatic(guiName, order, fileKey)
	local img = nil
	SafePcall(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
		if pg:FindFirstChild(guiName) then
			pg[guiName]:Destroy()
		end
		
		local s = Instance.new("ScreenGui")
		s.Name = guiName
		s.ResetOnSpawn = false
		s.DisplayOrder = order
		s.IgnoreGuiInset = true
		s.Parent = pg
		
		local im = Instance.new("ImageLabel")
		im.Name = "Img"
		im.Size = CONFIG.LAYER_SIZE
		im.Position = CONFIG.LAYER_POS
		im.BackgroundTransparency = 1
		im.Visible = false
		im.ScaleType = Enum.ScaleType.Fit
		im.Image = ""
		im.Parent = s
		
		local asset = SafeAsset(ASSET_FOLDER .. CONFIG[fileKey])
		if asset and asset ~= "" then im.Image = asset end
		img = im
	end)
	return img
end

local function SetupStatics()
	L1Img = MakeStatic("Layer1FX", 992, "LAYER1_FILE")
	L2Img = MakeStatic("Layer2FX", 992, "LAYER2_FILE")
	L3Img = MakeStatic("Layer3FX", 992, "LAYER3_FILE")
	TransImg = MakeStatic("TransFX", 991, "TRANSITION_FILE")
end

local function UpdateLayerStatics(dt, state, layerNum)
	local a, b, c, t = false, false, false, false
	
	if CONFIG.IS_ACTIVE and not IsDead then
		if state == "idle" then
			if "idle" ~= LastLayerKey then
				if LastLayerKey ~= "none" and CONFIG.TRANSITION_ENABLED and TransImg and TransImg.Image ~= "" then
					TransTimer = CONFIG.TRANSITION_DURATION
				end
				LastLayerKey = "idle"
			end
			if TransTimer > 0 then t = true
			else a = CONFIG.LAYER1_ENABLED and L1Img and L1Img.Image ~= "" end
		elseif state == "layer" or state == "lastlayer" then
			local key = "layer" .. tostring(layerNum) .. state
			if key ~= LastLayerKey then
				if LastLayerKey ~= "none" and CONFIG.TRANSITION_ENABLED and TransImg and TransImg.Image ~= "" then
					TransTimer = CONFIG.TRANSITION_DURATION
				end
				LastLayerKey = key
			end
			if TransTimer > 0 then t = true
			else
				if layerNum <= 1 then a = CONFIG.LAYER1_ENABLED and L1Img and L1Img.Image ~= ""
				elseif layerNum == 2 then b = CONFIG.LAYER2_ENABLED and L2Img and L2Img.Image ~= ""
				else c = CONFIG.LAYER3_ENABLED and L3Img and L3Img.Image ~= "" end
			end
		else
			LastLayerKey = state
		end
	end
	
	if TransTimer > 0 then
		TransTimer -= dt
		if TransTimer < 0 then TransTimer = 0 end
	end
	
	SafePcall(function()
		if L1Img then L1Img.Visible = a end
		if L2Img then L2Img.Visible = b end
		if L3Img then L3Img.Visible = c end
		if TransImg then TransImg.Visible = t end
	end)
end

-- Visualizer
local function SetupVisualizer()
	SafePcall(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
		if pg:FindFirstChild("ChaseVisualizer") then
			pg.ChaseVisualizer:Destroy()
		end
		
		VisBars = {}
		local screen = Instance.new("ScreenGui")
		screen.Name = "ChaseVisualizer"
		screen.ResetOnSpawn = false
		screen.DisplayOrder = 998
		screen.IgnoreGuiInset = true
		screen.Parent = pg
		
		local s = CONFIG.VISUALIZER_SCALE or 0.6
		local vw = math.floor(200 * s)
		local vh = math.floor(56 * s)
		
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, vw, 0, vh)
		frame.Position = UDim2.new(0.5, -vw / 2, 1, -vh - 8)
		frame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
		frame.BackgroundTransparency = 0.25
		frame.BorderSizePixel = 0
		frame.Visible = false
		frame.Parent = screen
		
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 6)
		cc.Parent = frame
		
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, math.floor(14 * s) + 6)
		lbl.BackgroundTransparency = 1
		lbl.Text = "IDLE"
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = math.max(7, math.floor(10 * s))
		lbl.Parent = frame
		VisLabel = lbl
		
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, -10, 1, -(math.floor(14 * s) + 10))
		holder.Position = UDim2.new(0, 5, 0, math.floor(14 * s) + 8)
		holder.BackgroundTransparency = 1
		holder.Parent = frame
		
		local lay = Instance.new("UIListLayout")
		lay.FillDirection = Enum.FillDirection.Horizontal
		lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
		lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
		lay.Padding = UDim.new(0, 2)
		lay.Parent = holder
		
		for i = 1, (CONFIG.VISUALIZER_BARS or 12) do
			local b = Instance.new("Frame")
			b.Size = UDim2.new(1 / (CONFIG.VISUALIZER_BARS or 12), -2, 0, 4)
			b.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
			b.BorderSizePixel = 0
			b.Parent = holder
			
			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 2)
			bc.Parent = b
			
			table.insert(VisBars, b)
		end
		
		VisFrame = frame
	end)
end

local function UpdateVisualizer(dt, state, layerNum)
	if not VisFrame then return end
	
	local show = CONFIG.VISUALIZER_ENABLED and CONFIG.IS_ACTIVE and not IsDead and state ~= "silence"
	SafePcall(function() VisFrame.Visible = show end)
	if not show then return end
	
	VisTime += dt
	local loud = 0
	
	SafePcall(function()
		if state == "chase" and Sounds.chase then
			loud = Sounds.chase.PlaybackLoudness
		elseif state == "lastchance" and Sounds.lastChance then
			loud = Sounds.lastChance.PlaybackLoudness
		elseif state == "final" and Sounds.finalChance then
			loud = Sounds.finalChance.PlaybackLoudness
		elseif state == "layer" and Sounds.layers[layerNum] then
			loud = Sounds.layers[layerNum].PlaybackLoudness
		elseif state == "lastlayer" and Sounds.lastLayers[layerNum] then
			loud = Sounds.lastLayers[layerNum].PlaybackLoudness
		end
	end)
	
	local base = math.clamp(loud / 400, 0.1, 1)
	if state == "idle" then base = 0.15 end
	
	local txt = "IDLE"
	local col = Color3.fromRGB(120, 120, 120)
	
	if state == "layer" then
		txt = "LAYER " .. tostring(layerNum)
		col = Color3.fromRGB(255, 180, 80)
	elseif state == "lastlayer" then
		txt = "LAST LAYER " .. tostring(layerNum)
		col = Color3.fromRGB(180, 120, 255)
	elseif state == "chase" then
		txt = "CHASE MODE"
		col = Color3.fromRGB(255, 60, 60)
	elseif state == "lastchance" then
		txt = "LAST CHANCE"
		col = Color3.fromRGB(180, 60, 255)
	elseif state == "final" then
		txt = "FINAL"
		col = Color3.fromRGB(255, 0, 80)
	end
	
	SafePcall(function()
		VisLabel.Text = txt
		VisLabel.TextColor3 = col
	end)
	
	local maxH = VisFrame.Size.Y.Offset - 20
	for i, b in ipairs(VisBars) do
		local w = math.sin(VisTime * 10 + i * 0.9) * 0.5 + 0.5
		local h = math.clamp((base * 0.7 + w * 0.3), 0.08, 1) * maxH
		SafePcall(function()
			b.Size = UDim2.new(1 / (#VisBars), -2, 0, math.max(2, math.floor(h)))
			b.BackgroundColor3 = col
		end)
	end
end

-- Audio Functions
local function PlaySound(id, vol, looped)
	if not id or id == "" then return nil end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = 0
	s.Looped = looped
	s.Parent = workspace
	
	local ok = SafePcall(function() s:Play() end)
	if not ok then
		s:Destroy()
		return nil
	end
	
	SafePcall(function()
		TweenService:Create(s, TweenInfo.new(0.5), {Volume = vol}):Play()
	end)
	return s
end

local function StopSound(obj)
	if not obj then return end
	SafePcall(function()
		TweenService:Create(obj, TweenInfo.new(0.5), {Volume = 0}):Play()
	end)
	task.delay(0.6, function()
		if obj then SafePcall(function() obj:Destroy() end) end
	end)
end

local function StopAllSounds()
	for i = 1, 3 do
		if Sounds.layers[i] then
			StopSound(Sounds.layers[i])
			Sounds.layers[i] = nil
		end
		if Sounds.lastLayers[i] then
			StopSound(Sounds.lastLayers[i])
			Sounds.lastLayers[i] = nil
		end
	end
	if Sounds.chase then StopSound(Sounds.chase); Sounds.chase = nil end
	if Sounds.idle then StopSound(Sounds.idle); Sounds.idle = nil end
	if Sounds.heartbeat then StopSound(Sounds.heartbeat); Sounds.heartbeat = nil end
	if Sounds.lastChance then StopSound(Sounds.lastChance); Sounds.lastChance = nil end
	if Sounds.finalChance then StopSound(Sounds.finalChance); Sounds.finalChance = nil end
	
	SetFinalFX(false)
	isChaseActive = false
	chaseExitTimer = 0
end

local function StopLayersAndIdle()
	for i = 1, 3 do
		if Sounds.layers[i] then
			StopSound(Sounds.layers[i])
			Sounds.layers[i] = nil
		end
		if Sounds.lastLayers[i] then
			StopSound(Sounds.lastLayers[i])
			Sounds.lastLayers[i] = nil
		end
	end
	if Sounds.idle then
		StopSound(Sounds.idle)
		Sounds.idle = nil
	end
end

local function StopLastLayers()
	for i = 1, 3 do
		if Sounds.lastLayers[i] then
			StopSound(Sounds.lastLayers[i])
			Sounds.lastLayers[i] = nil
		end
	end
end

local function StopNormalLayers()
	for i = 1, 3 do
		if Sounds.layers[i] then
			StopSound(Sounds.layers[i])
			Sounds.layers[i] = nil
		end
	end
end

local function UpdateLayers(dist, theme)
	local dists = CONFIG.LAYER_DISTANCES
	local n = 0
	if dist < dists[1] then
		if dist >= dists[2] then n = 1
		elseif dist >= dists[3] then n = 2
		else n = 3 end
	end
	
	for i = 1, 3 do
		local should = i <= n
		local playing = Sounds.layers[i] ~= nil
		if should and not playing then
			local a = {theme.layer1, theme.layer2, theme.layer3}
			Sounds.layers[i] = PlaySound(a[i], CONFIG.VOLUME_LAYERS, true)
		elseif not should and playing then
			StopSound(Sounds.layers[i])
			Sounds.layers[i] = nil
		end
	end
	
	for i = 1, n do
		if Sounds.layers[i] then
			Sounds.layers[i].Volume = CONFIG.VOLUME_LAYERS * (CONFIG.CROSSFADE_FACTOR ^ (n - i))
		end
	end
	
	return n
end

local function UpdateLastLayers(dist, theme)
	if not theme.hasLastLayers then return 0 end
	SafePcall(function() RefreshThemeAssets(theme) end)
	
	local dists = CONFIG.LAST_CHANCE_LAYER_DISTANCES
	local n = 0
	if dist < dists[1] then
		if dist >= dists[2] then n = 1
		elseif dist >= dists[3] then n = 2
		else n = 3 end
	end
	
	for i = 1, 3 do
		local should = i <= n
		local playing = Sounds.lastLayers[i] ~= nil
		if should and not playing then
			local a = {theme.lastLayer1, theme.lastLayer2, theme.lastLayer3}
			Sounds.lastLayers[i] = PlaySound(a[i], CONFIG.VOLUME_LAST_CHANCE, true)
		elseif not should and playing then
			StopSound(Sounds.lastLayers[i])
			Sounds.lastLayers[i] = nil
		end
	end
	
	for i = 1, n do
		if Sounds.lastLayers[i] then
			Sounds.lastLayers[i].Volume = CONFIG.VOLUME_LAST_CHANCE * (CONFIG.CROSSFADE_FACTOR ^ (n - i))
		end
	end
	
	return n
end

local function SetChaseSound(theme, v)
	if not Sounds.chase then
		Sounds.chase = PlaySound(theme.chase, v, true)
	else
		if Sounds.chase.SoundId ~= theme.chase then
			StopSound(Sounds.chase)
			Sounds.chase = nil
			Sounds.chase = PlaySound(theme.chase, v, true)
		else
			Sounds.chase.Volume = v
		end
	end
end

local GlobalIdleId = ""
local GlobalHeartbeatId = ""
local GlobalRefreshT = 0

local function RefreshGlobalIds()
	SafePcall(function()
		local a = SafeAsset(ASSET_FOLDER .. "Idle.mp3")
		if a and a ~= "" then GlobalIdleId = a end
		if GlobalIdleId == "" then
			local c = SafeAsset(ASSET_FOLDER .. "idle.mp3")
			if c and c ~= "" then GlobalIdleId = c end
		end
		
		local b = SafeAsset(ASSET_FOLDER .. "Heartbeat.mp3")
		if b and b ~= "" then GlobalHeartbeatId = b end
		if GlobalHeartbeatId == "" then
			local d = SafeAsset(ASSET_FOLDER .. "heartbeat.mp3")
			if d and d ~= "" then GlobalHeartbeatId = d end
		end
	end)
end

local function GetIdleId(theme)
	if GlobalIdleId ~= "" then return GlobalIdleId end
	if theme and theme.idle and theme.idle ~= "" then return theme.idle end
	return ""
end

local function SetIdleSound(theme)
	local want = GetIdleId(theme)
	if not want or want == "" then return end
	
	if not Sounds.idle then
		Sounds.idle = PlaySound(want, CONFIG.VOLUME_IDLE, true)
	else
		local cur = nil
		SafePcall(function() cur = Sounds.idle.SoundId end)
		if cur ~= want then
			SafePcall(function() StopSound(Sounds.idle) end)
			Sounds.idle = nil
			Sounds.idle = PlaySound(want, CONFIG.VOLUME_IDLE, true)
		else
			SafePcall(function() Sounds.idle.Volume = CONFIG.VOLUME_IDLE end)
		end
	end
end

local function StopHeartbeat()
	if Sounds.heartbeat then
		SafePcall(function() StopSound(Sounds.heartbeat) end)
		Sounds.heartbeat = nil
	end
end

local function SetHeartbeatOn()
	if GlobalHeartbeatId == "" then RefreshGlobalIds() end
	if GlobalHeartbeatId == "" then return end
	
	if not Sounds.heartbeat then
		Sounds.heartbeat = PlaySound(GlobalHeartbeatId, CONFIG.VOLUME_HEARTBEAT, true)
	else
		SafePcall(function() Sounds.heartbeat.Volume = CONFIG.VOLUME_HEARTBEAT end)
	end
end

local function UpdateHeartbeat(health, lowHP, alive)
	if not alive or not lowHP then
		if Sounds.heartbeat then StopHeartbeat() end
		return
	end
	SetHeartbeatOn()
	SafePcall(function()
		if Sounds.heartbeat then
			local denom = CONFIG.HEARTBEAT_HEALTH
			if not denom or denom <= 0 then denom = 0.35 end
			local t = 1 - math.clamp(health / denom, 0, 1)
			Sounds.heartbeat.PlaybackSpeed = 1 + t * 1.6
		end
	end)
end

local function HookEndedReroll(soundObj, kind)
	if not soundObj or typeof(soundObj) ~= "Instance" then return end
	
	SafePcall(function()
		pcall(function() soundObj.Looped = false end)
		local endedEv = nil
		pcall(function() endedEv = soundObj.Ended end)
		if not endedEv then return end
		
		local ok, _ = pcall(function()
			endedEv:Connect(function()
				local function doReroll()
					if kind == "last" then
						if Sounds.lastChance == soundObj then
							SafePcall(function() soundObj:Destroy() end)
							Sounds.lastChance = nil
							if typeof(math.random) == "function" then
								CurrentLastChanceVariant = math.random(1, 2)
							end
						end
					elseif kind == "final" then
						if Sounds.finalChance == soundObj then
							SafePcall(function() soundObj:Destroy() end)
							Sounds.finalChance = nil
							if typeof(math.random) == "function" then
								CurrentFinalVariant = math.random(1, 2)
							end
						end
					end
				end
				
				if typeof(task) == "table" and typeof(task.delay) == "function" then
					task.delay(0.1, function() SafePcall(doReroll) end)
				elseif typeof(delay) == "function" then
					delay(0.1, function() SafePcall(doReroll) end)
				else
					SafePcall(doReroll)
				end
			end)
		end)
		if not ok then warn("[Chase][Hook] Ended connect failed") end
	end)
end

local function ResolveLastChaseId(theme)
	if not theme then return "" end
	if theme.lastChaseRandom then
		local id = CurrentLastChanceVariant == 1 and theme.lastChase1 or theme.lastChase2
		if id and id ~= "" then return id end
		if theme.lastChase1 and theme.lastChase1 ~= "" then return theme.lastChase1 end
		if theme.lastChase2 and theme.lastChase2 ~= "" then return theme.lastChase2 end
		return ""
	end
	return theme.lastChase or ""
end

local function HasLastChanceFile(theme)
	if not theme then return false end
	if theme.lastChaseRandom then
		return (theme.lastChase1 and theme.lastChase1 ~= "") or (theme.lastChase2 and theme.lastChase2 ~= "")
	end
	return theme.lastChase and theme.lastChase ~= ""
end

local function HasLastLayerFiles(theme)
	if not theme or not theme.hasLastLayers then return false end
	if (theme.lastLayer1 and theme.lastLayer1 ~= "") or
	   (theme.lastLayer2 and theme.lastLayer2 ~= "") then return true end
	
	local a1 = SmartAsset("tell-me-buddy-layer1.mp3")
	local a2 = SmartAsset("tell-me-buddy-layer2.mp3")
	local a3 = SmartAsset("tell-me-buddy-layer3.mp3")
	
	if a1 ~= "" then theme.lastLayer1 = a1 end
	if a2 ~= "" then theme.lastLayer2 = a2 end
	if a3 ~= "" then theme.lastLayer3 = a3 end
	
	return (a1 ~= "" or a2 ~= "")
end

local function ResolveFinalId(theme)
	if theme and theme.hasFinalCustom and theme.finalCustom and theme.finalCustom ~= "" then
		return theme.finalCustom
	end
	local id = CurrentFinalVariant == 1 and FINAL_CHASE_1 or FINAL_CHASE_2
	if id and id ~= "" then return id end
	return FINAL_CHASE_1
end

local function SetLastChanceSound(theme)
	if not theme then return end
	SafePcall(function() RefreshThemeAssets(theme) end)
	
	local w = ResolveLastChaseId(theme)
	if not w or w == "" then return end
	
	if not Sounds.lastChance then
		local s = PlaySound(w, CONFIG.VOLUME_LAST_CHANCE, false)
		if s then
			Sounds.lastChance = s
			SafePcall(function() HookEndedReroll(s, "last") end)
		end
	else
		local curId = nil
		SafePcall(function() curId = Sounds.lastChance.SoundId end)
		if curId ~= w then
			SafePcall(function() StopSound(Sounds.lastChance) end)
			Sounds.lastChance = nil
			local s2 = PlaySound(w, CONFIG.VOLUME_LAST_CHANCE, false)
			if s2 then
				Sounds.lastChance = s2
				SafePcall(function() HookEndedReroll(s2, "last") end)
			end
		end
	end
end

local function SetFinalSound(theme)
	if not theme then return end
	SafePcall(function() RefreshThemeAssets(theme) end)
	
	local w = ResolveFinalId(theme)
	if not w or w == "" then return end
	
	if theme and theme.hasFinalCustom then
		if not Sounds.finalChance then
			local s = PlaySound(w, CONFIG.VOLUME_FINAL_CHANCE, true)
			if s then Sounds.finalChance = s end
		else
			local curId = nil
			SafePcall(function() curId = Sounds.finalChance.SoundId end)
			if curId ~= w then
				SafePcall(function() StopSound(Sounds.finalChance) end)
				Sounds.finalChance = nil
				local s2 = PlaySound(w, CONFIG.VOLUME_FINAL_CHANCE, true)
				if s2 then Sounds.finalChance = s2 end
			end
		end
		return
	end
	
	if not Sounds.finalChance then
		local s3 = PlaySound(w, CONFIG.VOLUME_FINAL_CHANCE, false)
		if s3 then
			Sounds.finalChance = s3
			SafePcall(function() HookEndedReroll(s3, "final") end)
		end
	else
		local curId2 = nil
		SafePcall(function() curId2 = Sounds.finalChance.SoundId end)
		if curId2 ~= w then
			SafePcall(function() StopSound(Sounds.finalChance) end)
			Sounds.finalChance = nil
			local s4 = PlaySound(w, CONFIG.VOLUME_FINAL_CHANCE, false)
			if s4 then
				Sounds.finalChance = s4
				SafePcall(function() HookEndedReroll(s4, "final") end)
			end
		end
	end
end

-- Helper Functions
local function GetCurrentTheme()
	local idx = tonumber(CONFIG.CURRENT_THEME) or 1
	idx = math.clamp(math.floor(idx), 1, #THEMES)
	CONFIG.CURRENT_THEME = idx
	return THEMES[idx]
end

local function GetHealth()
	if IsDead then return 0 end
	local hum = GetHumanoid()
	if hum then return hum.Health / hum.MaxHealth end
	return 1
end

local function GetHealthAbs()
	local hum = GetHumanoid()
	if hum then return hum.Health end
	return 100
end

SafePcall(function() RefreshGlobalIds() end)

-- Main Update Loop
local function Update(dt)
	local function finish(s, l)
		UpdateLayerStatics(dt, s, l)
		UpdateCloseVignette(dt, s)
		local singleOn = UpdateEyeSingles(dt, s)
		UpdateEyes(s, l, singleOn)
		UpdateVisualizer(dt, s, l)
	end
	
	GlobalRefreshT += (dt or 0.016)
	if GlobalRefreshT >= 5 then
		GlobalRefreshT = 0
		SafePcall(function() RefreshGlobalIds() end)
		if Sounds.idle then SafePcall(function() Sounds.idle.Volume = CONFIG.VOLUME_IDLE end) end
		if Sounds.heartbeat then SafePcall(function() Sounds.heartbeat.Volume = CONFIG.VOLUME_HEARTBEAT end) end
	end
	
	if not CONFIG.IS_ACTIVE then
		if Sounds.heartbeat then StopHeartbeat() end
		finish("idle", 0)
		return
	end
	
	if IsDead then
		if Sounds.heartbeat then StopHeartbeat() end
		StopAllSounds()
		finish("dead", 0)
		return
	end
	
	local _, dist = GetClosestTarget()
	local health = GetHealth()
	local hpAbs = GetHealthAbs()
	local theme = GetCurrentTheme()
	if not theme then finish("idle", 0) return end
	local chaseDist = GetChaseDist(theme)
	
	-- Final Chance State
	if hpAbs <= CONFIG.FINAL_CHANCE_HP and hpAbs > 0 then
		if isChaseActive then
			if Sounds.chase then
				StopSound(Sounds.chase)
				Sounds.chase = nil
			end
			isChaseActive = false
		end
		if Sounds.lastChance then
			StopSound(Sounds.lastChance)
			Sounds.lastChance = nil
		end
		StopLastLayers()
		if not Sounds.finalChance and not theme.hasFinalCustom then
			CurrentFinalVariant = math.random(1, 2)
		end
		StopLayersAndIdle()
		SetFinalSound(theme)
		SetFinalFX(true)
		finish("final", 0)
		return
	else
		if Sounds.finalChance then
			StopSound(Sounds.finalChance)
			Sounds.finalChance = nil
		end
		SetFinalFX(false)
	end
	
	-- Low HP State
	if theme and theme.hasLastLayers then
		SafePcall(function() RefreshThemeAssets(theme) end)
	end
	
	local lowHP = health <= CONFIG.HEARTBEAT_HEALTH and health > 0
	SafePcall(function() UpdateHeartbeat(health, lowHP, true) end)
	
	if lowHP and theme.hasLastLayers and (HasLastLayerFiles(theme) or HasLastChanceFile(theme)) then
		local lastChaseRange = CONFIG.LAST_CHANCE_DISTANCE
		local lastLayerRange = CONFIG.LAST_CHANCE_LAYER_DISTANCES[1]
		
		if dist < lastChaseRange then
			if isChaseActive then
				if Sounds.chase then
					StopSound(Sounds.chase)
					Sounds.chase = nil
				end
				isChaseActive = false
			end
			StopNormalLayers()
			if Sounds.idle then
				StopSound(Sounds.idle)
				Sounds.idle = nil
			end
			StopLastLayers()
			if not Sounds.lastChance then
				CurrentLastChanceVariant = math.random(1, 2)
			end
			SetLastChanceSound(theme)
			finish("lastchance", 3)
			return
		elseif dist < lastLayerRange then
			if isChaseActive then
				if Sounds.chase then
					StopSound(Sounds.chase)
					Sounds.chase = nil
				end
				isChaseActive = false
			end
			if Sounds.lastChance then
				StopSound(Sounds.lastChance)
				Sounds.lastChance = nil
			end
			if Sounds.idle then
				StopSound(Sounds.idle)
				Sounds.idle = nil
			end
			StopNormalLayers()
			local ln = UpdateLastLayers(dist, theme)
			finish("lastlayer", ln)
			return
		end
	end
	
	-- Normal Chase Logic
	local inChase = dist < chaseDist
	local inLC = dist < CONFIG.LAST_CHANCE_DISTANCE
	local useLC = lowHP and inLC and theme.hasLastChance and HasLastChanceFile(theme) and not theme.hasLastLayers
	
	if useLC then
		if isChaseActive then
			if Sounds.chase then
				StopSound(Sounds.chase)
				Sounds.chase = nil
			end
			isChaseActive = false
		end
		if not Sounds.lastChance then
			CurrentLastChanceVariant = math.random(1, 2)
		end
		StopLayersAndIdle()
		StopLastLayers()
		SetLastChanceSound(theme)
		finish("lastchance", 3)
	else
		if Sounds.lastChance then
			StopSound(Sounds.lastChance)
			Sounds.lastChance = nil
		end
		StopLastLayers()
		
		if inChase then
			chaseExitTimer = 0
			if not isChaseActive then
				StopLayersAndIdle()
				isChaseActive = true
			end
			local inten = 1 - math.clamp(dist / chaseDist, 0, 1)
			SetChaseSound(theme, CONFIG.VOLUME_CHASE * (0.5 + inten * 0.5))
			finish("chase", 0)
		else
			if isChaseActive then
				chaseExitTimer += (dt or 0.016)
				if chaseExitTimer >= CONFIG.CHASE_EXIT_DELAY then
					if Sounds.chase then
						StopSound(Sounds.chase)
						Sounds.chase = nil
					end
					isChaseActive = false
					chaseExitTimer = 0
				end
			end
			
			if not isChaseActive then
				if theme.hasLayers and dist < CONFIG.LAYER_DISTANCES[1] then
					if Sounds.idle then
						StopSound(Sounds.idle)
						Sounds.idle = nil
					end
					local ln = UpdateLayers(dist, theme)
					finish("layer", ln)
				elseif GetIdleId(theme) ~= "" then
					StopLayersAndIdle()
					SetIdleSound(theme)
					finish("idle", 0)
				else
					StopLayersAndIdle()
					if Sounds.chase then StopSound(Sounds.chase); Sounds.chase = nil end
					if Sounds.lastChance then StopSound(Sounds.lastChance); Sounds.lastChance = nil end
					if Sounds.finalChance then StopSound(Sounds.finalChance); Sounds.finalChance = nil end
					StopLastLayers()
					isChaseActive = false
					chaseExitTimer = 0
					finish("silence", 0)
				end
			else
				finish("chase", 0)
			end
		end
	end
end

-- GUI Construction
local function MakeDraggable(main, handle)
	handle.Active = true
	local dragging, dragStart, startPos
	
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
									  startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function SetupPersistentToggle()
	SafePcall(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
		if pg:FindFirstChild("ChaseToggleGui") then
			pg.ChaseToggleGui:Destroy()
		end
		
		local scr = Instance.new("ScreenGui")
		scr.Name = "ChaseToggleGui"
		scr.ResetOnSpawn = false
		scr.DisplayOrder = 1001
		scr.IgnoreGuiInset = true
		scr.Parent = pg
		
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 64, 0, 64)
		btn.Position = UDim2.new(1, -74, 0.5, -32)
		btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		btn.BackgroundTransparency = 0.15
		btn.Text = "MUS"
		btn.TextSize = 16
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Active = true
		btn.Parent = scr
		
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 12)
		bc.Parent = btn
		
		btn.Activated:Connect(function()
			for _, gname in ipairs({"ChaseGUI", "ChaseGUI_Dead"}) do
				local g = pg:FindFirstChild(gname)
				if g and g:FindFirstChild("MainFrame") then
					g.MainFrame.Visible = not g.MainFrame.Visible
				end
			end
		end)
		
		local dragging, dragStart, startPos
		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = btn.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						task.delay(0.15, function() dragging = false end)
					end
				end)
			end
		end)
		
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
										 startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
	end)
end

-- BuildGUI function is very long - I'll include a condensed version
local function BuildGUI(isDeathGui)
	SafePcall(function()
		local guiName = isDeathGui and "ChaseGUI_Dead" or "ChaseGUI"
		local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
		if pg:FindFirstChild(guiName) then
			pg[guiName]:Destroy()
		end
		
		local screen = Instance.new("ScreenGui")
		screen.Name = guiName
		screen.ResetOnSpawn = false
		screen.DisplayOrder = 999
		screen.IgnoreGuiInset = true
		screen.Parent = pg
		
		local main = Instance.new("Frame")
		main.Name = "MainFrame"
		main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		main.BackgroundTransparency = 0.1
		main.BorderSizePixel = 0
		main.Active = true
		main.Parent = screen
		
		local vy = 667
		SafePcall(function() vy = workspace.CurrentCamera.ViewportSize.Y end)
		
		local w = 280
		local mh = math.clamp(vy - 60, 380, 780)
		main.Size = UDim2.new(0, w, 0, mh)
		main.Position = UDim2.new(0.5, -w / 2, 0, 8)
		
		local mc = Instance.new("UICorner")
		mc.CornerRadius = UDim.new(0, 6)
		mc.Parent = main
		
		-- Title
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 24)
		title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		title.Text = isDeathGui and "Chase (DEAD)" or "Chase System - drag me"
		title.TextColor3 = Color3.fromRGB(220, 80, 80)
		title.TextSize = 12
		title.Font = Enum.Font.GothamBold
		title.Parent = main
		MakeDraggable(main, title)
		
		-- Close Button
		local close = Instance.new("TextButton")
		close.Size = UDim2.new(0, 22, 0, 22)
		close.Position = UDim2.new(1, -26, 0, 2)
		close.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
		close.Text = "X"
		close.TextColor3 = Color3.fromRGB(255, 100, 100)
		close.TextSize = 12
		close.Font = Enum.Font.GothamBold
		close.Parent = main
		close.Activated:Connect(function() main.Visible = false end)
		
		-- Scroll Frame
		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1, -10, 1, -40)
		scroll.Position = UDim2.new(0, 5, 0, 32)
		scroll.BackgroundTransparency = 1
		scroll.ScrollBarThickness = 6
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.Parent = main
		
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 5)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = scroll
		
		-- Helper Functions
		local orderCounter = 0
		local function nextOrder()
			orderCounter += 1
			return orderCounter
		end
		
		local function section(name, color)
			local f = Instance.new("Frame")
			f.LayoutOrder = nextOrder()
			f.Size = UDim2.new(1, 0, 0, 22)
			f.BackgroundColor3 = color
			f.Parent = scroll
			
			local t = Instance.new("TextLabel")
			t.Size = UDim2.new(1, -8, 1, 0)
			t.Position = UDim2.new(0, 4, 0, 0)
			t.BackgroundTransparency = 1
			t.Text = name
			t.TextColor3 = Color3.fromRGB(255, 255, 255)
			t.TextSize = 11
			t.Font = Enum.Font.GothamBold
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Parent = f
			return f
		end
		
		local function makeToggle(label, key, cb)
			local b = Instance.new("TextButton")
			b.LayoutOrder = nextOrder()
			b.Size = UDim2.new(1, -4, 0, 22)
			b.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(80, 40, 40)
			b.Text = label .. ": " .. (CONFIG[key] and "ON" or "OFF")
			b.TextColor3 = Color3.fromRGB(255, 255, 255)
			b.TextSize = 9
			b.Font = Enum.Font.GothamBold
			b.Parent = scroll
			
			b.Activated:Connect(function()
				CONFIG[key] = not CONFIG[key]
				SafePcall(function() SaveConfig(true) end)
				b.Text = label .. ": " .. (CONFIG[key] and "ON" or "OFF")
				b.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(80, 40, 40)
				if cb then cb() end
			end)
			return b
		end
		
		local function makeInput(label, key, mn, mx, isString)
			local row = Instance.new("Frame")
			row.Name = "row_" .. key
			row.LayoutOrder = nextOrder()
			row.Size = UDim2.new(1, -4, 0, 22)
			row.BackgroundTransparency = 1
			row.Parent = scroll
			
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0.55, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = label
			lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
			lbl.TextSize = 9
			lbl.Font = Enum.Font.Gotham
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = row
			
			local box = Instance.new("TextBox")
			box.Size = UDim2.new(0.45, 0, 0, 18)
			box.Position = UDim2.new(0.55, 0, 0.5, -9)
			box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			box.Text = tostring(CONFIG[key])
			box.TextColor3 = Color3.fromRGB(255, 255, 255)
			box.TextSize = 8
			box.Font = Enum.Font.GothamBold
			box.ClearTextOnFocus = false
			box.Parent = row
			
			box.FocusLost:Connect(function()
				if isString then
					CONFIG[key] = box.Text
					SafePcall(function() SaveConfig(true) end)
					if key == "CROUCH_IMAGE_FILE" then
						SafePcall(function()
							local a = SafeAsset(ASSET_FOLDER .. CONFIG.CROUCH_IMAGE_FILE)
							if CrouchBtnImg then
								CrouchBtnImg.Image = a
								CrouchBtnImg.Visible = (a ~= "")
							end
						end)
					end
					return
				end
				
				local num = tonumber(box.Text)
				if num then
					num = math.clamp(num, mn, mx)
					CONFIG[key] = num
					box.Text = tostring(num)
					SafePcall(function() SaveConfig(true) end)
					
					if key == "VISUALIZER_SCALE" or key == "VISUALIZER_BARS" then
						SetupVisualizer()
					elseif key == "EYE_SCALE" or key == "EYE_POS_X" or key == "EYE_POS_Y" then
						ApplyEyeTransform()
					elseif key == "CROUCH_SPEED" and IsCrouching then
						SafePcall(function()
							local hum = GetHumanoid()
							if hum then hum.WalkSpeed = num end
						end)
					elseif key == "SPEED_VALUE" and IsSpeeding then
						SafePcall(function()
							local hum = GetHumanoid()
							if hum then hum.WalkSpeed = num end
							NormalWalkSpeed = num
						end)
					end
				end
			end)
			return row
		end
		
		local function makeLayerInput(tbl, idx, label)
			local row = Instance.new("Frame")
			row.LayoutOrder = nextOrder()
			row.Size = UDim2.new(1, -4, 0, 22)
			row.BackgroundTransparency = 1
			row.Parent = scroll
			
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0.55, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = label
			lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
			lbl.TextSize = 9
			lbl.Font = Enum.Font.Gotham
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = row
			
			local box = Instance.new("TextBox")
			box.Size = UDim2.new(0.45, 0, 0, 18)
			box.Position = UDim2.new(0.55, 0, 0.5, -9)
			box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			box.Text = tostring(tbl[idx])
			box.TextColor3 = Color3.fromRGB(255, 255, 255)
			box.TextSize = 8
			box.Font = Enum.Font.GothamBold
			box.ClearTextOnFocus = false
			box.Parent = row
			
			box.FocusLost:Connect(function()
				local num = tonumber(box.Text)
				if num then
					tbl[idx] = math.clamp(num, 10, 300)
					box.Text = tostring(tbl[idx])
					SafePcall(function() SaveConfig(true) end)
				end
			end)
			return row
		end
		
		-- Theme Selector
		local themeFrame = Instance.new("Frame")
		themeFrame.LayoutOrder = nextOrder()
		themeFrame.Size = UDim2.new(1, 0, 0, 86)
		themeFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		themeFrame.Parent = scroll
		
		local themeLabel = Instance.new("TextLabel")
		themeLabel.Size = UDim2.new(1, -8, 0, 14)
		themeLabel.Position = UDim2.new(0, 4, 0, 3)
		themeLabel.BackgroundTransparency = 1
		themeLabel.Text = "THEME " .. CONFIG.CURRENT_THEME .. " / " .. #THEMES
		themeLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
		themeLabel.TextSize = 10
		themeLabel.Font = Enum.Font.GothamBold
		themeLabel.Parent = themeFrame
		
		local themeDisplay = Instance.new("TextLabel")
		themeDisplay.Size = UDim2.new(0.55, -6, 0, 20)
		themeDisplay.Position = UDim2.new(0, 4, 0, 17)
		themeDisplay.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		themeDisplay.Text = GetCurrentTheme().name
		themeDisplay.TextColor3 = Color3.fromRGB(255, 200, 100)
		themeDisplay.TextSize = 9
		themeDisplay.Font = Enum.Font.GothamBold
		themeDisplay.TextScaled = true
		themeDisplay.Parent = themeFrame
		
		local themeBtn = Instance.new("TextButton")
		themeBtn.Size = UDim2.new(0.38, 0, 0, 20)
		themeBtn.Position = UDim2.new(0.58, 0, 0, 17)
		themeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		themeBtn.Text = "NEXT"
		themeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		themeBtn.TextSize = 10
		themeBtn.Font = Enum.Font.GothamBold
		themeBtn.Parent = themeFrame
		
		local changeBtn = Instance.new("TextButton")
		changeBtn.Size = UDim2.new(1, -8, 0, 20)
		changeBtn.Position = UDim2.new(0, 4, 0, 39)
		changeBtn.BackgroundColor3 = Color3.fromRGB(90, 70, 140)
		changeBtn.Text = "Change"
		changeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		changeBtn.TextSize = 10
		changeBtn.Font = Enum.Font.GothamBold
		changeBtn.Parent = themeFrame
		
		local changeCorner = Instance.new("UICorner")
		changeCorner.CornerRadius = UDim.new(0, 6)
		changeCorner.Parent = changeBtn
		
		local function RefreshChangeBtn()
			local cn = GetCurrentTheme() and GetCurrentTheme().name or ""
			if cn == "Paper Cut" or cn == "Fleeting Failure" then
				changeBtn.Visible = true
				if cn == "Paper Cut" then
					changeBtn.Text = "Change -> Fleeting Failure"
				else
					changeBtn.Text = "Change -> Paper Cut"
				end
			else
				changeBtn.Visible = false
			end
		end
		
		SafePcall(RefreshChangeBtn)
		
		themeBtn.Activated:Connect(function()
			StopAllSounds()
			CONFIG.IS_ACTIVE = false
			CONFIG.CURRENT_THEME = CONFIG.CURRENT_THEME % #THEMES + 1
			themeLabel.Text = "THEME " .. CONFIG.CURRENT_THEME .. " / " .. #THEMES
			themeDisplay.Text = GetCurrentTheme().name
			SafePcall(function() SaveConfig(true) end)
			SafePcall(RefreshChangeBtn)
		end)
		
		changeBtn.Activated:Connect(function()
			local cn = GetCurrentTheme() and GetCurrentTheme().name or ""
			local target = nil
			if cn == "Paper Cut" then
				for i, th in ipairs(THEMES) do
					if th.name == "Fleeting Failure" then target = i break end
				end
			elseif cn == "Fleeting Failure" then
				for i, th in ipairs(THEMES) do
					if th.name == "Paper Cut" then target = i break end
				end
			else
				return
			end
			
			if target then
				StopAllSounds()
				CONFIG.IS_ACTIVE = false
				CONFIG.CURRENT_THEME = target
				themeLabel.Text = "THEME " .. CONFIG.CURRENT_THEME .. " / " .. #THEMES
				themeDisplay.Text = GetCurrentTheme().name
				SafePcall(function() SaveConfig(true) end)
				SafePcall(RefreshChangeBtn)
			end
		end)
		
		-- Start/Stop Button
		local startBtn = Instance.new("TextButton")
		startBtn.LayoutOrder = nextOrder()
		startBtn.Size = UDim2.new(1, 0, 0, 30)
		startBtn.BackgroundColor3 = CONFIG.IS_ACTIVE and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 150, 50)
		startBtn.Text = CONFIG.IS_ACTIVE and "STOP" or "START"
		startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		startBtn.TextSize = 13
		startBtn.Font = Enum.Font.GothamBold
		startBtn.Parent = scroll
		
		startBtn.Activated:Connect(function()
			CONFIG.IS_ACTIVE = not CONFIG.IS_ACTIVE
			startBtn.Text = CONFIG.IS_ACTIVE and "STOP" or "START"
			startBtn.BackgroundColor3 = CONFIG.IS_ACTIVE and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 150, 50)
			if not CONFIG.IS_ACTIVE then StopAllSounds() end
		end)
		
		-- Team System
		section("TEAM SYSTEM", Color3.fromRGB(40, 80, 100))
		
		local modeBtn = Instance.new("TextButton")
		modeBtn.LayoutOrder = nextOrder()
		modeBtn.Size = UDim2.new(1, -4, 0, 22)
		modeBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 140)
		modeBtn.Text = "MODE: " .. string.upper(CONFIG.TEAM_MODE)
		modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		modeBtn.TextSize = 9
		modeBtn.Font = Enum.Font.GothamBold
		modeBtn.Parent = scroll
		
		modeBtn.Activated:Connect(function()
			CONFIG.TEAM_MODE = (CONFIG.TEAM_MODE == "any" and "team" or "any")
			modeBtn.Text = "MODE: " .. string.upper(CONFIG.TEAM_MODE)
		end)
		
		-- Team Container
		local teamContainerOrder = nextOrder()
		local teamContainer = Instance.new("Frame")
		teamContainer.Name = "TeamContainer"
		teamContainer.LayoutOrder = teamContainerOrder
		teamContainer.Size = UDim2.new(1, 0, 0, 10)
		teamContainer.BackgroundTransparency = 1
		teamContainer.AutomaticSize = Enum.AutomaticSize.Y
		teamContainer.Parent = scroll
		
		local teamLay = Instance.new("UIListLayout")
		teamLay.Padding = UDim.new(0, 5)
		teamLay.SortOrder = Enum.SortOrder.LayoutOrder
		teamLay.Parent = teamContainer
		
		teamLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			SafePcall(function()
				teamContainer.Size = UDim2.new(1, 0, 0, teamLay.AbsoluteContentSize.Y)
			end)
		end)
		
		local function buildTeamButtons()
			for _, ch in ipairs(teamContainer:GetChildren()) do
				if ch:IsA("TextButton") then ch:Destroy() end
			end
			
			SafePcall(function()
				for _, t in ipairs(Teams:GetTeams()) do
					local on = CONFIG.TARGET_TEAMS[t.Name] == true
					local b = Instance.new("TextButton")
					b.Name = "TeamBtn"
					b.LayoutOrder = #teamContainer:GetChildren()
					b.Size = UDim2.new(1, -4, 0, 22)
					b.BackgroundColor3 = on and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(80, 40, 40)
					b.Text = t.Name .. (on and ": ON" or ": OFF")
					b.TextColor3 = Color3.fromRGB(255, 255, 255)
					b.TextSize = 9
					b.Font = Enum.Font.GothamBold
					b.Parent = teamContainer
					
					b.Activated:Connect(function()
						if CONFIG.TARGET_TEAMS[t.Name] then
							CONFIG.TARGET_TEAMS[t.Name] = nil
							b.Text = t.Name .. ": OFF"
							b.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
						else
							CONFIG.TARGET_TEAMS[t.Name] = true
							CONFIG.TEAM_MODE = "team"
							modeBtn.Text = "MODE: TEAM"
							b.Text = t.Name .. ": ON"
							b.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
						end
					end)
				end
				task.delay(0.1, function()
					SafePcall(function()
						teamContainer.Size = UDim2.new(1, 0, 0, teamLay.AbsoluteContentSize.Y)
					end)
				end)
			end)
		end
		
		local refreshBtn = Instance.new("TextButton")
		refreshBtn.Name = "TeamRefresh"
		refreshBtn.LayoutOrder = nextOrder()
		refreshBtn.Size = UDim2.new(1, -4, 0, 22)
		refreshBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 40)
		refreshBtn.Text = "REFRESH TEAMS (FPE:S fix)"
		refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 200)
		refreshBtn.TextSize = 9
		refreshBtn.Font = Enum.Font.GothamBold
		refreshBtn.Parent = scroll
		
		refreshBtn.Activated:Connect(function()
			refreshBtn.Text = "REFRESHING..."
			task.wait(0.1)
			buildTeamButtons()
			refreshBtn.Text = "REFRESH TEAMS (FPE:S fix)"
		end)
		
		buildTeamButtons()
		
		-- Settings Sections
		section("DISTANCES", Color3.fromRGB(70, 60, 40))
		makeLayerInput(CONFIG.LAYER_DISTANCES, 1, "LAYER1 DIST")
		makeLayerInput(CONFIG.LAYER_DISTANCES, 2, "LAYER2 DIST")
		makeLayerInput(CONFIG.LAYER_DISTANCES, 3, "LAYER3 DIST")
		makeLayerInput(CONFIG.LAST_CHANCE_LAYER_DISTANCES, 1, "LC-LAYER1 DIST")
		makeLayerInput(CONFIG.LAST_CHANCE_LAYER_DISTANCES, 2, "LC-LAYER2 DIST")
		makeLayerInput(CONFIG.LAST_CHANCE_LAYER_DISTANCES, 3, "LC-LAYER3 DIST")
		makeInput("CHASE_DISTANCE 10-200", "CHASE_DISTANCE", 10, 200)
		makeInput("CHASE_ONLY_BONUS 0-50", "CHASE_ONLY_BONUS", 0, 50)
		makeInput("LAST_CHANCE_DIST 10-200", "LAST_CHANCE_DISTANCE", 10, 200)
		makeInput("HEARTBEAT_HP 0-1", "HEARTBEAT_HEALTH", 0, 1)
		makeInput("FINAL_HP 0-100", "FINAL_CHANCE_HP", 0, 100)
		makeInput("EXIT_DELAY 0-10", "CHASE_EXIT_DELAY", 0, 10)
		
		section("VOLUMES", Color3.fromRGB(60, 40, 80))
		makeInput("VOL_LAYERS 0-2", "VOLUME_LAYERS", 0, 2)
		makeInput("VOL_CHASE 0-2", "VOLUME_CHASE", 0, 2)
		makeInput("VOL_IDLE 0-2", "VOLUME_IDLE", 0, 2)
		makeInput("VOL_HEART 0-2", "VOLUME_HEARTBEAT", 0, 2)
		makeInput("VOL_LAST 0-2", "VOLUME_LAST_CHANCE", 0, 2)
		makeInput("VOL_FINAL 0-2", "VOLUME_FINAL_CHANCE", 0, 2)
		makeInput("CROSSFADE 0-1", "CROSSFADE_FACTOR", 0, 1)
		makeInput("TRANS_DUR 0-2", "TRANSITION_DURATION", 0, 2)
		
		section("VISUALS / LAYERS", Color3.fromRGB(50, 70, 90))
		makeToggle("LAYER1", "LAYER1_ENABLED")
		makeToggle("LAYER2", "LAYER2_ENABLED")
		makeToggle("LAYER3", "LAYER3_ENABLED")
		makeToggle("TRANSITION", "TRANSITION_ENABLED")
		makeToggle("CLOSE_VIGNETTE", "CLOSE_ENABLED")
		makeInput("CLOSE_LAST_T 0-1", "CLOSE_LAST_TRANS", 0, 1)
		makeInput("CLOSE_FINAL_T 0-1", "CLOSE_FINAL_TRANS", 0, 1)
		
		section("EYE - FULLSCREEN SHAKE", Color3.fromRGB(60, 60, 60))
		makeToggle("EYE_ENABLED", "EYE_ENABLED")
		makeToggle("SINGLE_IMGS", "EYE_INDIVIDUAL_ENABLED", function()
			SafePcall(EnsureAssets)
			RefreshEyeSingles()
		end)
		makeToggle("SHAKE", "EYE_SHAKE_ENABLED")
		makeInput("EYE_SCALE 0.2-1", "EYE_SCALE", 0.2, 1)
		makeInput("EYE_POS_X 0-1", "EYE_POS_X", 0, 1)
		makeInput("EYE_POS_Y 0-1", "EYE_POS_Y", 0, 1)
		makeInput("SHAKE_AMT 0-20", "EYE_SHAKE_AMOUNT", 0, 20)
		
		section("BACKWARD ANIM", Color3.fromRGB(80, 50, 50))
		makeToggle("BACKWARD_ANIM", "BACKWARD_ANIM_ENABLED")
		makeInput("BACK_THRESH -1-0", "BACKWARD_ANIM_THRESHOLD", -1, 0)
		makeInput("BACK_SPEED 0.2-3", "BACKWARD_ANIM_SPEED", 0.2, 3)
		
		section("ACCEL (NO CROUCH)", Color3.fromRGB(80, 80, 50))
		makeToggle("ACCEL_ENABLE", "ACCEL_ENABLED")
		makeInput("ACCEL_RATE 5-200", "ACCEL_RATE", 5, 200)
		makeInput("ACCEL_MIN 1-10", "ACCEL_MIN", 1, 10)
		
		section("CROUCH SYSTEM", Color3.fromRGB(50, 80, 50))
		makeToggle("CROUCH_ENABLE", "CROUCH_ENABLED", function()
			SetupCrouchButton()
			if not CONFIG.CROUCH_ENABLED then ExitCrouch(true) end
		end)
		makeToggle("SHOW_CROUCH_BTN", "CROUCH_SHOW_BUTTON", function() RefreshCrouchBtn() end)
		makeToggle("DRAG_CROUCH_BTN", "CROUCH_BTN_DRAGGABLE")
		
		local crouchNow = Instance.new("TextButton")
		crouchNow.LayoutOrder = nextOrder()
		crouchNow.Size = UDim2.new(1, -4, 0, 22)
		crouchNow.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
		crouchNow.Text = "CROUCH / STAND NOW"
		crouchNow.TextColor3 = Color3.fromRGB(255, 255, 255)
		crouchNow.TextSize = 9
		crouchNow.Font = Enum.Font.GothamBold
		crouchNow.Parent = scroll
		
		crouchNow.Activated:Connect(function() EnterCrouch() end)
		
		makeInput("CROUCH_IDLE_ID", "CROUCH_ANIM_ID", 0, 0, true)
		makeInput("CROUCH_WALK_ID", "CROUCH_WALK_ID", 0, 0, true)
		makeInput("CROUCH_IMG_FILE", "CROUCH_IMAGE_FILE", 0, 0, true)
		makeInput("CROUCH_SPEED 1-10", "CROUCH_SPEED", 1, 10)
		makeInput("BREAK_SPEED 5-30", "CROUCH_BREAK_SPEED", 5, 30)
		makeInput("CROUCH_CD 0-15", "CROUCH_COOLDOWN", 0, 15)
		makeInput("CROUCH_KEY", "CROUCH_KEY", 0, 0, true)
		
		section("WALK SPEED OVERRIDE", Color3.fromRGB(50, 80, 120))
		
		local walkNowLbl = Instance.new("TextLabel")
		walkNowLbl.LayoutOrder = nextOrder()
		walkNowLbl.Size = UDim2.new(1, -4, 0, 16)
		walkNowLbl.BackgroundTransparency = 1
		walkNowLbl.Text = "GAME NOW: ? | YOURS: 16"
		walkNowLbl.TextColor3 = Color3.fromRGB(170, 220, 255)
		walkNowLbl.TextSize = 8
		walkNowLbl.Font = Enum.Font.GothamBold
		walkNowLbl.Parent = scroll
		
		task.spawn(function()
			while walkNowLbl.Parent do
				task.wait(0.25)
				SafePcall(function()
					if not walkNowLbl.Parent then return end
					local cur = -1
					local hum = GetHumanoid()
					if hum then cur = math.floor(hum.WalkSpeed + 0.5) end
					walkNowLbl.Text = "GAME NOW: " .. tostring(cur) .. " | YOURS: " ..
									  tostring(CONFIG.SPEED_VALUE) .. (IsSpeeding and " [ON]" or " [OFF]")
				end)
			end
		end)
		
		makeToggle("SPEED_ENABLE", "SPEED_ENABLED", function()
			RefreshSpeedBtn()
			if not CONFIG.SPEED_ENABLED and IsSpeeding then ExitSpeed() end
			SafePcall(function() SaveConfig(true) end)
		end)
		
		local speedNow = Instance.new("TextButton")
		speedNow.LayoutOrder = nextOrder()
		speedNow.Size = UDim2.new(1, -4, 0, 22)
		speedNow.BackgroundColor3 = Color3.fromRGB(50, 110, 180)
		speedNow.Text = "SPEED ON / OFF NOW"
		speedNow.TextColor3 = Color3.fromRGB(255, 255, 255)
		speedNow.TextSize = 9
		speedNow.Font = Enum.Font.GothamBold
		speedNow.Parent = scroll
		
		speedNow.Activated:Connect(function() EnterSpeed() end)
		
		makeToggle("SHOW_SPEED_BTN", "SPEED_SHOW_BUTTON", function() RefreshSpeedBtn() end)
		makeToggle("DRAG_SPEED_BTN", "SPEED_BTN_DRAGGABLE")
		makeInput("SPEED_VALUE 4-100", "SPEED_VALUE", 4, 100)
		makeToggle("SPEED_BREAK", "SPEED_BREAK_ENABLED")
		makeInput("BREAK_LIMIT 10-100", "SPEED_BREAK_LIMIT", 10, 100)
		makeToggle("BREAK_AUTO_RESUME", "SPEED_BREAK_AUTO_RESUME")
		makeInput("RESUME_DELAY 0-3", "SPEED_BREAK_RESUME_DELAY", 0, 3)
		
		-- Speed bump buttons
		local row2 = Instance.new("Frame")
		row2.LayoutOrder = nextOrder()
		row2.Size = UDim2.new(1, -4, 0, 22)
		row2.BackgroundTransparency = 1
		row2.Parent = scroll
		
		local function bumpBtn(label, delta, xpos)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0.23, 0, 1, 0)
			b.Position = UDim2.new(xpos, 0, 0, 0)
			b.BackgroundColor3 = Color3.fromRGB(50, 110, 180)
			b.Text = label
			b.TextColor3 = Color3.fromRGB(255, 255, 255)
			b.TextSize = 10
			b.Font = Enum.Font.GothamBold
			b.Parent = row2
			
			b.Activated:Connect(function()
				local nv = math.clamp((CONFIG.SPEED_VALUE or 16) + delta, 4, 100)
				CONFIG.SPEED_VALUE = nv
				SafePcall(function() SaveConfig(true) end)
				SafePcall(function()
					for _, ch in ipairs(scroll:GetChildren()) do
						if ch:IsA("Frame") and ch.Name == "row_SPEED_VALUE" then
							for _, c2 in ipairs(ch:GetChildren()) do
								if c2:IsA("TextBox") then c2.Text = tostring(nv) end
							end
						end
					end
				end)
				if IsSpeeding then
					SafePcall(function()
						local hum = GetHumanoid()
						if hum then hum.WalkSpeed = nv end
						NormalWalkSpeed = nv
					end)
				end
			end)
		end
		
		bumpBtn("-5", -5, 0)
		bumpBtn("-1", -1, 0.26)
		bumpBtn("+1", 1, 0.51)
		bumpBtn("+5", 5, 0.76)
		
		makeInput("SPEED_KEY", "SPEED_KEY", 0, 0, true)
		
		section("CONFIG SAVE", Color3.fromRGB(70, 70, 90))
		
		local saveRow = Instance.new("Frame")
		saveRow.LayoutOrder = nextOrder()
		saveRow.Size = UDim2.new(1, -4, 0, 22)
		saveRow.BackgroundTransparency = 1
		saveRow.Parent = scroll
		
		local saveBtn = Instance.new("TextButton")
		saveBtn.Size = UDim2.new(0.48, 0, 1, 0)
		saveBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		saveBtn.Text = "SAVE"
		saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		saveBtn.TextSize = 9
		saveBtn.Font = Enum.Font.GothamBold
		saveBtn.Parent = saveRow
		
		local loadBtn = Instance.new("TextButton")
		loadBtn.Size = UDim2.new(0.48, 0, 1, 0)
		loadBtn.Position = UDim2.new(0.52, 0, 0, 0)
		loadBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 160)
		loadBtn.Text = "LOAD"
		loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		loadBtn.TextSize = 9
		loadBtn.Font = Enum.Font.GothamBold
		loadBtn.Parent = saveRow
		
		saveBtn.Activated:Connect(function()
			SaveConfig(false)
			saveBtn.Text = "SAVED!"
			task.delay(1, function() SafePcall(function() saveBtn.Text = "SAVE" end) end)
		end)
		
		loadBtn.Activated:Connect(function()
			LoadConfig()
			loadBtn.Text = "LOADED!"
			task.delay(1, function() SafePcall(function() loadBtn.Text = "LOAD" end) end)
			SafePcall(function() RefreshSpeedBtn() end)
			SafePcall(function() RefreshCrouchBtn() end)
		end)
		
		local autoLbl = Instance.new("TextLabel")
		autoLbl.LayoutOrder = nextOrder()
		autoLbl.Size = UDim2.new(1, -4, 0, 16)
		autoLbl.BackgroundTransparency = 1
		autoLbl.Text = "auto-saves on toggle/input | speed starts OFF"
		autoLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
		autoLbl.TextSize = 8
		autoLbl.Font = Enum.Font.Gotham
		autoLbl.Parent = scroll
		
		section("MINI VISUALIZER", Color3.fromRGB(50, 90, 70))
		makeToggle("VISUALIZER", "VISUALIZER_ENABLED", function() SetupVisualizer() end)
		makeInput("VIS_SCALE 0.4-1.2", "VISUALIZER_SCALE", 0.4, 1.2)
		makeInput("VIS_BARS 6-24", "VISUALIZER_BARS", 6, 24)
	end)
end

-- Character Management
local function OnCharAdded(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	
	IsDead = false
	SetFinalFX(false)
	IsCrouching = false
	IsSpeeding = false
	SpeedAutoBroken = false
	SpeedBreakBelowTime = 0
	WasSpeedBeforeCrouch = false
	StopCrouchTracks()
	
	OrigWalkSpeed = hum.WalkSpeed
	NormalWalkSpeed = hum.WalkSpeed
	AccelCur = nil
	LastUncrouchAt = 0
	
	task.delay(0.35, function()
		SafePcall(function() PlayRespawnSfx() end)
	end)
	
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if pg and pg:FindFirstChild("ChaseGUI_Dead") then
		pg.ChaseGUI_Dead:Destroy()
	end
	
	hum.Died:Connect(function()
		IsDead = true
		if IsCrouching then
			IsCrouching = false
			StopCrouchTracks()
		end
		StopAllSounds()
		BuildGUI(true)
	end)
	
	task.delay(0.2, function()
		RefreshCrouchBtn()
		RefreshSpeedBtn()
	end)
end

-- Respawn SFX System
local RespawnAltIdx = 0
local RespawnLastSnd = nil

local function RespawnAsset(name)
	if not name or name == "" then return "" end
	return SafeAsset(ASSET_FOLDER .. name)
end

local function RespawnPlayId(assetId)
	if not assetId or assetId == "" then return end
	
	pcall(function()
		if RespawnLastSnd then
			RespawnLastSnd:Stop()
			RespawnLastSnd:Destroy()
			RespawnLastSnd = nil
		end
	end)
	
	local ok, s = pcall(function()
		local snd = Instance.new("Sound")
		snd.Name = "RespawnSfx"
		snd.SoundId = assetId
		snd.Volume = CONFIG.RESPAWN_VOLUME or 1
		snd.Looped = false
		snd.PlayOnRemove = false
		snd.Parent = game:GetService("SoundService")
		return snd
	end)
	
	if ok and s then
		RespawnLastSnd = s
		pcall(function()
			pcall(function()
				if not s.IsLoaded then s.Loaded:Wait(5) end
			end)
			s:Play()
			print("[RespawnSfx] playing " .. tostring(s.SoundId))
		end)
		task.delay(8, function()
			pcall(function()
				if RespawnLastSnd == s then RespawnLastSnd = nil end
				s:Destroy()
			end)
		end)
	end
end

PlayRespawnSfx = function()
	if not CONFIG.RESPAWN_ENABLED then return end
	
	local f1 = CONFIG.RESPAWN_FILE_1
	local f2 = CONFIG.RESPAWN_FILE_2
	local a1 = RespawnAsset(f1)
	local a2 = RespawnAsset(f2)
	
	if (not a1 or a1 == "") and (not a2 or a2 == "") then
		warn("[RespawnSfx] both missing in " .. ASSET_FOLDER)
		return
	end
	
	local mode = string.lower(tostring(CONFIG.RESPAWN_MODE or "random"))
	
	if mode == "both" then
		if a1 and a1 ~= "" then RespawnPlayId(a1) end
		if a2 and a2 ~= "" then
			task.delay(0.05, function()
				local ok, s = pcall(function()
					local snd = Instance.new("Sound")
					snd.Name = "RespawnSfx2"
					snd.SoundId = a2
					snd.Volume = CONFIG.RESPAWN_VOLUME or 1
					snd.Looped = false
					snd.Parent = game:GetService("SoundService")
					return snd
				end)
				if ok and s then
					pcall(function() s:Play() end)
					task.delay(8, function() pcall(function() s:Destroy() end) end)
				end
			end)
		end
		return
	end
	
	if mode == "alternate" then
		RespawnAltIdx = (RespawnAltIdx % 2) + 1
		local pick = (RespawnAltIdx == 1) and a1 or a2
		if not pick or pick == "" then pick = (a1 and a1 ~= "") and a1 or a2 end
		RespawnPlayId(pick)
		return
	end
	
	-- random mode
	local use1 = (math.random(1, 2) == 1)
	local pick = use1 and a1 or a2
	if not pick or pick == "" then pick = (a1 and a1 ~= "") and a1 or a2 end
	RespawnPlayId(pick)
end

local function SetupRespawnGui()
	SafePcall(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
		if not pg then return end
		if pg:FindFirstChild("RespawnSfxGui") then
			pg.RespawnSfxGui:Destroy()
		end
		
		local scr = Instance.new("ScreenGui")
		scr.Name = "RespawnSfxGui"
		scr.ResetOnSpawn = false
		scr.DisplayOrder = 1004
		scr.IgnoreGuiInset = true
		scr.Parent = pg
		
		local main = Instance.new("Frame")
		main.Size = UDim2.new(0, 170, 0, 132)
		main.Position = UDim2.new(0, 10, 0.5, -66)
		main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		main.BackgroundTransparency = 0.15
		main.Active = true
		main.Parent = scr
		
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 8)
		cc.Parent = main
		
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 20)
		title.BackgroundTransparency = 1
		title.Text = "Respawn SFX"
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 11
		title.Parent = main
		SafePcall(function() MakeDraggable(main, title) end)
		
		local function mkBtn(txt, y, cb)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, -12, 0, 24)
			b.Position = UDim2.new(0, 6, 0, y)
			b.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
			b.TextColor3 = Color3.fromRGB(255, 255, 255)
			b.Font = Enum.Font.GothamBold
			b.TextSize = 10
			b.Text = txt
			b.Parent = main
			
			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 6)
			bc.Parent = b
			
			b.Activated:Connect(cb)
			return b
		end
		
		mkBtn("PREVIEW 1", 24, function()
			local a = RespawnAsset(CONFIG.RESPAWN_FILE_1)
			if not a or a == "" then
				warn("[RespawnSfx] missing " .. tostring(CONFIG.RESPAWN_FILE_1))
			else
				RespawnPlayId(a)
			end
		end)
		
		mkBtn("PREVIEW 2", 52, function()
			local a = RespawnAsset(CONFIG.RESPAWN_FILE_2)
			if not a or a == "" then
				warn("[RespawnSfx] missing " .. tostring(CONFIG.RESPAWN_FILE_2))
			else
				RespawnPlayId(a)
			end
		end)
		
		local modeBtn = mkBtn("MODE: " .. string.upper(tostring(CONFIG.RESPAWN_MODE or "random")), 80, function()
			local m = string.lower(tostring(CONFIG.RESPAWN_MODE or "random"))
			if m == "random" then CONFIG.RESPAWN_MODE = "alternate"
			elseif m == "alternate" then CONFIG.RESPAWN_MODE = "both"
			else CONFIG.RESPAWN_MODE = "random" end
			modeBtn.Text = "MODE: " .. string.upper(CONFIG.RESPAWN_MODE)
			SaveConfig(true)
		end)
		modeBtn.Activated:Connect(function() --[[deprecated dup]]
			local m = string.lower(tostring(CONFIG.RESPAWN_MODE or "random"))
			if m == "random" then CONFIG.RESPAWN_MODE = "alternate"
			elseif m == "alternate" then CONFIG.RESPAWN_MODE = "both"
			else CONFIG.RESPAWN_MODE = "random" end
			modeBtn.Text = "MODE: " .. string.upper(CONFIG.RESPAWN_MODE)
			SaveConfig(true)
		end)
		
		local togBtn = mkBtn(CONFIG.RESPAWN_ENABLED and "ENABLED: ON" or "ENABLED: OFF", 108, function()
			CONFIG.RESPAWN_ENABLED = not CONFIG.RESPAWN_ENABLED
			togBtn.Text = CONFIG.RESPAWN_ENABLED and "ENABLED: ON" or "ENABLED: OFF"
			SaveConfig(true)
		end)
		togBtn.Activated:Connect(function() --[[deprecated dup]]
			CONFIG.RESPAWN_ENABLED = not CONFIG.RESPAWN_ENABLED
			togBtn.Text = CONFIG.RESPAWN_ENABLED and "ENABLED: ON" or "ENABLED: OFF"
			SaveConfig(true)
		end)
	end)
end

-- Initialization
if LocalPlayer.Character then
	task.spawn(function()
		SafePcall(function() OnCharAdded(LocalPlayer.Character) end)
	end)
end

LocalPlayer.CharacterAdded:Connect(function(c)
	SafePcall(function() OnCharAdded(c) end)
end)

-- Startup
task.spawn(function()
	task.wait(0.3)
	SetupFinalOverlay()
	SetupEyes()
	SetupEyeSingles()
	SetupCloseVignette()
	SetupStatics()
	SetupVisualizer()
	SetupPersistentToggle()
	SetupCrouchButton()
	SetupSpeedButton()
	SetupRespawnGui()
	BuildGUI(false)
	print("[Chase] System initialized successfully")
end)

-- Main Loop
RunService.Heartbeat:Connect(function(dt)
	SafePcall(function() Update(dt) end)
	SafePcall(function() UpdateAccel(dt) end)
	SafePcall(function() UpdateBackwardAnim() end)
	SafePcall(function() UpdateCrouch(dt) end)
	SafePcall(function() UpdateSpeed(dt) end)
	SafePcall(function() RefreshCrouchBtn() end)
	SafePcall(function() RefreshSpeedBtn() end)
end)

pcall(function() RunService:UnbindFromRenderStep("ChaseBackwardFix") end)
RunService:BindToRenderStep("ChaseBackwardFix", Enum.RenderPriority.Last.Value + 1, function()
	SafePcall(function() UpdateBackwardAnim() end)
end)

pcall(function()
	_G.RespawnSfx = { Play = PlayRespawnSfx, Config = CONFIG }
end)

print("[Chase] v2.5p loaded. Test: _G.RespawnSfx.Play()")