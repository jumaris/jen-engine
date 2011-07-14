unit JEN_Display;

interface

uses
  Windows,
  Messages,
  JEN_Header;

const
  WINDOW_CLASS_NAME = 'JEngineWindowClass';

type
  IDisplay = interface(JEN_Header.IDisplay)
    function GetValid : Boolean;

    procedure Resize(W, H: LongWord);
    procedure Restore;
    procedure Update;

    property Valid: Boolean read GetValid;
  end;

  TDisplay = class(TInterfacedObject, IDisplay)
    destructor Destroy; override;
  private
    FValid      : Boolean;
    FFPS        : LongInt;
    FFPSTime    : LongInt;
    FFPSCount   : LongInt;
    FCaption    : String;
    FHandle     : HWND;
    FDC         : HDC;
    FWidth      : LongWord;
    FHeight     : LongWord;
    FRefresh    : Byte;
    FFullScreen : Boolean;
    FActive     : Boolean;
    FCursor     : Boolean;

    procedure SetActive(Value: Boolean); stdcall;
    procedure SetCaption(const Value: string); stdcall;
    procedure SetFullScreen(Value: Boolean); stdcall;

    function GetValid : Boolean;
    function GetFullScreen: Boolean; stdcall;
    function GetActive: Boolean; stdcall;
    function GetCursorState: Boolean; stdcall;
    function GetWndDC: HDC; stdcall;
    function GetWndHandle: HWND; stdcall;
    function GetWidth: LongWord; stdcall;
    function GetHeight: LongWord; stdcall;
    function GetFPS: LongWord; stdcall;

    class function WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall; static;
   public
    function Init(Width: LongWord; Height: LongWord; Refresh: Byte; FullScreen: Boolean): Boolean; stdcall;

    procedure Swap; stdcall;
    procedure ShowCursor(Value: Boolean); stdcall;

    procedure Resize(W, H: LongWord);
    procedure Restore;
    procedure Update;
  end;

implementation

uses
  JEN_MAIN,
  JEN_MATH;

class function TDisplay.WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall;
begin
// Assert(expr : Boolean [; const msg: string]
//  LogOut('message');
  Result := 0;

  case Msg of
    WM_CLOSE:
      TJenEngine.Quit := True;

   WM_ACTIVATE:
      begin
        Engine.CreateEvent(evActivate, Word(wParam));
        Display.Active := LOWORD(wParam) <> WA_INACTIVE;

        if Display.FullScreen then
          if Display.Active then
            ShowWindow(hWnd, SW_SHOW)
          else
            ShowWindow(hWnd, SW_MINIMIZE);
      end;

    WM_SETCURSOR:
      begin
        if (Display.Active) and (Word(lparam) = 1) and (not Display.Cursor) Then
          SetCursor(0)
        else
          SetCursor(LoadCursor(0, PWideChar(32512)));
      end;

  //  WM_MOVE, WM_SIZE :;
     { GetWindowRect(hWnd, CDisplay.FRect);
         }

    WM_SYSKEYUP, WM_KEYUP:
      Engine.CreateEvent(evKeyUp, WParam);

    WM_SYSKEYDOWN, WM_KEYDOWN:
    begin
      Engine.CreateEvent(evKeyDown, WParam);
      if (Msg = WM_SYSKEYDOWN) and (Wparam = LongInt(ikF4)) Then
        TJenEngine.Quit := True;
    end;

  // Mouse
    WM_LBUTTONUP:
      Engine.CreateEvent(evKeyUp, LongInt(ikMouseL));

    WM_RBUTTONUP:
      Engine.CreateEvent(evKeyUp, LongInt(ikMouseR));

    WM_MBUTTONUP:
      Engine.CreateEvent(evKeyUp, LongInt(ikMouseM));


    WM_LBUTTONDOWN:
      Engine.CreateEvent(evKeyDown, LongInt(ikMouseL));

    WM_RBUTTONDOWN:
      Engine.CreateEvent(evKeyDown, LongInt(ikMouseR));

    WM_MBUTTONDOWN:
      Engine.CreateEvent(evKeyDown, LongInt(ikMouseM));

    WM_MOUSEWHEEL  :;{
      begin
        with CMouse.FDelta do
          Inc(Wheel, SmallInt(wParam  shr 16) div 120);
        if SmallInt(wParam shr 16) > 0 then CInput.Down[KM_WHUP] := True;
        if SmallInt(wParam shr 16) < 0 then CInput.Down[KM_WHDN] := True;
      end     }
  else
    Result := DefWindowProc(hWnd, Msg, wParam, lParam);
  end;

end;

function TDisplay.Init(Width: LongWord; Height: LongWord; Refresh: Byte; FullScreen: Boolean): Boolean;
var
  WinClass: TWndClassEx;
