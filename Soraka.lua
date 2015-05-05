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

require("VPrediction") --vpred
require("DivinePred") -- divinepred
require("HPrediction") -- hpred

local processTime  = os.clock()*1000
local enemyChamps = {}
local dp = DivinePred()
local pred = nil

----------------------
--     Variables    --
----------------------

local spells = {}
spells.q = {name = myHero:GetSpellData(_Q).name, ready = false, range = 970, width = 250}
spells.w = {name = myHero:GetSpellData(_W).name, ready = false, range = 550, width = nil}
spells.e = {name = myHero:GetSpellData(_E).name, ready = false, range = 925, width = 250}
spells.r = {name = myHero:GetSpellData(_R).name, ready = false, range = nil, width = nil}

Interrupt = {
	["Katarina"] = {charName = "Katarina", stop = {["KatarinaR"] = {name = "Death lotus", spellName = "KatarinaR", ult = true }}},
	["Nunu"] = {charName = "Nunu", stop = {["AbsoluteZero"] = {name = "Absolute Zero", spellName = "AbsoluteZero", ult = true }}},
	["Malzahar"] = {charName = "Malzahar", stop = {["AlZaharNetherGrasp"] = {name = "Nether Grasp", spellName = "AlZaharNetherGrasp", ult = true}}},
	["Caitlyn"] = {charName = "Caitlyn", stop = {["CaitlynAceintheHole"] = {name = "Ace in the hole", spellName = "CaitlynAceintheHole", ult = true, projectileName = "caitlyn_ult_mis.troy"}}},
	["FiddleSticks"] = {charName = "FiddleSticks", stop = {["Crowstorm"] = {name = "Crowstorm", spellName = "Crowstorm", ult = true}}},
	["Galio"] = {charName = "Galio", stop = {["GalioIdolOfDurand"] = {name = "Idole of Durand", spellName = "GalioIdolOfDurand", ult = true}}},
	["MissFortune"] = {charName = "MissFortune", stop = {["MissFortune"] = {name = "Bullet time", spellName = "MissFortuneBulletTime", ult = true}}},
	["Pantheon"] = {charName = "Pantheon", stop = {["PantheonRJump"] = {name = "Skyfall", spellName = "PantheonRJump", ult = true}}},
	["Shen"] = {charName = "Shen", stop = {["ShenStandUnited"] = {name = "Stand united", spellName = "ShenStandUnited", ult = true}}},
	["Urgot"] = {charName = "Urgot", stop = {["UrgotSwap2"] = {name = "Position Reverser", spellName = "UrgotSwap2", ult = true}}},
	["Warwick"] = {charName = "Warwick", stop = {["InfiniteDuress"] = {name = "Infinite Duress", spellName = "InfiniteDuress", ult = true}}},
}

-- Spell cooldown check
function readyCheck()
	spells.q.ready, spells.w.ready, spells.e.ready, spells.r.ready = (myHero:CanUseSpell(_Q) == READY), (myHero:CanUseSpell(_W) == READY), (myHero:CanUseSpell(_E) == READY), (myHero:CanUseSpell(_R) == READY)
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
--  Cast functions  --
----------------------

local qpred = CircleSS(math.huge, 970, 150, .25, 1300)
local wpred = LineSS(math.huge, 925, 210, .25, math.huge)

function CastQ()
	local closestdistance = 975
	local enemycount = 0
	local unit = nil

	for i, enemy in ipairs(GetEnemyHeroes()) do
        if GetEnemyCountInPos(enemy, 250) > enemycount and GetDistance(enemy) <= spells.q.range then
			unit = enemy
			enemycount = GetEnemyCountInPos(enemy, 250)
			closestdistance = GetDistance(enemy)
		elseif GetEnemyCountInPos(enemy, 250) == enemycount and GetDistance(enemy) <= closestdistance then
			unit = enemy
			enemycount = GetEnemyCountInPos(enemy, 250)
			closestdistance = GetDistance(enemy)
		end
    end

	if settings.pred == 1 and ValidTarget(unit, spells.q.range) then
    	local castPos, chance, pos = pred:GetCircularCastPosition(unit, .25, 250, 975, 1300, myHero, false)
    	if  spells.q.ready and chance >= 2 then
    	    CastSpell(_Q, castPos.x, castPos.z)
    	end
    elseif settings.pred == 2 and ValidTarget(unit, spells.q.range) then
    	local targ = DPTarget(unit)
    	local state,hitPos,perc = dp:predict(targ, qpred)
    	if spells.q.ready and state == SkillShot.STATUS.SUCCESS_HIT then
       		CastSpell(_Q, hitPos.x, hitPos.z)
      	end
	elseif settings.pred == 3 and ValidTarget(unit, spells.q.range) then
		local pos, chance = HPred:GetPredict("Q", unit, myHero) 
		if spells.q.ready and chance >= 2 then
			CastSpell(_Q, pos.x, pos.z)
		end
	end
