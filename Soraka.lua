local version = "1.0"
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/gmzopper/BoL/master/Soraka.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function _AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>Soraka:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/gmzopper/BoL/master/version/Soraka.version")
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(version) < ServerVersion then
				_AutoupdaterMsg("New version available "..ServerVersion)
				_AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () _AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
			else
				_AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		_AutoupdaterMsg("Error downloading version info")
	end
end

if myHero.charName ~= "Soraka" then return end  

function OnLoad()
	CheckVPred()
   
	if FileExist(LIB_PATH .. "/VPrediction.lua") and FileExist(LIB_PATH .. "/SxOrbWalk.lua") then
		DelayAction(function() 
			CustomOnLoad()
			AddMsgCallback(CustomOnWndMsg)
			AddDrawCallback(CustomOnDraw)          
			AddProcessSpellCallback(CustomOnProcessSpell)
			AddTickCallback(CustomOnTick)
			AddApplyBuffCallback(CustomApplyBuff)          
		end, 6)
	end
end

function CheckVPred()
	if FileExist(LIB_PATH .. "/VPrediction.lua") then
		require("VPrediction")
		VP = VPrediction()
	else
		local ToUpdate = {}
		ToUpdate.Version = 0.0
		ToUpdate.UseHttps = true
		ToUpdate.Name = "VPrediction"
		ToUpdate.Host = "raw.githubusercontent.com"
		ToUpdate.VersionPath = "/SidaBoL/Scripts/master/Common/VPrediction.version"
		ToUpdate.ScriptPath =  "/SidaBoL/Scripts/master/Common/VPrediction.lua"
		ToUpdate.SavePath = LIB_PATH.."/VPrediction.lua"
		ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) print("<font color=\"#FF794C\"><b>" .. ToUpdate.Name .. ": </b></font> <font color=\"#FFDFBF\">Updated to "..NewVersion..". Please Reload with 2x F9</b></font>") end
		ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"#FF794C\"><b>" .. ToUpdate.Name .. ": </b></font> <font color=\"#FFDFBF\">No Updates Found</b></font>") end
		ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#FF794C\"><b>" .. ToUpdate.Name .. ": </b></font> <font color=\"#FFDFBF\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
		ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#FF794C\"><b>" .. ToUpdate.Name .. ": </b></font> <font color=\"#FFDFBF\">Error while Downloading. Please try again.</b></font>") end
		ScriptUpdate(ToUpdate.Version,ToUpdate.UseHttps, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
	end
end
 
function CustomOnLoad()
	if _G.AutoCarry ~= nil then
		PrintChat("<font color=\"#DF7401\"><b>SAC: </b></font> <font color=\"#D7DF01\">Loaded</font>")
		SAC = true
		SOWp = false
	else
		SOWp = true
		SAC = false
		require "SOW"
		
		SOWi = SOW(VP)
		SOWi:RegisterAfterAttackCallback(AutoAttackReset)
	end
	TargetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, DAMAGE_MAGICAL, false, true)
	Variables()
	Menu()
end

function Checks()
	SkillQ.ready = (myHero:CanUseSpell(_Q) == READY)
	SkillW.ready = (myHero:CanUseSpell(_W) == READY)
	SkillE.ready = (myHero:CanUseSpell(_E) == READY)
	SkillR.ready = (myHero:CanUseSpell(_R) == READY)

	 _G.DrawCircle = _G.oldDrawCircle
end

function Variables()
	SkillQ = { name = myHero:GetSpellData(_Q).name, range = 970, delay = 0.25, speed = 1300, width = 200, ready = false }
	SkillW = { name = myHero:GetSpellData(_W).name, range = 550, delay = 0.5, speed = math.huge, width = nil, ready = false }
	SkillE = { name = myHero:GetSpellData(_E).name, range = 925, delay = 0.5, speed = math.huge, width = 200, ready = false }
	SkillR = { name = myHero:GetSpellData(_R).name, range = nil, delay = 0.5, speed = math.huge, width = nil, ready = false }
	
	myEnemyTable = GetEnemyHeroes()
	Champ = { }
	for i, enemy in pairs(myEnemyTable) do
		Champ[i] = enemy.charName
	end
   
	local ts
	local Target

	_G.oldDrawCircle = rawget(_G, 'DrawCircle')
	_G.DrawCircle = DrawCircle2
end

function DrawCircle2(x, y, z, radius, color)
  local vPos1 = Vector(x, y, z)
  local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
  local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
  local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
end

