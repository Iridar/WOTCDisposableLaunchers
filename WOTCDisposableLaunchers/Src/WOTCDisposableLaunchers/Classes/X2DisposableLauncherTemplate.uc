class X2DisposableLauncherTemplate extends X2WeaponTemplate;

function string DetermineGameArchetypeForUnit(XComGameState_Item ItemState, XComGameState_Unit UnitState, optional TAppearance PawnAppearance)
{
	// Don't display this DRL if there's more than one equipped.
	if (ItemState.bMergedOut)
	{
		return "";
	}
	return GameArchetype;
}

function int GetUIStatMarkup(ECharStatType Stat, optional XComGameState_Item Item)
{
	//`LOG(GetFuncName() @ self.DataName @ Stat @ Item != none @ Item.GetMyTemplateName() @ Item.InventorySlot,, 'IRITEST');
	switch (Stat)
	{
	case eStat_Mobility:
		//`LOG("This is mobility label",, 'IRITEST');
		if (Item != none && Item.InventorySlot == eInvSlot_Utility)
		{
			//`LOG("Utility DRL, showing mobility markup",, 'IRITEST');
			return super.GetUIStatMarkup(Stat, Item);
		}
		//`LOG("Non-utility DRL, showing zero mobility markup",, 'IRITEST');
		return 0;
	default:
		return super.GetUIStatMarkup(Stat, Item);
	}
}

function XComGameState_Item CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_Item_DRL Item;

	Item = XComGameState_Item_DRL(NewGameState.CreateNewStateObject(class'XComGameState_Item_DRL', self));

	if (OnAcquiredFn != none && !HideInInventory)
		OnAcquiredFn( NewGameState, Item );

	return Item;
}