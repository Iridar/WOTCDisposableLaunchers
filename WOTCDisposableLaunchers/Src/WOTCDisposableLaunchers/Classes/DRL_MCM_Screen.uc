class DRL_MCM_Screen extends Object config(WOTCDisposableLaunchers_NullConfig);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized string GroupHeader;

`include(WOTCDisposableLaunchers\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoCheckBoxVars(DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR);
`MCM_API_AutoCheckBoxVars(UTILITY_DRL_OCCUPIES_TWO_SLOTS);
`MCM_API_AutoCheckBoxVars(UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES);

`include(WOTCDisposableLaunchers\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

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
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup Group;

	LoadSavedSettings();

	Page = ConfigAPI.NewSettingsPage(ModName);
	Page.SetPageTitle(PageTitle);
	Page.SetSaveHandler(SaveButtonClicked);
	Page.EnableResetButton(ResetButtonClicked);

	Group = Page.AddGroup('Group', GroupHeader);
	
	`MCM_API_AutoAddCheckBox(Group, DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR);	
	`MCM_API_AutoAddCheckBox(Group, UTILITY_DRL_OCCUPIES_TWO_SLOTS);	
	`MCM_API_AutoAddCheckBox(Group, UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES);	

	Page.ShowSettings();
}

simulated function LoadSavedSettings()
{
	DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR = `GETMCMVAR(DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR);
	UTILITY_DRL_OCCUPIES_TWO_SLOTS = `GETMCMVAR(UTILITY_DRL_OCCUPIES_TWO_SLOTS);
	UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES = `GETMCMVAR(UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES);
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`MCM_API_AutoReset(DRL_STAT_PENALTIES_APPLIED_TO_HEAVY_ARMOR);
	`MCM_API_AutoReset(UTILITY_DRL_OCCUPIES_TWO_SLOTS);
	`MCM_API_AutoReset(UTILITY_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES);
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}
