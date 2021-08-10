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
