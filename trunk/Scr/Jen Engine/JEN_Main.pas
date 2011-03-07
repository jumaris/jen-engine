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

  JEN_OpenGLHeader,
  JEN_Render,
  JEN_ResourceManager,
  JEN_DDSTexture,
  JEN_Shader,


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
  TFileStream     = JEN_Utils.TFileStream;

  TResourceManager= JEN_ResourceManager.TResourceManager;
  TDDSLoader      = JEN_DDSTexture.TDDSLoader;
  TTexture        = JEN_ResourceManager.TTexture;
  TShader         = JEN_Shader.TShader;

  TJenEngine = class(TInterfacedObject, IJenEngine)
    constructor Create;
    destructor Destroy; override;
  private
    class var FisRunnig : Boolean;
    class var FQuit : Boolean;
  public
    procedure GetSubSystem(SubSystemType: TJenSubSystemType; out SubSystem: IJenSubSystem); stdcall;
    procedure Start(Game : IGame); stdcall;
    procedure Finish; stdcall;
    class property Quit: Boolean read FQuit write FQuit;
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
  Log.Print(Text, MType);
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
  Render := TRender.Create;
  {$IFDEF DEBUG}
  AllocConsole;
  SetConsoleTitleW('Jen Console');
  TDefConsoleLog.Create;
  {$ENDIF}
  Log.Init;
end;

destructor TJenEngine.Destroy;
begin
  Utils.Free;
  SystemParams.Free;
  Log.Free;
  inherited;
end;

procedure TJenEngine.GetSubSystem(SubSystemType: TJenSubSystemType;out SubSystem: IJenSubSystem);
begin
  case SubSystemType of
    ssUtils : SubSystem :=  IJenSubSystem(Utils);
 //   ssSystemParams : SubSystem := SystemParams;
    ssLog : SubSystem :=  IJenSubSystem(Log);
    ssDisplay : SubSystem := IJenSubSystem(Display);
    ssRender : SubSystem := IJenSubSystem(Render);
   { ssResMan : SubSystem := ResMan;     }
  else
    SubSystem := nil;
  end;

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
procedure TJenEngine.Finish;
begin
  FQuit := True;
end;

procedure TJenEngine.Start(Game : IGame);
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
          Assigned(ResMan)} {) )then   }    {
  begin
    Logout('Error in some subsustem', lmError);
    Exit;
  end;                        }

  Logout('Let''s rock!', lmNotify);
  FisRunnig := true;

  Game.LoadContent;

  while not FQuit do
    begin
      Display.Update;
      Game.OnUpdate(0);
      Game.OnRender;
   //   glfinish;
      glClear( GL_COLOR_BUFFER_BIT);
      Display.Swap;
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
    GetJenEngine := pGetEngine;
  {$ENDIF}
{$ENDIF}
end;

end.
