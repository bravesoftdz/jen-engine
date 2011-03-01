unit JEN_Main;
{$I Jen_config.INC}

interface

uses
  JEN_Header,
  JEN_Utils,
  JEN_SystemInfo,
  JEN_Log,
  JEN_DefConsoleLog,
  JEN_Display,
  JEN_Display_Window,
  JEN_OpenGLHeader,
  JEN_OpenGL,
  JEN_Render,
  JEN_ResourceManager,
  JEN_DDSTexture,
  JEN_Shader,
  JEN_Camera3D,
  JEN_Math,
  XSystem;

const
  lmInfo       = TLogMsg.lmInfo;
  lmNotify     = TLogMsg.lmNotify;
  lmWarning    = TLogMsg.lmWarning;
  lmError      = TLogMsg.lmError;

  btNone        = TBlendType.btNone;
  btNormal      = TBlendType.btNormal;
  btAdd         = TBlendType.btAdd;
  btMult        = TBlendType.btMult;
  btOne         = TBlendType.btOne;
  btNoOverride  = TBlendType.btNoOverride;
  btAddAlpha    = TBlendType.btAddAlpha;

  cfNone        = TCullFace.cfNone;
  cfFront       = TCullFace.cfFront;
  cfBack        = TCullFace.cfBack;

  mtViewProj    = TMatrixType.mtViewProj;
  mtModel       = TMatrixType.mtModel;
  mtProj        = TMatrixType.mtProj;
  mtView        = TMatrixType.mtView;

type
  TGLRender       = JEN_OpenGL.TGLRender;

  TFileStream     = JEN_Utils.TFileStream;

  TResourceManager= JEN_ResourceManager.TResourceManager;
  TDDSLoader      = JEN_DDSTexture.TDDSLoader;
  TTexture        = JEN_ResourceManager.TTexture;
  TShader         = JEN_Shader.TShader;

  TJenEngine = class(TInterfacedObject, IJenEngine)
    constructor Create;
  private
    class var FisRunnig : Boolean;
    class var FQuit : Boolean;
  public
    function GetSubSystem(SubSystemType: TSubSystemType; out SubSystem: IEngineSubSystem) : HResult; stdcall;
    function Start(Game : IGame) : HResult; stdcall;
    function Finish : HResult;
    class property Quit: Boolean read FQuit;
  end;

var
  Engine       : TJenEngine;
  Game         : IGame;
  Utils        : TUtils;
  SystemParams : TSystem;
  Log          : TLog;
  Render       : TRender;
  Display      : TDisplay;
  ResMan       : TResourceManager;

procedure LogOut(const Text: string; MType: TLogMsg);
procedure pGetEngine(out Engine: IJenEngine); stdcall;

implementation

procedure LogOut(const Text: string; MType: TLogMsg);
begin
  Log.AddMsg(Text, MType);
end;

procedure pGetEngine(out Engine: IJenEngine);
begin
   Engine := TJenEngine.Create;
end;

constructor TJenEngine.Create;
begin
  inherited;
  Utils := TUtils.Create;
  SystemParams := TSystem.Create;
  Log := TLog.Create;
  Display := TDisplay.Create;
  {$IFDEF DEBUG}
  AllocConsole;
  SetConsoleTitleW('Jen Console');
  TDefConsoleLog.Create;
  {$ENDIF}
  Log.Init;
end;

function TJenEngine.GetSubSystem(SubSystemType: TSubSystemType;out SubSystem: IEngineSubSystem): HResult;
begin
//Result := S_OK;
  //subSystem := Display;
//  case SubSystemType of
   { ssUtils : SubSystem := Utils;
    ssSystemParams : SubSystem := SystemParams;
    ssLog : SubSystem := Log;         }
 //   ssDisplay : SubSystem := Display;
 {   ssRender : SubSystem := Render;
    ssResMan : SubSystem := ResMan;    }
//  else
//     Result := S_FALSE;
//  end;
  //Display.Init(800,800,0,False);
end;


     {
  if(FisRunnig) then
  begin
    LogOut('Engine alredy running', lmError);
    Exit;
  end;

  FQuit  := False;

  destructor TGame.Destroy;
begin
  if Assigned(Render) then
    FreeAndNil(Render);

  if Assigned(Display) then
    FreeAndNil(Display);

  if Assigned(ResMan) then
    FreeAndNil(ResMan);

  FisRunnig := False;
  inherited;
end;
               }
function TJenEngine.Finish;
begin
  FQuit := True;
end;

function TJenEngine.Start(Game : IGame) : HResult;
begin
  if not Assigned(Game) then
  begin
    LogOut('Game is not assigned', lmError);
    Exit;
  end;

  if(FisRunnig) then
  begin
    LogOut('Engine alredy running', lmError);
    Exit;
  end;

  {if(not( Assigned(Display) and Display.Valid and
          Assigned(Render) and Render.Valid{ and
          Assigned(ResMan)} {) )then   }
  begin
    Logout('Error in some subsustem', lmError);
    Exit;
  end;

  Logout('Let''s rock!', lmNotify);
  FisRunnig := true;

  Game.LoadContent;

  while not FQuit do
    begin
     // Display.Update;
      Game.OnUpdate(0);
      Game.OnRender;
  //   glfinish;
     // Display.Swap;
    end;
end;

initialization
begin
  TJenEngine.FisRunnig := false;
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
{$IFNDEF JEN_CTD}
  {$IFNDEF JEN_ATTACH_DLL}
    GetEngine := pGetEngine;
  {$ENDIF}
{$ENDIF}
end;

finalization
begin
  Utils.Free;
  SystemParams.Free;
  Log.Free;
end;

end.
