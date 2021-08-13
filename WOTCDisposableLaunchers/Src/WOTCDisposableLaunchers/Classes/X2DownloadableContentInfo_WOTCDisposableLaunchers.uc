class X2DownloadableContentInfo_WOTCDisposableLaunchers extends X2DownloadableContentInfo;

var localized string DRL_WeaponCategory;
var localized string DRL_Requires_Two_Utility_Slots;

//var config(DisposableLaunchers) bool Utility_DRL_Occupies_Two_Slots;
//var config(DisposableLaunchers) bool Utility_DRL_Mutually_Exclusive_With_Grenades;
var config(DisposableLaunchers) array<name> BELT_CARRIED_MELEE_WEAPONS;

var config(TemplateCreator) array<name> AddItemsToHQInventory;

var private X2GrenadeTemplate DummyGrenadeTemplate;

// Other things to do:
// Gameplay tests
// Russian loc?
// Spring cleaning

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

// Runs every time
static event OnLoadedSavedGameToTactical()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Replace old DRL items");
	if (ReplaceOldLaunchersInHQ(NewGameState))
	{
		`TACTICALRULES.AddGameStateToHistory(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
	ReplaceOldLaunchersOnUnitsTactical();
}

static event OnLoadedSavedGameToStrategy()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Replace old DRL items");
	if (ReplaceOldLaunchersInHQ(NewGameState))
	{
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
	ReplaceOldLaunchersOnUnits();
}

static final function ReplaceOldLaunchersOnUnitsTactical()
{
	local XComGameStateHistory		History;
	local XComGameState				NewGameState;
	local XComGameState_Unit		UnitState;
	local XComGameState_Item		ItemState;
	local XComGameState_Item		NewItemState;
	local XComGameState_Player		PlayerState;
	local X2ItemTemplateManager		ItemMgr;
	local EInventorySlot			Slot;
	local bool						bChange;
	local X2TacticalGameRuleset		TacticalRules;
	local XComGameState_Ability		AbilityState;
	local array<AbilitySetupData>	AbilityDatas;
	local AbilitySetupData			AbilityData;
	local array<int>				NewItemObjectIDs;
	local int						NewItemIndex;
	local StateObjectReference		Ref;
	local array<EInventorySlot>		AllowedSlots;
	local XComGameState_Effect		EffectState;
	local array<X2GrenadeTemplate>	BestGrenadeTemplates;
	local X2GrenadeTemplate			BestGrenadeTemplate;
	local XComGameState_HeadquartersXCom XComHQ;

	local int i;
	local int j;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if (XComHQ == none)
		return;

	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	AllowedSlots = `GETMCMVAR(DRL_ALLOWED_INVENTORY_SLOTS);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Replace old DRL items");
	
	`LOG(GetFuncName(),, 'IRITEST');

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		NewItemObjectIDs.Length = 0;
		`LOG("\nBEGIN UNIT PRINTOUT:" @ UnitState.GetFullName(),, 'IRITEST');

		for (i = UnitState.InventoryItems.Length - 1; i >= 0; i--)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(UnitState.InventoryItems[i].ObjectID));
			if (ItemState == none)
				continue;

			`LOG(ItemState.GetMyTemplateName() @ ItemState.InventorySlot,, 'IRITEST');

			NewItemState = MaybeGetReplacementItemState(ItemState, ItemMgr, NewGameState);
			if (NewItemState != none && UnitState.CanRemoveItemFromInventory(ItemState, NewGameState))
			{
				`LOG("Replacement:" @ NewItemState.GetMyTemplateName(),, 'IRITEST');
				// Attempt to equip a new DRL in place of the old one.
				Slot = ItemState.InventorySlot;

				// Remove abilities associated with the old item
				for (j = UnitState.Abilities.Length - 1; j >= 0; j--)
				{	
					AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[j].ObjectID));
					if (AbilityState == none || AbilityState.SourceWeapon.ObjectID != ItemState.ObjectID)
						continue;

					`LOG("Removed ability from unit:" @ AbilityState.GetMyTemplateName(),, 'IRITEST');
					UnitState.Abilities.Remove(j, 1);
				}

				foreach UnitState.AffectedByEffects(Ref)
				{
					EffectState = XComGameState_Effect(History.GetGameStateForObjectID(Ref.ObjectID));
					if (EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID == ItemState.ObjectID)
					{	
						EffectState.RemoveEffect(NewGameState, NewGameState, true);
					}
				}
				foreach UnitState.AppliedEffects(Ref)
				{
					EffectState = XComGameState_Effect(History.GetGameStateForObjectID(Ref.ObjectID));
					if (EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID == ItemState.ObjectID)
					{	
						EffectState.RemoveEffect(NewGameState, NewGameState, true);
					}
				}

				if (UnitState.RemoveItemFromInventory(ItemState, NewGameState))
				{
					`LOG("Removed successfully",, 'IRITEST');
					NewGameState.RemoveStateObject(ItemState.ObjectID);

					// Don't attempt to auto-equip replacement items into unallowed slots.
					if (AllowedSlots.Find(Slot) == INDEX_NONE)
					{
						NewGameState.PurgeGameStateForObjectID(NewItemState.ObjectID);
						continue;
					}

					// If equipping new DRL fails, simply get rid of it.
					if (!UnitState.AddItemToInventory(NewItemState, Slot, NewGameState))
					{
						`LOG("Failed to equip new item.",, 'IRITEST');
						NewGameState.PurgeGameStateForObjectID(NewItemState.ObjectID);
						
						// See if we can at least equip a grenade instead.
						// Get best grenade from HQ inventory
						BestGrenadeTemplates = UnitState.GetBestGrenadeTemplates();
						foreach BestGrenadeTemplates(BestGrenadeTemplate)
						{
							`LOG("Attempting to equip a grenade instead:" @ BestGrenadeTemplate.DataName,, 'IRITEST');
							NewItemState = XComHQ.GetItemByName(BestGrenadeTemplate.DataName);
							if (NewItemState == none)
							{
								`LOG("Couldn't get grenade Item State from HQ inventory",, 'IRITEST');
								continue;
							}
			
							// Attempt to equip it
							XComHQ.GetItemFromInventory(NewGameState, NewItemState.GetReference(), NewItemState);
							if (UnitState.AddItemToInventory(NewItemState, Slot, NewGameState))
							{
								`LOG("Equipped a grenade:" @ NewItemState.GetMyTemplateName(),, 'IRITEST');
								NewItemObjectIDs.AddItem(NewItemState.ObjectID);
								break; // Exit template cycle if we succeed
							}
							else
							{
								`LOG("Failed to equip this grenade, putting it back",, 'IRITEST');
								XComHQ.PutItemInInventory(NewGameState, NewItemState); // But this grenade back, otherwise.
							}
						}
					}
					else
					{
						`LOG("Equipped replacement successfully. Ammo:" @ NewItemState.Ammo @ NewItemState.bMergedOut @ NewItemState.MergedItemCount,, 'IRITEST');
						NewItemObjectIDs.AddItem(NewItemState.ObjectID);
						bChange = true;
					}
				}
				else 
				{
					`LOG("Failed to remove old item.",, 'IRITEST');
					NewGameState.PurgeGameStateForObjectID(NewItemState.ObjectID);
				}
			}
		}


		// Initiate abilities associated with the newly added weapon.
		// Do this after all inventory management for this unit has been done so we don't end up merging ammo several times.
		if (NewItemObjectIDs.Length > 0)
		{
			PlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));			
			AbilityDatas = UnitState.GatherUnitAbilitiesForInit(NewGameState, PlayerState);
			foreach AbilityDatas(AbilityData)
			{
				NewItemIndex = NewItemObjectIDs.Find(AbilityData.SourceWeaponRef.ObjectID);
				if (NewItemIndex != INDEX_NONE)
				{	
					`LOG("Init ability for unit:" @ AbilityData.Template.DataName,, 'IRITEST');
					Ref.ObjectID = NewItemObjectIDs[NewItemIndex];
					TacticalRules.InitAbilityForUnit(AbilityData.Template, UnitState, NewGameState, Ref);
				}
			}
		}
	}

	if (bChange)
	{
		`LOG("Submitting",, 'IRITEST');
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = InitNewWeapons_BuildVisualization;
		TacticalRules.SubmitGameState(NewGameState);
	}
	else
	{	
		`LOG("Cleanup",, 'IRITEST');
		History.CleanupPendingGameState(NewGameState);
	}
}

