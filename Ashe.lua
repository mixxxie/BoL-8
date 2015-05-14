local version = "1.0"
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/gmzopper/BoL/master/Ashe.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function _AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>Ashe:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/gmzopper/BoL/master/version/Ashe.version")
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

if myHero.charName ~= "Ashe" then return end   

require("VPrediction")

if VIP_USER and FileExist(LIB_PATH .. "/DivinePred.lua") then 
	require "DivinePred" 
	dp = DivinePred()
	wpred = LineSS(2000, 1200, 50, 0.25, 0)
	rpred = LineSS(1600, math.huge, 130, 0.25, math.huge)
end

----------------------
--     Variables    --
----------------------

pred = nil
enemyTick = {}
lastPosition = {}
lastWCheck = 0
lastRCheck = 0
canCastQ = false

Item = {
		BOTRK = {Slot = nil, Ready = nil},
		BC    = {Slot = nil, Ready = nil},
		YMG   = {Slot = nil, Ready = nil}
}

MyTrueRange = (600 + GetDistance(myHero.minBBox))

spells = {}
spells.q = {name = myHero:GetSpellData(_Q).name, ready = false}
spells.w = {name = myHero:GetSpellData(_W).name, ready = false, range = 1200, width = 50, speed = 2000, delay = 0.25}
spells.e = {name = myHero:GetSpellData(_E).name, ready = false, range = math.huge}
spells.r = {name = myHero:GetSpellData(_R).name, ready = false, range = math.huge, width = 130, speed = 1600, delay = 0.25}

Interrupt = {
	["Katarina"] = {charName = "Katarina", stop = {["KatarinaR"] = {name = "Death lotus", spellName = "KatarinaR", ult = true }}},
	["Nunu"] = {charName = "Nunu", stop = {["AbsoluteZero"] = {name = "Absolute Zero", spellName = "AbsoluteZero", ult = true }}},
	["Malzahar"] = {charName = "Malzahar", stop = {["AlZaharNetherGrasp"] = {name = "Nether Grasp", spellName = "AlZaharNetherGrasp", ult = true}}},
	["Caitlyn"] = {charName = "Caitlyn", stop = {["CaitlynAceintheHole"] = {name = "Ace in the hole", spellName = "CaitlynAceintheHole", ult = true, projectileName = "caitlyn_ult_mis.troy"}}},
	["FiddleSticks"] = {charName = "FiddleSticks", stop = {["Crowstorm"] = {name = "Crowstorm", spellName = "Crowstorm", ult = true}}},
	["Galio"] = {charName = "Galio", stop = {["GalioIdolOfDurand"] = {name = "Idole of Durand", spellName = "GalioIdolOfDurand", ult = true}}},
	["Janna"] = {charName = "Janna", stop = {["ReapTheWhirlwind"] = {name = "Monsoon", spellName = "ReapTheWhirlwind", ult = true}}},
	["MissFortune"] = {charName = "MissFortune", stop = {["MissFortune"] = {name = "Bullet time", spellName = "MissFortuneBulletTime", ult = true}}},
	["Pantheon"] = {charName = "Pantheon", stop = {["PantheonRJump"] = {name = "Skyfall", spellName = "PantheonRJump", ult = true}}},
	["Shen"] = {charName = "Shen", stop = {["ShenStandUnited"] = {name = "Stand united", spellName = "ShenStandUnited", ult = true}}},
	["Urgot"] = {charName = "Urgot", stop = {["UrgotSwap2"] = {name = "Position Reverser", spellName = "UrgotSwap2", ult = true}}},
	["Warwick"] = {charName = "Warwick", stop = {["InfiniteDuress"] = {name = "Infinite Duress", spellName = "InfiniteDuress", ult = true}}},
}

