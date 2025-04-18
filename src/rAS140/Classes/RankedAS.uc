//=============================================================================
// RankedAS Mutator
//=============================================================================
class RankedAS extends Mutator;

var() config string MapFixPackage, SupportPackage, PlusPackageBaseName, SupportPackageBaseName;
var() config string PlusWeaponSettingsTag;

var bool bHasStarted;
var bool bRestartRequired;
var name TempName;

function PreBeginPlay()
{
   // Allow this to be spawned but not started through DataLink for configuration
   if (!bHasStarted)
   {
      if (Owner != None && (Owner.IsA('ServerSetupDataLink') || Owner.IsA('PugLink') || Owner.IsA('ServerQuery')))
      {
         log("Loaded RankedAS mutator into memory for configuration purposes only.",'RankedAS');
      }
      else
      {
         log("Seeking and starting Map Fixes via package:"@MapFixPackage$".u",'RankedAS');
         Level.Game.RegisterMessageMutator(Self);
         StartMapFixMutator();
      }
   }
   bHasStarted = true;
}

function PostBeginPlay()
{
   
   if (bRestartRequired)
   {
      log("Attempting restart of level (package or settings updates).",'RankedAS');
      Level.ServerTravel("?restart",false);
      SetTimer(6,false);
   }
}

event Timer()
{
   // Handle when something clashes with the restart...
   if (bRestartRequired && Level.NextURL == "")
   {
      log("Forcing restart of level (package or settings updates).",'RankedAS');
      Level.ServerTravel("?restart",false);
      bRestartRequired = false;
   }
}

function StartMapFixMutator()
{
   local class C;
   local actor A;
   local Mutator M;

    // Dynamically Load the MapFix mutator
    C = class<Actor>(DynamicLoadObject(MapFixPackage$".MapFixes",class'Class'));
    if (C == None)
    {
        Log("MapFix mutator Load failed - "@MapFixPackage$".MapFixes",'RankedAS');
    } else if (C != None)
    {
        A = Level.Spawn(class<Actor>(C));
        if (A!=None)
        {
        Log("MapFixes mutator spawned successfully.",'RankedAS');
        if (A.IsA('Mutator') && (Mutator(A)!=None))
        {
            for (M=Level.Game.BaseMutator; M!=None; M=M.NextMutator) if (M==A) return;
            Level.Game.BaseMutator.AddMutator(Mutator(A));
        }
        }
    }      
}

defaultproperties
{
   MapFixPackage="MapFixesLA13"
}