function Menu()
	Settings = scriptConfig("MyAnivia", "Zopper")
	
	Settings:addSubMenu("["..myHero.charName.."] - Combo Settings (SBTW)", "combo")
		Settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		Settings.combo:addParam("useQ", "Use (Q) in Combo", SCRIPT_PARAM_ONOFF, true)
		Settings.combo:permaShow("comboKey")
	
	Settings:addSubMenu("["..myHero.charName.."] - Draw Settings", "drawing")      
		Settings.drawing:addParam("mDraw", "Disable All Range Draws", SCRIPT_PARAM_ONOFF, false)
		Settings.drawing:addParam("myHero", "Draw My Range", SCRIPT_PARAM_ONOFF, true)
        Settings.drawing:addParam("myColor", "Draw My Range Color", SCRIPT_PARAM_COLOR, {0, 100, 44, 255})
		Settings.drawing:addParam("qDraw", "Draw "..SkillQ.name.." (Q) Range", SCRIPT_PARAM_ONOFF, true)
		Settings.drawing:addParam("qColor", "Draw "..SkillQ.name.." (Q) Color", SCRIPT_PARAM_COLOR, {0, 100, 44, 255})
		Settings.drawing:addParam("wDraw", "Draw "..SkillW.name.." (W) Range", SCRIPT_PARAM_ONOFF, true)
		Settings.drawing:addParam("wColor", "Draw "..SkillW.name.." (W) Color", SCRIPT_PARAM_COLOR, {0, 100, 44, 255})
		Settings.drawing:addParam("eDraw", "Draw "..SkillE.name.." (E) Range", SCRIPT_PARAM_ONOFF, true)
		Settings.drawing:addParam("eColor", "Draw "..SkillE.name.." (E) Color", SCRIPT_PARAM_COLOR, {0, 100, 44, 255})
		Settings.drawing:addParam("rDraw", "Draw "..SkillR.name.." (R) Range", SCRIPT_PARAM_ONOFF, true)
		Settings.drawing:addParam("rColor", "Draw "..SkillR.name.." (R) Color", SCRIPT_PARAM_COLOR, {0, 100, 44, 255})
		
	Settings:addSubMenu("["..myHero.charName.."] - Skill Settings", "SSettings")

		Settings.SSettings:addSubMenu("["..myHero.charName.."] - Q Settings", "Qset")
			Settings.SSettings.Qset:addParam("autoQ", "Use Q automatically", SCRIPT_PARAM_ONOFF, true)
			Settings.SSettings.Qset:addParam("autoQmana","Min mana to use Q automatically", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
			Settings.SSettings.Qset:addParam("autoQhp","Max health to use Q automatically", SCRIPT_PARAM_SLICE, 80, 0, 100, 0)
			
	TargetSelector.name = "Soraka"
		Settings:addTS(TargetSelector)

	if SOWp then
		Settings:addSubMenu("["..myHero.charName.."] - Orbwalking Settings", "Orbwalking")
		SOWi:LoadToMenu(Settings.Orbwalking)
	end   
end

function CustomOnDraw()
	if not myHero.dead and not Settings.drawing.mDraw then 
		if SkillQ.ready then
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillQ.range, RGB(Settings.drawing.qColor[2], Settings.drawing.qColor[3], Settings.drawing.qColor[4]))
		end
		if SkillW.ready and Settings.drawing.wDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillW.range, RGB(Settings.drawing.wColor[2], Settings.drawing.wColor[3], Settings.drawing.wColor[4]))
		end
		if SkillE.ready and Settings.drawing.eDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillE.range, RGB(Settings.drawing.eColor[2], Settings.drawing.eColor[3], Settings.drawing.eColor[4]))
		end
		if SkillR.ready and Settings.drawing.rDraw then
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillR.range, RGB(Settings.drawing.rColor[2], Settings.drawing.rColor[3], Settings.drawing.rColor[4]))
		end
		if Settings.drawing.myHero then
			DrawCircle(myHero.x, myHero.y, myHero.z, 600, RGB(Settings.drawing.myColor[2], Settings.drawing.myColor[3], Settings.drawing.myColor[4]))
		end
	end
end

function GetCustomTarget()
	TargetSelector:update()
	if SelectedTarget ~= nil and ValidTarget(SelectedTarget, 1000) and (Ignore == nil or (Ignore.networkID ~= SelectedTarget.networkID)) then
		return SelectedTarget
	end
	if TargetSelector.target and not TargetSelector.target.dead and TargetSelector.target.type == myHero.type then
		return TargetSelector.target
	else
		return nil
	end
end

function CustomOnTick()
	TargetSelector:update()
	Target = GetCustomTarget()
	if SAC then
		if _G.AutoCarry.Keys.AutoCarry then
			_G.AutoCarry.Orbwalker:Orbwalk(Target)
		end
	end
	ComboKey = Settings.combo.comboKey
	
	Checks()
	
	if Settings.SSettings.Qset.autoQ then
		CastQ()
	end
	
	if ComboKey then
		Cast(Q)
	end
end

function GetEnemyCountInPos(pos, radius)
    local n = 0
    for _, enemy in ipairs(GetEnemyHeroes()) do
        if GetDistanceSqr(pos, enemy) <= radius * radius then n = n + 1 end 
    end
    return n
end

function CastQ()
	local bestenemy = nil
	local highestcount = 1	

	for i, enemy in pairs(myEnemyTable) do
        if GetDistance(enemy) <= SkillQ.range and SkillQ.ready and ValidTarget(enemy) then
			aoeCastPos, hitChance, nTargets = VP:GetCircularAOECastPosition(enemy, SkillQ.delay, SkillQ.width, SkillQ.range, SkillQ.speed, myHero)
			
			if GetEnemyCountInPos(aoeCastPos, SkillQ.width) > highestcount then
				highestcount = GetEnemyCountInPos(aoeCastPos, SkillQ.width)
				bestenemy = enemy
			end
		end
    end
	
	if bestenemy ~= nil and ValidTarget(bestenemy) and GetDistance(bestenemy) <= SkillQ.range and SkillQ.ready then
		aoeCastPos, hitChance, nTargets = VP:GetCircularAOECastPosition(enemy, SkillQ.delay, SkillQ.width, SkillQ.range, SkillQ.speed, myHero)
		CastSpell(_Q, aoeCastPos.x, aoeCastPos.z)
	end
end