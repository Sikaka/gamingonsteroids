if myHero.charName ~= "Alistar" then return end
keybindings = { [ITEM_1] = HK_ITEM_1, [ITEM_2] = HK_ITEM_2, [ITEM_3] = HK_ITEM_3, [ITEM_4] = HK_ITEM_4, [ITEM_5] = HK_ITEM_5, [ITEM_6] = HK_ITEM_6}


local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
function SetMovement(bool)
	if _G.EOWLoaded then
		EOW:SetMovements(bool)
		EOW:SetAttacks(bool)
	elseif _G.SDK then
		SDK.Orbwalker:SetMovement(bool)
		SDK.Orbwalker:SetAttack(bool)
	else
		GOS.BlockMovement = not bool
		GOS.BlockAttack = not bool
	end
	if bool then
		castSpell.state = 0
	end
end

class "Alistar"
local Scriptname,Version,Author,LVersion = "TRUSt in my Alistar","v1.0","TRUS","7.24b"
local flashslot
local castedWonce = false
function Alistar:__init()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	
	local orbwalkername = ""
	if _G.SDK then
		orbwalkername = "IC'S orbwalker"
	elseif _G.EOW then
		orbwalkername = "EOW"	
	elseif _G.GOS then
		orbwalkername = "Noddy orbwalker"
	else
		orbwalkername = "Orbwalker not found"
		
	end
	PrintChat(Scriptname.." "..Version.." - Loaded...."..orbwalkername .. (TPred and " TPred" or ""))
end

--[[Spells]]
function Alistar:LoadSpells()
	Q = {Range = 365, Delay = 0.25}
	W = {Range = 650}
	E = {Range = 350}
end
function Alistar:EnemyInRange(source,radius)
	local count = 0
	if not source then return end
	for i, target in ipairs(self:GetEnemyHeroes()) do
		if target.pos:DistanceTo(source) < radius then 
			count = count + 1
		end
	end
	return count
end

function Alistar:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Alistar:GetAllyHeroes()
	self.AllyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly then
			table.insert(self.AllyHeroes, Hero)
		end
	end
	return self.AllyHeroes
end


function Alistar:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "TRUStinymyAlistar", name = Scriptname})
	
	
	--[[FlashCombos]]
	self.Menu:MenuElement({type = MENU, id = "FlashCombo", name = "FlashCombo Settings"})
	for i, hero in pairs(self:GetEnemyHeroes()) do
		self.Menu.FlashCombo:MenuElement({id = "RU"..hero.charName, name = "Use FlashQ only on: "..hero.charName, value = true})
	end
	
	self.Menu.FlashCombo:MenuElement({id = "qFlash", name = "qFlash key", key = string.byte("G")})
	
	--[[Protector]]
	self.Menu:MenuElement({type = MENU, id = "Protector", name = "Protect from dashes"})
	self.Menu.Protector:MenuElement({id = "enabled", name = "Enabled", value = true})
	for i, hero in pairs(self:GetAllyHeroes()) do
		self.Menu.Protector:MenuElement({id = "RU"..hero.charName, name = "Protect from dashes: "..hero.charName, value = true})
	end
	
	--[[Combo]]
	self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	self.Menu.Combo:MenuElement({id = "comboUseQ", name = "Use Q", value = true})
	self.Menu.Combo:MenuElement({id = "comboUseW", name = "Use W", value = true})
	self.Menu.Combo:MenuElement({id = "comboUseE", name = "Use E", value = true})
	self.Menu.Combo:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
	
	
	--[[Harass]]
	self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
	self.Menu.Harass:MenuElement({id = "harassUseQ", name = "Use Q", value = true})
	self.Menu.Harass:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("C")})
	
	self.Menu:MenuElement({type = MENU, id = "DrawMenu", name = "Draw Settings"})
	self.Menu.DrawMenu:MenuElement({id = "DrawQ", name = "Draw Q Range", value = true})
	self.Menu.DrawMenu:MenuElement({id = "QRangeC", name = "Q Range color", color = Draw.Color(0xBF3F3FFF)})
	self.Menu.DrawMenu:MenuElement({id = "DrawW", name = "Draw W Range", value = true})
	self.Menu.DrawMenu:MenuElement({id = "WRangeC", name = "W Range color", color = Draw.Color(0xBFBF3FFF)})
	
	self.Menu:MenuElement({id = "CustomSpellCast", name = "Use custom spellcast", tooltip = "Can fix some casting problems with wrong directions and so", value = true})
	self.Menu:MenuElement({id = "delay", name = "Custom spellcast delay", value = 50, min = 0, max = 200, step = 5, identifier = ""})
	
	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. "" .. (TPred and " TPred" or "")})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end

