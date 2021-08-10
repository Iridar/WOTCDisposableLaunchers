class X2Item_DisposableLaunchers extends X2Item config(DisposableLaunchers);

var config WeaponDamageValue RPG_CV_BASEDAMAGE;
var config int RPG_CV_ISOUNDRANGE;
var config int RPG_CV_IENVIRONMENTDAMAGE;
var config int RPG_CV_ICLIPSIZE;
var config int RPG_CV_RANGE;
var config int RPG_CV_RADIUS;
var config float RPG_CV_MOBILITY_PENALTY;
var config float RPG_CV_DETECTION_RADIUS_MODIFIER;
var config name RPG_CV_CREATOR_TEMPLATE;

var config WeaponDamageValue RPG_MG_BASEDAMAGE;
var config int RPG_MG_ISOUNDRANGE;
var config int RPG_MG_IENVIRONMENTDAMAGE;
var config int RPG_MG_ICLIPSIZE;
var config int RPG_MG_RANGE;
var config int RPG_MG_RADIUS;
var config float RPG_MG_MOBILITY_PENALTY;
var config float RPG_MG_DETECTION_RADIUS_MODIFIER;
var config name RPG_MG_CREATOR_TEMPLATE;

var config WeaponDamageValue RPG_BM_BASEDAMAGE;
var config int RPG_BM_ISOUNDRANGE;
var config int RPG_BM_IENVIRONMENTDAMAGE;
var config int RPG_BM_ICLIPSIZE;
var config int RPG_BM_RANGE;
var config int RPG_BM_RADIUS;
var config float RPG_BM_MOBILITY_PENALTY;
var config float RPG_BM_DETECTION_RADIUS_MODIFIER;
var config name RPG_BM_CREATOR_TEMPLATE;

var config int RPG_ACTION_POINT_COST;
var config bool RPG_ACTION_POINT_ENDS_TURN;
var config array<name> RPG_NON_TURN_ENDING_ABILITIES;

var config name RPG_ItemCat;
var config name RPG_WeaponCat;

var config name RPG_Utility_ItemCat;
var config name RPG_Utility_WeaponCat;

var config name RPG_Secondary_ItemCat;
var config name RPG_Secondary_WeaponCat;

var config name RPG_Heavy_ItemCat;
var config name RPG_Heavy_WeaponCat;

var config bool MAX_ONE_DRL_PER_SOLDIER;
var config bool UTILITY_SLOT_DRL_MUTUALLY_EXCLUSIVE_WITH_GRENADES;

var config array<name> RPG_ABILITIES;

var config bool HIDE_PREVIOUS_RPG_TIERS;
var config bool RPG_CV_AVAILABLE_FROM_THE_START;

var config EInventorySlot RPG_Inventory_Slot;
var config bool DISABLE_ROCKET_SCATTER;

var config bool MOBILITY_PENALTY_IS_COUNTED_PER_ROCKET;
var config bool MOBILITY_PENALTY_IS_APPLIED_TO_HEAVY_ARMOR;

