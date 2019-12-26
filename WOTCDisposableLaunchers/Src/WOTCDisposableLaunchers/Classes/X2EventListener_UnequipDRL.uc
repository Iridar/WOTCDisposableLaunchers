class X2EventListener_UnequipDRL extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListener());

	return Templates;
}


static function CHEventListenerTemplate CreateListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IridarUnequipDRL_Listener');

	//	triggered by Highlander event
	//	https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/blob/1a31c1620d9ace07fc46cc716510c7bebc637073/X2WOTCCommunityHighlander/Src/XComGame/Classes/CHItemSlot.uc#L390-L425
	Template.AddCHEvent('OverrideItemUnequipBehavior', ShowUnequipButton, ELD_Immediate);	
	Template.RegisterInStrategy = true;

	return Template; 
}

static protected function EventListenerReturn ShowUnequipButton(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComLWTuple				Tuple;
	local XComGameState_Item		ItemState;
	local X2PairedWeaponTemplate	Template;

	Tuple = XComLWTuple(EventData);
	ItemState = XComGameState_Item(EventSource);

	//	this triggers whenever the game decides whether it needs to show the small cross icon in the corner of the item
	//	that allows the player unequip the item from the soldier

	if (ItemState != none && Tuple != none)
	{
		Template = X2PairedWeaponTemplate(ItemState.GetMyTemplate());
		//	if the item in question is a DRL
		if (Template != none && Template.WeaponCat == 'iri_disposable_launcher')
		{
			//	tell the game to show the icon.
			//	the icon is not shown by default, because the default behavior is to not show the icon for items that are infinite or have been modified (I assume robojumper meant weapon upgrades)
			//	clicking the cross icon will unequip the slot, and if necessary, the game will try to put something else in that slot (i.e. unit's default secondary weapon or a grenade for the utiltiy slot)
			Tuple.Data[0].i = eCHSUB_AttemptReEquip;
		}
	}
	return ELR_NoInterrupt;
}