function CurrentModes()
	local canmove, canattack
	if _G.SDK then -- ic orbwalker
		canmove = _G.SDK.Orbwalker:CanMove()
		canattack = _G.SDK.Orbwalker:CanAttack()
	elseif _G.EOW then -- eternal orbwalker
		canmove = _G.EOW:CanMove() 
		canattack = _G.EOW:CanAttack()
	else -- default orbwalker
		canmove = _G.GOS:CanMove()
		canattack = _G.GOS:CanAttack()
	end
	return canmove, canattack
end

function Alistar:getFlash()
	for i = 1, 5 do
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerFlash" then
			return SUMMONER_1
		end
		if myHero:GetSpellData(SUMMONER_2).name == "SummonerFlash" then
			return SUMMONER_2
		end
	end
	return 0
end
function Alistar:IsValidTarget(unit, range, checkTeam, from)
	local range = range == nil and math.huge or range
	if unit == nil or not unit.valid or not unit.visible or unit.dead or not unit.isTargetable or (checkTeam and unit.isAlly) then
		return false
	end
	if myHero.pos:DistanceTo(unit.pos)>range then return false end 
	return true 
end
function Alistar:Tick()
	if myHero.dead then return end
	local combomodeactive = self.Menu.Combo.comboActive:Value()
	local harassactive = self.Menu.Harass.harassActive:Value()
	local flashcombo = self.Menu.FlashCombo.qFlash:Value()
	local protector = self.Menu.Protector.enabled:Value()
	if not castedWonce and myHero:GetSpellData(_W).level > 0 and myHero:GetSpellData(_W).currentCd > 0 then
		castedWonce = true
	end
	flashslot = self:getFlash()
	if flashcombo and self:CanCast(_Q) and self:CanCast(flashslot) then
		self:CastQFlash()
	end
	
	if protector and self:CanCast(_W) then
		for i, hero in pairs(self:GetEnemyHeroes()) do 
			if hero.pathing.hasMovePath and hero.pathing.isDashing and hero.pathing.dashSpeed>500 then 
				for i, allyHero in pairs(self:GetAllyHeroes()) do 
					if self.Menu.Protector["RU"..allyHero.charName] and self.Menu.Protector["RU"..allyHero.charName]:Value() then 
						if GetDistance(hero.pathing.endPos,allyHero.pos)<100 and myHero.pos:DistanceTo(allyHero.pos)< W.Range then
							self:CastSpell(HK_W,hero.pos)
						end
					end
				end
			end
		end
	end
	
	if combomodeactive then
		if self.Menu.Combo.comboUseQ:Value() and self:CanCast(_Q) then
			self:CastQ()
			if castedWonce and myHero:GetSpellData(_W).currentCd > myHero:GetSpellData(_W).cd-1 then
				Control.CastSpell(HK_Q)
			end
		end
		if self.Menu.Combo.comboUseW:Value() and self:CanCast(_Q) and self:CanCast(_W) then
			self:CastW()
		end
		if self.Menu.Combo.comboUseE:Value() and self:CanCast(_E) then
			self:CastE()
		end
		
	elseif harassactive then 
		if self.Menu.Harass.harassUseQ:Value() and self:CanCast(_Q) then
			self:CastQ()
		end
	end
end


function GetDistanceSqr(p1, p2)
	assert(p1, "GetDistance: invalid argument: cannot calculate distance to "..type(p1))
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function GetDistance(p1, p2)
	return math.sqrt(GetDistanceSqr(p1, p2))
end



function EnableMovement()
	SetMovement(true)
