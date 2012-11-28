{%RunWorkingDir F:\Kot\Programming\Engines\MY\jen-engine\Bin\}
{%BuildWorkingDir F:\Kot\Programming\Engines\MY\jen-engine\Bin\}
unit JEN_Main;

interface

uses
  Windows,
  Messages,
  SysUtils,
  JEN_Header,
  JEN_Math,
  JEN_Helpers,
  JEN_Input,
  JEN_Console,
  JEN_Display,
  JEN_Render,
  JEN_Render2D,
  JEN_ResourceManager;

type
  TJenEngine = class(TInterfacedObject, IJenEngine)
    constructor Create(DebugMode : Boolean);
    destructor Destroy; override;
  private
    class var
      FDebugMode    : Boolean;
      FisRunnig     : Boolean;
      FQuit         : Boolean;

      FLogStream    : IStream;
      FDThread      : THandle;
      FConsole      : IConsole;
      FQuitEvent    : THandle;
      FJobEvent     : THandle;
      FJobDoneEvent : THandle;
      FLogMessage   : UnicodeString;
    var
      FEventsList : array[TEvent] of TList;
      FLastUpdate : LongInt;
  public
    procedure Start(Game: IGame); stdcall;
    procedure Finish; stdcall;

    procedure GetSubSystem(SubSystemType: TJenSubSystemType; out SubSystem: IJenSubSystem); stdcall;

    procedure AddEventListener(Event: TEvent; Proc: TEventListener); stdcall;
    procedure RemoveEventListener(Event: TEvent; Proc: TEventListener); stdcall;
    procedure DispatchEvent(Event: TEvent; Param: LongInt = 0; Data: Pointer = nil); stdcall;

    procedure InitLog;
    procedure DestroyLog;

    class procedure DThreadProc(lpParameter : Pointer); static; stdcall;
    class procedure AddMessage(MesType: TLogMsg; Text: PWideChar); static; stdcall;

    procedure LogHeader(Text: WideString);

    procedure Log(Text: PWideChar); overload; stdcall;
    procedure Log(Text: WideString); overload; stdcall;
    procedure Error(Text: PWideChar); overload; stdcall;
    procedure Error(Text: WideString); overload; stdcall;
    procedure Warning(Text: PWideChar); overload; stdcall;
    procedure Warning(Text: WideString); overload; stdcall;
    procedure CodeBlock(Text: PWideChar); overload; stdcall;
    procedure CodeBlock(Text: WideString); overload; stdcall;

    class property Quit: Boolean read FQuit write FQuit;
    class property DebugMode: Boolean read FDebugMode;
  end;

var
  Engine     : TJenEngine;
  Input      : IInput;
  Helpers    : IHelpers;
  Render     : IRender;
  Render2d   : IRender2D;
  Display    : IDisplay;
  ResMan     : IResourceManager;
  Game       : IGame;

function GetEngine(Debug: Boolean): JEN_Header.IJenEngine; stdcall;

implementation

function GetEngine(Debug: Boolean): JEN_Header.IJenEngine;
 begin
  if not Assigned(Engine) then
    TJenEngine.Create(Debug);
  Result := IJenEngine(Engine);
end;

constructor TJenEngine.Create;
var
  Event : TEvent;
begin
  Engine := Self;
  FisRunnig := False;
  FDebugMode := DebugMode;
  Helpers := THelpers.Create;

  for Event := Low(TEvent) to High(TEvent) do
    FEventsList[Event] := TList.Create;

  InitLog;

  try
    Input     := JEN_Input.TInput.Create;
    Render    := TRender.Create;
    Render2d  := TRender2D.Create;
    Display   := TDisplay.Create;
    ResMan    := TResourceManager.Create;
  except
    on E : Exception do
    begin

      Error('Exception in TJenEngine.Create unit ' + E.UnitName);
      Error(E.ClassName + ': ' + E.Message);

      Halt(0);
    end;
  end;
end;

destructor TJenEngine.Destroy;
var
  Event : TEvent;

  procedure TestRefCount(SubSystem: IUnknown; Name: UnicodeString);
  begin
    if not Assigned(SubSystem) then
    begin
      Engine.Error('OMG all reference to ' + Name + ' released');
      Exit;
    end;

    if(SubSystem._AddRef>3) then
      Engine.Error('Do not all reference to ' + Name + ' released');
    SubSystem._Release;
  end;

