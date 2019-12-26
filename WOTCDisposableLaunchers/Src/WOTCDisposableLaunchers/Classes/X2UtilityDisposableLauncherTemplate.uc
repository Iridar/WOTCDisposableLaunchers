class X2UtilityDisposableLauncherTemplate extends X2PairedWeaponTemplate;

function PairEquipped(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local X2ItemTemplate PairedItemTemplate;
	local XComGameState_Item PairedItem, RemoveItem;
	local XComGameState_Item				InvItemState;
	local XComGameState_HeadquartersXCom	XComHQ;

	//	Added
	InvItemState = UnitState.GetItemInSlot(eInvSlot_Utility, NewGameState);
	if (InvItemState != none)
	{
		if (UnitState.RemoveItemFromInventory(InvItemState, NewGameState))
		{
			`LOG("Unequipped: " @ InvItemState.GetMyTemplateName(),, 'IRIDRL');
			XComHQ = class'X2StrategyElement_DefaultResistanceModes'.static.GetNewXComHQState(NewGameState);
			XComHQ.PutItemInInventory(NewGameState, InvItemState);
		}
	}//	End of added

	if (PairedTemplateName != '')
	{
		RemoveItem = UnitState.GetItemInSlot(PairedSlot, NewGameState);
		if (RemoveItem != none)
		{
			if (UnitState.RemoveItemFromInventory(RemoveItem, NewGameState))
			{
				NewGameState.RemoveStateObject(RemoveItem.ObjectID);
			}
			else
			{
				`RedScreen("Unable to remove item" @ RemoveItem.GetMyTemplateName() @ "in PairedSlot" @ PairedSlot @ "so paired item equip will fail -jbouscher / @gameplay");
			}
		}
		PairedItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(PairedTemplateName);
		if (PairedItemTemplate != none)
		{
			PairedItem = PairedItemTemplate.CreateInstanceFromTemplate(NewGameState);
			PairedItem.WeaponAppearance = ItemState.WeaponAppearance; // Copy appearance data
			UnitState.AddItemToInventory(PairedItem, PairedSlot, NewGameState);
			if (UnitState.GetItemInSlot(PairedSlot, NewGameState, true).ObjectID != PairedItem.ObjectID)
			{
				`RedScreen("Created a paired item ID" @ PairedItem.ObjectID @ "but we could not add it to the unit's inventory, destroying it instead -jbouscher / @gameplay");
				NewGameState.PurgeGameStateForObjectID(PairedItem.ObjectID);
			}
		}
	}
}