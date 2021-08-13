class X2Condition_HeavyArmor extends X2Condition;

// checking if target unit has heavy armor equipped
// condition succeeds if the unit DOES NOT have it.

`include(WOTCDisposableLaunchers\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState;

	if (!`GETMCMVAR(DRL_STAT_PENALTIES_ENABLED))
		return 'AA_AbilityUnavailable';
	
	UnitState = XComGameState_Unit(kTarget);
	if (UnitState == none)	
		return 'AA_NotAUnit';

	if (DoesUnitHaveHeavyArmor(UnitState))
	{
		return 'AA_AbilityUnavailable';
	}

	return 'AA_Success';
}

function bool CanEverBeValid(XComGameState_Unit SourceUnit, bool bStrategyCheck)
{
	return `GETMCMVAR(DRL_STAT_PENALTIES_ENABLED) && DoesUnitHaveHeavyArmor(SourceUnit);
}

static private function bool DoesUnitHaveHeavyArmor(const XComGameState_Unit UnitState)
{
	local XComGameState_Item ItemState;
	local X2ArmorTemplate ArmorTemplate;

	// If MCM says penalties are applied to heavy armor, then we don't care what armor the unit has.
	if (`GETMCMVAR(DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR))
		return false;
	
	ItemState = UnitState.GetItemInSlot(eInvSlot_Armor);
	if (ItemState == none)
		return false;
	
	ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());
	if (ArmorTemplate == none)
		return false;
		
	return ArmorTemplate.ArmorClass == 'heavy' || ArmorTemplate.bHeavyWeapon;
}