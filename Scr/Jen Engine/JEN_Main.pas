unit JEN_Main;

interface

uses
  Windows,
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

type
  TJenEngine = class(TInterfacedObject, IJenEngine)
    constructor Create(FileLog: Boolean; Debug : Boolean);
    destructor Destroy; override;
  private
    class var
      FisRunnig : Boolean;
      FQuit : Boolean;
    var
      FEventsList : array[TEvent] of TList;
      FLastUpdate : LongInt;
      FConsoleLog : TConsole;
      FFileLog    : TFileLog;
  public
    procedure Start(Game: IGame); stdcall;
    procedure GetSubSystem(SubSystemType: TJenSubSystemType; out SubSystem: IJenSubSystem); stdcall;
    procedure CreateEvent(Event: TEvent; Param: LongInt = 0; Data: Pointer = nil);
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
  Render     : IRender;
  Render2d   : IRender2D;
  Display    : IDisplay;
  ResMan     : IResourceManager;
  Game       : IGame;

  var
   TDC : HDC;
   PFD :  TPixelFormatDescriptor;
   pixelFormat  : Integer;

procedure LogOut(const Text: string; MType: TLogMsg);
function GetEngine(FileLog, Debug: Boolean): JEN_Header.IJenEngine; stdcall;

implementation

procedure LogOut(const Text: string; MType: TLogMsg);
begin
  Engine.CreateEvent(evLogMsg, Ord(MType), PWideChar(Text));
end;

function GetEngine(FileLog, Debug: Boolean): JEN_Header.IJenEngine;
begin
  if not Assigned(Engine) then
    TJenEngine.Create(FileLog, Debug);
  Result := IJenEngine(Engine);
end;

constructor TJenEngine.Create;
var
  Event : TEvent;
begin
  FisRunnig := False;
  Engine := Self;

  for Event := Low(TEvent) to High(TEvent) do
    FEventsList[Event] := TList.Create;

  Utils   := TUtils.Create;
  Helpers := THelpers.Create;
  Input   := JEN_Input.TInput.Create;

  if FileLog then
    FFileLog := TFileLog.Create('log.txt');
  {$IFDEF DEBUG}
    FConsoleLog := TConsole.Create;
  {$ELSE}
  if Debug then
    FConsoleLog := TConsole.Create;
  {$ENDIF}

  Render    := TRender.Create;
  Render2d  := TRender2D.Create;
  Display   := TDisplay.Create;
  ResMan    := TResourceManager.Create;
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
  ResMan.Free;
  ResMan := nil;

  TestRefCount(Render2d, '2D render');
  Render2d.Free;
  Render2d := nil;

  TestRefCount(Render, 'render');
  Render.Free;
  Render := nil;

  TestRefCount(Display, 'display');
  Display.Free;
  Display := nil;

  if Assigned(FFileLog) then
    FFileLog.Free;

  if Assigned(FConsoleLog) then
    FConsoleLog.Free;

  TestRefCount(Helpers, 'helpers');
  Helpers.Free;
  Helpers := nil;

  TestRefCount(Input, 'input');
  Input.Free;
  Input := nil;

  TestRefCount(Utils, 'utils');
  Utils.Free;
  Utils := nil;
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
    Input.Update;
    Display.Update;

    Utils.FreezeTime := True;
    Game.OnUpdate(DeltaTime);
    Utils.FreezeTime := True;
    Render.Start;
    Game.OnRender;
    Utils.FreezeTime := False;
    Render.Finish;

    Display.Swap;

    if (Utils.Time - FLastUpdate)< 5 then
      Utils.Sleep(5);
    DeltaTime := Max(Utils.Time - FLastUpdate, 1);

    FLastUpdate := Utils.Time;
  end;

  Game.Close;
  Game := nil;
end;

procedure TJenEngine.GetSubSystem(SubSystemType: TJenSubSystemType;out SubSystem: IJenSubSystem);
begin
  case SubSystemType of
    ssUtils     : SubSystem := IJenSubSystem(Utils);
    ssInput     : SubSystem := IJenSubSystem(Input);
    ssDisplay   : SubSystem := IJenSubSystem(Display);
    ssResMan    : SubSystem := IJenSubSystem(ResMan);
    ssRender    : SubSystem := IJenSubSystem(Render);
    ssRender2d  : SubSystem := IJenSubSystem(Render2d);
    ssHelpers   : SubSystem := IJenSubSystem(Helpers);
  else
    SubSystem := nil;
  end;
end;

procedure TJenEngine.CreateEvent(Event: TEvent; Param: LongInt; Data: Pointer);
var
  i : LongInt;
begin
  for i:=0 to FEventsList[Event].Count-1 do
    TEventProc(FEventsList[Event][i])(Param, Data);
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

finalization
begin
  //Engine       := nil;
  Utils        := nil;
  Helpers      := nil;
  Render       := nil;
  Render2d     := nil;
  Display      := nil;
  ResMan       := nil;
  Game         := nil;
end;

end.