begin
  TestRefCount(Render2d, '2D render');
  Render2d.Free;
  Render2d := nil;

  TestRefCount(ResMan, 'resource manager');
  ResMan.Free;
  ResMan := nil;

  TestRefCount(Render, 'render');
  Render.Free;
  Render := nil;

  TestRefCount(Display, 'display');
  Display.Free;
  Display := nil;

  TestRefCount(Input, 'input');
  Input.Free;
  Input := nil;

  TestRefCount(Helpers, 'helpers');
  Helpers.Free;
  Helpers := nil;

  for Event:=Low(TEvent) to High(TEvent) do
    FEventsList[Event].Free;

  DestroyLog;

  inherited;
end;

procedure TJenEngine.Start(Game: IGame);
var
  DeltaTime : LongInt;
begin
  if not Assigned(Game) then
  begin
    Error('Game is not assigned');
    Exit;
  end;

  if(FisRunnig) then
  begin
    Error('Engine alredy running');
    Exit;
  end;

  if(not( Assigned(Display) and Display.Valid and
          Assigned(Render) and Render.Valid and
          Assigned(ResMan) and Assigned(Helpers) and
          Assigned(Render2d) ))then
  begin
    Error('Error in some subsustem');
    Exit;
  end;

  Log('Let''s rock!');

  FisRunnig := True;

  Game.LoadContent;
  Input.Init;
  FLastUpdate := Helpers.RealTime;
  DeltaTime   := 1;
  while not FQuit do
  begin
    Game.OnUpdate(DeltaTime);
    Render.Start;
    Game.OnRender;
    Render.Finish;

    Display.Swap;

    Input.Update;
    Display.Update;
    Helpers.Update;

    if (Helpers.RealTime - FLastUpdate) < 5 then
      Helpers.Sleep(5);
    DeltaTime := Max(Helpers.RealTime - FLastUpdate, 1);
    if DeltaTime > 200 then
      DeltaTime := 10;

    FLastUpdate := Helpers.RealTime;
  end;

  Game.Close;
  Game := nil;
end;

procedure TJenEngine.Finish;
begin
  FQuit := True;
end;

procedure TJenEngine.GetSubSystem(SubSystemType: TJenSubSystemType;out SubSystem: IJenSubSystem);
begin
  case SubSystemType of
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

procedure TJenEngine.DispatchEvent(Event: TEvent; Param: LongInt; Data: Pointer);
var
  i : LongInt;
begin
  for i:=0 to FEventsList[Event].Count-1 do
    TEventListener(FEventsList[Event][i])(Param, Data);
end;

procedure TJenEngine.AddEventListener(Event : TEvent; Proc: TEventListener);
begin
  FEventsList[Event].Add(@Proc);
end;

procedure TJenEngine.RemoveEventListener(Event: TEvent; Proc: TEventListener);
begin
  FEventsList[Event].Del(FEventsList[Event].IndexOf(@Proc));
end;

procedure TJenEngine.InitLog;
var
  lpThreadId : DWORD;
  i     : LongInt;
  Str   : UnicodeString;
  Major : LongInt;
  Minor : LongInt;
  Build : LongInt;
begin
  FQuitEvent    := CreateEvent(nil, True, False, '');
  FJobEvent     := CreateEvent(nil, True, False, '');
  FJobDoneEvent := CreateEvent(nil, True, False, '');
  FDThread      := BeginThread(nil, 0, {$IFDEF FPC}Pointer(DThreadProc){$ELSE}@DThreadProc{$ENDIF}, nil, 0, lpThreadId);
  WaitForSingleObject(FJobDoneEvent, INFINITE);

  Helpers.SystemInfo.WindowsVersion(Major, Minor, Build);
  SetLength(Str, 80);
  Str := StringOfChar('*', 80);

  LogHeader(Str);
  LogHeader('JenEngine');
  LogHeader('Windows version: '+IntToStr(Major)+'.'+IntToStr(Minor)+' (Build '+IntToStr(Build)+')');
  LogHeader('CPU            : '+Helpers.SystemInfo.CPUName+'(~'+IntToStr(Helpers.SystemInfo.CPUSpeed)+')x');
  LogHeader('RAM Total      : '+IntToStr(Helpers.SystemInfo.RAMTotal)+'Mb');
  LogHeader('RAM Available  : '+IntToStr(Helpers.SystemInfo.RAMFree)+'Mb');
  with Helpers.SystemInfo do
  for i := 0 to GPUList.Count - 1 do
    with PGPUInfo(GPUList[i])^ do
    begin
      LogHeader('GPU' + IntToStr(i) +'           : ' + Description);
      LogHeader('Chip           : ' + ChipType);
      LogHeader('MemorySize     : ' + IntToStr(MemorySize)+'Mb');
      LogHeader('DriverVersion  : ' + DriverVersion + '(' + DriverDate + ')');
    end;
  LogHeader(Str);
  Engine.AddEventListener(evLogMsg, {$IFDEF FPC}Pointer(AddMessage){$ELSE}@AddMessage{$ENDIF});
