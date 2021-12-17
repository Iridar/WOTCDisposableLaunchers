class X2DownloadableContentInfo_WOTCDisposableLaunchers extends X2DownloadableContentInfo;

var localized string DRL_WeaponCategory;
var localized string DRL_Requires_Two_Utility_Slots;

var config(DisposableLaunchers) array<name> BELT_CARRIED_MELEE_WEAPONS;

var config(TemplateCreator) array<name> AddItemsToHQInventory;

var private X2GrenadeTemplate DummyGrenadeTemplate;

// TODO
// Russian loc
// Check logs/redscreens during mod's normal operation.
// Record a new video, maybe?

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

`include(WOTCDisposableLaunchers\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

// Add new DRLs into HQ inventory if they're supposed to be there.
// This hook runs only once - when a save game is loaded for the first time after this mod was activated in an on-going campaign.
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
		if (ItemTemplate == none || !ItemTemplate.bInfiniteItem)
			continue;

		if (ItemTemplate.StartingItem || XComHQ.HasItemByName(ItemTemplate.CreatorTemplateName) || XComHQ.IsTechResearched(ItemTemplate.CreatorTemplateName))
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

	local SkeletalMeshSocket NewSocket;
	local array<SkeletalMeshSocket> NewSockets;

	local SkeletalMeshComponent		SkelMesh;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Pawn.ObjectID));
	
	if (UnitState != none && UnitState.IsSoldier())
	{
		UnitBackStruct = HasGrenadeLauncherOrSwordOnTheBack(UnitState);

		if (UnitBackStruct.HasGL)
		{
			if (UnitState.kAppearance.iGender == eGender_Male)
			{
				NewSocket = new class'SkeletalMeshSocket';
				NewSocket.SocketName = 'AT4_Sling';
				NewSocket.BoneName = 'GrenadeLauncherSling';
				NewSocket.RelativeLocation.X = -12.553877f;
				NewSocket.RelativeLocation.Y = 7.512947f;
				NewSocket.RelativeLocation.Z = 20.879244f;
				NewSocket.RelativeRotation.Roll = -15.0f * DegToUnrRot;
				NewSocket.RelativeRotation.Pitch = 182.0f * DegToUnrRot;
				NewSocket.RelativeRotation.Yaw = -1.50f * DegToUnrRot;
				NewSockets.AddItem(NewSocket);
				Pawn.Mesh.AppendSockets(NewSockets, true);
			}
			else
			{
				NewSocket = new class'SkeletalMeshSocket';
				NewSocket.SocketName = 'AT4_Sling';
				NewSocket.BoneName = 'GrenadeLauncherSling';
				NewSocket.RelativeLocation.X = -12.432682f;
				NewSocket.RelativeLocation.Y = 9.149284f;
				NewSocket.RelativeLocation.Z = 18.449038f;
				NewSocket.RelativeRotation.Roll = -15.0f * DegToUnrRot;
				NewSocket.RelativeRotation.Pitch = 180.0f * DegToUnrRot;
				NewSocket.RelativeRotation.Yaw = -3.00f * DegToUnrRot;
				NewSockets.AddItem(NewSocket);
				Pawn.Mesh.AppendSockets(NewSockets, true);
			}
		}
		else if (UnitBackStruct.HasSword) 
		{
			if (UnitState.kAppearance.iGender == eGender_Male)
			{
				NewSocket = new class'SkeletalMeshSocket';
				NewSocket.SocketName = 'AT4_Sling';
				NewSocket.BoneName = 'SwordSheath';
				NewSocket.RelativeLocation.X = -10.746689f;
				NewSocket.RelativeLocation.Y = -5.014373f;
				NewSocket.RelativeLocation.Z = 8.321416f;
				NewSocket.RelativeRotation.Roll = 30 * DegToUnrRot;
				NewSocket.RelativeRotation.Pitch = -116 * DegToUnrRot;
				//NewSocket.RelativeRotation.Yaw = 0 * DegToUnrRot;
				NewSockets.AddItem(NewSocket);
				Pawn.Mesh.AppendSockets(NewSockets, true);
			}
			else
			{
				NewSocket = new class'SkeletalMeshSocket';
				NewSocket.SocketName = 'AT4_Sling';
				NewSocket.BoneName = 'SwordSheath';
				NewSocket.RelativeLocation.X = -10.131029f;
				NewSocket.RelativeLocation.Y = -5.423597f;
				NewSocket.RelativeLocation.Z = 8.020929f;
				NewSocket.RelativeRotation.Roll = 30 * DegToUnrRot;
				NewSocket.RelativeRotation.Pitch = -116 * DegToUnrRot;
				//NewSocket.RelativeRotation.Yaw = 0 * DegToUnrRot;
				NewSockets.AddItem(NewSocket);
				Pawn.Mesh.AppendSockets(NewSockets, true);
			}
		}
		else 
		{
			if (UnitState.kAppearance.iGender == eGender_Male)
			{
				NewSocket = new class'SkeletalMeshSocket';
				NewSocket.SocketName = 'AT4_Sling';
				NewSocket.BoneName = 'GrenadeLauncherSling';
				NewSocket.RelativeLocation.X = -14.375536f;
				NewSocket.RelativeLocation.Y = 5.320904f;
				NewSocket.RelativeLocation.Z = 4.760049f;
				NewSocket.RelativeRotation.Roll = 180 * DegToUnrRot;
				NewSocket.RelativeRotation.Pitch = 180.0f * DegToUnrRot;
				NewSocket.RelativeRotation.Yaw = -7.50f * DegToUnrRot;
				NewSockets.AddItem(NewSocket);
				Pawn.Mesh.AppendSockets(NewSockets, true);
			}
			else
			{
				NewSocket = new class'SkeletalMeshSocket';
				NewSocket.SocketName = 'AT4_Sling';
				NewSocket.BoneName = 'GrenadeLauncherSling';
				NewSocket.RelativeLocation.X = -13.947793f;
				NewSocket.RelativeLocation.Y = 8.563524f;
				NewSocket.RelativeLocation.Z = 4.760049f;
				NewSocket.RelativeRotation.Roll = 180 * DegToUnrRot;
				NewSocket.RelativeRotation.Pitch = 180.0f * DegToUnrRot;
				NewSocket.RelativeRotation.Yaw = -7.50f * DegToUnrRot;
				NewSockets.AddItem(NewSocket);
				Pawn.Mesh.AppendSockets(NewSockets, true);
			}
		}
	}
	return "";
}

static private function BackStruct HasGrenadeLauncherOrSwordOnTheBack(XComGameState_Unit UnitState)
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

static private function bool HasPrimaryMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate()));
}

static private function bool HasSecondaryMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate()));
}

static private function bool HasDualMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate())) &&
		IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate()));
}

static private function bool IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon &&
		WeaponTemplate.iRange == 0 &&
		WeaponTemplate.WeaponCat != 'wristblade' &&
		WeaponTemplate.WeaponCat != 'shield' &&
		WeaponTemplate.WeaponCat != 'grenade_launcher' &&
		WeaponTemplate.WeaponCat != 'gauntlet';
}

static private function bool IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon &&
		WeaponTemplate.iRange == 0 &&
		WeaponTemplate.WeaponCat != 'wristblade' &&
		WeaponTemplate.WeaponCat != 'shield' &&
		WeaponTemplate.WeaponCat != 'grenade_launcher' &&
		WeaponTemplate.WeaponCat != 'gauntlet';
}

static private function bool IsMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.iRange == 0 &&
		WeaponTemplate.WeaponCat != 'wristblade' &&
		WeaponTemplate.WeaponCat != 'shield' &&
		WeaponTemplate.WeaponCat != 'grenade_launcher' &&
		WeaponTemplate.WeaponCat != 'gauntlet' &&
		default.BELT_CARRIED_MELEE_WEAPONS.Find(WeaponTemplate.DataName) == INDEX_NONE; // Musashi's combat knives are worn on belt, no reason to adjust DRL position for them
}

static function GetNumUtilitySlotsOverride(out int NumUtilitySlots, XComGameState_Item EquippedArmor, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	if (`GETMCMVAR(UTILITY_DRL_OCCUPIES_TWO_SLOTS) && NumUtilitySlots > 1)
	{
		// If you ever have some kind of inventory operation that fails to fix the stat, you can manually call ValidateLoadout (or just RealizeItemSlotsCount, CHL only) (c) robojumper
		NumUtilitySlots -= GetNumWeaponOfCategoryInSlot(UnitState, 'iri_disposable_launcher', eInvSlot_Utility, CheckGameState);
	}
}

