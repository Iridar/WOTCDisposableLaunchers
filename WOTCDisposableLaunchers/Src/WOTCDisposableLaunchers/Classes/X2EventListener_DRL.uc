class X2EventListener_DRL extends X2EventListener config(DisposableLaunchers);

var config array<EInventorySlot> AllowedDRLInventorySlots;

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
	
	Template.AddCHEvent('OverrideShowItemInLockerList', OnOverrideShowItemInLockerList, ELD_Immediate);

	Template.AddCHEvent('ItemAddedToSlot', OnItemAddedToSlot, ELD_Immediate);

	return Template; 
}

// When a DRL is equipped, its newly created instance will not be using custom XCGS_Item class due to this issue:
// https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/1058
// As a hacky solution, replace one item with another when a DRL is equipped.
static function EventListenerReturn OnItemAddedToSlot(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{
    local XComGameState_Item ItemState;
	local XComGameState_Item NewItemState;
    local XComGameState_Unit UnitState;
	local EInventorySlot	 Slot;

    ItemState = XComGameState_Item(EventData);
	if (ItemState == none || ItemState.GetWeaponCategory() != 'iri_disposable_launcher' || ItemState.Class == class'XComGameState_Item_DRL')
		 return ELR_NoInterrupt;

	ItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(ItemState.ObjectID));
	if (ItemState == none )
		 return ELR_NoInterrupt;
	
	Slot = ItemState.InventorySlot;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none )
		 return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));
	if (UnitState != none && UnitState.RemoveItemFromInventory(ItemState, NewGameState))
	{
		NewItemState = XComGameState_Item(NewGameState.CreateNewStateObject(class'XComGameState_Item_DRL', ItemState.GetMyTemplate()));
		UnitState.AddItemToInventory(NewItemState, Slot, NewGameState);
		NewGameState.RemoveStateObject(ItemState.ObjectID);
	}
	
    return ELR_NoInterrupt;
}

static function EventListenerReturn OnOverrideShowItemInLockerList(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
    local XComGameState_Item ItemState;
    local XComLWTuple Tuple;
    local EInventorySlot Slot;
    local XComGameState_Unit UnitState;

    ItemState = XComGameState_Item(EventSource);
    Tuple = XComLWTuple(EventData);

	if (ItemState == none || ItemState.GetWeaponCategory() != 'iri_disposable_launcher' || Tuple == none)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(Tuple.Data[2].o);
	if (UnitState == none || UnitState.UnitSize != 1 || UnitState.UnitHeight != 2) // Basic check to filter out SPARKs and other non-standard-soldier-sized units.
	{
		Tuple.Data[0].b = false; // bSlotShowItemInLockerList
		return ELR_NoInterrupt;
	}

    Slot = EInventorySlot(Tuple.Data[1].i);
	if (default.AllowedDRLInventorySlots.Find(Slot) != INDEX_NONE) // Is Slot Valid for DRL
	{
		Tuple.Data[0].b = true;
	}
    return ELR_NoInterrupt;
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
		// Use grenade weapon category so that "only one grenade per soldier" message is more consistent.
		if (Template.ItemCat == 'grenade')
		{
			Tuple.Data[0].s = class'XGLocalizedData'.default.UtilityCatGrenade;
		}
		else
		{
			Tuple.Data[0].s = class'X2DownloadableContentInfo_WOTCDisposableLaunchers'.default.DRL_WeaponCategory;
		}
		EventData = Tuple;
	}
	return ELR_NoInterrupt;
}