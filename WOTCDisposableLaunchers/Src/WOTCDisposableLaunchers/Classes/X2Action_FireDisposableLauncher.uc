class X2Action_FireDisposableLauncher extends X2Action_Fire;

function Init()
{
	local XComGameState_Item SourceWeapon;	

	super.Init();

	SourceWeapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));

	//	Note: the weapon's ammo will be examined *after* the ability ammo cost is paid.
	if (SourceWeapon != none && SourceWeapon.Ammo == 0 && SourceWeapon.InventorySlot != eInvSlot_SecondaryWeapon) // Temporary bandaid, ResetWeaponsToDefaultSockets() after the shot will force show the DRL if it's secondary. 
	{
		AnimParams.AnimName = 'FF_FireDrop';
	}
}