static final function bool HasItemOfCategoryInSlot(const XComGameState_Unit UnitState, const name ItemCat, const EInventorySlot Slot, optional XComGameState CheckGameState)
{
	local XComGameState_Item Item;
	local StateObjectReference ItemRef;

	foreach UnitState.InventoryItems(ItemRef)
	{
		Item = UnitState.GetItemGameState(ItemRef, CheckGameState);

		if (Item != none && Item.InventorySlot == Slot && Item.GetMyTemplate().ItemCat == ItemCat)
		{
			return true;
		}
	}
	return false;
}

static final function int GetNumWeaponOfCategoryInSlot(const XComGameState_Unit UnitState, const name WeaponCat, const EInventorySlot Slot, optional XComGameState CheckGameState)
{
	local array<XComGameState_Item>	Items;
	local XComGameState_Item		Item;
	local int NumItems;

	Items = UnitState.GetAllItemsInSlot(Slot, CheckGameState,, true);

	foreach Items(Item)
	{
		if (Item.InventorySlot == Slot && Item.GetWeaponCategory() == WeaponCat)
		{
			NumItems++;
		}
	}
	return NumItems;
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
static final function EHLDelegateReturn ShouldDisplayDRL_Strategy(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XComUnitPawn UnitPawn, optional XComGameState CheckGameState)
{
	if (ItemState.GetWeaponCategory() == 'iri_disposable_launcher' && !HasWeaponOfCategoryInSlotOtherThan(UnitState, 'iri_disposable_launcher', ItemState.InventorySlot, CheckGameState))
	{
		bDisplayItem = 1;
	}
	return EHLDR_NoInterrupt;
}
static final function EHLDelegateReturn ShouldDisplayDRL_Tactical(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XGUnit UnitVisualizer, optional XComGameState CheckGameState)
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
			else if (!ItemState.bMergedOut && X2WeaponTemplate(MainDRL.GetMyTemplate()).WeaponTech == X2WeaponTemplate(ItemState.GetMyTemplate()).WeaponTech) // Hack, relying on DRLs within each weapon tech to be the same.
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
// This is unapologetically ubercomplicated. Fowwy not fowwy.
static function bool CanAddItemToInventory_CH_Improved(out int bCanAddItem, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, int Quantity, XComGameState_Unit UnitState, optional XComGameState CheckGameState, optional out string DisabledReason, optional XComGameState_Item ItemState)
{
	local X2WeaponTemplate		WeaponTemplate;
	local XGParamTag            LocTag;
	local bool					OverrideNormalBehavior;
    local bool					DoNotOverrideNormalBehavior;
	local int					NumUtilitySlots;
	local StateObjectReference	ItemRef;
	local array<EInventorySlot> AllowedSlots;
	local array<XComGameState_Item> EquippedItems;
	local XComGameState_Item		EquippedItem;

	// This will be used to store Object ID of the item (if it exists)
	// that is currently equpped into the slot we're considering equipping this new item.
	// I.e. this is the item that is currently equipped on the soldier that will be replaced by the new item.
	local int					SelectedSlotEquippedItemObjectID; 

	OverrideNormalBehavior = CheckGameState != none;
    DoNotOverrideNormalBehavior = CheckGameState == none;   

	//`LOG(UnitState.GetFullName() @ ItemTemplate.DataName @ ItemTemplate.ItemCat @ Slot @ `GETMCMVAR(UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES) @ "called by UI:" @ CheckGameState == none,, 'IRITEST');

	// A. All of the rules regarding equipping a DRL.
	WeaponTemplate = X2WeaponTemplate(ItemTemplate);
	if (WeaponTemplate != none && WeaponTemplate.WeaponCat == 'iri_disposable_launcher')
	{
		// #0. Disallow equipping mismatching DRLs at the same time.
		// Causes maddest clipping.
		MaybeUpdateSelectedSlotEquippedItemObjectID(SelectedSlotEquippedItemObjectID);
		foreach UnitState.InventoryItems(ItemRef)
		{
			if (ItemRef.ObjectID == SelectedSlotEquippedItemObjectID)
				continue;
			
			EquippedItem = UnitState.GetItemGameState(ItemRef, CheckGameState);
			if (EquippedItem != none && EquippedItem.GetWeaponCategory() == 'iri_disposable_launcher' && EquippedItem.GetMyTemplateName() != ItemTemplate.DataName)
			{
				LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
				LocTag.StrValue0 = EquippedItem.GetMyTemplate().GetItemFriendlyNameNoStats();
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strAmmoIncompatible));
				bCanAddItem = 0;
				return OverrideNormalBehavior;
			}
		}

		// #1. Disallow equipping a DRL according to soldier class weapon restrictions.
		// The DRL won't even show up for completely invalid units, like SPARKs, thanks to the ShowItemInLockerList event listener.
		if (!IsWeaponAllowedByClassInSlot(UnitState.GetSoldierClassTemplate(), 'iri_disposable_launcher', Slot))
		{
			LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			LocTag.StrValue0 = UnitState.GetSoldierClassTemplate().DisplayName;
			DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strUnavailableToClass));
			bCanAddItem = 0;
			return OverrideNormalBehavior;
		}

		// Everything inside this statement is such an awful hack, I hate everything
		if (Slot == eInvSlot_Utility)
		{
			// #1A - Disallow equipping DRL into utility slot if the soldier has fewer than two slots currently
			if(`GETMCMVAR(UTILITY_DRL_OCCUPIES_TWO_SLOTS))
			{
				// Calculate number of free utility slots
				// Free Slots = Current Stat - Num Of Equipped Items
				if (CheckGameState != none)
				{
					// Necessary to prevent breaking the inventory when we replace one DRL with another, and the second one can't get equipped because soldier's number of slots didn't update.
					UnitState.RealizeItemSlotsCount(CheckGameState);
				}
				NumUtilitySlots = UnitState.GetCurrentStat(eStat_UtilityItems);
				EquippedItems = UnitState.GetAllItemsInSlot(eInvSlot_Utility, CheckGameState,, true);
				MaybeUpdateSelectedSlotEquippedItemObjectID(SelectedSlotEquippedItemObjectID);
				foreach EquippedItems(EquippedItem)
				{
					if (EquippedItem.ObjectID == SelectedSlotEquippedItemObjectID)
					{
						// If we're equipping a DRL into the slot already occupied by DRL, then we also count the second utility slot occupied by that DRL
						if (EquippedItem.GetWeaponCategory() == 'iri_disposable_launcher')
						{
							NumUtilitySlots++;
						}
						continue;
					}
					NumUtilitySlots--;
				}

				if (NumUtilitySlots < 2)
				{
					DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(default.DRL_Requires_Two_Utility_Slots);
					bCanAddItem = 0;
					return OverrideNormalBehavior;
				}
			}

			if (`GETMCMVAR(UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES))
			{
				EquippedItems = UnitState.GetAllItemsInSlot(eInvSlot_Utility, CheckGameState,, true);
				MaybeUpdateSelectedSlotEquippedItemObjectID(SelectedSlotEquippedItemObjectID);

				// #2. Disallow equipping a DRL into a utility slot if the soldier has a DRL equipped into another utility slot.
				// Check if the soldier has a DRL equipped in a utility slot other than the one we're currently selecting for.
				foreach EquippedItems(EquippedItem)
				{
					if (EquippedItem.ObjectID == SelectedSlotEquippedItemObjectID)
						continue;

					if (EquippedItem.GetWeaponCategory() == 'iri_disposable_launcher')
					{
						LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
						LocTag.StrValue0 = class'XGLocalizedData'.default.UtilityCatGrenade;
						DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strCategoryRestricted));
						bCanAddItem = 0;
						return OverrideNormalBehavior;
					}
				}

				// #3. Disallow equipping a DRL into utility slot if the soldier has a grenade equipped in another utility slot.
				// Check if the soldier has grenades equipped in any other slots.
				// Since DRL weapon template is not actually mutually exclusive with anything, spoof the unique equip check with a dummy grenade template
				if (!UnitState.RespectsUniqueRule(default.DummyGrenadeTemplate, eInvSlot_Utility, , SelectedSlotEquippedItemObjectID))
				{
					LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
					LocTag.StrValue0 = class'XGLocalizedData'.default.UtilityCatGrenade;
					DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strCategoryRestricted));
					return OverrideNormalBehavior;
				}
			}
		}

		// Force allow equipping the DRL into its MCM-configured allowed slots.
		// Being very conservative here; the override behavior is enabled only for single item slots, and only if they're empty.
		AllowedSlots = `GETMCMVAR(DRL_ALLOWED_INVENTORY_SLOTS);
		if (AllowedSlots.Find(Slot) != INDEX_NONE && CheckGameState != none && UnitState.GetItemInSlot(Slot, CheckGameState) == none && !class'CHItemSlot'.static.SlotIsMultiItem(Slot))
		{
			bCanAddItem = 1;
			return OverrideNormalBehavior;
		}
	} // B. Other items.
	else if (Slot == eInvSlot_Utility && ItemTemplate.ItemCat == 'grenade' && `GETMCMVAR(UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES))
	{
		// #4. Disallow equipping grenades into utility slots while the soldier has a DRL equipped in another utility slot.
		
		// Check if the soldier has a DRL equipped in a utility slot other than the one we're currently selecting for.
		EquippedItems = UnitState.GetAllItemsInSlot(eInvSlot_Utility, CheckGameState,, true);
		MaybeUpdateSelectedSlotEquippedItemObjectID(SelectedSlotEquippedItemObjectID);
		foreach EquippedItems(EquippedItem)
		{
			if (EquippedItem.ObjectID == SelectedSlotEquippedItemObjectID)
				continue;

			if (EquippedItem.GetWeaponCategory() == 'iri_disposable_launcher')
			{
				LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
				LocTag.StrValue0 = ItemTemplate.GetLocalizedCategory();
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strCategoryRestricted));
				bCanAddItem = 0;
				return OverrideNormalBehavior;
			}
		}
	}

	return DoNotOverrideNormalBehavior;
}

