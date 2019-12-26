class X2Effect_IRI_StackAmmo extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit			UnitState;
	local StateObjectReference			Ref; 
	local XComGameState_Item			ItemState, RPGState;
	local X2PairedWeaponTemplate		PairedTemplate;
	local X2DisposableLauncherTemplate	RPGTemplate;
	local XComGameStateHistory			History;

	//	Grab the Unit State of the soldier we're applying effect to
	UnitState = XComGameState_Unit(kNewTargetState);
	History = `XCOMHISTORY;

	RPGState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ApplyEffectParameters.ItemStateObjectRef.ObjectID));

	if (RPGState != none)
	{
		RPGTemplate = X2DisposableLauncherTemplate(RPGState.GetMyTemplate());
		
		if (RPGTemplate != none)
		{
			//	zero ammo out so that launcher doesn't double dip into its own ammo
			RPGState.Ammo = 0;

			//	go through all inventory items
			foreach UnitState.InventoryItems(Ref)
			{
				ItemState = XComGameState_Item(History.GetGameStateForObjectID(Ref.ObjectID));
				PairedTemplate = X2PairedWeaponTemplate(ItemState.GetMyTemplate());
		
				if(PairedTemplate != none) 
				{
					if (PairedTemplate.PairedTemplateName == RPGTemplate.DataName)
					{
						RPGState.Ammo += RPGTemplate.iClipSize;
					}
				}
			}
		}
	}
	//	and apply it
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}