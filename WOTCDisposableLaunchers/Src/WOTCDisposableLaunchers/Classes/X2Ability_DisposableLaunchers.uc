class X2Ability_DisposableLaunchers extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_IRI_FireRPG());
	Templates.AddItem(Create_IRI_MobilityPenalty());
	Templates.AddItem(Create_IRI_DisposableStackAmmo());

	return Templates;
}

static function X2AbilityTemplate Create_IRI_FireRPG()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityTarget_Cursor            CursorTarget;
	local X2AbilityMultiTarget_Radius       RadiusMultiTarget;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2AbilityToHitCalc_StandardAim    StandardAim;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_FireRPG');
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = class'X2Item_DisposableLaunchers'.default.RPG_ACTION_POINT_COST;
	ActionPointCost.bConsumeAllPoints = class'X2Item_DisposableLaunchers'.default.RPG_ACTION_POINT_ENDS_TURN;
	ActionPointCost.DoNotConsumeAllSoldierAbilities = class'X2Item_DisposableLaunchers'.default.RPG_NON_TURN_ENDING_ABILITIES;
	Template.AbilityCosts.AddItem(ActionPointCost);

	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
	
	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bGuaranteedHit = true;
	StandardAim.bIndirectFire = true;
	Template.AbilityToHitCalc = StandardAim;

	Template.bUseThrownGrenadeEffects = true;
	Template.bHideAmmoWeaponDuringFire = false; // hide the grenade

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = true;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	Template.AddShooterEffectExclusions();

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_CannotAfford_AmmoCost');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_firerocket";
	Template.bUseAmmoAsChargesForHUD = true;

	if (class'X2Item_DisposableLaunchers'.default.DISABLE_ROCKET_SCATTER)
	{
		Template.TargetingMethod = class'X2TargetingMethod_RocketLauncher';
	}
	else
	{
		Template.TargetingMethod = class'X2TargetingMethod_DisposableLauncher';
	}
	
	Template.DamagePreviewFn = class'X2Ability_Grenades'.static.GrenadeDamagePreview;

	Template.ActivationSpeech = 'RocketLauncher';
	//Template.CustomFireAnim = 'FF_IRI_FireRocketA';

	//Template.CinescriptCameraType = "Grenadier_GrenadeLauncher";
	//Template.CinescriptCameraType = "Soldier_HeavyWeapons";
	Template.CinescriptCameraType = "Iridar_DisposableLauncher";
	
	Template.ActionFireClass = class'X2Action_FireDisposableLauncher';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.HeavyWeaponLostSpawnIncreasePerUse;

	return Template;	
}

static function X2AbilityTemplate Create_IRI_MobilityPenalty()
{
	local X2AbilityTemplate						Template;	
	local X2Effect_DisposableMobilityPenalty	MobilityDamageEffect;
	local X2AbilityTrigger_EventListener		Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_DisposableMobilityPenalty');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_heavy_rockets";

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	if (!class'X2Item_DisposableLaunchers'.default.MOBILITY_PENALTY_IS_APPLIED_TO_HEAVY_ARMOR)
	{
		//	don't apply penalty to heavy armor
		Template.AbilityShooterConditions.AddItem(new class'X2Condition_HeavyArmor');
	}

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'PlayerTurnBegun';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);

	MobilityDamageEffect = new class 'X2Effect_DisposableMobilityPenalty';
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

static function X2AbilityTemplate Create_IRI_DisposableStackAmmo()
{
	local X2AbilityTemplate					Template;	

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_DisposableStackAmmo');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_heavy_rockets";

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Template.AddShooterEffect(new class'X2Effect_IRI_StackAmmo');

	Template.bDisplayInUITacticalText = false;
	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.bUniqueSource = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;	
}