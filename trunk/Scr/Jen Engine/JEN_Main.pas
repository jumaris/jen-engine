unit JEN_Main;
{$I Jen_config.INC}

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_Utils,
  JEN_Helpers,
  JEN_Input,
  JEN_Log,
  JEN_Console,
  JEN_Display,
  JEN_Render,
  JEN_Render2D,
  JEN_ResourceManager;
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

type
  TDDSLoader      = JEN_DDSTexture.TDDSLoader; }
type

  TJenEngine = class(TInterfacedObject, IJenEngine)
    constructor Create(Debug : Boolean);
    destructor Destroy; override;
  private
    class var FisRunnig : Boolean;
    class var FQuit : Boolean;
    var FEventsList : array[TEvent] of TList;
    var FLastUpdate : LongInt;
  public
    procedure Start(Game: IGame); stdcall;
    procedure GetSubSystem(SubSystemType: TJenSubSystemType; out SubSystem: IJenSubSystem); stdcall;
    procedure CreateEvent(Event: TEvent; Param: LongInt = 0);
    procedure AddEventProc(Event: TEvent; Proc: TEventProc); stdcall;
    procedure DelEventProc(Event: TEvent; Proc: TEventProc); stdcall;
    procedure Finish; stdcall;
    class property Quit: Boolean read FQuit write FQuit;
  end;

var
  Engine     : TJenEngine;
  Utils      : IUtils;
  Input      : IInput;
  Helpers    : IHelpers;
  Log        : ILog;
  Render     : IRender;
  Render2d   : IRender2D;
  Display    : IDisplay;
  ResMan     : IResourceManager;
  Game       : IGame;

procedure LogOut(const Text: string; MType: TLogMsg);
procedure pGetEngine(out Eng: JEN_Header.IJenEngine; Debug: Boolean); stdcall;

implementation

procedure LogOut(const Text: string; MType: TLogMsg);
begin
  if Assigned(Log) then
    Log.Print(Text, MType);
end;

procedure pGetEngine(out Eng: JEN_Header.IJenEngine; Debug: Boolean);
begin
   Engine := TJenEngine.Create(Debug);
   Eng := IJenEngine(Engine);
end;

constructor TJenEngine.Create;
var
  Event : TEvent;
begin
  for Event:=Low(TEvent) to High(TEvent) do
    FEventsList[Event] := TList.Create;

  Utils := TUtils.Create;
  Helpers := THelpers.Create;
  Log := TLog.Create;
  Input := JEN_Input.TInput.Create;

  {$IFDEF DEBUG}
  Log.RegisterOutput(TConsole.Create);
  {$ELSE}
  if Debug then
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

  procedure TestRefCount(SubSystem: IUnknown; Name: String);
  begin
    if not Assigned(SubSystem) then
    begin
      LogOut('OMG all reference to ' + Name + ' released', lmError);
      Exit;
    end;

    if(SubSystem._AddRef>3) then
      LogOut('Do not all reference to ' + Name + ' released', lmError);
    SubSystem._Release;
  end;

begin
  for Event:=Low(TEvent) to High(TEvent) do
    FEventsList[Event].Free;

  TestRefCount(ResMan, 'resource manager');
  ResMan       := nil;

  TestRefCount(Render2d, '2D render');
  Render2d     := nil;

  TestRefCount(Render, 'render');
  Render       := nil;

  TestRefCount(Display, 'display');
  Display      := nil;

  TestRefCount(Helpers, 'helpers');
  Helpers := nil;

  TestRefCount(Input, 'input');
  Input := nil;

  Log          := nil;
  Utils        := nil;
  inherited;
end;

procedure TJenEngine.Start(Game: IGame);
var
  DeltaTime : LongInt;
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
          Assigned(ResMan) and Assigned(Helpers) and
          Assigned(Render2d) and Assigned(Utils) ))then
  begin
    Logout('Error in some subsustem', lmError);
    Exit;
  end;

  Logout('Let''s rock!', lmNotify);
  FisRunnig := True;

  Game.LoadContent;
  Input.Init;

  FLastUpdate := Utils.Time;
  DeltaTime := 1;
  while not FQuit do
  begin
    Utils.Update;
    Display.Update;
    Input.Update;
    Game.OnUpdate(DeltaTime);
    Game.OnRender;
    Render.Flush;
    Display.Swap;

  //  if Render. then

    Utils.Sleep( Max(2 - (Utils.Time - FLastUpdate), 0));
    DeltaTime := Max(Utils.Time - FLastUpdate, 1);

    FLastUpdate := Utils.Time;
  end;

  Game.Close;
end;

procedure TJenEngine.GetSubSystem(SubSystemType: TJenSubSystemType;out SubSystem: IJenSubSystem);
begin
  case SubSystemType of
    ssUtils     : SubSystem := IJenSubSystem(Utils);
    ssInput     : SubSystem := IJenSubSystem(Input);
    ssLog       : SubSystem := IJenSubSystem(Log);
    ssDisplay   : SubSystem := IJenSubSystem(Display);
    ssResMan    : SubSystem := IJenSubSystem(ResMan);
    ssRender    : SubSystem := IJenSubSystem(Render);
    ssRender2d  : SubSystem := IJenSubSystem(Render2d);
    ssHelpers   : SubSystem := IJenSubSystem(Helpers);
  else
    SubSystem := nil;
  end;

end;

procedure TJenEngine.CreateEvent(Event: TEvent; Param: LongInt);
var
  i : LongInt;
begin
  for i:=0 to FEventsList[Event].Count-1 do
    TEventProc(FEventsList[Event][i])(Param);
end;

procedure TJenEngine.AddEventProc(Event : TEvent; Proc: TEventProc);
begin
  FEventsList[Event].Add(@Proc);
end;

procedure TJenEngine.DelEventProc(Event: TEvent; Proc: TEventProc);
begin
  FEventsList[Event].Del(FEventsList[Event].IndexOf(@Proc));
end;

procedure TJenEngine.Finish;
begin
  FQuit := True;
end;

initialization
begin
  TJenEngine.FisRunnig := False;
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
  //Engine       := nil;
  Utils        := nil;
  Helpers      := nil;
  Log          := nil;
  Render       := nil;
  Render2d     := nil;
  Display      := nil;
  ResMan       := nil;
  Game         := nil;
end;

end.