-- Spell cooldown check
function readyCheck()
	spells.q.ready, spells.w.ready, spells.e.ready, spells.r.ready = (myHero:CanUseSpell(_Q) == READY), (myHero:CanUseSpell(_W) == READY), (myHero:CanUseSpell(_E) == READY), (myHero:CanUseSpell(_R) == READY)
	
	Item.BOTRK.Slot = GetInventorySlotItem(3153)
	Item.BC.Slot = GetInventorySlotItem(3144)
	Item.YMG.Slot = GetInventorySlotItem(3142)

	Item.BOTRK.Ready = (Item.BOTRK.Slot ~= nil) and (myHero:CanUseSpell(Item.BOTRK.Slot) == READY)
	Item.BC.Ready = (Item.BC.Slot ~= nil) and (myHero:CanUseSpell(Item.BC.Slot) == READY)
	Item.YMG.Ready = (Item.YMG.Slot ~= nil) and (myHero:CanUseSpell(Item.YMG.Slot) == READY)
end

-- Orbwalker check
function orbwalkCheck()
	if _G.AutoCarry then
		PrintChat("SA:C detected, support enabled.")
		SACLoaded = true
	elseif _G.MMA_Loaded then
		PrintChat("MMA detected, support enabled.")
		MMALoaded = true
	else
		PrintChat("SA:C/MMA not running, loading SxOrbWalk.")
		require("SxOrbWalk")
		SxMenu = scriptConfig("SxOrbWalk", "SxOrbb")
		SxOrb:LoadToMenu(SxMenu)
		SACLoaded = false
	end
end

----------------------
--   Calculations   --
----------------------

function getTarg(t)
	ts:update()
	if _G.AutoCarry and ValidTarget(_G.AutoCarry.Crosshair:GetTarget()) then _G.AutoCarry.Crosshair:SetSkillCrosshairRange(1200) return _G.AutoCarry.Crosshair:GetTarget() end		
	if ValidTarget(SelectedTarget) and SelectedTarget.type == myHero.type then return SelectedTarget end
	if MMALoaded and ValidTarget(_G.MMA_Target) then return _G.MMA_Target end
	return ts.target
end

function GetEnemyCountInPos(pos, radius)
    local n = 0
    for _, enemy in ipairs(GetEnemyHeroes()) do
        if GetDistanceSqr(pos, enemy) <= radius * radius and ValidTarget(enemy) then n = n + 1 end 
    end
    return n
end

function getHealthPercent(unit)
    local obj = unit or myHero
    return (obj.health / obj.maxHealth) * 100
end

function getManaPercent(unit)
    local obj = unit or myHero
    return (obj.mana / obj.maxMana) * 100
end

function isRecall(hero)
	if hero ~= nil and ValidTarget(hero) then 
		for i = 1, hero.buffCount, 1 do
			local buff = hero:getBuff(i)
			if buff == "Recall" or buff == "SummonerTeleport" or buff == "RecallImproved" then return true end
		end
    end
	return false
end

----------------------
--      Hooks       --
----------------------

-- Init hook
function OnLoad()
	print("<font color='#009DFF'>[Ashe]</font><font color='#FFFFFF'> has loaded!</font> <font color='#2BFF00'>[v"..version.."]</font>")
	print("<font color='#009DFF'>[Ashe]</font><font color='#FFFFFF'> - do NOT reload script while you have Frost buff</font>")

	if autoupdate then
		update()
	end

	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1200, DAMAGE_PHYSICAL, true)
	pred = VPrediction()
	Menu()

	DelayAction(orbwalkCheck,7)
end

-- Tick hook
function OnTick()
	readyCheck()
	Target = getTarg()
	
	if settings.combo.comboKey and ValidTarget(Target) then
		if settings.combo.w then
			CastW(Target)
		end
		
		if settings.combo.r and GetDistance(Target) < settings.combo.rRange then
			CastR(Target)
		end
		
		if settings.combo.q then
			CastQ(Target)
		end
		
		if settings.combo.e then
			CastE()
		end
	end
	
	if settings.w.autoW and ValidTarget(Target) and not isRecall(myHero) then
		if getManaPercent() > settings.w.autoWmana then
			CastW(Target)
		end
	end
	
	if settings.ult.fireKey and ValidTarget(Target) then
		CastR(Target)
	end
	
	Killsteal()
	UseItems()
