class X2TargetingMethod_DisposableLauncher extends X2TargetingMethod_RocketLauncher config(DisposableLaunchers);

var config int ONE_ACTION_AIM_MODIFIER;
var config int ONE_ACTION_SCATTER_TILE_MODIFIER;
var config int NUM_AIM_SCATTER_ROLLS;
var config array<name> SCATTER_REDUCTION_ABILITIES;
var config array<int> SCATTER_REDUCTION_MODIFIERS;
var config array<int> ROCKET_RANGE_PROFILE;

var localized string strMaxScatter;

var UIScrollingTextField ScatterAmountText;

function Init(AvailableAction InAction, int NewTargetIndex)
{
    local UITacticalHUD TacticalHUD;

    super.Init(InAction, NewTargetIndex);

    TacticalHUD = UITacticalHUD(`SCREENSTACK.GetScreen(class'UITacticalHUD'));
    ScatterAmountText = TacticalHUD.Spawn(class'UIScrollingTextField', TacticalHUD);
    ScatterAmountText.bAnimateOnInit = false;
    ScatterAmountText.InitScrollingText('AverageScatterText_LW', "", 400, 0, 0);
    ScatterAmountText.SetHTMLText(class'UIUtilities_Text'.static.GetColoredText("? 1.4 Tiles", eUIState_Bad, class'UIUtilities_Text'.const.BODY_FONT_SIZE_3D));
    ScatterAmountText.ShowShadow(0);
}

function GetTargetLocations(out array<Vector> TargetLocations)
{
	local XComWorldData					World;
    local vector						ScatteredTargetLoc;
	local TTile							TileLocation;
	local array<StateObjectReference>	TargetsOnTile;
	local XComGameState_Unit			TargetUnit;

	World = `XWORLD;

    ScatteredTargetLoc = NewTargetLocation;
	ScatteredTargetLoc = static.GetScatterAmount(UnitState, ScatteredTargetLoc);
    
	//	Added by Iridar
	//	By default, the LW2 targeting logic makes the rocket hit half a floor above the tile targeted by scatter mechanics.
	//	This piece of code will change the Z-point the rocket hits based on if the targeted tile has some sort of object in it.

	//	Check if there are any units on targeted tile, and grab a unit state for the first of them.
	
	TileLocation = World.GetTileCoordinatesFromPosition(ScatteredTargetLoc);
	TargetsOnTile = World.GetUnitsOnTile(TileLocation);
	if (TargetsOnTile.Length > 0)
	{
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetsOnTile[0].ObjectID));
	}

	//	If there is a unit, the rocket hits a random point on the target's vertical profile, excluding the lower part of the "legs".
	if (TargetUnit != none)
	{
		ScatteredTargetLoc.Z = World.GetFloorZForPosition(ScatteredTargetLoc) + TargetUnit.UnitHeight * class'XComWorldData'.const.WORLD_HalfFloorHeight + `SYNC_FRAND() * (TargetUnit.UnitHeight - 1) * class'XComWorldData'.const.WORLD_HalfFloorHeight;
	}
	else
	{
		//	if there are no units, we check if there's an object or a piece of cover on the tile.
		if (!World.IsTileOccupied(TileLocation) && !World.IsLocationHighCover(ScatteredTargetLoc))
		{	
			// if there aren't, it basically means there's naked floor in there, so we make the rocket hit the floor
			ScatteredTargetLoc.Z = World.GetFloorZForPosition(ScatteredTargetLoc);
		}
	}
	//	Otherwise, the rocket uses the default logic and hits somewhere above the targeted tile.

	// End of added

	NewTargetLocation = ScatteredTargetLoc;
	TargetLocations.Length = 0;
    TargetLocations.AddItem(ScatteredTargetLoc);
}

function bool GetAdditionalTargets(out AvailableTarget AdditionalTargets)
{
    Ability.GatherAdditionalAbilityTargetsForLocation(NewTargetLocation, AdditionalTargets);
    return true;
}

function Update(float DeltaTime)
{
    local XComWorldData World;
    local VoxelRaytraceCheckResult Raytrace;
    local array<Actor> CurrentlyMarkedTargets;
    local int Direction, CanSeeFromDefault;
    local UnitPeekSide PeekSide;
    local int OutRequiresLean;
    local TTile BlockedTile, PeekTile, UnitTile, SnapTile;
    local bool GoodView;
    local CachedCoverAndPeekData PeekData;
    local array<TTile> Tiles;
    local vector2d vMouseCursorPos;
    local float ExpectedScatter;
    local GameRulesCache_VisibilityInfo OutVisibilityInfo;
    local vector FiringLocation;

    NewTargetLocation = Cursor.GetCursorFeetLocation();
    NewTargetLocation.Z += class'XComWorldData'.const.WORLD_FloorHeight;

    if( NewTargetLocation != CachedTargetLocation )
    {
        FiringLocation = FiringUnit.Location;
        FiringLocation.Z += class'XComWorldData'.const.WORLD_FloorHeight;
        
        World = `XWORLD;
        GoodView = false;
        if( World.VoxelRaytrace_Locations(FiringLocation, NewTargetLocation, Raytrace) )
        {
            BlockedTile = Raytrace.BlockedTile; 
            //  check left and right peeks
            FiringUnit.GetDirectionInfoForPosition(NewTargetLocation, OutVisibilityInfo, Direction, PeekSide, CanSeeFromDefault, OutRequiresLean, true);

            if (PeekSide != eNoPeek)
            {
                UnitTile = World.GetTileCoordinatesFromPosition(FiringUnit.Location);
                PeekData = World.GetCachedCoverAndPeekData(UnitTile);
                if (PeekSide == ePeekLeft)
                    PeekTile = PeekData.CoverDirectionInfo[Direction].LeftPeek.PeekTile;
                else
                    PeekTile = PeekData.CoverDirectionInfo[Direction].RightPeek.PeekTile;

                if (!World.VoxelRaytrace_Tiles(UnitTile, PeekTile, Raytrace))
                    GoodView = true;
                else
                    BlockedTile = Raytrace.BlockedTile;
            }               
        }       
        else
        {
            GoodView = true;
        }

        if( !GoodView )
        {
            NewTargetLocation = World.GetPositionFromTileCoordinates(BlockedTile);
           // Cursor.CursorSetLocation(NewTargetLocation); // new // Commented out per MrNice
        }
        else // new
        {
            if (SnapToTile)
            {
                SnapTile = `XWORLD.GetTileCoordinatesFromPosition(NewTargetLocation);
                `XWORLD.GetFloorPositionForTile(SnapTile, NewTargetLocation);
            }
        }
        GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);
        CheckForFriendlyUnit(CurrentlyMarkedTargets);   
        MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );
        DrawSplashRadius();
        DrawAOETiles(Tiles);

        //update expected scatter amount display

		//	Controller Support per MrNice
		//vMouseCursorPos = LocalPlayer(`LOCALPLAYERCONTROLLER.Player).Project(Cursor.GetCursorFeetLocation());

		/* since the scatter depends on the NewTargetLocation, not the actual point aimed at with the 3DCursor
		 (when they differ), may be better to have it track the NewTargetLocation? -- MrNice*/
		vMouseCursorPos = LocalPlayer(`LOCALPLAYERCONTROLLER.Player).Project(NewTargetLocation);

		/*may need to tweak the x/y offsets to get the precise kind of positioning you want, 
		but that makes it move with the 3D cursor,which always exists, as opposed to the mouse pointer -- MrNice*/
		ScatterAmountText.SetPosition((vMouseCursorPos.X+1)*960 + 2, (1-vMouseCursorPos.Y)*540 + 14); // this follows cursor

		//	Original LW2 code
        //vMouseCursorPos = class'UIUtilities_DRL'.static.GetMouseCoords();
        //ScatterAmountText.SetPosition(vMouseCursorPos.X + 2, vMouseCursorPos.Y + 14); // this follows cursor

        ExpectedScatter = static.GetExpectedScatter(UnitState, NewTargetLocation);
        ScatterAmountText.SetHTMLText(class'UIUtilities_DRL'.static.GetHTMLAverageScatterText(ExpectedScatter));
    }

    super(X2TargetingMethod_Grenade).UpdateTargetLocation(DeltaTime);
}

function Canceled()
{
    super.Canceled();

    ScatterAmountText.Remove();
  //ScatterAmountText.Destroy();	// Commented out per MrNice
}


static function vector GetScatterAmount(XComGameState_Unit Unit, vector ScatteredTargetLoc)
{
    local vector ScatterVector, ReturnPosition;
    local float EffectiveOffense;
    local int Idx, NumAimRolls, TileDistance, TileScatter;
    local float AngleRadians;
    local XComWorldData WorldData;

    WorldData = `XWORLD;

    NumAimRolls = GetNumAimRolls(Unit);
    TileDistance = TileDistanceBetween(Unit, ScatteredTargetLoc);
    NumAimRolls = Min(NumAimRolls, TileDistance);   //clamp the scatter for short range

    EffectiveOffense = GetEffectiveOffense(Unit, TileDistance);

    for(Idx=0 ; Idx < NumAimRolls  ; Idx++)
    {
        if(`SYNC_RAND_STATIC(100) >= EffectiveOffense)
            TileScatter += 1;
    }

    //pick a random direction in radians
    AngleRadians = `SYNC_FRAND_STATIC() * 2.0 * 3.141592653589793;
    ScatterVector.x = Cos(AngleRadians) * TileScatter * WorldData.WORLD_StepSize;
    ScatterVector.y = Sin(AngleRadians) * TileScatter * WorldData.WORLD_StepSize;
    ReturnPosition = ScatteredTargetLoc + ScatterVector;

    ReturnPosition = WorldData.FindClosestValidLocation(ReturnPosition, true, true);

    return ReturnPosition;
}

static function float GetExpectedScatter(XComGameState_Unit Unit, vector TargetLoc)
{
    local float ExpectedScatter;
    local int TileDistance;

    TileDistance = TileDistanceBetween(Unit, TargetLoc);
    ExpectedScatter = (100.0 - GetEffectiveOffense(Unit, TileDistance))/100.0 * float(GetNumAimRolls(Unit));

    return ExpectedScatter;
}

static function float GetEffectiveOffense(XComGameState_Unit Unit, int TileDistance)
{
    local float EffectiveOffense;

    EffectiveOffense = Unit.GetCurrentStat(eStat_Offense);
    if(Unit.ActionPoints.Length <= 1)
	{
        EffectiveOffense += default.ONE_ACTION_AIM_MODIFIER;
	}

    //adjust effective aim for distance
    if(default.ROCKET_RANGE_PROFILE.Length > 0)
    {
        if(TileDistance < default.ROCKET_RANGE_PROFILE.Length)
		{
            EffectiveOffense += default.ROCKET_RANGE_PROFILE[TileDistance];
		}
        else  //  if this tile is not configured, use the last configured tile
		{
            EffectiveOffense += default.ROCKET_RANGE_PROFILE[default.ROCKET_RANGE_PROFILE.Length-1];
		}
    }
    return EffectiveOffense;
}

static function int GetNumAimRolls(XComGameState_Unit Unit)
{
    local int NumAimRolls;
    local name AbilityName;
    local int Idx;

    //set up baseline value
    NumAimRolls = default.NUM_AIM_SCATTER_ROLLS;

    foreach default.SCATTER_REDUCTION_ABILITIES(AbilityName, Idx)
    {
        if(Unit.FindAbility(AbilityName).ObjectID > 0)
		{
            NumAimRolls += default.SCATTER_REDUCTION_MODIFIERS[Idx];
		}
    }

    if(Unit.ActionPoints.Length <= 1)
	{
        NumAimRolls += default.ONE_ACTION_SCATTER_TILE_MODIFIER;
	}
    return NumAimRolls;
}

static function int TileDistanceBetween(XComGameState_Unit Unit, vector TargetLoc)
{
    local XComWorldData WorldData;
    local vector UnitLoc;
    local float Dist;
    local int Tiles;

    WorldData = `XWORLD;
    UnitLoc = WorldData.GetPositionFromTileCoordinates(Unit.TileLocation);
    Dist = VSize(UnitLoc - TargetLoc);
    Tiles = Dist / WorldData.WORLD_StepSize;
    return Tiles;
}

defaultproperties
{
    SnapToTile = true;
}