end

function AutoUltimate()
	for i, ally in ipairs(GetAllyHeroes()) do

		------------------------------
		if ally.dead then return end
		if myHero.dead then return end
		------------------------------

		if spells.r.ready and Menu.ult.UseUlt then
			if Menu.ult.UltCast == 2 then
				if (ally.health / ally.maxHealth < Menu.ult.UltManager /100) then
					if Menu.ult.UltMode == 1 then
						CastSpell(_R)
					elseif Menu.ult.UltMode == 2 then
						if GetDistance(ally, myHero) <= 1500 then
							CastSpell(_R)
						end
					end
				end
			elseif Menu.ult.UltCast == 1 then
				if (myHero.health / myHero.maxHealth < Menu.ult.UltManager2 /100) then
					CastSpell(_R)
				end
			elseif Menu.ult.UltCast == 3 then
				if (ally.health / ally.maxHealth < Menu.ult.UltManager /100) or (myHero.health / myHero.maxHealth < Menu.ult.UltManager2 /100) then
					if Menu.ult.UltMode == 1 then
						CastSpell(_R)
					elseif Menu.ult.UltMode == 2 then
						if GetDistance(ally, myHero) <= 1500 then
							CastSpell(_R)
						end
					end
				end
			end
		end
    end
end

function AutoHeal()
	local ally = GetBestHealTarget()

	if spells.w.ready and settings.heal.UseHeal then
		if (ally.health / ally.maxHealth < settings.heal.HealManager /100) and (myHero.health / myHero.maxHealth > settings.heal.HPManager /100) then
			if GetDistance(ally, myHero) <= spells.w.range then
				CastSpell(_W, ally)
			end
		end
	end
end

----------------------
--   Calculations   --
----------------------
-- Target Calculation
function getTarg()
	ts:update()
	if _G.AutoCarry and ValidTarget(_G.AutoCarry.Crosshair:GetTarget()) then _G.AutoCarry.Crosshair:SetSkillCrosshairRange(1200) return _G.AutoCarry.Crosshair:GetTarget() end		
	if ValidTarget(SelectedTarget) then return SelectedTarget end
	if MMALoaded and ValidTarget(_G.MMA_Target) then return _G.MMA_Target end
	return ts.target
end

function GetEnemyCountInPos(pos, radius)
    local n = 0
    for _, enemy in ipairs(GetEnemyHeroes()) do
        if GetDistanceSqr(pos, enemy) <= radius * radius then n = n + 1 end 
    end
    return n
end

function GetBestHealTarget()
    local leastHp = getHealthPercent(myHero) / GetEnemyCountInPos(myHero, 550)
    local leastHpAlly = myHero

    for _, ally in ipairs(GetAllyHeroes()) do
        local allyHpPct = getHealthPercent(ally) / GetEnemyCountInPos(myHero, 550)
        if allyHpPct <= leastHp and not ally.dead and GetDistance(ally) < spells.w.range then
            leastHp = allyHpPct
            leastHpAlly = ally
        end
    end

    return leastHpAlly
end

function getHealthPercent(unit)
    local obj = unit or myHero
    return (obj.health / obj.maxHealth) * 100
end

----------------------
--      Hooks       --
----------------------

-- Init hook
function OnLoad()
	print("<font color='#009DFF'>[Soraka]</font><font color='#FFFFFF'> has loaded!</font> <font color='#2BFF00'>[v"..version.."]</font>")

	if autoupdate then
		update()
	end

	for i = 1, heroManager.iCount do
    	local hero = heroManager:GetHero(i)
		if hero.team ~= myHero.team then enemyChamps[""..hero.networkID] = DPTarget(hero) end
	end

	ts = TargetSelector(TARGET_LOW_HP, 600, DAMAGE_PHYSICAL, false, true)
	creep = minionManager(MINION_ENEMY, 200, myHero, MINION_SORT_HEALTH_ASC)
	pred = VPrediction()
	HPred = HPrediction()
	hpload = true

	Menu()

	DelayAction(orbwalkCheck,7)

	if hpload then
		Spell_Q.type['Soraka'] = "DelayCircle"
  		Spell_Q.delay['Soraka'] = .25
  		Spell_Q.range['Soraka'] = 975
  		Spell_Q.radius['Soraka'] = 250
		Spell_Q.speed['Soraka'] = 1300
  		Spell_E.type['Soraka'] = "PromptCircle"
  		Spell_E.delay['Soraka'] = .25
  		Spell_E.range['Soraka'] = 925
  		Spell_E.radius['Soraka'] = 250
  	end