end

function ReturnCursor(pos)
	Control.SetCursorPos(pos)
	DelayAction(EnableMovement,0.1)
end

function LeftClick(pos)
	Control.mouse_event(MOUSEEVENTF_LEFTDOWN)
	Control.mouse_event(MOUSEEVENTF_LEFTUP)
	DelayAction(ReturnCursor,0.05,{pos})
end

function Alistar:CastSpell(spell,pos)
	local customcast = self.Menu.CustomSpellCast:Value()
	if not customcast then
		Control.CastSpell(spell, pos)
		return
	else
		local delay = self.Menu.delay:Value()
		local ticker = GetTickCount()
		if castSpell.state == 0 and ticker > castSpell.casting then
			castSpell.state = 1
			castSpell.mouse = mousePos
			castSpell.tick = ticker
			if ticker - castSpell.tick < Game.Latency() then
				--block movement
				SetMovement(false)
				if (spell == HK_W) then
					Control.KeyDown(HK_TCO)
				end
				Control.SetCursorPos(pos)
				Control.KeyDown(spell)
				Control.KeyUp(spell)
				if (spell == HK_W) then
					Control.KeyUp(HK_TCO)
				end
				DelayAction(LeftClick,delay/1000,{castSpell.mouse})
				castSpell.casting = ticker + 500
			end
		end
	end
end

function Alistar:CastQFlash(target)
	if (not _G.SDK and not _G.GOS and not _G.EOW) then return end
	for i, hero in pairs(self:GetEnemyHeroes()) do 
		if self:IsValidTarget(hero,Q.Range+350) and self.Menu.FlashCombo["RU"..hero.charName] and self.Menu.FlashCombo["RU"..hero.charName]:Value() then 
			Control.CastSpell(HK_Q)
			self:CastSpell(flashslot == SUMMONER_1 and HK_SUMMONER_1 or HK_SUMMONER_2,hero.pos)
		end
	end
end


function Alistar:CastQ(target)
	if (not _G.SDK and not _G.GOS and not _G.EOW) then return end
	local target = target or (_G.SDK and _G.SDK.TargetSelector:GetTarget(Q.Range, _G.SDK.DAMAGE_TYPE_MAGICAL)) or (_G.GOS and _G.GOS:GetTarget(Q.Range,"AP"))
	if target and target.type == "AIHeroClient" and self:CanCast(_Q) then
		local temppred = target:GetPrediction(math.huge,0.25)
		if temppred:DistanceTo() < Q.Range then 
			Control.CastSpell(HK_Q)
		end
	end
end

function Alistar:CastW()
	if (not _G.SDK and not _G.GOS and not _G.EOW) then return end
	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(W.Range, _G.SDK.DAMAGE_TYPE_MAGICAL)) or (_G.GOS and _G.GOS:GetTarget(W.Range,"AP"))
	if target and GetDistance(myHero.pos,target.pos)>Q.Range then
		self:CastSpell(HK_W, target.pos)
	end
end

function Alistar:CastE()
	if (not _G.SDK and not _G.GOS and not _G.EOW) then return end
	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(E.Range, _G.SDK.DAMAGE_TYPE_MAGICAL)) or (_G.GOS and _G.GOS:GetTarget(E.Range,"AP"))
	if target then
		Control.CastSpell(HK_E)
	end
end



function Alistar:IsReady(spellSlot)
	return myHero:GetSpellData(spellSlot).currentCd == 0 and myHero:GetSpellData(spellSlot).level > 0
end

function Alistar:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Alistar:CanCast(spellSlot)
	return self:IsReady(spellSlot) and self:CheckMana(spellSlot)
end

function Alistar:Draw()
	if myHero.dead then return end 
	if self.Menu.DrawMenu.DrawQ:Value() then
		Draw.Circle(myHero.pos, Q.Range, 3, self.Menu.DrawMenu.QRangeC:Value())
	end
	if self.Menu.DrawMenu.DrawW:Value() then
		Draw.Circle(myHero.pos, W.Range, 3, self.Menu.DrawMenu.WRangeC:Value())
	end
end
function OnLoad()
	Alistar()
end