unit JEN_Console;

interface

uses
  SysUtils,
  Windows,
  Messages,
  JEN_Utils,
  JEN_Math,
  JEN_Header;

const
  CONSOLE_WINDOW_CLASS_NAME = 'JENConsoleWnd';

type TConsole = class(TManagedInterface, ILogOutput)
  constructor Create;
  destructor Destroy; override;
  private
    LastUpdate : LongInt;
    Thread     : THandle;
    class var FHandle : HWND;
    class var QuitEvent : THandle;
    class function CreateWindow(lpParameter : Pointer) : DWord; static; stdcall;
    class function WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall; static;
  public
    procedure Init; stdcall;
    procedure AddMsg(const Text: String; MType: TLogMsg); stdcall;
  end;

implementation

uses
  JEN_MAIN;

constructor TConsole.Create;
var
  lpThreadId : DWORD;
begin           {
  FCaption    := 'JEN Engine application';
  FWidth      := Width;
  FHeight     := Height;
  FRefresh    := Refresh;
  FFullScreen := FullScreen;
  FValid      := False;
  FActive     := True;
  FCursor     := True;
                       }
  QuitEvent := CreateEvent(nil, true, false, '');
  Thread := CreateThread(nil, 0, @TConsole.CreateWindow, nil, 0, lpThreadId);

end;

destructor TConsole.Destroy;
var
  str : String;
begin
  SetEvent(QuitEvent);
  WaitForSingleObject(Thread, INFINITE);
  CloseHandle(QuitEvent);
  CloseHandle(Thread);
  inherited;
end;

class function TConsole.CreateWindow(lpParameter : Pointer): DWord;
var
  WinClass   : TWndClassEx;
  Rect       : TRecti;
  Msg        : TMsg;
  i : integer;
  str : String;
begin
  FillChar(WinClass, SizeOf(TWndClassEx), 0);
  with WinClass do
  begin
    cbsize        := SizeOf(TWndClassEx);
 	  style         := CS_DBLCLKS or CS_OWNDC or CS_HREDRAW or CS_VREDRAW;
	  lpfnWndProc   := @TConsole.WndProc;
	  //hCursor		    := LoadCursor(NULL, IDC_ARROW);
    hbrBackground	:= GetStockObject(BLACK_BRUSH);
	  lpszClassName	:= CONSOLE_WINDOW_CLASS_NAME;
  end;

  if RegisterClassEx(WinClass) = 0 Then
  begin
    LogOut('Cannot register cosole window class.', lmError);
    Exit;
  end;

  Rect := SystemParams.Screen.DesktopRect;
  FHandle := CreateWindowEx(0, CONSOLE_WINDOW_CLASS_NAME, 'JEN Console',
  							            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_SIZEBOX or WS_VISIBLE,
                            0, Rect.y + Rect.Height - 100 - GetSystemMetrics(SM_CYDLGFRAME), 100, 100, 0, 0, 0, nil);

  if FHandle = 0 Then
    begin
      LogOut('Cannot create window.', lmError);
      Exit;
    end;

  SendMessage(FHandle, WM_SETICON, 1, LoadIconW(HInstance, 'MAINICON'));

  while WaitForSingleObject(QuitEvent,22) = WAIT_TIMEOUT do
  while PeekMessage(Msg, 0, 0, 0, PM_REMOVE)  do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

  if(FHandle <> 0) and (not DestroyWindow(FHandle)) Then
  begin
    LogOut('Cannot destroy console window.', lmError);
    FHandle := 0;
  end;

  if not UnRegisterClass(CONSOLE_WINDOW_CLASS_NAME, HInstance) Then
    LogOut('Cannot unregister console window class.', lmError);
end;


class function TConsole.WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall;
begin

  case Msg of
    WM_CLOSE: SetEvent(QuitEvent);
  else
    Result := DefWindowProc(hWnd, Msg, wParam, lParam);
  end;
end;

procedure TConsole.Init;
var
  S : AnsiString;
  Major : LongInt;
  Minor : LongInt;
  Build : LongInt;
begin

     {
  SystemParams.WindowsVersion(Major, Minor, Build);
  SetLength(S,80);
  FillChar(S[1],80,ord('*'));
  Write(s);
  Writeln('JenEngine');
  Writeln('Windows version: '+Utils.IntToStr(Major)+'.'+Utils.IntToStr(Minor)+' (Buid '+Utils.IntToStr(Build)+')');
  Writeln('CPU            : '+SystemParams.CPUName+'(~'+Utils.IntToStr(SystemParams.CPUSpeed)+')x'+Utils.IntToStr(SystemParams.CPUCount));
  Writeln('RAM Available  : '+Utils.IntToStr(SystemParams.RAMFree)+'Mb');
  Writeln('RAM Total      : '+Utils.IntToStr(SystemParams.RAMTotal)+'Mb');
  Write(s);
  LastUpdate := Utils.Time;    }
end;

procedure TConsole.AddMsg(const Text: String; MType: TLogMsg);
var
  str : String;
  tstr : String;
  h,m,s,start,i,j : LongInt;
begin

end;

end.
