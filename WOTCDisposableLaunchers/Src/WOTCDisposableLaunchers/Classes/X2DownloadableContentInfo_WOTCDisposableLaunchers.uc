class X2DownloadableContentInfo_WOTCDisposableLaunchers extends X2DownloadableContentInfo;

var localized string DRL_WeaponCategory;
var localized string DRL_Category;
var localized string DRL_Not_Allowed_With_Grenades_Message;
var localized string DRL_Requires_Two_Slots;

var config(DisposableLaunchers) bool Utility_DRL_Occupies_Two_Slots;
var config(DisposableLaunchers) array<name> BELT_CARRIED_MELEE_WEAPONS;

var config(TemplateCreator) array<name> AddItemsToHQInventory;

struct BackStruct
{
	var bool HasGL;
	var bool HasSword;

	structdefaultproperties
	{
		HasGL=false
		HasSword=false
	}
};

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGame()
{
	local XComGameState_HeadquartersXCom	XComHQ;	
	local X2ItemTemplateManager				ItemMgr;
	local name								ItemName;
	local X2ItemTemplate					ItemTemplate;
	local XComGameState						NewGameState;
	local XComGameState_Item				ItemState;
	local XComGameStateHistory				History;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if (XComHQ == none)
		return;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add items to HQ");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(XComHQ.Class, XComHQ.ObjectID));

	foreach default.AddItemsToHQInventory(ItemName)
	{
		if (XComHQ.HasItemByName(ItemName))
			continue;

		ItemTemplate = ItemMgr.FindItemTemplate(ItemName);
		if (ItemTemplate == none)
			continue;

		if (XComHQ.HasItemByName(ItemTemplate.CreatorTemplateName) || XComHQ.IsTechResearched(ItemTemplate.CreatorTemplateName))
		{	
			ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
			XComHQ.PutItemInInventory(NewGameState, ItemState);
		}
	}

	History = `XCOMHISTORY;
	if (ItemState != none)
	{
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

static function string DLCAppendSockets(XComUnitPawn Pawn)
{
	local XComGameState_Unit	UnitState;
	local BackStruct			UnitBackStruct;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Pawn.ObjectID));

	if (UnitState != none && UnitState.IsSoldier())
	{
		UnitBackStruct = HasGrenadeLauncherOrSwordOnTheBack(UnitState);

		if (UnitBackStruct.HasGL)
		{
			if (UnitState.kAppearance.iGender == eGender_Male)
			{
				return "Disposable_Common.Meshes.SM_Sockets_GL_M";
			}
			else
			{
				return "Disposable_Common.Meshes.SM_Sockets_GL_F";
			}
		}

		if (UnitBackStruct.HasSword) 
		{
			if (UnitState.kAppearance.iGender == eGender_Male)
			{
				return "Disposable_Common.Meshes.SM_Sockets_Sword_M";
			}
			else
			{
				return "Disposable_Common.Meshes.SM_Sockets_Sword_F";
			}
		}

		if (UnitState.kAppearance.iGender == eGender_Male)
		{
			return "Disposable_Common.Meshes.SM_MaleSockets";
		}
		else
		{
			return "Disposable_Common.Meshes.SM_FemaleSockets";
		}
	}
	return "";
}

static function BackStruct HasGrenadeLauncherOrSwordOnTheBack(XComGameState_Unit UnitState)
{
	local array<XComGameState_Item> InventoryItems;
	local X2GrenadeLauncherTemplate GLTemplate;
	local X2WeaponTemplate			WeaponTemplate;
	local BackStruct				ReturnStruct;

	local bool HasSword, HasPrimarySword;
	local bool HasGrenadeLauncher, HasPrimaryGrenadeLauncher;
	local int i;
	
	HasPrimarySword = HasPrimaryMeleeEquipped(UnitState);

	InventoryItems =  UnitState.GetAllInventoryItems();

	for (i = 0; i < InventoryItems.Length; ++i)
	{
		WeaponTemplate = X2WeaponTemplate(InventoryItems[i].GetMyTemplate());

		if (IsMeleeWeaponTemplate(WeaponTemplate))
		{
			HasSword = true;
			continue;
		}

		GLTemplate = X2GrenadeLauncherTemplate(WeaponTemplate);
		if (GLTemplate != none)
		{
			HasGrenadeLauncher = true;
			if (GLTemplate.InventorySlot == eInvSlot_PrimaryWeapon)
			{
				HasPrimaryGrenadeLauncher = true;
			}
		}
	}

	if (HasGrenadeLauncher && !HasPrimaryGrenadeLauncher)
	{
		// The soldier has a Secondary Weapon or a Utility Slot grenade launcher, so it's carried on the back.
		ReturnStruct.HasGL = true;
	}

	if (HasSword && !HasPrimarySword)
	{
		// The soldier has a Secondary Weapon or Utility Slot sword, so it's sheathed on the back (knives count as swords too)
		ReturnStruct.HasSword = true;
	}
	return ReturnStruct;
}

static function bool HasPrimaryMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate()));
}

static function bool HasSecondaryMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate()));
}

static function bool HasDualMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate())) &&
		IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate()));
}

static function bool IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon &&
		WeaponTemplate.iRange == 0 &&
		WeaponTemplate.WeaponCat != 'wristblade' &&
		WeaponTemplate.WeaponCat != 'shield' &&
		WeaponTemplate.WeaponCat != 'grenade_launcher' &&
		WeaponTemplate.WeaponCat != 'gauntlet';
}

static function bool IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon &&
		WeaponTemplate.iRange == 0 &&
		WeaponTemplate.WeaponCat != 'wristblade' &&
		WeaponTemplate.WeaponCat != 'shield' &&
		WeaponTemplate.WeaponCat != 'grenade_launcher' &&
		WeaponTemplate.WeaponCat != 'gauntlet';
}

static function bool IsMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.iRange == 0 &&
		WeaponTemplate.WeaponCat != 'wristblade' &&
		WeaponTemplate.WeaponCat != 'shield' &&
		WeaponTemplate.WeaponCat != 'grenade_launcher' &&
		WeaponTemplate.WeaponCat != 'gauntlet' &&
		default.BELT_CARRIED_MELEE_WEAPONS.Find(WeaponTemplate.DataName) == INDEX_NONE; // Musashi's combat knives are worn on belt, no reason to adjust DRL position for them
}

static function bool HasItem(name TemplateName, X2ItemTemplateManager ItemMgr, XComGameState_HeadquartersXCom OldXComHQState)
{
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = ItemMgr.FindItemTemplate(TemplateName);

	return OldXComHQState.HasItem(ItemTemplate);
}

static function GetNumUtilitySlotsOverride(out int NumUtilitySlots, XComGameState_Item EquippedArmor, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	if (default.Utility_DRL_Occupies_Two_Slots && NumUtilitySlots > 1 && HasWeaponOfCategoryInSlot(UnitState, 'iri_disposable_launcher', eInvSlot_Utility, CheckGameState))
	{
		// If you ever have some kind of inventory operation that fails to fix the stat, you can manually call ValidateLoadout (or just RealizeItemSlotsCount, CHL only) (c) robojumper
		NumUtilitySlots--;
	}
}

static final function bool HasWeaponOfCategoryInSlot(const XComGameState_Unit UnitState, const name WeaponCat, const EInventorySlot Slot, optional XComGameState CheckGameState)
{
	local XComGameState_Item Item;
	local StateObjectReference ItemRef;

	foreach UnitState.InventoryItems(ItemRef)
	{
		Item = UnitState.GetItemGameState(ItemRef, CheckGameState);

		if(Item != none && Item.GetWeaponCategory() == WeaponCat && Item.InventorySlot == Slot)
		{
			return true;
		}
	}
	return false;
}

static final function bool HasWeaponOfCategoryInSlotOtherThan(const XComGameState_Unit UnitState, const name WeaponCat, const EInventorySlot Slot, optional XComGameState CheckGameState)
{
	local XComGameState_Item Item;
	local StateObjectReference ItemRef;

	foreach UnitState.InventoryItems(ItemRef)
	{
		Item = UnitState.GetItemGameState(ItemRef, CheckGameState);

		if(Item != none && Item.GetWeaponCategory() == WeaponCat && Item.InventorySlot != Slot)
		{
			return true;
		}
	}
	return false;
}

// =========================

static event OnPostTemplatesCreated()
{
	local CHHelpers	CHHelpersObj;

	CHHelpersObj = class'CHHelpers'.static.GetCDO();
	if (CHHelpersObj != none)
	{		
		CHHelpersObj.AddShouldDisplayMultiSlotItemInStrategyCallback(ShouldDisplayDRL_Strategy);
		CHHelpersObj.AddShouldDisplayMultiSlotItemInTacticalCallback(ShouldDisplayDRL_Tactical);
	}
}
static function EHLDelegateReturn ShouldDisplayDRL_Strategy(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XComUnitPawn UnitPawn, optional XComGameState CheckGameState)
{
	if (ItemState.GetWeaponCategory() == 'iri_disposable_launcher' && !HasWeaponOfCategoryInSlotOtherThan(UnitState, 'iri_disposable_launcher', ItemState.InventorySlot, CheckGameState))
	{
		bDisplayItem = 1;
	}
	return EHLDR_NoInterrupt;
}
static function EHLDelegateReturn ShouldDisplayDRL_Tactical(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XGUnit UnitVisualizer, optional XComGameState CheckGameState)
{
	if (ItemState.GetWeaponCategory() == 'iri_disposable_launcher' && !ItemState.bMergedOut)
	{
		bDisplayItem = 1;
	}
	return EHLDR_NoInterrupt;
}

static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local XComGameState_Item ItemState;
	local XComGameState_Item SecondaryWeapon;
	local int Index;

	if (StartState != none)
	{
		MergeDRLAmmo(UnitState, StartState);
	}

	// Proceed only if the soldier has a secondary DRL equipped
	SecondaryWeapon = UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, StartState);
	if (SecondaryWeapon == none || SecondaryWeapon.GetWeaponCategory() != 'iri_disposable_launcher')
		return;

	// Cycle through soldier's abilities and see if they have any abilities applied to the secondary weapon (so DRL) 
	// that use launched grenade effects (e.g. Launch Grenade), and if so - remove them.
	for (Index = SetupData.Length - 1; Index >= 0; Index--)
	{
		if (SetupData[Index].Template.bUseLaunchedGrenadeEffects && SecondaryWeapon.ObjectID == SetupData[Index].SourceWeaponRef.ObjectID)
		{
			SetupData.Remove(Index, 1);
		}

		// Also get rid of FireRPG that is pointless on merged out DRLs.
		if (SetupData[Index].TemplateName == 'IRI_FireRPG')
		{
			ItemState = XComGameState_Item(StartState.GetGameStateForObjectID(SetupData[Index].SourceWeaponRef.ObjectID));
			if (ItemState != none && ItemState.bMergedOut)
			{
				SetupData.Remove(Index, 1);
			}
		}
	}
}

static final function MergeDRLAmmo(XComGameState_Unit UnitState, XComGameState StartState)
{
	local XComGameStateHistory	History; 
	local XComGameState_Item	MainDRL;
	local XComGameState_Item	ItemState;
	local int BonusAmmo;
	local int Idx;

	History = `XCOMHISTORY; 

	for (Idx = 0; Idx < UnitState.InventoryItems.Length; Idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(UnitState.InventoryItems[Idx].ObjectID));
		if (ItemState != none && ItemState.GetWeaponCategory() == 'iri_disposable_launcher')
		{
			if (MainDRL == none)
			{
				MainDRL = XComGameState_Item(StartState.ModifyStateObject(ItemState.Class, ItemState.ObjectID));
			}
			else if (X2WeaponTemplate(MainDRL.GetMyTemplate()).WeaponTech == X2WeaponTemplate(ItemState.GetMyTemplate()).WeaponTech) // Hack, relying on DRLs within each weapon tech to be the same.
			{
				MainDRL.MergedItemCount++;

				ItemState = XComGameState_Item(StartState.ModifyStateObject(ItemState.Class, ItemState.ObjectID));

				BonusAmmo += UnitState.GetBonusWeaponAmmoFromAbilities(ItemState, StartState); // Unprotect locally	
				ItemState.bMergedOut = true;
				ItemState.Ammo = 0;
			}
		}
	}
	if (MainDRL != none)
	{
		MainDRL.Ammo = MainDRL.GetClipSize() * MainDRL.MergedItemCount + BonusAmmo;
	}
}
