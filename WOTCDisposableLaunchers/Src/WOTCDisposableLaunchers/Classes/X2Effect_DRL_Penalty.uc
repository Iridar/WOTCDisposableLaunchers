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
var config bool MOBILITY_PENALTY_IS_APPLIED_TO_HEAVY_ARMOR;

 /*
struct native StatChange
{
	var ECharStatType   StatType;
	var float           StatAmount;
	var EStatModOp		ModOp;
	var ECharStatModApplicationRule ApplicationRule;

	structdefaultproperties
	{
		ApplicationRule=ECSMAR_Additive
	}
};
struct native StatChange
{
	var ECharStatType   StatType;
	var float           StatAmount;
	var EStatModOp		ModOp;
	var ECharStatModApplicationRule ApplicationRule;

	structdefaultproperties
	{
		ApplicationRule=ECSMAR_Additive
	}
};

// Current order of opperations - MODOP_Multiplication, MODOP_Addition, MODOP_PostMultiplication
enum EStatModOp
{
	MODOP_Addition,
	MODOP_Multiplication,   // Pre-multiplication - This is in the base game and so stays the same name.
	MODOP_PostMultiplication,
};

enum ECharStatType
{
	eStat_Invalid,
	eStat_UtilityItems,
	eStat_HP,
	eStat_Offense,
	eStat_Defense,
	eStat_Mobility,
	eStat_Will,
	eStat_Hacking,              // Used in calculating chance of success for hacking attempts.
	eStat_SightRadius,
	eStat_FlightFuel,
	eStat_AlertLevel,
	eStat_BackpackSize,
	eStat_Dodge,
	eStat_ArmorChance,          //  DEPRECATED - armor will always be used regardless of this value
	eStat_ArmorMitigation,      
	eStat_ArmorPiercing,
	eStat_PsiOffense,
	eStat_HackDefense,          // Units use this when defending against hacking attempts.
	eStat_DetectionRadius,		// The radius at which this unit will detect other concealed units.								Overall Detection Range = 
	eStat_DetectionModifier,	// The modifier this unit will apply to the range at which other units can detect this unit.	Detector.DetectionRadius * (1.0 - Detectee.DetectionModifier)
	eStat_CritChance,
	eStat_Strength,
	eStat_SeeMovement,
	eStat_HearingRadius,
	eStat_CombatSims,
	eStat_FlankingCritChance,
	eStat_ShieldHP,
	eStat_Job,
	eStat_FlankingAimBonus,
};
*/

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
				PenaltyState.ItemState = ItemState;
				PenaltyState.Penalties.Length = 0;

				// Calculate total ammount of remaining rockets.
				CurrentAmmo += ItemState.Ammo;

				//`LOG("DRL:" @ ItemState.InventorySlot,, 'IRITEST');

				// For each DRL Item State, store an array of penalties that should be applied for carriyng it.
				foreach default.Penalties(Penalty)
				{
					if ((Penalty.Slot == ItemState.InventorySlot || Penalty.Slot == eInvSlot_Unknown) && (Penalty.Template == ItemState.GetMyTemplateName() || Penalty.Template == ''))
					{
						//foreach Penalty.StatChanges(NewStatChange)
						//{	
						//	if (NewStatChange.StatAmount != 0)
						//	{
						//		`LOG("-- Has penalty:" @ NewStatChange.StatType @ NewStatChange.StatAmount,, 'IRITEST');
						//	}
						//}

						PenaltyState.Penalties.AddItem(Penalty);
					}
				}

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
