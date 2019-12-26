class X2DownloadableContentInfo_WOTCDisposableLaunchers extends X2DownloadableContentInfo config(DisposableLaunchers);

var localized string DRL_Category;
var localized string DRL_Not_Allowed_With_Grenades_Message;
var localized string DRL_Requires_Two_Slots;
var config bool Utility_DRL_Occupies_Two_Slots;

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
static event OnLoadedSavedGameToStrategy()
{
	local XComGameState_HeadquartersXCom OldXComHQState;	
	local X2ItemTemplateManager ItemMgr;

	OldXComHQState = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	if (!HasItem('IRI_RPG_CV_Utility', ItemMgr, OldXComHQState)) AddWeapon('IRI_RPG_CV_Utility');
	if (!HasItem('IRI_RPG_CV_Secondary', ItemMgr, OldXComHQState)) AddWeapon('IRI_RPG_CV_Secondary');

	if (!HasItem('IRI_RPG_MG_Utility', ItemMgr, OldXComHQState) && OldXComHQState.IsTechResearched(class'X2Item_DisposableLaunchers'.default.RPG_MG_CREATOR_TEMPLATE)) AddWeapon('IRI_RPG_MG_Utility');
	if (!HasItem('IRI_RPG_MG_Secondary', ItemMgr, OldXComHQState) && OldXComHQState.IsTechResearched(class'X2Item_DisposableLaunchers'.default.RPG_MG_CREATOR_TEMPLATE)) AddWeapon('IRI_RPG_MG_Secondary');

	if (!HasItem('IRI_RPG_BM_Utility', ItemMgr, OldXComHQState) && OldXComHQState.IsTechResearched(class'X2Item_DisposableLaunchers'.default.RPG_BM_CREATOR_TEMPLATE)) AddWeapon('IRI_RPG_BM_Utility');
	if (!HasItem('IRI_RPG_BM_Secondary', ItemMgr, OldXComHQState) && OldXComHQState.IsTechResearched(class'X2Item_DisposableLaunchers'.default.RPG_BM_CREATOR_TEMPLATE)) AddWeapon('IRI_RPG_BM_Secondary');
}

exec function IridarGiveMeDisposableLaunchers()
{
	local XComGameState_HeadquartersXCom OldXComHQState;	
	local X2ItemTemplateManager ItemMgr;

	OldXComHQState = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	if (!HasItem('IRI_RPG_CV_Utility', ItemMgr, OldXComHQState)) AddWeapon('IRI_RPG_CV_Utility');
	if (!HasItem('IRI_RPG_CV_Secondary', ItemMgr, OldXComHQState)) AddWeapon('IRI_RPG_CV_Secondary');

	if (!HasItem('IRI_RPG_MG_Utility', ItemMgr, OldXComHQState)) AddWeapon('IRI_RPG_MG_Utility');
	if (!HasItem('IRI_RPG_MG_Secondary', ItemMgr, OldXComHQState)) AddWeapon('IRI_RPG_MG_Secondary');

	if (!HasItem('IRI_RPG_BM_Utility', ItemMgr, OldXComHQState)) AddWeapon('IRI_RPG_BM_Utility');
	if (!HasItem('IRI_RPG_BM_Secondary', ItemMgr, OldXComHQState)) AddWeapon('IRI_RPG_BM_Secondary');
}

