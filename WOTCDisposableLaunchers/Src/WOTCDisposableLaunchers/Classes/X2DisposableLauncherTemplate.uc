class X2DisposableLauncherTemplate extends X2WeaponTemplate dependson(X2Effect_DRL_Penalty);

function string DetermineGameArchetypeForUnit(XComGameState_Item ItemState, XComGameState_Unit UnitState, optional TAppearance PawnAppearance)
{
	// Don't display this DRL if there's more than one equipped.
	if (ItemState.bMergedOut)
	{
		return "";
	}
	return GameArchetype;
}

function XComGameState_Item CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_Item Item;

	Item = XComGameState_Item(NewGameState.CreateNewStateObject(class'XComGameState_Item_DRL', self));

	if (OnAcquiredFn != none && !HideInInventory)
		OnAcquiredFn( NewGameState, Item );

	return Item;
}

function int GetUIStatMarkup(ECharStatType Stat, optional XComGameState_Item Weapon)
{
	local array<PenaltyStruct>	Penalties;
	local PenaltyStruct			Penalty;
	local StatChange			CycleStatChange;
	local UIArmory_Loadout		Loadout;
	local int Markup;

	//`LOG(GetFuncName() @ Weapon != none @ Weapon.GetMyTemplateName() @ Weapon.InventorySlot,, 'IRITEST');

	Markup = super.GetUIStatMarkup(Stat);
	if (Weapon != none)
	{
		// If this function is called when previewing a DRL in the armory locker list,
		// get the penalties for the slot we're about to equip the DRL into.
		if (Weapon.InventorySlot == eInvSlot_Unknown)
		{
			Loadout = UIArmory_Loadout(`SCREENSTACK.GetScreen(class'UIArmory_Loadout'));
			if (Loadout != none && Loadout.ActiveList == Loadout.LockerList)
			{
				Penalties = class'X2Effect_DRL_Penalty'.static.GetPenaltiesForItemState(Weapon, Loadout.GetSelectedSlot());
			}
			else
			{
				Penalties = class'X2Effect_DRL_Penalty'.static.GetPenaltiesForItemState(Weapon);
			}
		}
		else
		{
			Penalties = class'X2Effect_DRL_Penalty'.static.GetPenaltiesForItemState(Weapon);
		}
		
		foreach Penalties(Penalty)
		{
			foreach Penalty.StatChanges(CycleStatChange)
			{	
				if (CycleStatChange.StatType == Stat)
				{
					switch (CycleStatChange.ModOp)
					{
						case MODOP_Addition:
							Markup += CycleStatChange.StatAmount;
							break;
						case MODOP_Multiplication:
						case MODOP_PostMultiplication: // idk how to handle post multiplication properly here
							Markup *= CycleStatChange.StatAmount;
							break;
					}
				}
			}
		}
	}
	return Markup;
}