static final function MaybeUpdateSelectedSlotEquippedItemObjectID(out int SelectedSlotEquippedItemObjectID)
{
	local UIArmory_Loadout		Loadout;
	local UIArmory_LoadoutItem	LoadoutItem;
	local UIScreenStack			ScreenStack;

	if (SelectedSlotEquippedItemObjectID != 0)
		return;
	
	ScreenStack = `SCREENSTACK;
	if (ScreenStack == none)
		return;

	Loadout = UIArmory_Loadout(ScreenStack.GetScreen(class'UIArmory_Loadout'));
	if (Loadout != none && Loadout.EquippedList != none)
	{
		LoadoutItem = UIArmory_LoadoutItem(Loadout.EquippedList.GetSelectedItem());
		if (LoadoutItem != none)
		{
			SelectedSlotEquippedItemObjectID = LoadoutItem.ItemRef.ObjectID;
		}
	}
}

static final function bool IsWeaponAllowedByClassInSlot(const X2SoldierClassTemplate ClassTemplate, const name WeaponCat, const EInventorySlot Slot)
{
	local SoldierClassWeaponType WeaponType;

	switch (Slot)
	{
	case eInvSlot_SecondaryWeapon:
	case eInvSlot_PrimaryWeapon:
		break;
	default:
		return true;
	}

	if (ClassTemplate == none)
		return false;
    
	foreach ClassTemplate.AllowedWeapons(WeaponType)
	{
		if (WeaponType.WeaponType == WeaponCat && WeaponType.SlotType == Slot)
		{
			return true;
		}
	}
	return false;
}


defaultproperties
{
	Begin Object Class=X2GrenadeTemplate Name=DefaultGrenadeTemplate
	End Object
	DummyGrenadeTemplate = DefaultGrenadeTemplate;
}