static private function InitNewWeapons_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameState_Item	ItemState;
	local XGWeapon				Weapon;	
	local XGUnit				Unit;
	local XComGameStateHistory	History;
	local XGInventory			kInventory;
	
	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Item', ItemState)
	{
		if (ItemState.bMergedOut)
			continue;

		Weapon = XGWeapon(ItemState.GetVisualizer());
		if (Weapon == none)
		{
			`LOG("Didn't get visualizer the first time",, 'IRITEST');
			// Assume that weapons that didn't have a visualizer are the only ones that we want to visualize.
			Weapon = XGWeapon(class'XGWeapon'.static.CreateVisualizer(ItemState));

			if (Weapon != none)
			{
				`LOG("Creating entity",, 'IRITEST');
				Weapon.CreateEntity(ItemState);

				Unit = XGUnit(History.GetVisualizer(ItemState.OwnerStateObject.ObjectID));
				if (Unit != none)
				{
					kInventory = Unit.GetInventory();
					kInventory.PresEquip(Weapon, true);
				}
			}
		}
	}
}

static final function ReplaceOldLaunchersOnUnits()
{
	local XComGameStateHistory				History;
	local XComGameState						NewGameState;
	local XComGameState_Unit				UnitState;
	local XComGameState_Item				ItemState;
	local XComGameState_Item				NewItemState;
	local X2ItemTemplateManager				ItemMgr;
	local EInventorySlot					Slot;
	local bool								bChange;
	local int i;

	History = `XCOMHISTORY;
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Replace old DRL items");

	`LOG(GetFuncName(),, 'IRITEST');

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		`LOG("\nBEGIN UNIT PRINTOUT:" @ UnitState.GetFullName(),, 'IRITEST');

		for (i = UnitState.InventoryItems.Length - 1; i >= 0; i--)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(UnitState.InventoryItems[i].ObjectID));
			if (ItemState == none)
				continue;

			`LOG(ItemState.GetMyTemplateName() @ ItemState.InventorySlot,, 'IRITEST');

			NewItemState = MaybeGetReplacementItemState(ItemState, ItemMgr, NewGameState);
			if (NewItemState != none)
			{
				`LOG("Replacement:" @ NewItemState.GetMyTemplateName(),, 'IRITEST');
				// Attempt to equip a new DRL in place of the old one.
				Slot = ItemState.InventorySlot;

				if (UnitState.RemoveItemFromInventory(ItemState, NewGameState))
				{
					`LOG("Removed successfully",, 'IRITEST');
					NewGameState.RemoveStateObject(ItemState.ObjectID);

					// If equipping new DRL fails, simply get rid of it.
					if (!UnitState.AddItemToInventory(NewItemState, Slot, NewGameState))
					{
						`LOG("Failed to equip new item.",, 'IRITEST');
						NewGameState.PurgeGameStateForObjectID(NewItemState.ObjectID);
					}
					else
					{
						`LOG("Equipped replacement successfully",, 'IRITEST');
						bChange = true;
					}
				}
				else 
				{
					`LOG("Failed to remove old item.",, 'IRITEST');
					NewGameState.RemoveStateObject(NewItemState.ObjectID);
				}
			}
		}
	}

	if (bChange)
	{
		`LOG("Submitting",, 'IRITEST');
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{	
		`LOG("Cleanup",, 'IRITEST');
		History.CleanupPendingGameState(NewGameState);
	}
}


static final function bool ReplaceOldLaunchersInHQ(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameStateHistory				History;
	local XComGameState_Item				ItemState;
	local XComGameState_Item				NewItemState;
	local array<XComGameState_Item>			NewItemStates;
	local X2ItemTemplateManager				ItemMgr;
	local int								i;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if (XComHQ == none)
		return;

	History = `XCOMHISTORY;
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(XComHQ.Class, XComHQ.ObjectID));

	for (i = XComHQ.Inventory.Length - 1; i >= 0; i--)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[i].ObjectID));
		if (ItemState == none)
			continue;

		NewItemState = MaybeGetReplacementItemState(ItemState, ItemMgr, NewGameState);
		if (NewItemState != none)
		{
			NewItemStates.AddItem(NewItemState);

			XComHQ.Inventory.Remove(i, 1);
			NewGameState.RemoveStateObject(ItemState.ObjectID);
		}
	}
	foreach NewItemStates(NewItemState)
	{
		if (NewItemState.GetMyTemplate().bInfiniteItem)
		{
			// Don't add infinite items if they're already there.
			if (XComHQ.HasItemByName(NewItemState.GetMyTemplateName()))
				continue;

			XComHQ.AddItemToHQInventory(NewItemState);
		}
		else
		{
			XComHQ.PutItemInInventory(NewGameState, NewItemState);
		}
	}
	return NewItemStates.Length > 0;
}