end

-- Tick hook
function OnTick()
	readyCheck()

	ts:update()

	local hp = myHero.health / myHero.maxHealth * 100
	local mana = myHero.mana / myHero.maxMana * 100

	if settings.ult.UseUlt then
        AutoUltimate()
    end
	
	if settings.heal.UseHeal then
        AutoHeal()
    end
	
	if settings.q.autoQ and hp <= settings.q.autoQhp and mana >= settings.q.autoQmana then
		CastQ()
	end
	
	if settings.combo.comboKey then
		CastQ()
	end
end

-- Drawing hook
function OnDraw()
	if myHero.dead then return end
	
	if settings.draw.q and spells.q.ready then
		DrawCircle(myHero.x, myHero.y, myHero.z, spells.q.range, ARGB(255,0,255,0))
	end

	if settings.draw.w and spells.w.ready then
		DrawCircle(myHero.x, myHero.y, myHero.z, spells.w.range, ARGB(255,255,255,0))
	end

	if settings.draw.e and spells.e.ready then
		DrawCircle(myHero.x, myHero.y, myHero.z, spells.e.range, ARGB(255,255,0,0))
	end
end

function OnProcessSpell(object, spellProc)
	if myHero.dead then return end
	if object.team ~= myHero.team then
		if Interrupt[object.charName] ~= nil then
			spell = Interrupt[object.charName].stop[spellProc.name]
			if spell ~= nil and spell.ult == true then
				if GetDistance(object) < spells.r.range then
					if settings.interrupt[spellProc.name] then
						CastSpell(_E, object.x, object.z)	
					end
				end
			end
		end
	end
end

-- Menu creation
function Menu()
	settings = scriptConfig("Soraka", "Zopper")
	TargetSelector.name = "Soraka"
	settings:addTS(ts)

	settings:addSubMenu("[" .. myHero.charName.. "] - Combo", "combo")
		settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		settings.combo:addParam("q", "Q", SCRIPT_PARAM_ONOFF, true)

	settings:addSubMenu("[" .. myHero.charName.. "] - Auto Q", "q")
		settings.q:addParam("autoQ", "Auto Q", SCRIPT_PARAM_ONOFF, true)
		settings.q:addParam("autoQmana", "My Minimum Mana", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)
		settings.q:addParam("autoQhp", "My Maximum HP", SCRIPT_PARAM_SLICE, 100, 0, 100, 0)	
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Auto Heal", "heal")        
        settings.heal:addParam("UseHeal", "Auto Heal Allies", SCRIPT_PARAM_ONOFF, true)
        settings.heal:addParam("HealManager", "Heal allies under", SCRIPT_PARAM_SLICE, 65, 0, 100, 0)
        settings.heal:addParam("HPManager", "Don't heal under (my hp)", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

	settings:addSubMenu("[" .. myHero.charName.. "] - Auto R", "ult")
		settings.ult:addParam("UseUlt", "Use ult", SCRIPT_PARAM_ONOFF, true)
        settings.ult:addParam("UltCast", "Auto Ultimate On: ", SCRIPT_PARAM_LIST, 3, {"Only Me", "Allies", "Both"})
        settings.ult:addParam("UltMode", "Auto Ultimate Mode: ", SCRIPT_PARAM_LIST, 1, {"Global",  "In Range"})
        settings.ult:addParam("UltManager", "Ultimate allies under", SCRIPT_PARAM_SLICE, 25, 0, 100, 0)
        settings.ult:addParam("UltManager2", "Ultimate me under", SCRIPT_PARAM_SLICE, 25, 0, 100, 0)
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Drawing", "draw")
		settings.draw:addParam("q", "Draw Q", SCRIPT_PARAM_ONOFF, true)
		settings.draw:addParam("w", "Draw W", SCRIPT_PARAM_ONOFF, true)
		settings.draw:addParam("e", "Draw E", SCRIPT_PARAM_ONOFF, true)
		settings.draw:addParam("target", "Draw Target", SCRIPT_PARAM_ONOFF, true)

	settings:addSubMenu("[" .. myHero.charName.. "] - Auto-Interrupt", "interrupt")
		for i, a in pairs(GetEnemyHeroes()) do
			if Interrupt[a.charName] ~= nil then
				for i, spell in pairs(Interrupt[a.charName].stop) do
					if spell.ult == true then
						settings.interrupt:addParam(spell.spellName, a.charName.." - "..spell.name, SCRIPT_PARAM_ONOFF, true)
					end
				end
			end
		end
	
			
    settings:addParam("pred", "Prediction Type", SCRIPT_PARAM_LIST, 1, { "VPrediction", "DivinePred", "HPred"})
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