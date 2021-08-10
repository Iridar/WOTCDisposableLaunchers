class XComGameState_Item_DRL extends XComGameState_Item;

simulated function array<UISummary_ItemStat> GetUISummary_WeaponStats(optional X2WeaponUpgradeTemplate PreviewUpgradeStats)
{
	local array<UISummary_ItemStat> Stats; 
	local int i;

	// TODO: slot check doesn't work?

	`LOG(GetFuncName() @ self.m_TemplateName @ InventorySlot,, 'IRITEST');

	if (InventorySlot != eInvSlot_Utility)
	{
		Stats = super.GetUISummary_WeaponStats(PreviewUpgradeStats);
		for (i = Stats.Length - 1; i >= 0; i--)
		{
			`LOG(i @ Stats[i].Label,, 'IRITEST');
			if (Stats[i].Label == class'XLocalizedData'.default.MobilityLabel)
			{
				`LOG("Removing mobility",, 'IRITEST');
				Stats.Remove(i, 1);
			}
		}
	}
	return Stats;
}


simulated function bool PopulateWeaponStat(int Value, bool bIsStatModified, int UpgradeValue, out UISummary_ItemStat Item, optional bool bIsPercent)
{
	`LOG(GetFuncName(),, 'IRITEST');
	if (Item.Label == class'XLocalizedData'.default.MobilityLabel && InventorySlot != eInvSlot_Utility)
	{
		`LOG("This is mobility label, exiting",, 'IRITEST');
		return false;
	}
	return super.PopulateWeaponStat(Value, bIsStatModified, UpgradeValue, Item, bIsPercent);
}