exec function UnequipDisposableLaunchers()
{
	local XComGameState_HeadquartersXCom	OldXComHQState;	
	local XComGameState						NewGameState;
	local XComGameStateHistory				History;
	local StateObjectReference				Reference;
	local XComGameState_Unit				UnitState;
	local XComGameState_Unit				NewUnitState;
	local XComGameState_Item				ItemState;
	//local XComGameState_Item				NewItemState;
	local X2PairedWeaponTemplate			PairedTemplate;
	local X2DisposableLauncherTemplate		DRLTemplate;
	local bool								AddedSomething;

	History = `XCOMHISTORY;	

	OldXComHQState = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unequipping DRLs from soldiers");

	foreach OldXComHQState.Crew(Reference)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Reference.ObjectID));

		if (UnitState.IsSoldier())
		{
			//NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

			foreach NewUnitState.InventoryItems(Reference)
			{
				ItemState = XComGameState_Item(History.GetGameStateForObjectID(Reference.ObjectID));

				PairedTemplate = X2PairedWeaponTemplate(ItemState.GetMyTemplate());
				DRLTemplate = X2DisposableLauncherTemplate(ItemState.GetMyTemplate());

				if (PairedTemplate != none && PairedTemplate.WeaponCat == 'iri_disposable_launcher' || DRLTemplate != none)
				{
					//NewItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));
					//NewGameState.AddStateObject(NewItemState);

					`LOG("Found DRL: " @ ItemState.GetMyTemplateName() @ "equipped on: " @ UnitState.GetFullName(),, 'IRIDRL');
					if (NewUnitState.RemoveItemFromInventory(ItemState, NewGameState))
					{
						`LOG("Removed item: " @ ItemState.GetMyTemplateName() @ "from" @ UnitState.GetFullName(),, 'IRIDRL');
						//NewGameState.PurgeGameStateForObjectID(NewItemState.ObjectID);
					}
					else
					{	
						`LOG("Couldn't remove item " @ ItemState.GetMyTemplateName() @ "from" @ UnitState.GetFullName(),, 'IRIDRL');
					}
					NewGameState.AddStateObject(NewUnitState);
					AddedSomething = true;
				}
			}
		}
	}
	if (AddedSomething)
	{
		//`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
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

//	Using a hook to remove instances of Launch Grenade ability attached to rockets, since they're not intended to be launchable with grenade launchers (duh)
static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local XComGameState_Item	ItemState;
	local XComGameStateHistory	History;
	local StateObjectReference	Ref; 
	local bool HasGrenadeLauncher;
	local int Index;

	if (!UnitState.IsSoldier())	return;

	History = `XCOMHISTORY;

	foreach UnitState.InventoryItems(Ref)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(Ref.ObjectID));

		if (X2GrenadeLauncherTemplate(ItemState.GetMyTemplate()) != none)
		{
			HasGrenadeLauncher = true;
			break;
		}
	}

	for (Index = SetupData.Length - 1; Index >= 0; Index--)
	{
		if (SetupData[Index].Template.bUseLaunchedGrenadeEffects)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(SetupData[Index].SourceAmmoRef.ObjectID));

			//	Remove 'Launche Grenade' from disposable rocket launchers
			if(ItemState != none && X2DisposableLauncherTemplate(ItemState.GetMyTemplate()) != none) 
			{
				SetupData.Remove(Index, 1);
			}
			else 
			{
				//	Remove 'Launche Grenade' from grenades too if the soldier doesn't have a grenade launcher equipped
				if (!HasGrenadeLauncher)
				{
					if(X2GrenadeTemplate(ItemState.GetMyTemplate()) != none) 
					{
						SetupData.Remove(Index, 1);
					}
				}
			}
		}
	}
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
		class'X2Item_DisposableLaunchers'.default.BELT_CARRIED_MELEE_WEAPONS.Find(WeaponTemplate.DataName) == INDEX_NONE; // Musashi's combat knives are worn on belt, no reason to adjust DRL position for them
}

static function bool HasItem(name TemplateName, X2ItemTemplateManager ItemMgr, XComGameState_HeadquartersXCom OldXComHQState)
{
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = ItemMgr.FindItemTemplate(TemplateName);

	return OldXComHQState.HasItem(ItemTemplate);
}

static function AddWeapon(name TemplateName)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom OldXComHQState;	
	local XComGameState_HeadquartersXCom NewXComHQState;
	local XComGameState_Item ItemState;
	local X2ItemTemplateManager ItemMgr;
	local X2ItemTemplate ItemTemplate;

	//In this method, we demonstrate functionality that will add ExampleWeapon to the player's inventory when loading a saved
	//game. This allows players to enjoy the content of the mod in campaigns that were started without the mod installed.
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	History = `XCOMHISTORY;	

	//Create a pending game state change
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding EXALT Objects");

	//Get the previous XCom HQ state - we'll need it's ID to create a new state for it
	OldXComHQState = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	//Make the new XCom HQ state. This starts out as just a copy of the previous state.
	NewXComHQState = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', OldXComHQState.ObjectID));
	
	//Make the changes to the HQ state. Here we add items to the HQ's inventory
	ItemTemplate = ItemMgr.FindItemTemplate(TemplateName);
		
	//Instantiate a new item state object using the template.
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(ItemState);

	//Add the newly created item to the HQ inventory
	NewXComHQState.AddItemToHQInventory(ItemState);	

	//Commit the new HQ state object to the state change that we built
	NewGameState.AddStateObject(NewXComHQState);

	//Commit the state change into the history.
	History.AddGameStateToHistory(NewGameState);
}

