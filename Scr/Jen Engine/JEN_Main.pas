unit JEN_Main;
{$I Jen_config.INC}

interface

uses
  JEN_Header,
  JEN_Utils,
  JEN_SystemInfo,
  JEN_Log,
  JEN_Console,
  JEN_DefConsoleLog,
  JEN_Display,
  JEN_Render,
  JEN_Render2D,
  JEN_ResourceManager,
  JEN_DDSTexture,
  JEN_Shader,
  Windows;
   {
const
  lmInfo       = TLogMsg.lmInfo;
  lmNotify     = TLogMsg.lmNotify;
  lmCode       = TLogMsg.lmCode;
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

  TShaderResource = JEN_Shader.TShaderResource;
                                               }
type
  TDDSLoader      = JEN_DDSTexture.TDDSLoader;

  IJenEngine = interface(JEN_Header.IJenEngine)
    procedure Finish;
    procedure CreateEvent(Event: TEvent);
  end;

  TJenEngine = class(TInterfacedObject, IJenEngine)
    constructor Create;
    destructor Destroy; override;
  private
    class var FisRunnig : Boolean;
    class var FQuit : Boolean;
    var FEventsList : array[TEvent] of TList;
  public
    procedure Start(Game: IGame); stdcall;
    procedure GetSubSystem(SubSystemType: TJenSubSystemType; out SubSystem: IJenSubSystem); stdcall;
    procedure CreateEvent(Event: TEvent);
    procedure AddEventProc(Event: TEvent; Proc: TProc); stdcall;
    procedure DelEventProc(Event: TEvent; Proc: TProc); stdcall;
    procedure Finish;
    class property Quit: Boolean read FQuit write FQuit;
  end;

var
  Engine       : IJenEngine;
  Utils        : IUtils;
  SystemParams : ISystemParams;
  Log          : ILog;
  Render       : IRender;
  Render2d     : IRender2D;
  Display      : IDisplay;
  ResMan       : IResourceManager;
  Game         : IGame;

procedure LogOut(const Text: string; MType: TLogMsg);
procedure pGetEngine(out Eng: JEN_Header.IJenEngine); stdcall;

implementation

procedure LogOut(const Text: string; MType: TLogMsg);
begin
  if Assigned(Log) then
  Log.Print(Text, MType);
end;

procedure pGetEngine(out Eng: JEN_Header.IJenEngine);
begin
   Engine := TJenEngine.Create;
   Eng := Engine;
end;

constructor TJenEngine.Create;
var
  Event : TEvent;
begin

  inherited;
  for Event:=Low(TEvent) to High(TEvent) do
    FEventsList[Event] := TList.Create;

  Utils := TUtils.Create;
  SystemParams := TSystem.Create;
  Log := TLog.Create;

  {$IFDEF DEBUG}
  //AllocConsole;
//  SetConsoleTitle('Jen Console');
  //Log.RegisterOutput(TDefConsoleLog.Create);
  Log.RegisterOutput(TConsole.Create);
  {$ENDIF}

  Render := TRender.Create;
  Render2d := TRender2D.Create;
  Display := TDisplay.Create;
  ResMan := TResourceManager.Create;
end;

destructor TJenEngine.Destroy;
var
  Event : TEvent;
begin
  for Event:=Low(TEvent) to High(TEvent) do
    FEventsList[Event].Free;

  inherited;
end;

procedure TJenEngine.Start(Game: IGame);

  procedure TestRefCount(SubSystem: IUnknown; Name: String);
  begin
    if(SubSystem._AddRef>3) then
      LogOut('Do not all reference to ' + Name + ' released', lmError);
    SubSystem._Release;
  end;

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

  if(not( Assigned(Display) and Display.Valid and
          Assigned(Render) and Render.Valid and
          Assigned(ResMan) ) )then
  begin
    Logout('Error in some subsustem', lmError);
    Exit;
  end;

  Logout('Let''s rock!', lmNotify);
  FisRunnig := true;

  Game.LoadContent;

  while not FQuit do
    begin
      Display.Update;
      Game.OnUpdate(0);
      Game.OnRender;
      Render.Flush;
      Display.Swap;
    end;

  Game.Close;

  TestRefCount(ResMan, 'resource manager');
  ResMan       := nil;

  TestRefCount(Render2d, '2D render');
  Render2d     := nil;

  TestRefCount(Render, 'render');
  Render       := nil;

  TestRefCount(Display, 'display');
  Display      := nil;

  TestRefCount(SystemParams, 'system info');
  SystemParams := nil;

  {$IFDEF DEBUG}
  Utils.Sleep(1500);
  {$ENDIF}

  Log          := nil;
  Utils        := nil;
end;

procedure TJenEngine.GetSubSystem(SubSystemType: TJenSubSystemType;out SubSystem: IJenSubSystem);
begin
  case SubSystemType of
    ssUtils : SubSystem :=  IJenSubSystem(Utils);
 //   ssSystemParams : SubSystem := SystemParams;
    ssLog : SubSystem :=  IJenSubSystem(Log);
    ssDisplay : SubSystem := IJenSubSystem(Display);
    ssResMan : SubSystem := IJenSubSystem(ResMan);
    ssRender : SubSystem := IJenSubSystem(Render);
    ssRender2d : SubSystem := IJenSubSystem(Render2d);
  else
    SubSystem := nil;
  end;
end;

procedure TJenEngine.CreateEvent(Event: TEvent);
var
  i : LongInt;
begin
  for i:=0 to FEventsList[Event].Count-1 do
    TProc(FEventsList[Event][i]);
end;

procedure TJenEngine.AddEventProc(Event : TEvent; Proc: TProc);
begin
  FEventsList[Event].Add(@Proc);
end;

procedure TJenEngine.DelEventProc(Event: TEvent; Proc: TProc);
begin
  FEventsList[Event].Del(FEventsList[Event].IndexOf(@Proc));
end;

procedure TJenEngine.Finish;
begin
  FQuit := True;
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
finalization
begin
  Engine       := nil;
  Utils        := nil;
  SystemParams := nil;
  Log          := nil;
  Render       := nil;
  Render2d     := nil;
  Display      := nil;
  ResMan       := nil;
  Game         := nil;
end;

end.
