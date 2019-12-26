class X2Effect_DisposableMobilityPenalty extends X2Effect_ModifyStats;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local StatChange					NewChange;
	local XComGameState_Unit			UnitState;
	local XComGameState_Item			ItemState;
	local X2DisposableLauncherTemplate	Rocket;
	local X2PairedWeaponTemplate		PairedTemplate;
	local int							IgnoredPenalty;
	local StateObjectReference			Ref; 

	//	Grab the source weapon of this ability
	ItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
	Rocket = X2DisposableLauncherTemplate(ItemState.GetMyTemplate());

	if(Rocket != none) 
	{	
		//	calculate the initial penalty multiplier
		if (class'X2Item_DisposableLaunchers'.default.MOBILITY_PENALTY_IS_COUNTED_PER_ROCKET)
		{
			NewChange.StatAmount = ItemState.Ammo;
		}
		else
		{
			NewChange.StatAmount = FCeil(float(ItemState.Ammo) / float(Rocket.iClipSize));	//	rounding up so even 1 rocket left in the launcher gives a penalty
		}

		//	then cycle through all inventory items of the soldier
		UnitState = XComGameState_Unit(kNewTargetState);
		foreach UnitState.InventoryItems(Ref)
		{
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
			PairedTemplate = X2PairedWeaponTemplate(ItemState.GetMyTemplate());

			//	if we find a weapon paired to the launcher, and it's not carried in the utility slot, then we ignore its mobility penalty.
			if (PairedTemplate != none) 
			{
				if (PairedTemplate.PairedSlot == class'X2Item_DisposableLaunchers'.default.RPG_Inventory_Slot)
				{
					if (PairedTemplate.InventorySlot != eInvSlot_Utility)
					{
						//	calculate how much penalty we need to ignore, either per-rocet or per-launcher
						if (class'X2Item_DisposableLaunchers'.default.MOBILITY_PENALTY_IS_COUNTED_PER_ROCKET)
						{
							IgnoredPenalty += PairedTemplate.iClipSize;
						}
						else
						{
							IgnoredPenalty++;
						}
					}				
				}
			}
		}

		//	subtract the ignored penalty from the initial penalty
		NewChange.StatAmount -= IgnoredPenalty;

		if (NewChange.StatAmount < 0) NewChange.StatAmount = 0;

		NewChange.StatAmount *= Rocket.MobilityPenalty;

		//	set the mobility penalty
		//	StatAmount is float too, but somewhere later in game's code the mobility stat gets truncated, 
		NewChange.StatType = eStat_Mobility;
		NewChange.ModOp = MODOP_Addition;			//	so subtracting 0.25f is the same as subtracting a full 1.
													//	from our perspective, it means a mobility penalty of 1.25f is equal to 2.0, i.e. it's rounded up
		NewEffectState.StatChanges.AddItem(NewChange);

		//	Add Detection Radius Modifier
		NewChange.StatAmount /= Rocket.MobilityPenalty;
		NewChange.StatAmount *= Rocket.DetectionRadiusModifier;
		NewChange.StatType = eStat_DetectionModifier;
		NewChange.ModOp = MODOP_Addition;
		NewEffectState.StatChanges.AddItem(NewChange);
	}
	//	and apply it
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}