class X2DLCInfo_OnLoadedSaveGame extends X2DownloadableContentInfo;

// This whole DLC info exists only to bridge the gab between 1.0 and 2.0 versions, and the 3.0 update.
// When the player loads a saved game, this will replace all instances of the old DRLs in HQ inventory and on units.

`include(WOTCDisposableLaunchers\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

// Runs once.
static event OnLoadedSavedGame()
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

	RemoveLooseDRLs();
}

// Remove any old DRLs that aren't equipped on units or aren't located in HQ inventry
// (they really shouldn't exist, but who knows?)
static final function RemoveLooseDRLs()
{	
	local XComGameState			NewGameState;
	local XComGameStateHistory	History;
	local XComGameState_Item	ItemState;
	local bool					bChange;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Loose DRLs");
	foreach History.IterateByClassType(class'XComGameState_Item', ItemState)
	{
		if (IsOldDRLItem(ItemState.GetMyTemplateName()))
		{
			NewGameState.RemoveStateObject(ItemState.ObjectID);
			bChange = true;
		}
	}
	if (bChange)
	{
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

// Runs every time
static event OnLoadedSavedGameToTactical()
{
	ReplaceOldLaunchersOnUnitsTactical();
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
	
	//`LOG(GetFuncName(),, 'IRITEST');

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if (UnitState.bRemovedFromPlay) // Skip units not in tactical
			continue;

		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		NewItemObjectIDs.Length = 0;
		//`LOG("\nBEGIN UNIT PRINTOUT:" @ UnitState.GetFullName(),, 'IRITEST');

		for (i = UnitState.InventoryItems.Length - 1; i >= 0; i--)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(UnitState.InventoryItems[i].ObjectID));
			if (ItemState == none)
				continue;

			//`LOG(ItemState.GetMyTemplateName() @ ItemState.InventorySlot,, 'IRITEST');

			NewItemState = MaybeGetReplacementItemState(ItemState, ItemMgr, NewGameState);
			if (NewItemState != none && UnitState.CanRemoveItemFromInventory(ItemState, NewGameState))
			{
				//`LOG("Replacement:" @ NewItemState.GetMyTemplateName(),, 'IRITEST');
				// Attempt to equip a new DRL in place of the old one.
				Slot = ItemState.InventorySlot;

				// Remove abilities associated with the old item
				for (j = UnitState.Abilities.Length - 1; j >= 0; j--)
				{	
					AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[j].ObjectID));
					if (AbilityState == none || AbilityState.SourceWeapon.ObjectID != ItemState.ObjectID)
						continue;

					//`LOG("Removed ability from unit:" @ AbilityState.GetMyTemplateName(),, 'IRITEST');
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
					//`LOG("Removed successfully",, 'IRITEST');
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
						//`LOG("Failed to equip new item.",, 'IRITEST');
						NewGameState.PurgeGameStateForObjectID(NewItemState.ObjectID);
						
						// See if we can at least equip a grenade instead.
						// Get best grenade from HQ inventory
						BestGrenadeTemplates = UnitState.GetBestGrenadeTemplates();
						foreach BestGrenadeTemplates(BestGrenadeTemplate)
						{
							//`LOG("Attempting to equip a grenade instead:" @ BestGrenadeTemplate.DataName,, 'IRITEST');
							NewItemState = XComHQ.GetItemByName(BestGrenadeTemplate.DataName);
							if (NewItemState == none)
							{
								//`LOG("Couldn't get grenade Item State from HQ inventory",, 'IRITEST');
								continue;
							}
			
							// Attempt to equip it
							XComHQ.GetItemFromInventory(NewGameState, NewItemState.GetReference(), NewItemState);
							if (UnitState.AddItemToInventory(NewItemState, Slot, NewGameState))
							{
								//`LOG("Equipped a grenade:" @ NewItemState.GetMyTemplateName(),, 'IRITEST');
								NewItemObjectIDs.AddItem(NewItemState.ObjectID);
								break; // Exit template cycle if we succeed
							}
							else
							{
								//`LOG("Failed to equip this grenade, putting it back",, 'IRITEST');
								XComHQ.PutItemInInventory(NewGameState, NewItemState); // But this grenade back, otherwise.
							}
						}
					}
					else
					{
						//`LOG("Equipped replacement successfully. Ammo:" @ NewItemState.Ammo @ NewItemState.bMergedOut @ NewItemState.MergedItemCount,, 'IRITEST');
						NewItemObjectIDs.AddItem(NewItemState.ObjectID);
						bChange = true;
					}
				}
				else 
				{
					//`LOG("Failed to remove old item.",, 'IRITEST');
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
					//`LOG("Init ability for unit:" @ AbilityData.Template.DataName,, 'IRITEST');
					Ref.ObjectID = NewItemObjectIDs[NewItemIndex];
					TacticalRules.InitAbilityForUnit(AbilityData.Template, UnitState, NewGameState, Ref);
				}
			}
		}
	}

	if (bChange)
	{
		//`LOG("Submitting",, 'IRITEST');
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = InitNewWeapons_BuildVisualization;
		TacticalRules.SubmitGameState(NewGameState);
	}
	else
	{	
		//`LOG("Cleanup",, 'IRITEST');
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
			//`LOG("Didn't get visualizer the first time",, 'IRITEST');
			// Assume that weapons that didn't have a visualizer are the only ones that we want to visualize.
			Weapon = XGWeapon(class'XGWeapon'.static.CreateVisualizer(ItemState));

			if (Weapon != none)
			{
				//`LOG("Creating entity",, 'IRITEST');
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

	//`LOG(GetFuncName(),, 'IRITEST');

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if (!UnitState.bRemovedFromPlay) // Skip units that are in tactical play (in case OnLoadedSavedGame() was loaded to tactical)
			continue;

		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		//`LOG("\nBEGIN UNIT PRINTOUT:" @ UnitState.GetFullName(),, 'IRITEST');

		for (i = UnitState.InventoryItems.Length - 1; i >= 0; i--)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(UnitState.InventoryItems[i].ObjectID));
			if (ItemState == none)
				continue;

			//`LOG(ItemState.GetMyTemplateName() @ ItemState.InventorySlot,, 'IRITEST');

			NewItemState = MaybeGetReplacementItemState(ItemState, ItemMgr, NewGameState);
			if (NewItemState != none)
			{
				//`LOG("Replacement:" @ NewItemState.GetMyTemplateName(),, 'IRITEST');
				// Attempt to equip a new DRL in place of the old one.
				Slot = ItemState.InventorySlot;

				if (UnitState.RemoveItemFromInventory(ItemState, NewGameState))
				{
					//`LOG("Removed successfully",, 'IRITEST');
					NewGameState.RemoveStateObject(ItemState.ObjectID);

					// If equipping new DRL fails, simply get rid of it.
					if (!UnitState.AddItemToInventory(NewItemState, Slot, NewGameState))
					{
						//`LOG("Failed to equip new item.",, 'IRITEST');
						NewGameState.PurgeGameStateForObjectID(NewItemState.ObjectID);
					}
					else
					{
						//`LOG("Equipped replacement successfully",, 'IRITEST');
						bChange = true;
					}
				}
				else 
				{
					//`LOG("Failed to remove old item.",, 'IRITEST');
					NewGameState.RemoveStateObject(NewItemState.ObjectID);
				}
			}
		}
	}

	if (bChange)
	{
		//`LOG("Submitting",, 'IRITEST');
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{	
		//`LOG("Cleanup",, 'IRITEST');
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
		return false;

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

static final function bool IsOldDRLItem(const name TemplateName)
{
	switch (TemplateName)
	{
	// 2.0 version
	case 'IRI_DRL_CV_Utility':
	case 'IRI_DRL_CV_Secondary':
	case 'IRI_DRL_CV_Heavy':
	case 'IRI_DRL_MG_Utility':
	case 'IRI_DRL_MG_Secondary':
	case 'IRI_DRL_MG_Heavy':
	case 'IRI_DRL_BM_Utility':
	case 'IRI_DRL_BM_Secondary':
	case 'IRI_DRL_BM_Heavy':
	case 'IRI_RPG_CV_Utility':
	case 'IRI_RPG_CV_Secondary':
	case 'IRI_RPG_CV_Heavy':
	case 'IRI_RPG_MG_Utility':
	case 'IRI_RPG_MG_Secondary':
	case 'IRI_RPG_MG_Heavy':
	case 'IRI_RPG_BM_Utility':
	case 'IRI_RPG_BM_Secondary':
	case 'IRI_RPG_BM_Heavy':
	case 'IRI_RPG_CV':
	case 'IRI_RPG_MG':
	case 'IRI_RPG_BM':
		return true;
	default:
		return false;
	}
}