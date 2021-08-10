class X2Effect_DRL_Penalty extends X2Effect_ModifyStats config(DisposableLaunchers);

struct PenaltyStruct
{
	var name Template;
	var EInventorySlot Slot;
	var array<StatChange> StatChanges;

	var bool bApply; // Runtime flag, don't set it in config.

	structdefaultproperties
	{
		Slot = eInvSlot_Unknown; // Pretty sure that's default anyway, but let's be safe
	}
};
var config array<PenaltyStruct> Penalties;

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
	local StatChange					CycleChange;
	local PenaltyStruct					Penalty;
	local XComGameState_Unit			UnitState;
	local XComGameState_Item			ItemState;
	local array<XComGameState_Item>		ItemStates;
	local StateObjectReference			ItemRef; 
	local XComGameStateHistory			History;
	local float							MaxAmmo;
	local float							CurrentAmmo;
	local float							AmmoModifier;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		NewEffectState.StatChanges.Length = 0;
		NewEffectState.StatChanges.AddItem(CycleChange); // Add an empty stat modifier to prevent an anal redscreen

		History = `XCOMHISTORY;
		foreach UnitState.InventoryItems(ItemRef)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
			if (ItemState.GetWeaponCategory() == 'iri_disposable_launcher')
			{
				if (!ItemState.bMergedOut)
				{
					CurrentAmmo = ItemState.Ammo;
					MaxAmmo = ItemState.GetClipSize() * ItemState.MergedItemCount;
				}
				ItemStates.AddItem(ItemState);
			}
		}

		if (MaxAmmo != 0) // Prevent divison by 0 just in case
		{
			AmmoModifier = CurrentAmmo / MaxAmmo;
	
			foreach ItemStates(ItemState)
			{
				foreach default.Penalties(Penalty)
				{
					if ((Penalty.Slot == ItemState.InventorySlot || Penalty.Slot == eInvSlot_Unknown) && (Penalty.Template == ItemState.GetMyTemplateName() || Penalty.Template == ''))
					{
						foreach Penalty.StatChanges(CycleChange)
						{	
							// Reduce magnitude of stat penalties based on the number of shots left.
							// Hacky, but this is the best I could come up.
							CycleChange.StatAmount *= AmmoModifier;
							if (CycleChange.StatAmount != 0)
							{
								NewEffectState.StatChanges.AddItem(CycleChange);
							}
						}
					}
				}
			}
		}
	}

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{
	return EffectGameState.StatChanges.Length > 1;
}