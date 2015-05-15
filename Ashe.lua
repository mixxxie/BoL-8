local version = "1.09"
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

if not FileExist(LIB_PATH .. "/VPrediction.lua") then
	PrintChat("This script wont work without VPrediction. Please download it.")
	return
end

require "VPrediction"

if FileExist(LIB_PATH .. "/HPrediction.lua") then
	require "HPrediction"
	useHP = true
else
	useHP = false
	PrintChat("For better prediction please download HPrediction. The script WILL work without it though.")
end

if VIP_USER then
	if FileExist(LIB_PATH .. "/DivinePred.lua") then
		require "DivinePred" 
		useDP = true
		dp = DivinePred()
		wpred = LineSS(2000, 1200, 50, 0.25, 0)
		rpred = LineSS(1600, math.huge, 130, 0.25, math.huge)
		
	else
		useDP = false
		PrintChat("For better prediction please download DPrediction. The script WILL work without it though.")
	end
end

if FileExist(LIB_PATH .. "/spellDmg.lua") then
	require "spellDmg"
else	
	PrintChat("This script wont work without spellDmg library. Please download it and save it as 'spellDmg.lua'")
	return
end

----------------------
--     Variables    --
----------------------

pred = nil
enemyTick = {}
lastPosition = {}
lastWCheck = 0
lastRCheck = 0
qStackCount = 0
qStackExpire = 0

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
	
	if qStackCount > 0 and qStackExpire < os.clock() * 1000 then
		qStackCount = 0
	end
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

function getTarg()
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

	if autoupdate then
		update()
	end

	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1200, DAMAGE_PHYSICAL, true)
	pred = VPrediction()
	
	if useHP then
		HPred = HPrediction()
		HPred:AddSpell("W", 'Ashe', {collisionM = true, collisionH = true, delay = spells.w.delay, range = spells.w.range, speed = spells.w.speed, type = "DelayLine", width = spells.w.width})
		HPred:AddSpell("R", 'Ashe', {delay = spells.r.delay, range = math.huge, speed = spells.r.speed, type = "DelayLine", width = spells.r.width})
	end
	
	Menu()

	DelayAction(orbwalkCheck,7)
	AddUpdateBuffCallback(CustomUpdateBuff)	
end

-- Tick hook
function OnTick()
	readyCheck()
	Target = getTarg()
	
	if (settings.combo.comboKey or settings.combo.comboKeyNoUlt) and ValidTarget(Target) then
		UseItems(Target)
		
		if settings.combo.q then
			CastQ()
		end
		
		if settings.combo.w then
			if settings.combo.onlyWGap and GetDistance(Target) < MyTrueRange then return end
			if settings.combo.dontW and not wKSSoon() then
				CastW(Target)
			end
		end
		
		if settings.combo.r and ValidTarget(Target) and settings.combo.comboKey and GetDistance(Target) < settings.combo.rRange then
			if settings.combo.immobileR and Target.canMove == false then
				CastR(Target)
			elseif not settings.combo.immobileR then
				CastR(Target)
			end
		end
		
		if settings.combo.e then
			CastE()
		end
	end
	
	if settings.w.autoW and ValidTarget(Target) and not isRecall(myHero) then
		if getManaPercent() > settings.w.autoWmana then
			if settings.combo.dontW and not wKSSoon() then
				CastW(Target)
			end
		end
	end
	
	if settings.ult.fireKey and ValidTarget(Target) then
		CastR(Target)
	end
	
	Killsteal()
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

