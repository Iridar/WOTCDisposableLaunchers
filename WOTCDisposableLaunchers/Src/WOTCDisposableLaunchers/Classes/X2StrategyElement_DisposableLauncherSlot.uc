class X2StrategyElement_DisposableLauncherSlot extends CHItemSlotSet;

//	Adds a hidden inventory slot to all soldiers which is used to store the cosmetic copies of rockets and disposable launchers

var const array<name> DRL_Templates;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	Templates.AddItem(CreateSlotTemplate());
	return Templates;
}

static function X2DataTemplate CreateSlotTemplate()
{
	local CHItemSlot Template;

	`CREATE_X2TEMPLATE(class'CHItemSlot', Template, 'DisposableLauncherSlot');

	Template.InvSlot = class'X2Item_DisposableLaunchers'.default.RPG_Inventory_Slot;
	Template.SlotCatMask = Template.SLOT_WEAPON | Template.SLOT_ITEM;

	Template.IsUserEquipSlot = false;
	Template.IsEquippedSlot = false;
	Template.SlotCatMask = 0;
	Template.BypassesUniqueRule = true;
	Template.IsMultiItemSlot = false;

	Template.IsSmallSlot = false;
	Template.NeedsPresEquip = true;
	Template.ShowOnCinematicPawns = true;

	Template.UnitShowSlotFn = ShowSlot;
	Template.CanAddItemToSlotFn = CanAddItemToSlot;
	Template.UnitHasSlotFn = HasSlot;
	Template.GetPriorityFn = SlotGetPriority;
	Template.ShowItemInLockerListFn = ShowItemInLockerList;
	Template.ValidateLoadoutFn = ValidateLoadout;
	Template.GetSlotUnequipBehaviorFn = SlotGetUnequipBehavior;

	return Template;
}

static function bool CanAddItemToSlot(CHItemSlot Slot, XComGameState_Unit Unit, X2ItemTemplate Template, optional XComGameState CheckGameState, optional int Quantity = 1, optional XComGameState_Item ItemState)
{
    return true;
}


static function bool HasSlot(CHItemSlot Slot, XComGameState_Unit UnitState, out string LockedReason, optional XComGameState CheckGameState)
{
	if (UnitState.IsSoldier())
	{	
		return true;	
	}
	return false;
}

static function int SlotGetPriority(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return 55;
}

static function bool ShowItemInLockerList(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_Item ItemState, X2ItemTemplate ItemTemplate, XComGameState CheckGameState)
{
	return true;
}

static function bool ShowSlot(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return false;
}

static function ValidateLoadout(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	local XComGameState_Item EquippedItem;
	local string strDummy;
	local bool HasSlot;
	
	local bool HasDRL;
	local name TemplateName;

	//	Run a check if the soldier has a DRL equipped at all
	HasDRL = false;
	foreach default.DRL_Templates(TemplateName)
	{
		HasDRL = HasDRL || Unit.HasItemOfTemplateType(TemplateName);
	}
	
	EquippedItem = Unit.GetItemInSlot(Slot.InvSlot, NewGameState);
	HasSlot = Slot.UnitHasSlot(Unit, strDummy, NewGameState);

	//	if the soldier has an item in the templateed slot AND
	//	(he's not supposed to have the slot in the first place OR if the soldier has a slot but on DRL in utility / secondary / heavy slots
	//	then unequip the item from the templated slot and put it back into HQ inventory (maybe should destroy it instead?)
	if(EquippedItem != none && (!HasSlot || HasSlot && !HasDRL))
	{
		EquippedItem = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', EquippedItem.ObjectID));
		Unit.RemoveItemFromInventory(EquippedItem, NewGameState);
		XComHQ.PutItemInInventory(NewGameState, EquippedItem);
		EquippedItem = none;
	}
}

function ECHSlotUnequipBehavior SlotGetUnequipBehavior(CHItemSlot Slot, ECHSlotUnequipBehavior DefaultBehavior, XComGameState_Unit Unit, XComGameState_Item ItemState, optional XComGameState CheckGameState)
{
	return eCHSUB_AllowEmpty;
}

defaultproperties
{
	DRL_Templates[0]="IRI_RPG_CV_Utility"
	DRL_Templates[1]="IRI_RPG_CV_Secondary"
	DRL_Templates[2]="IRI_RPG_CV_Heavy"
	DRL_Templates[3]="IRI_RPG_MG_Utility"
	DRL_Templates[4]="IRI_RPG_MG_Secondary"
	DRL_Templates[5]="IRI_RPG_MG_Heavy"
	DRL_Templates[6]="IRI_RPG_BM_Utility"
	DRL_Templates[7]="IRI_RPG_BM_Secondary"
	DRL_Templates[8]="IRI_RPG_BM_Heavy"
}