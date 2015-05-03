local version = "1.2"
local autoupdateenabled = true
local UPDATE_SCRIPT_NAME = "Anivia"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/gmzopper/BoL/Anivia.lua?rand="..math.random(1000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

local ServerData
if autoupdateenabled then
	GetAsyncWebResult(UPDATE_HOST, UPDATE_PATH, function(d) ServerData = d end)
	function update()
		if ServerData ~= nil then
			local ServerVersion
			local send, tmp, sstart = nil, string.find(ServerData, "local version = \"")
			if sstart then
				send, tmp = string.find(ServerData, "\"", sstart+1)
			end
			if send then
				ServerVersion = string.sub(ServerData, sstart+1, send-1)
			end

			if ServerVersion ~= nil and tonumber(ServerVersion) ~= nil and tonumber(ServerVersion) > tonumber(version) then
				DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> successfully updated. ("..version.." => "..ServerVersion.."). Press F9 Twice to Re-load.</font>") end)     
			elseif ServerVersion then
				print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> You have got the latest version: <u><b>"..ServerVersion.."</b></u></font>")
			end		
			ServerData = nil
		end
	end
	AddTickCallback(update)
end

if myHero.charName ~= "Anivia" then return end   

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
	TargetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1100, DAMAGE_MAGICAL, false, true)
	Variables()
	Menu()
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
			DrawCircle(myHero.x, myHero.y, myHero.z, myHero.range, RGB(Settings.drawing.myColor[2], Settings.drawing.myColor[3], Settings.drawing.myColor[4]))
		end
	end
end
 
function GetCustomTarget()
	TargetSelector:update()
	if SelectedTarget ~= nil and ValidTarget(SelectedTarget, 1100) and (Ignore == nil or (Ignore.networkID ~= SelectedTarget.networkID)) then
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
	autoR = Settings.SSettings.Rset.autoR
	autoE = Settings.SSettings.Eset.autoE
	Checks()
	
	DetQ()
	CancelR()
	KS()
	
	if autoE then
		CastE()
	end
	
	if Target ~= nil then
		if ComboKey then
			Combo(Target)
		end
	end
end

function Combo(unit)
	if ValidTarget(unit) and unit ~= nil and unit.type == myHero.type then
		if Settings.combo.useQ then
			CastQ(unit)
		end
		
		if Settings.combo.useE then
			CastE()
		end
		
		if Settings.combo.useR then
			CastR(unit)
		end
	end
end

function Checks()
	SkillQ.ready = (myHero:CanUseSpell(_Q) == READY)
	SkillW.ready = (myHero:CanUseSpell(_W) == READY)
	SkillE.ready = (myHero:CanUseSpell(_E) == READY)
	SkillR.ready = (myHero:CanUseSpell(_R) == READY)

	 _G.DrawCircle = _G.oldDrawCircle
end
 
function Menu()
	Settings = scriptConfig("MyAnivia", "Zopper")
   
	Settings:addSubMenu("["..myHero.charName.."] - Combo Settings (SBTW)", "combo")
		Settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		Settings.combo:addParam("useQ", "Use (Q) in Combo", SCRIPT_PARAM_ONOFF, true)
		Settings.combo:addParam("useE", "Use (E) in Combo", SCRIPT_PARAM_ONOFF, true)
		Settings.combo:addParam("useR", "Use (R) in Combo", SCRIPT_PARAM_ONOFF, true)
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
		Settings.drawing:addParam("targetcircle", "Draw Circle On Target", SCRIPT_PARAM_ONOFF, true)
   
	Settings:addSubMenu("["..myHero.charName.."] - Skill Settings", "SSettings")

		Settings.SSettings:addSubMenu("["..myHero.charName.."] - Q Settings", "Qset")
			Settings.SSettings.Qset:addParam("Qdet", "Detonate Q on 1st contact", SCRIPT_PARAM_ONOFF, true)
			Settings.SSettings.Qset:addParam("rand1", "if ^ is false, will detonate on target only", SCRIPT_PARAM_INFO, "")
			
		Settings.SSettings:addSubMenu("["..myHero.charName.."] - E Settings", "Eset")	
			Settings.SSettings.Eset:addParam("autoE", "Auto E", SCRIPT_PARAM_ONOFF, true)
			Settings.SSettings.Eset:addParam("Echilled", "Only E chilled targets", SCRIPT_PARAM_ONOFF, true)
			
		Settings.SSettings:addSubMenu("["..myHero.charName.."] - R Settings", "Rset")	
			Settings.SSettings.Rset:addParam("cancelR", "Cancel ULT", SCRIPT_PARAM_ONOFF, true)
			Settings.SSettings.Rset:addParam("autoR", "Cast ULT automatically on stunned", SCRIPT_PARAM_ONOFF, true)
		
	Settings:addSubMenu("["..myHero.charName.."] - KS", "KS")
		Settings.KS:addParam("ksQ", "KS with Q", SCRIPT_PARAM_ONOFF, true)
		Settings.KS:addParam("ksE", "KS with E", SCRIPT_PARAM_ONOFF, true)
		Settings.KS:addParam("ksR", "KS with R", SCRIPT_PARAM_ONOFF, true)
		Settings.KS:addParam("ksIgnite", "KS with Ignite", SCRIPT_PARAM_ONOFF, true)
   
	TargetSelector.name = "Nautilus"
		Settings:addTS(TargetSelector)

	if SOWp then
		Settings:addSubMenu("["..myHero.charName.."] - Orbwalking Settings", "Orbwalking")
		SOWi:LoadToMenu(Settings.Orbwalking)
	end   