static final function XComGameState_Item MaybeGetReplacementItemState(XComGameState_Item ItemState, X2ItemTemplateManager ItemMgr, XComGameState NewGameState)
{
	local X2ItemTemplate		Template;
	local XComGameState_Item	NewItemState;

	switch (ItemState.GetMyTemplateName())
	{
	// 2.0 version
	case 'IRI_DRL_CV_Utility':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_CV'); break;
	case 'IRI_DRL_CV_Secondary':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_CV'); break;
	case 'IRI_DRL_CV_Heavy':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_CV'); break;
	case 'IRI_DRL_MG_Utility':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_MG'); break;
	case 'IRI_DRL_MG_Secondary':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_MG'); break;
	case 'IRI_DRL_MG_Heavy':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_MG'); break;
	case 'IRI_DRL_BM_Utility':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_BM'); break;
	case 'IRI_DRL_BM_Secondary':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_BM'); break;
	case 'IRI_DRL_BM_Heavy':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_BM'); break;

	// 1.0
	case 'IRI_RPG_CV_Utility':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_CV'); break;
	case 'IRI_RPG_CV_Secondary':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_CV'); break;
	case 'IRI_RPG_CV_Heavy':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_CV'); break;
	case 'IRI_RPG_MG_Utility':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_MG'); break;
	case 'IRI_RPG_MG_Secondary':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_MG'); break;
	case 'IRI_RPG_MG_Heavy':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_MG'); break;
	case 'IRI_RPG_BM_Utility':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_BM'); break;
	case 'IRI_RPG_BM_Secondary':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_BM'); break;
	case 'IRI_RPG_BM_Heavy':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_BM'); break;

	// These were paired template names and shouldn't exist in inventory
	case 'IRI_RPG_CV':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_CV'); break;
	case 'IRI_RPG_MG':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_MG'); break;
	case 'IRI_RPG_BM':
		Template = ItemMgr.FindItemTemplate('IRI_DRL_BM'); break;
	default:
		break;
	}
	if (Template != none)
	{
		NewItemState = Template.CreateInstanceFromTemplate(NewGameState);
		NewItemState.Quantity = ItemState.Quantity;
		NewItemState.Ammo = ItemState.Ammo;
		NewItemState.bMergedOut = ItemState.bMergedOut;
		NewItemState.MergedItemCount = ItemState.MergedItemCount;
	}
	return NewItemState;
}

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

static function GetNumUtilitySlotsOverride(out int NumUtilitySlots, XComGameState_Item EquippedArmor, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	if (`GETMCMVAR(UTILITY_DRL_OCCUPIES_TWO_SLOTS) && NumUtilitySlots > 1 && HasWeaponOfCategoryInSlot(UnitState, 'iri_disposable_launcher', eInvSlot_Utility, CheckGameState))
	{
		// If you ever have some kind of inventory operation that fails to fix the stat, you can manually call ValidateLoadout (or just RealizeItemSlotsCount, CHL only) (c) robojumper
		NumUtilitySlots--;
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

static final function bool HasWeaponOfCategoryInSlot(const XComGameState_Unit UnitState, const name WeaponCat, const EInventorySlot Slot, optional XComGameState CheckGameState)
{
	local XComGameState_Item Item;
	local StateObjectReference ItemRef;

	foreach UnitState.InventoryItems(ItemRef)
	{
		Item = UnitState.GetItemGameState(ItemRef, CheckGameState);

		if (Item != none && Item.InventorySlot == Slot && Item.GetWeaponCategory() == WeaponCat)
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