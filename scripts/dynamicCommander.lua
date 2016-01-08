local INLOS = {inlos = true}
local spSetUnitShieldState = Spring.SetUnitShieldState

local dgunTable
local weapon1
local weapon2
local shield
local weaponNumMap = {}
local weaponsInitialized = false
local paceMult

local commWreckUnitRulesParam = {"comm_baseWreckID", "comm_baseHeapID"}
local moduleWreckNamePrefix = {"module_wreck_", "module_heap_"}

local isManual = {}

local shields = {}
local wepTable = UnitDefs[unitDefID].weapons
for i = 1, #wepTable do
	local weaponDef = WeaponDefs[wepTable[i].weaponDef]
	if weaponDef.type == "Shield" then
		shields[#shields + 1] = i
	end
end

local function IsManualFire(num)
	return isManual[num]
end

local function CalculatePaceMult()
	local levelToPace = {
		[0] = 1,
		[1] = 1,
		[2] = 0.93,
		[3] = 0.86,
		[4] = 0.8,
		[5] = 0.75,
	}
	
	paceMult = levelToPace[Spring.GetUnitRulesParam(unitID, "comm_level") or 0] or levelToPace[5]
	return paceMult
end

local function GetPace()
	return paceMult or CalculatePaceMult()
end

local function GetWeapon(num)
	local retNum = GG.Upgrades_WeaponNumMap(unitID, num) or weaponNumMap[num]
	if retNum then
		return retNum
	end
	if not weaponsInitialized then
		local tempWeapon1 = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_1")
		local tempWeapon2 = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_2")
		local tempShield = Spring.GetUnitRulesParam(unitID, "comm_shield_num")
		if num == tempWeapon1 then
			return 1
		elseif num == tempWeapon2 then
			return 2
		elseif num == tempShield then
			return 3
		end
	end
	return false
end

local function EmitWeaponFireSfx(pieceNum, num)
	local weaponNum = GetWeapon(num)
	if weaponNum == 1 then
		EmitSfx(pieceNum, 1029 + weapon1*2)
	elseif weaponNum == 2 then
		EmitSfx(pieceNum, 1029 + weapon2*2)
	end
end

local function EmitWeaponShotSfx(pieceNum, num)
	local weaponNum = GetWeapon(num)
	if weaponNum == 1 then
		EmitSfx(pieceNum, 1030 + weapon1*2)
	elseif weaponNum == 2 then
		EmitSfx(pieceNum, 1030 + weapon2*2)
	end
end

local function UpdateWeapons(w1, w2, sh, rangeMult)
	weapon1 = w1 and w1.num
	weapon2 = w2 and w2.num
	shield  = sh and sh.num
	
	weaponNumMap = {}
	if weapon1 then
		weaponNumMap[weapon1] = 1
	end
	if weapon2 then
		weaponNumMap[weapon2] = 2
	end
	if shield then
		weaponNumMap[shield] = 3
	end
	
	local hasManualFire = (w1 and w1.manualFire) or (w2 and w2.manualFire)
	local cmdDesc = Spring.FindUnitCmdDesc(unitID, CMD.MANUALFIRE)
	if not hasManualFire and cmdDesc then
		Spring.RemoveUnitCmdDesc(unitID, cmdDesc)
	elseif hasManualFire and not cmdDesc then
		cmdDesc = Spring.FindUnitCmdDesc(unitID, CMD.ATTACK) + 1 -- insert after attack so that it appears in the correct spot in the menu
		Spring.InsertUnitCmdDesc(unitID, cmdDesc, dgunTable)
	end

	local maxRange = 0
	local otherRange = false
	if weapon1 and weapon1 ~= 0 then
		isManual[weapon1] = w1.manualFire
		local range = tonumber(WeaponDefs[w1.weaponDefID].range)*rangeMult
		if w1.manualFire then
			otherRange = range
		else
			maxRange = range
		end
		Spring.SetUnitWeaponState(unitID, w1.num, "range", range)
	end
	
	if weapon2 and weapon2 ~= 0 then
		isManual[weapon2] = w2.manualFire
		local range = tonumber(WeaponDefs[w2.weaponDefID].range)*rangeMult
		if maxRange then
			if w2.manualFire then
				otherRange = range
			elseif range > maxRange then
				otherRange = maxRange
				maxRange = range
			elseif range < maxRange then
				otherRange = range
			end
		else
			maxRange = range
		end
		Spring.SetUnitWeaponState(unitID, w2.num, "range", range)
	end
	
	if weapon1 and weapon1 ~= 0 then
		if weapon2 and weapon2 ~= 0 then
			local reload1 = Spring.GetUnitWeaponState(unitID, weapon1, 'reloadTime')
			local reload2 = Spring.GetUnitWeaponState(unitID, weapon2, 'reloadTime')
			if reload1 > reload2 then
				Spring.SetUnitRulesParam(unitID, "primary_weapon_override",  weapon1, INLOS)
			else
				Spring.SetUnitRulesParam(unitID, "primary_weapon_override",  weapon2, INLOS)
			end
		else
			Spring.SetUnitRulesParam(unitID, "primary_weapon_override",  weapon1, INLOS)
		end
	end
	
	-- Set other ranges to 0 for leashing
	if 1 ~= weapon1 and 1 ~= weapon2 then
		Spring.SetUnitWeaponState(unitID, 1, "range", maxRange)
	end
	for i = 2, 16 do
		if i ~= weapon1 and i ~= weapon2 then
			Spring.SetUnitWeaponState(unitID, i, "range", 0)
		end
	end
	Spring.SetUnitMaxRange(unitID, maxRange)
	
	Spring.SetUnitRulesParam(unitID, "sightRangeOverride", math.max(500, math.min(600, maxRange*1.1)), INLOS)
	
	if otherRange then
		Spring.SetUnitRulesParam(unitID, "secondary_range", otherRange, INLOS)
	end
	
	-- shields
	for i = 1, #shields do
		Spring.SetUnitShieldState(unitID, shields[i], false)
	end
	
	if (shield) then
		Spring.SetUnitShieldState(unitID, shield, true)
	end
	
	weaponsInitialized = true
end

local function Create()
	-- copy the dgun command table because we sometimes need to reinsert it
	local cmdID = Spring.FindUnitCmdDesc(unitID, CMD.MANUALFIRE)
	dgunTable = Spring.GetUnitCmdDescs(unitID, cmdID)[1]
	
	if Spring.GetUnitRulesParam(unitID, "comm_weapon_id_1") then
		UpdateWeapons(
			{
				weaponDefID = Spring.GetUnitRulesParam(unitID, "comm_weapon_id_1"),
				num = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_1"),
				manualFire = Spring.GetUnitRulesParam(unitID, "comm_weapon_manual_1") == 1,
			},
			{
				weaponDefID = Spring.GetUnitRulesParam(unitID, "comm_weapon_id_2"),
				num = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_2"),
				manualFire = Spring.GetUnitRulesParam(unitID, "comm_weapon_manual_2") == 1,
			},
			{
				weaponDefID = Spring.GetUnitRulesParam(unitID, "comm_shield_id"),
				num = Spring.GetUnitRulesParam(unitID, "comm_shield_num"),
			},
			Spring.GetUnitRulesParam(unitID, "comm_range_mult") or 1
		)
	end
end


local function SpawnModuleWreck(moduleDefID, wreckLevel, totalCount, teamID, x, y, z, vx, vy, vz)
	local featureDefID = FeatureDefNames[moduleWreckNamePrefix[wreckLevel] .. moduleDefID]
	if not featureDefID then
		Spring.Echo("Cannot find module wreck", moduleWreckNamePrefix[wreckLevel] .. moduleDefID)
		return
	end
	featureDefID = featureDefID.id
	
	local dir = math.random(2*math.pi)
	local pitch = (math.random(2)^2 - 1)*math.pi/2
	local heading = math.random(65536)
	local mag = math.min(20 + math.random(20)*totalCount, 80)
	local horScale = mag*math.cos(pitch)
	vx, vy, vz = vx + math.cos(dir)*horScale, vy + math.sin(pitch)*mag, vz + math.sin(dir)*horScale
	
	local featureID = Spring.CreateFeature(featureDefID, x + vx, y, z + vz, heading, teamID)
end

local function SpawnModuleWrecks(wreckLevel)
	local x, y, z, mx, my, mz = Spring.GetUnitPosition(unitID, true)
	local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	local teamID	= Spring.GetUnitTeam(unitID)
	
	local moduleCount = Spring.GetUnitRulesParam(unitID, "comm_module_count")
	for i = 1, moduleCount do
		SpawnModuleWreck(Spring.GetUnitRulesParam(unitID, "comm_module_" .. i), wreckLevel, moduleCount, teamID, x, y, z, vx, vy, vz)
	end
end

local function SpawnWreck(wreckLevel)
	local makeRezzable = (wreckLevel == 1)
	local wreckDef = FeatureDefs[Spring.GetUnitRulesParam(unitID, commWreckUnitRulesParam[wreckLevel])]
	
	local x, y, z = Spring.GetUnitPosition(unitID)
	
	local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	
	if (wreckDef) then
		local heading   = Spring.GetUnitHeading(unitID)
		local teamID	= Spring.GetUnitTeam(unitID)
		local featureID = Spring.CreateFeature(wreckDef.id, x, y, z, heading, teamID)
		Spring.SetFeatureVelocity(featureID, vx, vy, vz)
		if makeRezzable then
			local baseUnitDefID = Spring.GetUnitRulesParam(unitID, "comm_baseUnitDefID") or unitDefID
			Spring.SetFeatureResurrect(featureID, UnitDefs[baseUnitDefID].name)
		end
	end
end

return {
	GetPace           = GetPace,
	GetWeapon         = GetWeapon,
	EmitWeaponFireSfx = EmitWeaponFireSfx,
	EmitWeaponShotSfx = EmitWeaponShotSfx,
	UpdateWeapons     = UpdateWeapons,
	IsManualFire      = IsManualFire,
	Create            = Create,
	SpawnModuleWrecks = SpawnModuleWrecks,
	SpawnWreck        = SpawnWreck,
}	
