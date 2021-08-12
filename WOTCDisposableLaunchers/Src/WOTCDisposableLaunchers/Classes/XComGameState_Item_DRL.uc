class XComGameState_Item_DRL extends XComGameState_Item;

/*
struct UISummary_ItemStat
{
	var string Label; 
	var string Value; 
	var EUIState LabelState; 
	var EUIState ValueState; 
	var EUIUtilities_TextStyle LabelStyle; 
	var EUIUtilities_TextStyle ValueStyle; 

	structdefaultproperties
	{
		LabelState = eUIState_Normal;
		ValueState = eUIState_Normal;
		LabelStyle = eUITextStyle_Tooltip_StatLabel;
		ValueStyle = eUITextStyle_Tooltip_StatValue; 
	}
};*/

var localized string strDetectionModifier;

simulated function array<UISummary_ItemStat> GetUISummary_WeaponStats(optional X2WeaponUpgradeTemplate PreviewUpgradeStats)
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat		Item;
	local array<PenaltyStruct>		Penalties;
	local PenaltyStruct				Penalty;
	local StatChange				CycleStatChange;
	local UIArmory_Loadout		Loadout;
	Stats = super.GetUISummary_WeaponStats(PreviewUpgradeStats);

	//`LOG(GetFuncName() @ GetMyTemplateName() @ InventorySlot,, 'IRITEST');

	// If this function is called when previewing a DRL in the armory locker list,
	// get the penalties for the slot we're about to equip the DRL into.
	if (InventorySlot == eInvSlot_Unknown)
	{
		Loadout = UIArmory_Loadout(`SCREENSTACK.GetScreen(class'UIArmory_Loadout'));
		if (Loadout != none && Loadout.ActiveList == Loadout.LockerList)
		{
			Penalties = class'X2Effect_DRL_Penalty'.static.GetPenaltiesForItemState(self, Loadout.GetSelectedSlot());
		}
		else
		{
			Penalties = class'X2Effect_DRL_Penalty'.static.GetPenaltiesForItemState(self);
		}
	}
	else
	{
		Penalties = class'X2Effect_DRL_Penalty'.static.GetPenaltiesForItemState(self);
	}

	foreach Penalties(Penalty)
	{
		foreach Penalty.StatChanges(CycleStatChange)
		{	
			if (CycleStatChange.StatAmount != 0)
			{
				switch (CycleStatChange.ModOp)
				{
				case MODOP_Multiplication:
				case MODOP_PostMultiplication:
					Item.Label = GetLabelForStat(CycleStatChange.StatType);
					Item.Value = string(FCeil((1 - CycleStatChange.StatAmount) * 100)) $ "%";
					break;
				case MODOP_Addition:
				default:
					Item.Label = GetLabelForStat(CycleStatChange.StatType);
					Item.Value = string(int(CycleStatChange.StatAmount));
					break;
				}

				//`LOG("-- adding stat penalty",, 'IRITEST');
				Stats.AddItem(Item);
			}
		}
	}
	return Stats;
}

static final function string GetLabelForStat(ECharStatType Stat)
{
	local string ReturnString;

	ReturnString = class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[Stat];

	if (ReturnString == "")
	{
		switch (Stat)
		{
		case eStat_ArmorMitigation:      
			return class'XLocalizedData'.default.ArmorLabel;
		case eStat_ArmorPiercing:
			return class'XLocalizedData'.default.PierceLabel;
		case eStat_DetectionModifier:	// The modifier this unit will apply to the range at which other units can detect this unit. Overall Detection Range =  Detector.DetectionRadius * (1.0 - Detectee.DetectionModifier)
			return default.strDetectionModifier;
		case eStat_CritChance:
			return class'XLocalizedData'.default.CritLabel;
		case eStat_FlankingCritChance:
			return class'XLocalizedData'.default.FlankingCritBonus @ class'XLocalizedData'.default.CritLabel;
		case eStat_FlankingAimBonus:
			return class'XLocalizedData'.default.OffenseStat @ class'XLocalizedData'.default.CritLabel;
		case eStat_ShieldHP:
		case eStat_HackDefense:          // Units use this when defending against hacking attempts.
		case eStat_DetectionRadius:		// The radius at which this unit will detect other concealed units.	
		case eStat_BackpackSize:
		case eStat_UtilityItems:
		case eStat_SeeMovement:
		case eStat_HearingRadius:
		case eStat_CombatSims:
		case eStat_Job:
		case eStat_AlertLevel:
		case eStat_FlightFuel:
		case eStat_Invalid:
		default:
			return "";
		}
	}
	return ReturnString;
}
