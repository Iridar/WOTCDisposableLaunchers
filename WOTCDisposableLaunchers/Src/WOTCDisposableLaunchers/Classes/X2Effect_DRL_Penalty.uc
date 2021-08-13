class X2Effect_DRL_Penalty extends X2Effect_ModifyStats config(DisposableLaunchers);

// Unnecessarily fancy effect that applies stat penalties for DRLs while they have ammo remaining.

struct PenaltyStruct
{
	var name Template;
	var EInventorySlot Slot;
	var array<StatChange> StatChanges;

	structdefaultproperties
	{
		Slot = eInvSlot_Unknown; // Pretty sure that's default anyway, but let's be safe
	}
};
struct PenaltyStateStruct
{
	var XComGameState_Item ItemState;
	var array<PenaltyStruct> Penalties;
};
var config array<PenaltyStruct> Penalties;

`include(WOTCDisposableLaunchers\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

static final function array<PenaltyStruct> GetPenaltiesForItemState(XComGameState_Item ItemState, optional EInventorySlot OverrideSlot = -1)
{
	local array<PenaltyStruct> ReturnArray;
	local PenaltyStruct	Penalty;

	if (!`GETMCMVAR(DRL_STAT_PENALTIES_ENABLED))
		return ReturnArray;

	if (OverrideSlot != -1)
	{
		foreach default.Penalties(Penalty)
		{
			if ((Penalty.Slot == OverrideSlot || Penalty.Slot == eInvSlot_Unknown) && (Penalty.Template == ItemState.GetMyTemplateName() || Penalty.Template == ''))
			{
				ReturnArray.AddItem(Penalty);
			}
		}
	}
	else
	{
		foreach default.Penalties(Penalty)
		{
			if ((Penalty.Slot == ItemState.InventorySlot || Penalty.Slot == eInvSlot_Unknown) && (Penalty.Template == ItemState.GetMyTemplateName() || Penalty.Template == ''))
			{
				ReturnArray.AddItem(Penalty);
			}
		}
	}
	return ReturnArray;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local StatChange					NewStatChange;
	local PenaltyStruct					Penalty;
	local XComGameState_Unit			UnitState;
	local XComGameState_Item			ItemState;
	local StateObjectReference			ItemRef; 
	local XComGameStateHistory			History;
	local float							CurrentAmmo;
	local array<PenaltyStateStruct>		PenaltyStates;
	local PenaltyStateStruct			PenaltyState;

	UnitState = XComGameState_Unit(kNewTargetState);
	//`LOG(GetFuncName() @ UnitState.GetFullName(),, 'IRITEST');
	if (UnitState != none)
	{
		// Zero out the array so that newly calculated stat changes don't stack with stat changes calculated on the previous turn.
		NewEffectState.StatChanges.Length = 0;
		// Add an empty stat modifier to prevent an anal redscreen in case we don't end up applying any real modifiers
		NewEffectState.StatChanges.AddItem(NewStatChange); 

		// Build an array of DRL Item State equipped on a soldier, each Item State is accompanied by Stat Penalties that should be applied "for" carrying that DRL.
		History = `XCOMHISTORY;
		foreach UnitState.InventoryItems(ItemRef)
		{
			// We're interested in DRLs that never had any ammo (because they were merged out), or DRLs that did not expend any ammo.
			// DRLs that had ammo, but have expended it, are of no interest to us.
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
			if (ItemState.GetWeaponCategory() == 'iri_disposable_launcher' && (ItemState.bMergedOut || ItemState.Ammo > 0))
			{	
				//`LOG("DRL:" @ ItemState.InventorySlot,, 'IRITEST');

				PenaltyState.ItemState = ItemState;

				// Calculate total ammount of remaining rockets.
				CurrentAmmo += ItemState.Ammo;

				// For each DRL Item State, store an array of penalties that should be applied for carriyng it.
				PenaltyState.Penalties = GetPenaltiesForItemState(ItemState);

				// Filter out any DRLs that don't apply any penalties.
				if (PenaltyState.Penalties.Length > 0)
				{
					//`LOG("This DRL has penalties, adding to array, increasing Current Ammo by:" @ ItemState.Ammo,, 'IRITEST');

					PenaltyStates.AddItem(PenaltyState);
				}
			}
		}

		PenaltyStates.Sort(SortPenaltyStates);
		//`LOG("First cycle done:" @ `showvar(CurrentAmmo) @ "have DRL-penalty pairs:" @ PenaltyStates.Length,, 'IRITEST');

		// Cycle through the DRL-penalty array we have built.
		foreach PenaltyStates(PenaltyState)
		{
			// This cycle breaker serves the purpose of not applying penalties for those DRLs that have exhausted their ammo.
			if (CurrentAmmo <= 0)
			{	
				//`LOG("### END OF THE LINE ###",, 'IRITEST');
				break;
			}
			// This should work regardless if DRL was merged out or exhausted their ammo naturally.
			CurrentAmmo -= PenaltyState.ItemState.GetClipSize();
			//`LOG("Still in the cycle:" @ `showvar(CurrentAmmo) @ "applying penalties for DRL in slot:" @ PenaltyState.ItemState.InventorySlot,, 'IRITEST');

			// Add the penalties into the Effect's array
			foreach PenaltyState.Penalties(Penalty)
			{
				foreach Penalty.StatChanges(NewStatChange)
				{	
					if (NewStatChange.StatAmount != 0)
					{
						//`LOG("-- Applied penalty:" @ NewStatChange.StatType @ NewStatChange.StatAmount,, 'IRITEST');
						NewEffectState.StatChanges.AddItem(NewStatChange);
					}
				}
			}
		}

		//`LOG("### END OF THE LINE ###",, 'IRITEST');
	}

	// And apply them.
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

static final function int SortPenaltyStates(PenaltyStateStruct A, PenaltyStateStruct B)
{
	if (A.ItemState.Ammo > B.ItemState.Ammo)
		return 1;
	else if (A.ItemState.Ammo < B.ItemState.Ammo)
		return  -1;
	else return 0;
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{
	return EffectGameState.StatChanges.Length > 1;
}
