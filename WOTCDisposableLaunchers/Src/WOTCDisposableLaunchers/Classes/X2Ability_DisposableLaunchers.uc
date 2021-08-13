class X2Ability_DisposableLaunchers extends X2Ability config (DisposableLaunchers);

var config int RPG_ACTION_POINT_COST;
var config bool RPG_ACTION_POINT_ENDS_TURN;
var config array<name> RPG_NON_TURN_ENDING_ABILITIES;

`include(WOTCDisposableLaunchers\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(IRI_FireRPG());
	Templates.AddItem(IRI_PenaltyRPG());

	return Templates;
}

static function X2AbilityTemplate IRI_FireRPG()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityTarget_Cursor            CursorTarget;
	local X2AbilityMultiTarget_Radius       RadiusMultiTarget;
	local X2AbilityToHitCalc_StandardAim    StandardAim;
	local X2Effect_ApplyWeaponDamage		WeaponDamageEffect;
	local X2Effect_Knockback				KnockbackEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_FireRPG');

	// Icon setup
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_CannotAfford_AmmoCost');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_firerocket";
	Template.bUseAmmoAsChargesForHUD = true;

	// Targeting and Triggering
	Template.TargetingMethod = class'X2TargetingMethod_RocketLauncher';	
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bGuaranteedHit = true;
	StandardAim.bIndirectFire = true;
	Template.AbilityToHitCalc = StandardAim;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = true;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.RPG_ACTION_POINT_COST;
	ActionPointCost.bConsumeAllPoints = default.RPG_ACTION_POINT_ENDS_TURN;
	ActionPointCost.DoNotConsumeAllSoldierAbilities = default.RPG_NON_TURN_ENDING_ABILITIES;
	Template.AbilityCosts.AddItem(ActionPointCost);

	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
	
	// Effects
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.AddMultiTargetEffect(WeaponDamageEffect);

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	Template.AddMultiTargetEffect(KnockbackEffect);

	// State and Viz
	Template.ActivationSpeech = 'RocketLauncher';
	Template.CinescriptCameraType = "Iridar_DisposableLauncher";
	Template.ActionFireClass = class'X2Action_FireDisposableLauncher';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.HeavyWeaponLostSpawnIncreasePerUse;

	return Template;	
}

static function X2AbilityTemplate IRI_PenaltyRPG()
{
	local X2AbilityTemplate					Template;	
	local X2Effect_DRL_Penalty				MobilityDamageEffect;
	local X2AbilityTrigger_EventListener	Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_PenaltyRPG');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_heavy_rockets";

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	//	don't apply penalty to heavy armor
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_HeavyArmor');
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'PlayerTurnBegun';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);

	MobilityDamageEffect = new class 'X2Effect_DRL_Penalty';
	MobilityDamageEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	MobilityDamageEffect.SetDisplayInfo(ePerkBuff_Passive,Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage,,, Template.AbilitySourceName);
	MobilityDamageEffect.DuplicateResponse = eDupe_Ignore;
	MobilityDamageEffect.EffectName = 'IRI_MobilityPenalty';
	Template.AddShooterEffect(MobilityDamageEffect);

	Template.bDisplayInUITacticalText = false;
	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.bUniqueSource = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;	
}