function CustomUpdateBuff(unit,buff)
	if unit then
		if unit.type == myHero.type then
			if unit.team == myHero.team then
				if buff.name == "AsheQ" then
					if qStackCount < 5 then
						qStackCount = qStackCount + 1
					else
						qStackCount = 5
					end
					
					qStackExpire = (os.clock() + 4) * 1000
				end
				
				if buff.name == "asheqcastready" then
					qStackCount = 5
					qStackExpire = (os.clock() + 4) * 1000
				end
				
				if buff.name == "asheqbuff" then
					qStackCount = 0
				end
			end
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
		settings.combo:addParam("comboKeyNoUlt", "Combo Key WITHOUT Ult", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Y"))
		settings.combo:addParam("q", "Use Q", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("H"))
		settings.combo:addParam("w", "Use W", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("dontW", "Dont use W if can use it to KS soon", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("onlyWGap", "Only use W if not in range for AA", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("e", "Use E", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("r", "Use R", SCRIPT_PARAM_ONOFF, true)
		settings.combo:addParam("immobileR", "Only use R on Immobile", SCRIPT_PARAM_ONOFF, false)
		settings.combo:addParam("rRange", "R range", SCRIPT_PARAM_SLICE, 1000, 1, 1500, 0)
		settings.combo:permaShow("comboKey")
		settings.combo:permaShow("q")
		
	settings:addSubMenu("[" .. myHero.charName.. "] - Auto W", "w")
		settings.w:addParam("autoW", "Auto W", SCRIPT_PARAM_ONOFF, true)
		settings.w:addParam("autoWmana", "Minimum Mana", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Ult Helper", "ult")
		settings.ult:addParam("fireKey", "Fire ult on Target", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
		settings.ult:permaShow("fireKey")
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Killsteal Settings", "ks")
		settings.ks:addParam("w", "KS with W", SCRIPT_PARAM_ONOFF, true)
		settings.ks:addParam("r", "KS with R", SCRIPT_PARAM_ONOFF, true)
		settings.ks:addParam("rRange", "KS with R range", SCRIPT_PARAM_SLICE, 1000, 1, 1500, 0)
	
	settings:addSubMenu("[" .. myHero.charName.. "] - Items Settings", "item")
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
	
    settings:addParam("pred", "Prediction Type", SCRIPT_PARAM_LIST, 1, { "VPrediction", "DivinePred", "HPrediction"})
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

function wKSSoon()
	for i, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) and GetDistance(enemy) < spells.w.range and getDmg("W", enemy, myHero) * 2 > enemy.health and not enemy.dead then
			return true
		end
	end
	
	return false
end

----------------------
--  Cast functions  --
----------------------

function CastQ()
	if spells.q.ready and qStackCount == 5 and GetEnemyCountInPos(myHero, 700) > 0 then
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
		elseif settings.pred == 2 and VIP_USER and (os.clock() * 1000 - lastWCheck) > 200 and useDP then	
			local targ = DPTarget(unit)
			local state,hitPos,perc = dp:predict(targ, wpred)
			
			lastWCheck = os.clock() * 1000
			
			if state == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_W, hitPos.x, hitPos.z)
			end
		elseif settings.pred == 3 and useHP then
			local WPos, WHitChance = HPred:GetPredict("W", unit, myHero)
  
			if WHitChance > 0 then
				CastSpell(_W, WPos.x, WPos.z)
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
			
			if lastPosition[i] ~= nil then
				if (os.clock() * 1000 - enemyTick[i]) < 1000 and distance(lastPosition[i].x, lastPosition[i].z) < 1000 then
					CastSpell(_E, lastPosition[i].x, lastPosition[i].z)
				end
			end
		elseif enemy.team ~= myHero.team and enemy.visible and not enemy.dead then
			enemyTick[i] = nil
			lastPosition[i] = {x = enemy.x, z = enemy.z}
		end
	end
end

function CastR(unit)
	if ValidTarget(unit) and spells.r.ready then
		if settings.pred == 1 then
			local castPos, chance, pos = pred:GetLineCastPosition(unit, spells.r.delay, spells.r.width, spells.r.range, spells.r.speed, myHero, false)
			if chance >= 2 then
				CastSpell(_R, castPos.x, castPos.z)
			end
		elseif settings.pred == 2 and VIP_USER and (os.clock() * 1000 - lastRCheck) > 200 and useDP then	
			local targ = DPTarget(unit)
			local state,hitPos,perc = dp:predict(targ, rpred)
			
			lastRCheck = os.clock() * 1000
			
			if state == SkillShot.STATUS.SUCCESS_HIT then
				CastSpell(_R, hitPos.x, hitPos.z)
			end
		elseif settings.pred == 3 and useHP then
			local RPos, RHitChance = HPred:GetPredict("R", unit, myHero)
  
			if RHitChance > 0 then
				CastSpell(_R, RPos.x, RPos.z)
			end
		end
	end
end

function Killsteal()
	for i, enemy in pairs(GetEnemyHeroes()) do
		if settings.ks.w then
			if GetDistance(enemy) < spells.w.range and ValidTarget(enemy) and not enemy.dead then
				if getDmg("W", enemy, myHero) * 0.95 > enemy.health then
					CastW(enemy)
				end
			end
		end
	
	
		if settings.ks.r then
			if GetDistance(enemy) < settings.ks.rRange and ValidTarget(enemy) and not enemy.dead then
				if getDmg("R", enemy, myHero) * 0.95 > enemy.health then
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