end
 
function Variables()
	SkillQ = { name = "Flash Frost", range = 1100, delay = 0.25, speed = 850, width = 150, ready = false }
	SkillW = { name = "Crystallize", range = 1000, delay = 0.5, speed = math.huge, width = nil, ready = false }
	SkillE = { name = "Frostbite", range = 650, delay = nil, speed = math.huge, width = nil, ready = false }
	SkillR = { name = "Glacial Storm", range = 625, delay = 0.25, speed = math.huge, width = 210, ready = false }
	
	Qobject = nil
	Robject = nil
	Rscript = false
	
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

function OnProcessSpell(object, spell)
	if spell.name == myHero:GetSpellData(_Q).name then
		Qobject = object
	end
end

function OnCreateObj(object)
	if object.name == "cryo_FlashFrost_Player_mis.troy" then
		Qobject = object
	end
	
	if object.name == "cryo_storm_green_team.troy" then
		Robject = object
	end
end

function OnApplyBuff(source, unit, buff)
	if buff.name == "Stun" then
		for i, enemy in pairs(myEnemyTable) do
            if unit.name == enemy.name then
				if autoR then
					Rscript = true
					CastSpell(_R, unit.x, unit.z)
				end
			end
        end
	end
end

function OnDeleteObj(object)
	if object.name == "cryo_FlashFrost_mis.troy" then
		Qobject = nil
	end
	
	if object.name == "cryo_storm_green_team.troy" then
		Robject = nil
		Rscript = false
	end
end

function DetQ()
	if Settings.SSettings.Qset.Qdet then
		for i=1, heroManager.iCount, 1 do
			local champ = heroManager:GetHero(i)
			if champ.team ~= myHero.team then
				if GetDistance(champ, Qobject) < 150 then
					CastSpell(_Q)
				end
			end
		end
	else
		if GetDistance(Target, Qobject) < 150 then
			CastSpell(_Q)
		end
	end
end

function CastQ(unit)
	if unit ~= nil and GetDistance(unit) <= SkillQ.range and SkillQ.ready and Qobject == nil then                    
		CastPosition,  HitChance,  Position = VP:GetLineCastPosition(unit, SkillQ.delay, SkillQ.width,Settings.combo.rangeQ, SkillQ.speed, myHero, true)       
		CastSpell(_Q, CastPosition.x, CastPosition.z)
	end
end    

function CastE()
	for i, enemy in pairs(myEnemyTable) do
        if GetDistance(enemy) <= SkillE.range then
			if SkillE.ready then
				if Settings.SSettings.Eset.Echilled then
					if TargetHaveBuff("chilled", enemy) then
						CastSpell(_E, enemy)
					end
				else
					CastSpell(_E, enemy)
				end
			end
		end
    end
end

function CastR(unit)
	if Robject == nil and SkillR.ready and GetDistance(unit) < SkillR.range then
		Rscript = true
		CastSpell(_R, unit)
	end
end

function CancelR()
	if Robject ~= nil and Rscript == true then
		local rcount = 0
		for i, enemy in pairs(myEnemyTable) do
			if GetDistance(enemy, Robject) < SkillR.range then
				rcount = rcount + 1
			end
		end
		
		if rcount == 0 then
			Rscript = false
			CastSpell(_R) 
		end
	end
end

function KS()
	for _, unit in pairs(GetEnemyHeroes()) do
		local health = unit.health
		local dmgR = getDmg("R", unit, myHero) + (myHero.ap)
		local dmgQ = getDmg("Q", unit, myHero) + (myHero.ap)
		if health < dmgQ * 0.95 and Settings.killsteal.useQ and ValidTarget(unit) then
			CastQ(unit)
		elseif health < dmgR * 0.95 and Settings.killsteal.useR and ValidTarget(unit) then
			CastR(unit)
		end
	 end
end

function KS()
	for _, champ in pairs(GetEnemyHeroes()) do
		if ValidTarget(champ) and GetDistance(champ, myHero) < 1100 then
			local Qdmg = getDmg("Q", champ, myHero)
			local Edmg = getDmg("E", champ, myHero)
			local Rdmg = getDmg("R", champ, myHero)
			local Idmg = getDmg("IGNITE", champ, myHero)
			
			if Settings.KS.ksQ and champ.health < Qdmg * 0.95 and ValidTarget(champ) then
				CastQ(champ)
			end
			
			if Settings.KS.ksE and GetDistance(champ, myHero) < 650 and champ.health < Edmg * 0.95 and ValidTarget(champ) then
				CastSpell(_E, champ)
			end
			
			if Settings.KS.ksR and GetDistance(champ) < SkillR.range and champ.health < Rdmg and ValidTarget(champ) then
				CastR(unit)
			end
			
			if Settings.KS.ksI and GetDistance(champ) < 500 and champ.health < Idmg and ValidTarget(champ) then
				CastSpell(ignite, champ)
			end
		end
	end
end