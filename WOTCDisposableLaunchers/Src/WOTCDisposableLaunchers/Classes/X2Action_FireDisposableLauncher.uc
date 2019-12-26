class X2Action_FireDisposableLauncher extends X2Action_Fire;

// A copy of the original class that X2Action_Fire class that changes firing animation based on how much ammo remains in the weapon

var private XComPresentationLayer	PresentationLayer;
var privatewrite int                PrimaryTargetID;

function Init()
{
	local XComGameState_Ability AbilityState;	
	local XGUnit FiringUnit;	
	local XComPrecomputedPath Path;
	local XComGameState_Item WeaponItem;
	local X2WeaponTemplate WeaponTemplate;
	local Actor TargetVisualizer;
	local Vector TargetLoc;
	local string MissAnimString;
	local name MissAnimName;
	local int LastCharacter;
	local XComGameState_Item Item;
	local XGWeapon AmmoWeapon;
	local XComWeapon Entity, WeaponEntity;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local name AdditiveAnim;
	local XComGameState_Unit PrimaryTargetState;

	super.Init();

	//`LOG("FIRING ROCKET",, 'IRIDIS');

	PresentationLayer = `PRES;

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);

	VisualizeGameState = AbilityContext.GetLastStateInInterruptChain();

	History = `XCOMHISTORY;

	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	SourceItemGameState = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

	AbilityTemplate = AbilityState.GetMyTemplate();

	bComingFromEndMove = AbilityContext.InputContext.MovementPaths.Length > 0;
	if(bComingFromEndMove && AbilityContext.InputContext.MovementPaths[0].MovementData.Length > 0)
	{
		MoveEndDestination = AbilityContext.InputContext.MovementPaths[0].MovementData[AbilityContext.InputContext.MovementPaths[0].MovementData.Length - 1].Position;
	}
	else
	{
		MoveEndDestination = UnitPawn.Location;
	}

	MoveEndDirection = vector(UnitPawn.Rotation);

	//bUseKillAnim = false;
	if (PrimaryTargetID == 0)
		PrimaryTargetID = AbilityContext.InputContext.PrimaryTarget.ObjectID;

	if( PrimaryTargetID > 0 )
	{
		PrimaryTargetState = XComGameState_Unit(History.GetGameStateForObjectID(PrimaryTargetID));
		if (PrimaryTargetState != none)
		{
			bPrimaryTargetIsPlayerControlled = PrimaryTargetState.IsPlayerControlled();
			TargetVisualizer = History.GetGameStateForObjectID(PrimaryTargetID).GetVisualizer();
			TargetUnit = XGUnit(TargetVisualizer);
			PrimaryTarget = X2VisualizerInterface(TargetVisualizer);
			//bUseKillAnim = TargetUnit != none ? XComGameState_Unit(History.GetGameStateForObjectID(PrimaryTargetID)).IsDead() : false;
			TargetLoc = TargetVisualizer.Location;
		}		
	}

	if( AbilityContext.InputContext.TargetLocations.Length > 0 )
	{		
		TargetLocation = AbilityContext.InputContext.TargetLocations[0];
		TargetLoc = TargetLocation;
		AimAtLocation = TargetLocation;
	}

	MoveEndDirection = TargetLoc - MoveEndDestination;
	MoveEndDirection.Z = 0;
	if( MoveEndDirection.X == 0.0f && MoveEndDirection.Y == 0.0f )
	{
		MoveEndDirection = vector(UnitPawn.Rotation);
	}
	MoveEndDirection = Normal(MoveEndDirection);

	AnimParams = default.AnimParams;
	//AnimParams.AnimName = AbilityState.GetFireAnimationName(UnitPawn, bComingFromEndMove, bUseKillAnim, MoveEndDirection, vector(UnitPawn.Rotation), PrimaryTargetID == SourceUnitState.ObjectID, DistanceForAttack);
	
	//	ADDED BY IRIDAR
	//	Note: the weapon's ammo will be pulled *after* the ability ammo cost is paid.
	if (AbilityState.GetSourceWeapon().Ammo > 0) AnimParams.AnimName = 'FF_FirePutBack';
	else AnimParams.AnimName = 'FF_Fire';
	
	// END OF ADDED

	// Check for hit or miss. If miss, remove A, append MissA. Only orverwrite if can play.
	if( !class'XComGameStateContext_Ability'.static.IsHitResultHit(AbilityContext.ResultContext.HitResult) )
	{
		MissAnimString = string(AnimParams.AnimName);
		LastCharacter = Asc(Right(MissAnimString, 1));
		
		// Jwats: Only remove the A-Z if it is there, otherwise leave it the same
		if( LastCharacter >= 65 && LastCharacter <= 90 )
		{
			MissAnimString = Mid(MissAnimString, 0, (Len(MissAnimString) - 1));
		}
		
		MissAnimString $= "Miss";
		MissAnimName = name(MissAnimString);

		if( UnitPawn.GetAnimTreeController().CanPlayAnimation(MissAnimName) )
		{
			AnimParams.AnimName = MissAnimName;
		}
	}

	if (bComingFromEndMove)
	{
		AnimParams.DesiredEndingAtoms.Add(1);
		AnimParams.DesiredEndingAtoms[0].Translation = MoveEndDestination;
		AnimParams.DesiredEndingAtoms[0].Translation.Z = Unit.GetDesiredZForLocation(MoveEndDestination);
		AnimParams.DesiredEndingAtoms[0].Rotation = QuatFromRotator(Rotator(MoveEndDirection));
		AnimParams.DesiredEndingAtoms[0].Scale = 1.0f;

		Unit.RestoreLocation = AnimParams.DesiredEndingAtoms[0].Translation;
		Unit.RestoreHeading = vector(QuatToRotator(AnimParams.DesiredEndingAtoms[0].Rotation));
	}


	if (SourceItemGameState != none)
		WeaponVisualizer = XGWeapon(SourceItemGameState.GetVisualizer());

	//Set the timeout based on our expected run time
	if( AbilityTemplate.TargetingMethod.static.GetProjectileTimingStyle() == class'X2TargetingMethod_Grenade'.default.ProjectileTimingStyle )
	{
		Path = `PRECOMPUTEDPATH;
		FiringUnit = XGUnit(History.GetVisualizer(AbilityState.OwnerStateObject.ObjectID));
		
		WeaponItem = AbilityState.GetSourceWeapon();
		if (WeaponItem != none)
		{
			WeaponTemplate = X2WeaponTemplate(WeaponItem.GetMyTemplate());
			WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());
			WeaponEntity = WeaponVisualizer.GetEntity();
		}
		else if (FiringUnit.CurrentPerkAction != none)
		{
			WeaponEntity = FiringUnit.CurrentPerkAction.GetPerkWeapon();
		}

		// grenade tosses hide the weapon
		if( AbilityTemplate.bHideWeaponDuringFire)
		{
			WeaponEntity.Mesh.SetHidden( false );						// unhide the grenade that was hidden after the last one fired
		}
		else if( AbilityTemplate.bHideAmmoWeaponDuringFire)
		{
			Item = XComGameState_Item( `XCOMHISTORY.GetGameStateForObjectID( AbilityState.SourceAmmo.ObjectID ) );
			AmmoWeapon = XGWeapon( Item.GetVisualizer( ) );
			Entity = XComWeapon( AmmoWeapon.m_kEntity );
			Entity.Mesh.SetHidden( true );
		}

		if( AbilityTemplate.bUseThrownGrenadeEffects || AbilityTemplate.bAllowUnderhandAnim)
		{
			// hackhackhack - we are assuming the underhand fire name here! --Ned
			if (Path.m_bIsUnderhandToss)
				AnimParams.AnimName = 'FF_GrenadeUnderhand';
		}

		Path.SetWeaponAndTargetLocation( WeaponEntity, FiringUnit.GetTeam( ), AbilityContext.InputContext.TargetLocations[ 0 ], WeaponTemplate.WeaponPrecomputedPathData );

		if (Path.iNumKeyframes <= 0) // just in case (but mostly because replays don't have a proper path computed)
		{
			Path.CalculateTrajectoryToTarget( WeaponTemplate.WeaponPrecomputedPathData );
			`assert( Path.iNumKeyframes > 0 );
		}

		Path.bUseOverrideTargetLocation = true;
		Path.UpdateTrajectory();
		Path.bUseOverrideTargetLocation = false; //Only need this for the above calculation
		NotifyTargetTimer = Path.GetEndTime() + 1.5f;
		bUseAnimToSetNotifyTimer = false;

		AimAtLocation = Path.ExtractInterpolatedKeyframe(0.3f).vLoc;
	}
	else if( AbilityTemplate.TargetingMethod.static.GetProjectileTimingStyle() == class'X2TargetingMethod_BlasterLauncher'.default.ProjectileTimingStyle )
	{
		Path = `PRECOMPUTEDPATH;
		FiringUnit = XGUnit(History.GetVisualizer(AbilityState.OwnerStateObject.ObjectID));
		
		WeaponItem = AbilityState.GetSourceWeapon();
		WeaponTemplate = X2WeaponTemplate(WeaponItem.GetMyTemplate());
		WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());

		Path.SetWeaponAndTargetLocation( WeaponVisualizer.GetEntity( ), FiringUnit.GetTeam( ), AbilityContext.InputContext.TargetLocations[ 0 ], WeaponTemplate.WeaponPrecomputedPathData );

		if (Path.iNumKeyframes <= 0) // just in case (but mostly because replays don't have a proper path computed)
		{
			Path.CalculateBlasterBombTrajectoryToTarget();
			`assert( Path.iNumKeyframes > 0 );
		}

		NotifyTargetTimer = Path.GetEndTime() + 1.5f;
		bUseAnimToSetNotifyTimer = false;

		AimAtLocation = Path.ExtractInterpolatedKeyframe(0.3f).vLoc;
	}
	else
	{
		//RAM - backwards compatibility support for old projectiles
		NotifyTargetTimer = UnitPawn.GetAnimTreeController().GetFirstCustomFireNotifyTime(AnimParams.AnimName);
		if( NotifyTargetTimer > 0.0f )
		{
			bUseAnimToSetNotifyTimer = true;
		}
	}

	foreach SourceUnitState.AppliedEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		AdditiveAnim = EffectState.GetX2Effect().ShooterAdditiveAnimOnFire(StateChangeContext, SourceUnitState, EffectState);
		if (AdditiveAnim != '')
			ShooterAdditiveAnims.AddItem(AdditiveAnim);
	}
}