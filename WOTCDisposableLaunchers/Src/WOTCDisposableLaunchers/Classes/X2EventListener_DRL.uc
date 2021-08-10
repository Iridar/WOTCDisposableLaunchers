class X2EventListener_DRL extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateStrategyListener());
	Templates.AddItem(CreateListener());

	return Templates;
}


static final function CHEventListenerTemplate CreateStrategyListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IRI_X2EventListener_DRL_Strategy');

	Template.RegisterInStrategy = true;

	//	triggered by Highlander event
	//	https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/blob/1a31c1620d9ace07fc46cc716510c7bebc637073/X2WOTCCommunityHighlander/Src/XComGame/Classes/CHItemSlot.uc#L390-L425
	Template.AddCHEvent('OverrideItemUnequipBehavior', ShowUnequipButton, ELD_Immediate);	
	
	// https://x2communitycore.github.io/X2WOTCCommunityHighlander/strategy/ShowItemInLockerList/
	Template.AddCHEvent('OverrideShowItemInLockerList', OnOverrideShowItemInLockerList, ELD_Immediate);	

	return Template; 
}

static final function EventListenerReturn OnOverrideShowItemInLockerList(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
    local XComGameState_Item	ItemState;
	local XComGameState_Unit	UnitState;
    local XComLWTuple			Tuple;

    ItemState = XComGameState_Item(EventSource);
	if (ItemState != none && ItemState.GetWeaponCategory() == 'iri_disposable_launcher')
	{
		Tuple = XComLWTuple(EventData);
		switch (Tuple.Data[1].i)
		{
		case eInvSlot_SecondaryWeapon:
			UnitState = XComGameState_Unit(Tuple.Data[2].o);
			if (UnitState != none && 
				IsWeaponAllowedByClassInSlot(UnitState.GetSoldierClassTemplate(), 'iri_disposable_launcher', eInvSlot_SecondaryWeapon))
			{
				Tuple.Data[0].b = true;
			}
			break;
		case eInvSlot_HeavyWeapon:
			Tuple.Data[0].b = true;
			break;
		default:
			break;
		}
	}
    return ELR_NoInterrupt;
}

static final function bool IsWeaponAllowedByClassInSlot(const X2SoldierClassTemplate ClassTemplate, const name WeaponCat, const EInventorySlot Slot)
{
	local SoldierClassWeaponType WeaponType;
	
	foreach ClassTemplate.AllowedWeapons(WeaponType)
	{
		if (WeaponType.WeaponType == WeaponCat && WeaponType.SlotType == Slot)
		{
			return true;
		}
	}
	return false;
}

static final function EventListenerReturn ShowUnequipButton(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComLWTuple				Tuple;
	local XComGameState_Item		ItemState;

	Tuple = XComLWTuple(EventData);
	ItemState = XComGameState_Item(EventSource);

	//	this triggers whenever the game decides whether it needs to show the small cross icon in the corner of the item
	//	that allows the player unequip the item from the soldier

	if (ItemState != none && ItemState.GetWeaponCategory() == 'iri_disposable_launcher' && Tuple != none)
	{
		//	tell the game to show the icon.
		//	the icon is not shown by default, because the default behavior is to not show the icon for items that are infinite or have been modified 
		//	clicking the cross icon will unequip the slot, and if necessary, the game will try to put something else in that slot (i.e. unit's default secondary weapon or a grenade for the utiltiy slot)
		Tuple.Data[0].i = eCHSUB_AttemptReEquip;
	}
	return ELR_NoInterrupt;
}

static final function CHEventListenerTemplate CreateListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IRI_X2EventListener_DRL');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('GetLocalizedCategory', OnGetLocalizedCategory, ELD_Immediate);
	return Template;
}

static final function EventListenerReturn OnGetLocalizedCategory(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComLWTuple Tuple;
    local X2WeaponTemplate Template;

    Tuple = XComLWTuple(EventData);
    Template = X2WeaponTemplate(EventSource);

	if (Template.WeaponCat == 'iri_disposable_launcher')
	{
		Tuple.Data[0].s = class'X2DownloadableContentInfo_WOTCDisposableLaunchers'.default.DRL_WeaponCategory;
		EventData = Tuple;
	}
	return ELR_NoInterrupt;
}