begin
  if (Width = Helpers.SystemInfo.Screen.Width) and (Height = Helpers.SystemInfo.Screen.Height) then
    FullScreen := True;

  Result := False;

  FCaption    := 'JEN Engine application';
  FWidth      := Width;
  FHeight     := Height;
  FRefresh    := Refresh;
  FFullScreen := FullScreen;
  FValid      := False;
  FActive     := True;
  FCursor     := True;

  if FullScreen then
    case Helpers.SystemInfo.Screen.SetMode(Width, Height, Refresh) of
      SM_SetDefault:
        begin
          FWidth   := Helpers.SystemInfo.Screen.Width;
          FHeight  := Helpers.SystemInfo.Screen.Height;
          FRefresh := Helpers.SystemInfo.Screen.Refresh;
        end;
      SM_Error: Exit;
    end;

  FillChar(WinClass, SizeOf(TWndClassEx), 0);
  with WinClass do
  begin
    cbsize        := SizeOf(TWndClassEx);
 	  style         := CS_DBLCLKS or CS_OWNDC or CS_HREDRAW or CS_VREDRAW;
	  lpfnWndProc   := @TDisplay.WndProc;
	  //hCursor		    := LoadCursor(NULL, IDC_ARROW);
    hbrBackground	:= GetStockObject(BLACK_BRUSH);
	  lpszClassName	:= WINDOW_CLASS_NAME;
  end;

  if RegisterClassEx(WinClass) = 0 Then
  begin
    LogOut('Cannot register window class.', lmError);
    Exit;
  end else
    LogOut('Register window class.', lmNotify);

  FHandle := CreateWindowEx(WS_EX_APPWINDOW, WINDOW_CLASS_NAME, @FCaption[1], WS_SYSMENU or WS_VISIBLE, 0, 0,
                             0, 0, 0, 0, 0, nil);

  if FHandle = 0 Then
    begin
      LogOut('Cannot create window.', lmError);
      Exit;
    end else
      LogOut('Create window.', lmNotify);

  SendMessage(FHandle, WM_SETICON, 1, LoadIconW(HInstance, 'MAINICON'));
  FDC := GetDC(FHandle);
  FValid := True;
  Result := True;
  Restore;
end;

destructor TDisplay.Destroy;
begin
  if not FValid then Exit;

  if ReleaseDC(FHandle, FDC) = 0 Then
    LogOut('Cannot release device context.', lmError)
  else
    LogOut('Release device context.', lmNotify);

  if(FHandle <> 0) and (not DestroyWindow(FHandle)) Then
  begin
    LogOut('Cannot destroy window.', lmError);
    FHandle := 0;
  end else
    LogOut('Destroy window.', lmNotify);

  if not UnRegisterClass(WINDOW_CLASS_NAME, 0) Then
    LogOut('Cannot unregister window class.', lmError)
  else
    LogOut('Unregister window class.', lmNotify);

  if FFullScreen then
    Helpers.SystemInfo.Screen.ResetMode;

  inherited;
end;

procedure TDisplay.Swap;
begin
  SwapBuffers(FDC);

  Inc(FFPSCount);
  if Utils.Time - FFPSTime >= 1000 then
  begin
    FFPS      := FFPSCount;
    FFPSCount := 0;
    FFPSTime  := Utils.Time;
  end;
end;

procedure TDisplay.SetFullScreen(Value: Boolean);
begin
  if (FFullScreen <> Value) then
  begin
    FFullScreen := Value;

    if Value then
      FValid := FValid and (Helpers.SystemInfo.Screen.SetMode(FWidth, FHeight, FRefresh) <> SM_Error)
    else
      Helpers.SystemInfo.Screen.ResetMode;

    Restore;
  end;
end;

procedure TDisplay.SetActive(Value: Boolean);
begin
  if (FActive <> Value) then
  begin
    FActive := Value;

    if FFullScreen then
    begin
      if Value then
        FValid := FValid and (Helpers.SystemInfo.Screen.SetMode(FWidth, FHeight, FRefresh) <> SM_Error)
      else
        Helpers.SystemInfo.Screen.ResetMode;
      Restore;
    end;

  end;
end;

procedure TDisplay.SetCaption(const Value: String);
begin
  FCaption := Value;
  SetWindowText(FHandle, PWideChar(Value));
end;

procedure TDisplay.Restore;
var
  Style : LongWord;
  Rect  : TRecti;
begin
  FFPSTime  := Utils.Time;
  FFPSCount := 0;

  Rect := Recti((Helpers.SystemInfo.Screen.Width - FWidth) div 2, (Helpers.SystemInfo.Screen.Height - FHeight) div 2, FWidth, FHeight);

  if FFullScreen then
  begin
    Rect.Location := ZeroPoint;
    Style := WS_POPUP
  end else
  begin
    Style := WS_CAPTION or WS_MINIMIZEBOX;
    Rect.Inflate(GetSystemMetrics(SM_CXDLGFRAME), GetSystemMetrics(SM_CYDLGFRAME) + GetSystemMetrics(SM_CYCAPTION) div 2);
  end;

  SetWindowLongA(FHandle, GWL_STYLE, Style or WS_SYSMENU);
  SetWindowPos(FHandle, 0, Rect.x, Rect.y, Rect.Width, Rect.Height, $220);

  ShowWindow(FHandle, SW_SHOWNORMAL);

  Update;
  //Render.Viewport := Recti(0, 0, FWidth, FHeight);
end;

procedure TDisplay.Update;
var
  Msg : TMsg;
begin
  while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;

procedure TDisplay.Resize(W, H: LongWord);
begin
  FWidth  := W;
  FHeight := H;
  if FFullScreen and FActive then
    Helpers.SystemInfo.Screen.SetMode(FWidth, FHeight, FRefresh);
  Restore;
end;

procedure TDisplay.ShowCursor(Value: Boolean);
begin
  FCursor := Value;
end;

function TDisplay.GetValid : Boolean;
begin
  Result := FValid;
end;

function TDisplay.GetFullScreen: Boolean;
begin
  Result := FFullScreen;
end;

function TDisplay.GetActive: Boolean;
begin
  Result := FActive;
end;

function TDisplay.GetCursorState: Boolean;
begin
  Result := FCursor;
end;

function TDisplay.GetWndDC: HDC;
begin
  Result := FDC;
end;

function TDisplay.GetWndHandle: HWND;
begin
  Result := FHandle;
end;

function TDisplay.GetWidth: LongWord;
begin
  Result := FWidth;
end;

function TDisplay.GetHeight: LongWord;
begin
  Result := FHeight;
end;

function TDisplay.GetFPS: LongWord;
begin
  Result := FFPS;
end;

end.