end

-- Drawing hook
function OnDraw()
	if myHero.dead then return end
	
	Target = getTarg()
	
	if settings.draw.target and ValidTarget(Target) then
		DrawCircle(Target.x, Target.y, Target.z, 150, 0xffffff00)
	end
	
	if settings.draw.w and spells.w.ready then
		DrawCircle(myHero.x, myHero.y, myHero.z, spells.w.range, 0xFFFF0000)
	end
end

function OnCreateObj(object)
	if GetDistance(object) < 20 then
		if object.name == "Ashe_Base_Q_ready.troy" then
			canCastQ = true
		end
	end
end

function OnDeleteObj(object)
	if GetDistance(object) < 20 then
		if object.name == "Ashe_Base_Q_ready.troy" then
			canCastQ = false
		end
	end
end

function OnProcessSpell(object, spellProc)
	if myHero.dead then return end
	if object.team == myHero.team then return end
	
	if Interrupt[object.charName] ~= nil then
		spell = Interrupt[object.charName].stop[spellProc.name]
		if spell ~= nil then
			if settings.interrupt[spellProc.name] then
				if GetDistance(object) < settings.interrupt.interruptRange and spells.r.ready and settings.interrupt.r then
					CastSpell(_R, object.x, object.z)
				end
			end
		end
	end
end

