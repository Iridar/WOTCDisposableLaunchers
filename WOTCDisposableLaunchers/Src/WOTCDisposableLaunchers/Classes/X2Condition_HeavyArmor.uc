class X2Condition_HeavyArmor extends X2Condition;

// checking if target unit has heavy armor equipped
// condition succeeds if the unit DOES NOT have it.

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Item ItemState;
	local XComGameState_Unit UnitState;
	local X2ArmorTemplate ArmorTemplate;

	UnitState = XComGameState_Unit(kTarget);
	if (UnitState == none)	return 'AA_NotAUnit';

	ItemState = UnitState.GetItemInSlot(eInvSlot_Armor);

	if (ItemState != none) ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());

	if (ArmorTemplate != none && (ArmorTemplate.ArmorClass == 'heavy' || ArmorTemplate.bHeavyWeapon)) return 'AA_AbilityUnavailable';

	return 'AA_Success';
}
