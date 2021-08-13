class DRL_MCM_Screen extends Object config(WOTCDisposableLaunchers_NullConfig);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized string GroupHeader;
var localized string GroupHeader2;

`include(WOTCDisposableLaunchers\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoCheckBoxVars(DRL_STAT_PENALTIES_ENABLED);
`MCM_API_AutoCheckBoxVars(DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR);
`MCM_API_AutoCheckBoxVars(UTILITY_DRL_OCCUPIES_TWO_SLOTS);
`MCM_API_AutoCheckBoxVars(UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES);

var config array<EInventorySlot> DRL_ALLOWED_INVENTORY_SLOTS;

`include(WOTCDisposableLaunchers\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoCheckBoxFns(DRL_STAT_PENALTIES_ENABLED, 1);
`MCM_API_AutoCheckBoxFns(DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR, 1);
`MCM_API_AutoCheckBoxFns(UTILITY_DRL_OCCUPIES_TWO_SLOTS, 1);
`MCM_API_AutoCheckBoxFns(UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES, 1);

event OnInit(UIScreen Screen)
{
	`MCM_API_Register(Screen, ClientModCallback);
}

//Simple one group framework code
simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local MCM_API_SettingsPage	Page;
	local MCM_API_SettingsGroup Group;
	local string SlotLocName;
	local int i;

	LoadSavedSettings();

	Page = ConfigAPI.NewSettingsPage(ModName);
	Page.SetPageTitle(PageTitle);
	Page.SetSaveHandler(SaveButtonClicked);
	Page.EnableResetButton(ResetButtonClicked);

	Group = Page.AddGroup('Group_1', GroupHeader);
	
	`MCM_API_AutoAddCheckBox(Group, DRL_STAT_PENALTIES_ENABLED, DRL_STAT_PENALTIES_ENABLED_ChangeHandler);	
	`MCM_API_AutoAddCheckBox(Group, DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR);	
	//`MCM_API_AutoAddCheckBox(Group, DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR).SetEditable(DRL_STAT_PENALTIES_ENABLED); // IDK why this doesn't compile
	Group.GetSettingByName('DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR').SetEditable(DRL_STAT_PENALTIES_ENABLED); 

	`MCM_API_AutoAddCheckBox(Group, UTILITY_DRL_OCCUPIES_TWO_SLOTS);	
	`MCM_API_AutoAddCheckBox(Group, UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES);	

	Group = Page.AddGroup('Group_2', GroupHeader2);

	for (i = eInvSlot_Unknown + 1; i < eInvSlot_END_TEMPLATED_SLOTS; i++)
	{
		if (i >= eInvSlot_END_VANILLA_SLOTS && i <= eInvSlot_BEGIN_TEMPLATED_SLOTS) // Skip buffer slots
			continue;

		SlotLocName = class'CHItemSlot'.static.SlotGetName(EInventorySlot(i));
		if (SlotLocName == "")
			SlotLocName = Repl(string(GetEnum(enum'EInventorySlot', EInventorySlot(i))), "eInvSlot_", "");

		Group.AddCheckbox(name("IRI_DRL_Slot_Checkbox_" $ i), SlotLocName, "Tooltip", IsSlotEnabled(i), DRL_ALLOWED_INVENTORY_SLOTS_SaveHandler);
	}

	Page.ShowSettings();
}

simulated function DRL_STAT_PENALTIES_ENABLED_ChangeHandler(MCM_API_Setting _Setting, bool _SettingValue)
{
	DRL_STAT_PENALTIES_ENABLED = _SettingValue;
	_Setting.GetParentGroup().GetSettingByName('DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR').SetEditable(DRL_STAT_PENALTIES_ENABLED);
}

simulated final function bool IsSlotEnabled(int i)
{
	local EInventorySlot CheckSlot;

	//`LOG(GetFuncName() @ i @ EInventorySlot(i) @ DRL_ALLOWED_INVENTORY_SLOTS.Find(CheckSlot) != INDEX_NONE @ DRL_ALLOWED_INVENTORY_SLOTS.Length,, 'IRITEST');

	CheckSlot = EInventorySlot(i);

	return DRL_ALLOWED_INVENTORY_SLOTS.Find(CheckSlot) != INDEX_NONE;
}

simulated function DRL_ALLOWED_INVENTORY_SLOTS_SaveHandler(MCM_API_Setting _Setting, bool _SettingValue)
{
	local string SettingName;
	local int SlotIndex;

	SettingName = Repl(string(_Setting.GetName()), "IRI_DRL_Slot_Checkbox_", "");
	SlotIndex = int(SettingName);

	//`LOG(GetFuncName() @ _Setting.GetName() @ _SettingValue @ SettingName @ SlotIndex @ "slot:" @ EInventorySlot(SlotIndex),, 'IRITEST');

	if (_SettingValue)
	{
		DRL_ALLOWED_INVENTORY_SLOTS.AddItem(EInventorySlot(SlotIndex));
	}
	else
	{	
		DRL_ALLOWED_INVENTORY_SLOTS.RemoveItem(EInventorySlot(SlotIndex));
	}
}

simulated function LoadSavedSettings()
{	
	DRL_STAT_PENALTIES_ENABLED = `GETMCMVAR(DRL_STAT_PENALTIES_ENABLED);
	DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR = `GETMCMVAR(DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR);
	UTILITY_DRL_OCCUPIES_TWO_SLOTS = `GETMCMVAR(UTILITY_DRL_OCCUPIES_TWO_SLOTS);
	UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES = `GETMCMVAR(UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES);

	DRL_ALLOWED_INVENTORY_SLOTS = getDRL_ALLOWED_INVENTORY_SLOTS();
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	local MCM_API_SettingsGroup Group;
	local MCM_API_Setting		_Setting;
	local MCM_API_Checkbox		_Checkbox;
	local int i;

	`MCM_API_AutoReset(DRL_STAT_PENALTIES_ENABLED);
	`MCM_API_AutoReset(DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR);
	`MCM_API_AutoReset(UTILITY_DRL_OCCUPIES_TWO_SLOTS);
	`MCM_API_AutoReset(UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES);
	
	DRL_ALLOWED_INVENTORY_SLOTS = class'DRL_MCM_Defaults'.default.DRL_ALLOWED_INVENTORY_SLOTS;
	Group = Page.GetGroupByName('Group_2');
	for (i = eInvSlot_Unknown + 1; i < eInvSlot_END_TEMPLATED_SLOTS; i++)
	{
		if (i >= eInvSlot_END_VANILLA_SLOTS && i <= eInvSlot_BEGIN_TEMPLATED_SLOTS) // Skip buffer slots
			continue;
			
		_Setting = Group.GetSettingByName(name("IRI_DRL_Slot_Checkbox_" $ i));
		_Checkbox = MCM_API_Checkbox(_Setting);
		_Checkbox.SetValue(IsSlotEnabled(i), false);
	}
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}

static function array<EInventorySlot> getDRL_ALLOWED_INVENTORY_SLOTS()
{
    return ((MCM_CH_IMPL_VersionChecker(1)) ? class'DRL_MCM_Defaults'.default.DRL_ALLOWED_INVENTORY_SLOTS : default.DRL_ALLOWED_INVENTORY_SLOTS);
}