-- Menu creation
function Menu()
	settings = scriptConfig("Ashe", "Zopper")
	TargetSelector.name = "Ashe"
	settings:addTS(ts)
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Combo", "combo")
		settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		settings.combo:addParam("q", "Use Q", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("w", "Use W", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("e", "Use E", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("r", "Use R", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("rRange", "KS with R range", SCRIPT_PARAM_SLICE, 1000, 1, 1500, 0)
		settings.combo:permaShow("comboKey")
		
	settings:addSubMenu("[" .. myHero.charName.. "] - Auto W", "w")
		settings.w:addParam("autoW", "Auto W", SCRIPT_PARAM_ONOFF, true)
		settings.w:addParam("autoWmana", "Minimum Mana", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Ult Helper", "ult")
		settings.ult:addParam("fireKey", "Fire ult on Target", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
		settings.ult:permaShow("fireKey")
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Killsteal Settings", "ks")
		settings.ks:addParam("r", "KS with R", SCRIPT_PARAM_ONOFF, true)
		settings.ks:addParam("rRange", "KS with R range", SCRIPT_PARAM_SLICE, 1000, 1, 1500, 0)
	
	settings:addSubMenu("Items Settings", "item")
		settings.item:addParam("BOTRK", "Use Ruined King", SCRIPT_PARAM_ONOFF, true)
		settings.item:addParam("BC", "Use Bilgewater Cutlass", SCRIPT_PARAM_ONOFF, true)
		settings.item:addParam("YMG", "Use Youmouu's Ghostblade", SCRIPT_PARAM_ONOFF, true)
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Auto-Interrupt", "interrupt")
		settings.interrupt:addParam("interruptRange", "Interrupt Range", SCRIPT_PARAM_SLICE, 1000, 1, 1500, 0)
		settings.interrupt:addParam("r", "Interrupt with R", SCRIPT_PARAM_ONOFF, true)
		for i, a in pairs(GetEnemyHeroes()) do
			if Interrupt[a.charName] ~= nil then
				for i, spell in pairs(Interrupt[a.charName].stop) do
					settings.interrupt:addParam(spell.spellName, a.charName.." - "..spell.name, SCRIPT_PARAM_ONOFF, true)
				end
			end
		end
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Drawing", "draw")
		settings.draw:addParam("w", "Draw W", SCRIPT_PARAM_ONOFF, true)
		settings.draw:addParam("target", "Draw Target", SCRIPT_PARAM_ONOFF, true)
	
    settings:addParam("pred", "Prediction Type", SCRIPT_PARAM_LIST, 1, { "VPrediction", "DivinePred"})
end


--Lag Free Circles
function DrawCircle(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
		
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 300) 
	end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(40, Round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
	quality = 2 * math.pi / quality
	radius = radius * .92
	local points = {}
		
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)	
end

function Round(number)
	if number >= 0 then 
		return math.floor(number+.5) 
	else 
		return math.ceil(number-.5) 
	end
end

function distance(x , z)
	return math.sqrt((myHero.x - x) ^ 2 + (myHero.z - z) ^ 2) 
end

----------------------
--  Cast functions  --
----------------------

function CastQ(Target)
	if spells.q.ready and canCastQ and GetDistance(Target) < MyTrueRange then
		CastSpell(_Q)
	end
end

function CastW(unit)
	if ValidTarget(unit) and GetDistance(unit) <= spells.w.range and spells.w.ready then
		if settings.pred == 1 then
			local castPos, chance, pos = pred:GetLineCastPosition(unit, spells.w.delay, spells.w.width, spells.w.range, spells.w.speed, myHero, true)
			if chance >= 2 then
				CastSpell(_W, castPos.x, castPos.z)
			end
		elseif settings.pred == 2 and VIP_USER and (os.clock() * 1000 - lastWCheck) > 200 then	
			local targ = DPTarget(unit)
			local state,hitPos,perc = dp:predict(targ, wpred)
			
			lastWCheck = os.clock() * 1000
			
			if state == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_W, hitPos.x, hitPos.z)
			end
		end
	end
end

function CastE()
	if myHero.dead then return end

	for i = 1, heroManager.iCount, 1 do
        local enemy = heroManager:getHero(i)
		
		if enemy.visible == false and enemy.dead == false and enemy.team ~= myHero.team then
			if enemyTick[i] == nil then
				enemyTick[i] = os.clock() * 1000
			end

			unittraveled = enemy.ms * (os.clock() * 1000 - enemyTick[i])
			if lastPosition[i] ~= nil then
				if unittraveled < 1000 and distance(lastPosition[i].x, lastPosition[i].z) < 1000 then
					CastSpell(_E, lastPosition[i].x, lastPosition[i].z)
				end
			end
		elseif enemy.team ~= myHero.team and enemy.visible then
			enemyTick[i] = nil
			lastPosition[i] = {x = enemy.x, z = enemy.z}
		end
	end
end

function CastR(unit)
	if ValidTarget(unit) and spells.r.ready then
		if settings.pred == 1 then
			local castPos, chance, pos = pred:GetLineCastPosition(unit, spells.r.delay, spells.r.width, spells.r.range, spells.r.speed, myHero, true)
			if chance >= 2 then
				CastSpell(_R, castPos.x, castPos.z)
			end
		elseif settings.pred == 2 and VIP_USER and (os.clock() * 1000 - lastRCheck) > 200 then	
			local targ = DPTarget(unit)
			local state,hitPos,perc = dp:predict(targ, rpred)
			
			lastRCheck = os.clock() * 1000
			
			if state == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_R, hitPos.x, hitPos.z)
			end
		end
	end
end

function Killsteal()
	local enemies = GetEnemyHeroes()
	for i, enemy in pairs(enemies) do
		if settings.ks.r then
			if GetDistance(enemy) < settings.ks.rRange and ValidTarget(enemy) then
				if getDmg("R", enemy, myHero) > enemy.health then
					CastR(enemy)
				end
			end
		end
	end
end

function UseItems(Target)
	if Target ~= nil and ValidTarget(Target) then
		if settings.item.BOTRK and GetDistance(Target) < 450 then
			if Item.BOTRK.Ready then
				CastSpell(Item.BOTRK.Slot, Target)
			end
		end

		if settings.item.BC and GetDistance(Target) < 450 then
			if Item.BC.Ready then
				CastSpell(Item.BC.Slot, Target)
			end
		end

		if settings.item.useYMG and GetDistance(Target) < MyTrueRange then
			if Item.YMG.Ready then
				CastSpell(Item.YMG.Slot)
			end
		end
	end
end