static function bool CanAddItemToInventory_CH_Improved(out int bCanAddItem, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, int Quantity, XComGameState_Unit UnitState, optional XComGameState CheckGameState, optional out string DisabledReason, optional XComGameState_Item ItemState) 
{
    local X2PairedWeaponTemplate        Template;
    local XGParamTag                    LocTag;
    local bool							OverrideNormalBehavior;
    local bool							DoNotOverrideNormalBehavior;
	local X2SoldierClassTemplateManager	Manager;

    // Prepare return values to make it easier for us to read the code.
    OverrideNormalBehavior = CheckGameState != none;
    DoNotOverrideNormalBehavior = CheckGameState == none;

    // If there already is a Disabled Reason, it means another mod has already disallowed equipping this item.
    // In this case, we do not interfere with that mod's functions for better compatibility.
    if(DisabledReason != "")
        return DoNotOverrideNormalBehavior; 

	// Checks for Disposable Launchers
    Template = X2PairedWeaponTemplate(ItemTemplate);

    //  This weapon is a variant of the DRL
    if(Template != none && Template.WeaponCat == 'iri_disposable_launcher')
    {
        Manager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

        //  if this is a secondary weapon DRL and the soldier class is not allowed to equip it, do nothing
        if (Template.InventorySlot == eInvSlot_SecondaryWeapon && !Manager.FindSoldierClassTemplate(UnitState.GetSoldierClassTemplateName()).IsWeaponAllowedByClass(Template))
		{
            return DoNotOverrideNormalBehavior;     
		}

		//	if this is a utility DRL, and it is configured to occupy two slots, allow equipping it only if the soldier has more than one slot.
		if (default.Utility_DRL_Occupies_Two_Slots && Template.InventorySlot == eInvSlot_Utility)
		{
			if (UnitState.GetCurrentStat(eStat_UtilityItems) > 1)
			{
				return DoNotOverrideNormalBehavior;  
			}
			else 
			{
				DisabledReason = default.DRL_Requires_Two_Slots;
				bCanAddItem = 0;
				return OverrideNormalBehavior;
			}
		}

		//	spark or a MEC
		if (!UnitState.CanTakeCover())
		{
			// return "unavailable to this class" error
			LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			LocTag.StrValue0 = UnitState.GetSoldierClassTemplate().DisplayName;
			DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strUnavailableToClass));
			bCanAddItem = 0;
			return OverrideNormalBehavior;
		}
		
		//	if only one DRL per soldier...
		if (class'X2Item_DisposableLaunchers'.default.MAX_ONE_DRL_PER_SOLDIER)
		{
			if (UnitState.HasItemOfTemplateClass(class'X2DisposableLauncherTemplate'))
			{
				//DisabledReason = "Only one DRL per soldier";
				LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
				LocTag.StrValue0 = default.DRL_Category;
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strCategoryRestricted));
				bCanAddItem = 0;
				return OverrideNormalBehavior;
			}
		}
    }
    return DoNotOverrideNormalBehavior; //the item could not have possibly been a DRL or a grenade so we don't care
}

static function GetNumUtilitySlotsOverride(out int NumUtilitySlots, XComGameState_Item EquippedArmor, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	if (default.Utility_DRL_Occupies_Two_Slots && NumUtilitySlots > 1 && UnitHasUtilityDRLEquipped(UnitState))
	{
		// If you ever have some kind of inventory operation that fails to fix the stat, you can manually call ValidateLoadout (or just RealizeItemSlotsCount, CHL only) (c) robojumper
		NumUtilitySlots--;
	}
}

//	this function will cycle through all inventory items of a given unit and return true if one of them is an offensive grenade in a utility slot
/*
static function bool UnitHasGrenadeEquipped(XComGameState_Unit UnitState)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item		Item;

	Items = UnitState.GetAllInventoryItems(, true);
	foreach Items(Item)
	{
		if (ItemTemplateIsAGrenade(Item.GetMyTemplate()))
		{
			return true;
		}
	}
	return false;
}

static function int GetNumberOfUtilityItems(XComGameState_Unit UnitState)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item		Item;
	local int iValue;

	Items = UnitState.GetAllInventoryItems(, true);
	foreach Items(Item)
	{
		if (Item.InventorySlot == eInvSlot_Utility) iValue++;
	}
	return iValue;
}


static function bool ItemTemplateIsAGrenade(X2ItemTemplate ItemTemplate)
{
	local X2GrenadeTemplate Template;

	Template = X2GrenadeTemplate(ItemTemplate);

	if(Template != none && Template.InventorySlot == eInvSlot_Utility && Template.WeaponCat == 'grenade' && Template.ItemCat == 'grenade')
	{
		return true;
	}
	return false;
}

*/
static function bool UnitHasUtilityDRLEquipped(XComGameState_Unit UnitState)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item		Item;
	
	Items = UnitState.GetAllInventoryItems(, true);
	foreach Items(Item)
	{
		if (ItemTemplateIsAUtilityDRL(Item.GetMyTemplate()))
		{
			return true;
		}
	}
	return false;
}

static function bool ItemTemplateIsAUtilityDRL(X2ItemTemplate ItemTemplate)
{
	local X2PairedWeaponTemplate	Template;

	Template = X2PairedWeaponTemplate(ItemTemplate);

	if(Template != none && Template.InventorySlot == eInvSlot_Utility && Template.WeaponCat == 'iri_disposable_launcher')
	{
		return true;
	}
	return false;
}