var config array<name> BELT_CARRIED_MELEE_WEAPONS;
/*
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_IRI_RPG_CV());
	Templates.AddItem(Create_IRI_RPG_CV_Secondary());
	Templates.AddItem(Create_IRI_RPG_CV_Utility());
	Templates.AddItem(Create_IRI_RPG_CV_Heavy());

	Templates.AddItem(Create_IRI_RPG_MG());
	Templates.AddItem(Create_IRI_RPG_MG_Secondary());
	Templates.AddItem(Create_IRI_RPG_MG_Utility());
	Templates.AddItem(Create_IRI_RPG_MG_Heavy());

	Templates.AddItem(Create_IRI_RPG_BM());
	Templates.AddItem(Create_IRI_RPG_BM_Secondary());
	Templates.AddItem(Create_IRI_RPG_BM_Utility());
	Templates.AddItem(Create_IRI_RPG_BM_Heavy());

	return Templates;
}
*/
//	*********************************************
//	*********************************************
//				COMMON CODE
//	*********************************************
//	*********************************************
/*
static function X2DisposableLauncherTemplate Setup_DisposableLauncher(name TemplateName)
{
	local X2DisposableLauncherTemplate	Template;
	local X2Effect_ApplyWeaponDamage	WeaponDamageEffect;
	local X2Effect_Knockback			KnockbackEffect;

	`CREATE_X2TEMPLATE(class'X2DisposableLauncherTemplate', Template, TemplateName);

	Template.Abilities = default.RPG_ABILITIES;

	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = false;

	Template.StowedLocation = eSlot_LeftBack;
	Template.InventorySlot = default.RPG_Inventory_Slot;
	Template.bMergeAmmo = false;	//	the Highlander inventory slot cannot be a Multi Item slot and be displayed on the soldier at the same time.
									//	So I had to write a sort of Aggregate Ammo ability that triggers at mission start.

	//Template.WeaponPrecomputedPathData.InitialPathTime = 1.0f;
	//Template.WeaponPrecomputedPathData.MaxPathTime = 2.5f;
	//Template.WeaponPrecomputedPathData.MaxNumberOfBounces = 0;

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	Template.ThrownGrenadeEffects.AddItem(KnockbackEffect);

	Template.OnThrowBarkSoundCue = 'RocketLauncher';
	Template.DamageTypeTemplateName = 'Explosion';

	Template.ItemCat = default.RPG_ItemCat;
	Template.WeaponCat = default.RPG_WeaponCat;

	return Template;
}

static function Setup_DisposableLauncher_Utility(out X2PairedWeaponTemplate Template)
{
	Template.InventorySlot=eInvSlot_Utility;
	Template.StowedLocation=eSlot_None;

	Template.PairedSlot = default.RPG_Inventory_Slot;

	Template.EquipSound = "StrategyUI_Heavy_Weapon_Equip";
	
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.ItemCat = default.RPG_Utility_ItemCat;
	Template.WeaponCat = default.RPG_Utility_WeaponCat;
}

//	*********************************************
//	*********************************************
//				CONVENTIONAL RPG
//	*********************************************
//	*********************************************

static function X2DataTemplate Create_IRI_RPG_CV()
{
	local X2DisposableLauncherTemplate Template;

	Template = Setup_DisposableLauncher('IRI_RPG_CV');

	Template.strImage = "img:///AT4_Assets.UI.AT4_Inv";

	Template.MobilityPenalty = default.RPG_CV_MOBILITY_PENALTY;
	Template.DetectionRadiusModifier = default.RPG_CV_DETECTION_RADIUS_MODIFIER;

	Template.iRange = default.RPG_CV_RANGE;
	Template.iRadius = default.RPG_CV_RADIUS;
	Template.BaseDamage = default.RPG_CV_BASEDAMAGE;
	Template.iSoundRange = default.RPG_CV_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.RPG_CV_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.RPG_CV_ICLIPSIZE;

	Template.Tier = -3;
	Template.WeaponTech = 'conventional';

	Template.GameArchetype = "AT4_Assets.Archetypes.WP_AT4";

	return Template;
}

static function X2PairedWeaponTemplate Setup_DisposableLauncher_Utility_CV(X2DataTemplate InTemplate)
{
	local X2PairedWeaponTemplate Template;

	Template = X2PairedWeaponTemplate(InTemplate);

	Setup_DisposableLauncher_Utility(Template);

	Template.Tier = -3;
	Template.WeaponTech = 'conventional';

	Template.strImage = "img:///AT4_Assets.UI.AT4_Inv";

	Template.PairedTemplateName = 'IRI_RPG_CV';

	Template.iRange = default.RPG_CV_RANGE;
	Template.iRadius = default.RPG_CV_RADIUS;
	Template.BaseDamage = default.RPG_CV_BASEDAMAGE;
	Template.iEnvironmentDamage = default.RPG_CV_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.RPG_CV_ICLIPSIZE;

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.RPG_CV_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.RPG_CV_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.RPG_CV_BASEDAMAGE.Shred);
	if (default.RPG_CV_MOBILITY_PENALTY != 0)
	{
		Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, default.RPG_CV_MOBILITY_PENALTY);
	}

	if (default.HIDE_PREVIOUS_RPG_TIERS)
	{
		Template.HideIfResearched = default.RPG_MG_CREATOR_TEMPLATE;
	}
	if (default.RPG_CV_AVAILABLE_FROM_THE_START)
	{
		Template.StartingItem = true;
	}
	else
	{
		Template.CreatorTemplateName = default.RPG_CV_CREATOR_TEMPLATE;
	}
	return Template;
}

static function X2UtilityDisposableLauncherTemplate Create_IRI_RPG_CV_Utility(optional name TemplateName = 'IRI_RPG_CV_Utility')
{
	local X2UtilityDisposableLauncherTemplate Template;

	`CREATE_X2TEMPLATE(class'X2UtilityDisposableLauncherTemplate', Template, TemplateName);

	Template = X2UtilityDisposableLauncherTemplate(Setup_DisposableLauncher_Utility_CV(Template));

	return Template;
}

static function X2DataTemplate Create_IRI_RPG_CV_Secondary()
{
	local X2PairedWeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2PairedWeaponTemplate', Template, 'IRI_RPG_CV_Secondary');

	Template = Setup_DisposableLauncher_Utility_CV(Template);

	Template.StowedLocation = eSlot_RightBack;
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.ItemCat = default.RPG_Secondary_ItemCat;
	Template.WeaponCat = default.RPG_Secondary_WeaponCat;

	Template.UIStatMarkups.Remove(3, 1);	// remove previously configured stat markup for mobility penalty
	
	//Template.GameArchetype = "AT4_Assets.Archetypes.WP_AT4";
	//Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Shotgun';
	//Template.WeaponPanelImage = "_ConventionalShotgun";

	return Template;
}

static function X2DataTemplate Create_IRI_RPG_CV_Heavy()
{
	local X2PairedWeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2PairedWeaponTemplate', Template, 'IRI_RPG_CV_Heavy');

	Template = Setup_DisposableLauncher_Utility_CV(Template);

	Template.StowedLocation = eSlot_HeavyWeapon;
	Template.InventorySlot = eInvSlot_HeavyWeapon;
	Template.ItemCat = default.RPG_Heavy_ItemCat;
	Template.WeaponCat = default.RPG_Heavy_WeaponCat;

	Template.UIStatMarkups.Remove(3, 1);

	return Template;
}


//	*********************************************
//	*********************************************
//				MAGNETIC RPG
//	*********************************************
//	*********************************************

static function X2DataTemplate Create_IRI_RPG_MG()
{
	local X2DisposableLauncherTemplate Template;

	Template = Setup_DisposableLauncher('IRI_RPG_MG');

	Template.strImage = "img:///Disposable_MG.UI.Disposable_MG_Inv";

	Template.MobilityPenalty = default.RPG_MG_MOBILITY_PENALTY;
	Template.DetectionRadiusModifier = default.RPG_MG_DETECTION_RADIUS_MODIFIER;

	Template.iRange = default.RPG_MG_RANGE;
	Template.iRadius = default.RPG_MG_RADIUS;
	Template.BaseDamage = default.RPG_MG_BASEDAMAGE;
	Template.iSoundRange = default.RPG_MG_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.RPG_MG_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.RPG_MG_ICLIPSIZE;

	Template.WeaponTech = 'magnetic';
	Template.Tier = -2;

	Template.GameArchetype = "Disposable_MG.Archetypes.WP_Disposable_MG";

	Template.BaseItem = 'IRI_RPG_CV';

	return Template;
}

static function X2PairedWeaponTemplate Setup_DisposableLauncher_Utility_MG(X2DataTemplate InTemplate)
{
	local X2PairedWeaponTemplate Template;

	Template = X2PairedWeaponTemplate(InTemplate);

	Setup_DisposableLauncher_Utility(Template);

	Template.Tier = -2;
	Template.WeaponTech = 'magnetic';

	Template.strImage = "img:///Disposable_MG.UI.Disposable_MG_Inv";

	Template.PairedTemplateName = 'IRI_RPG_MG';

	Template.iRange = default.RPG_MG_RANGE;
	Template.iRadius = default.RPG_MG_RADIUS;
	Template.BaseDamage = default.RPG_MG_BASEDAMAGE;
	Template.iEnvironmentDamage = default.RPG_MG_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.RPG_MG_ICLIPSIZE;

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.RPG_MG_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.RPG_MG_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.RPG_MG_BASEDAMAGE.Shred);
	if (default.RPG_BM_MOBILITY_PENALTY != 0)
	{
		Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, default.RPG_MG_MOBILITY_PENALTY);
	}

	if (default.HIDE_PREVIOUS_RPG_TIERS)
	{
		Template.HideIfResearched = default.RPG_BM_CREATOR_TEMPLATE;
	}
	Template.CreatorTemplateName = default.RPG_MG_CREATOR_TEMPLATE;

	Template.BaseItem = 'IRI_RPG_CV_Utility';

	return Template;
}

static function X2UtilityDisposableLauncherTemplate Create_IRI_RPG_MG_Utility(optional name TemplateName = 'IRI_RPG_MG_Utility')
{
	local X2UtilityDisposableLauncherTemplate Template;

	`CREATE_X2TEMPLATE(class'X2UtilityDisposableLauncherTemplate', Template, TemplateName);

	Template = X2UtilityDisposableLauncherTemplate(Setup_DisposableLauncher_Utility_MG(Template));

	return Template;
}

static function X2DataTemplate Create_IRI_RPG_MG_Secondary()
{
	local X2PairedWeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2PairedWeaponTemplate', Template, 'IRI_RPG_MG_Secondary');

	Template = Setup_DisposableLauncher_Utility_MG(Template);

	Template.BaseItem = 'IRI_RPG_CV_Secondary';

	Template.StowedLocation = eSlot_RightBack;
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.ItemCat = default.RPG_Secondary_ItemCat;
	Template.WeaponCat = default.RPG_Secondary_WeaponCat;

	Template.UIStatMarkups.Remove(3, 1);

	return Template;
}

static function X2DataTemplate Create_IRI_RPG_MG_Heavy()
{
	local X2PairedWeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2PairedWeaponTemplate', Template, 'IRI_RPG_MG_Heavy');

	Template = Setup_DisposableLauncher_Utility_MG(Template);

	Template.StowedLocation = eSlot_HeavyWeapon;
	Template.InventorySlot = eInvSlot_HeavyWeapon;
	Template.ItemCat = default.RPG_Heavy_ItemCat;
	Template.WeaponCat = default.RPG_Heavy_WeaponCat;

	Template.UIStatMarkups.Remove(3, 1);

	return Template;
}

//	*********************************************
//	*********************************************
//				BEAM RPG
//	*********************************************
//	*********************************************

static function X2PairedWeaponTemplate Setup_DisposableLauncher_Utility_BM(X2DataTemplate InTemplate)
{
	local X2PairedWeaponTemplate Template;

	Template = X2PairedWeaponTemplate(InTemplate);

	Setup_DisposableLauncher_Utility(Template);

	Template.Tier = -1;
	Template.WeaponTech = 'beam';

	Template.strImage = "img:///Disposable_BM.UI.Disposable_BM_Inv";

	Template.PairedTemplateName = 'IRI_RPG_BM';

	Template.iRange = default.RPG_BM_RANGE;
	Template.iRadius = default.RPG_BM_RADIUS;
	Template.BaseDamage = default.RPG_BM_BASEDAMAGE;
	Template.iEnvironmentDamage = default.RPG_BM_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.RPG_BM_ICLIPSIZE;

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.RPG_BM_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.RPG_BM_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.RPG_BM_BASEDAMAGE.Shred);
	if (default.RPG_BM_MOBILITY_PENALTY != 0)
	{
		Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, default.RPG_BM_MOBILITY_PENALTY);
	}

	Template.CreatorTemplateName = default.RPG_BM_CREATOR_TEMPLATE;

	Template.BaseItem = 'IRI_RPG_MG_Utility';

	return Template;
}

static function X2DataTemplate Create_IRI_RPG_BM()
{
	local X2DisposableLauncherTemplate Template;

	Template = Setup_DisposableLauncher('IRI_RPG_BM');

	Template.strImage = "img:///Disposable_BM.UI.Disposable_BM_Inv";

	Template.MobilityPenalty = default.RPG_BM_MOBILITY_PENALTY;
	Template.DetectionRadiusModifier = default.RPG_BM_DETECTION_RADIUS_MODIFIER;

	Template.iRange = default.RPG_BM_RANGE;
	Template.iRadius = default.RPG_BM_RADIUS;
	Template.BaseDamage = default.RPG_BM_BASEDAMAGE;
	Template.iSoundRange = default.RPG_BM_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.RPG_BM_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.RPG_BM_ICLIPSIZE;

	Template.Tier = -1;
	Template.WeaponTech = 'beam';
	Template.GameArchetype = "Disposable_BM.Archetypes.WP_Disposable_BM";

	Template.BaseItem = 'IRI_RPG_MG';

	return Template;
}


static function X2UtilityDisposableLauncherTemplate Create_IRI_RPG_BM_Utility(optional name TemplateName = 'IRI_RPG_BM_Utility')
{
	local X2UtilityDisposableLauncherTemplate Template;

	`CREATE_X2TEMPLATE(class'X2UtilityDisposableLauncherTemplate', Template, TemplateName);

	Template = X2UtilityDisposableLauncherTemplate(Setup_DisposableLauncher_Utility_BM(Template));

	return Template;
}

static function X2DataTemplate Create_IRI_RPG_BM_Secondary()
{
	local X2PairedWeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2PairedWeaponTemplate', Template, 'IRI_RPG_BM_Secondary');

	Template = Setup_DisposableLauncher_Utility_BM(Template);

	Template.BaseItem = 'IRI_RPG_MG_Secondary';

	Template.StowedLocation = eSlot_RightBack;
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.ItemCat = default.RPG_Secondary_ItemCat;
	Template.WeaponCat = default.RPG_Secondary_WeaponCat;

	Template.UIStatMarkups.Remove(3, 1);

	return Template;
}

static function X2DataTemplate Create_IRI_RPG_BM_Heavy()
{
	local X2PairedWeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2PairedWeaponTemplate', Template, 'IRI_RPG_BM_Heavy');

	Template = Setup_DisposableLauncher_Utility_BM(Template);

	Template.StowedLocation = eSlot_HeavyWeapon;
	Template.InventorySlot = eInvSlot_HeavyWeapon;
	Template.ItemCat = default.RPG_Heavy_ItemCat;
	Template.WeaponCat = default.RPG_Heavy_WeaponCat;

	Template.UIStatMarkups.Remove(3, 1);

	return Template;
}*/