end;

procedure TJenEngine.DestroyLog;
begin
  WaitForSingleObject(FJobDoneEvent, 2000);
  SetEvent(FQuitEvent);
  if Assigned(FConsole) then
    PostMessage(FConsole.Handle, WM_NULL, 0, 0);
  WaitForSingleObject(FDThread, INFINITE);
  CloseHandle(FQuitEvent);
  CloseHandle(FDThread);
  CloseHandle(FJobEvent);
  CloseHandle(FJobDoneEvent);
end;

class procedure TJenEngine.DThreadProc(lpParameter : Pointer);
var
  Console : Boolean;
  Events  : array[0..1] of THandle;
  Msg     : TMsg;
  Str     : UnicodeString;
begin
  Helpers.CreateStream(FLogStream, 'Log.txt');
  Str := #65279;
  FLogStream.Write(Str[1], 2);

  Console := Debugmode;
  {$IFDEF Debug}Console := true;{$ENDIF}

  if Console then
  begin
    FConsole := TConsole.Create;
    if not FConsole.InitWindow then
    begin
      Str := 'Error while init console';
      FLogStream.Write(Str[1], Length(Str)*SizeOf(WideChar));
      FConsole := nil;
    end;
  end;

  Events[0] := FQuitEvent;
  Events[1] := FJobEvent;
  SetEvent(FJobDoneEvent);

  while (Assigned(FConsole) = False) or (GetMessage(Msg, 0, 0, 0)) do
  begin
    if Assigned(FConsole) then
    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;

    case WaitForMultipleObjects(2, @Events[0], False, LongWord(ord(not Assigned(FConsole))*INFINITE) ) of
      WAIT_OBJECT_0+1:
        begin
          if(Assigned(FConsole)) then
            FConsole.AddMessage(PWideChar(FLogMessage));

          FLogMessage := FLogMessage + sLineBreak;
          FLogStream.Write(FLogMessage[1], Length(FLogMessage)*SizeOf(WideChar));

          ResetEvent(FJobEvent);
          SetEvent(FJobDoneEvent);
        end;
      WAIT_OBJECT_0: Break;
    end;
  end;

  if Assigned(FConsole) then
  begin
    Sleep(2500);
    FConsole := nil;
  end;

  Str := '';
  EndThread(0);
end;

class procedure TJenEngine.AddMessage(MesType: TLogMsg; Text: PWideChar);
begin
  WaitForSingleObject(FJobDoneEvent, INFINITE);
  ResetEvent(FJobDoneEvent);

  FLogMessage := IntToStr(random(100));
  FLogMessage := UnicodeString(Text); //Copy?
  SetEvent(FJobEvent);

  if Assigned(FConsole) then
    PostMessage(FConsole.Handle, WM_NULL, 0, 0);
end;

procedure TJenEngine.LogHeader(Text: WideString);
begin
  AddMessage(lmHeaderMsg, PWideChar(Text));
end;

procedure TJenEngine.Log(Text: PWideChar);
begin
  AddMessage(lmNotify, Text);
end;

procedure TJenEngine.Log(Text: WideString);
begin
  AddMessage(lmNotify, PWideChar(Text));
end;

procedure TJenEngine.Error(Text: PWideChar);
begin
  AddMessage(lmError, Text);
end;

procedure TJenEngine.Error(Text: WideString);
begin
  AddMessage(lmError, PWideChar(Text));
end;

procedure TJenEngine.Warning(Text: PWideChar);
begin
  AddMessage(lmWarning, Text);
end;

procedure TJenEngine.Warning(Text: WideString);
begin
  AddMessage(lmWarning, PWideChar(Text));
end;

procedure TJenEngine.CodeBlock(Text: PWideChar);
begin
  AddMessage(lmCode, Text);
end;

procedure TJenEngine.CodeBlock(Text: WideString);
begin
  AddMessage(lmCode, PWideChar(Text));
end;

initialization

finalization
begin
  Engine       := nil;
  Helpers      := nil;
  Render       := nil;
  Render2d     := nil;
  Display      := nil;
  ResMan       := nil;
  Game         := nil;
end;

end.
