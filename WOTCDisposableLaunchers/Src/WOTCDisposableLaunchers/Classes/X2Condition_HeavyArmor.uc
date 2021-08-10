class X2Condition_HeavyArmor extends X2Condition;

// checking if target unit has heavy armor equipped
// condition succeeds if the unit DOES NOT have it.

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	
	local XComGameState_Unit UnitState;
	
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
	return DoesUnitHaveHeavyArmor(SourceUnit);
}

static private function bool DoesUnitHaveHeavyArmor(const XComGameState_Unit UnitState)
{
	local XComGameState_Item ItemState;
	local X2ArmorTemplate ArmorTemplate;

	ItemState = UnitState.GetItemInSlot(eInvSlot_Armor);
	if (ItemState == none)
		return false;
	
	ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());
	if (ArmorTemplate == none)
		return false;
		
	return ArmorTemplate.ArmorClass == 'heavy' || ArmorTemplate.bHeavyWeapon;
}