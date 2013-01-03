unit JEN_Display;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Windows,
  Messages,
  JEN_Header;

const
  WINDOW_CLASS_NAME = 'JEngineWindowClass';

type
  TWndProc = function(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall;
  IDisplay = interface(JEN_Header.IDisplay)
    function GetValid : Boolean;
    function GetCustom : Boolean;

    procedure Restore;
    procedure Update;

    property Valid: Boolean read GetValid;
    property Custom: Boolean read GetCustom;
  end;

  TDisplay = class(TInterfacedObject, IDisplay)
    procedure Free; stdcall;
  private
    FValid        : Boolean;
    FCustomHandle : Boolean;
    FCaption      : UnicodeString;
    FHandle       : HWND;
    FDC           : HDC;
    FWidth        : LongInt;
    FHeight       : LongInt;
    FRefresh      : Byte;
    FFullScreen   : Boolean;
    FActive       : Boolean;
    FCursor       : Boolean;

    procedure SetActive(Value: Boolean); stdcall;
    procedure SetCaption(Value: PWideChar); stdcall;
    procedure SetFullScreen(Value: Boolean); stdcall;

    function GetValid: Boolean;
    function GetCustom: Boolean;
    function GetFullScreen: Boolean; stdcall;
    function GetActive: Boolean; stdcall;
    function GetCursorState: Boolean; stdcall;
    function GetWndDC: HDC; stdcall;
    function GetWndHandle: HWND; stdcall;
    function GetWidth: LongInt; stdcall;
    function GetHeight: LongInt; stdcall;

    class function WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall; static;
   public
    function Init(Width: LongWord; Height: LongWord; Refresh: Byte; FullScreen: Boolean): Boolean; overload; stdcall;
    function Init(Handle: HWND): Boolean; overload; stdcall;

    procedure Swap; stdcall;
    procedure ShowCursor(Value: Boolean); stdcall;

    procedure Resize(Width, Height: LongWord); stdcall;
    procedure Restore;
    procedure Update;
  end;

implementation

uses
  JEN_MAIN,
  JEN_MATH;

class function TDisplay.WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall;
var
  Rect : TRect;
begin
  Result := 0;

  case Msg of
   WM_CLOSE:
     TJenEngine.Quit := True;

   WM_ACTIVATE:
      begin
        Engine.DispatchEvent(evActivate, Word(wParam));
        Display.Active := LOWORD(wParam) <> WA_INACTIVE;

        if Display.FullScreen then
          if Display.Active then
            ShowWindow(hWnd, SW_SHOW)
          else
            ShowWindow(hWnd, SW_MINIMIZE);
      end;

    WM_ENTERSIZEMOVE:
      Helpers.FreezeTime := True;

    WM_EXITSIZEMOVE:
      Helpers.FreezeTime := False;

    WM_SETCURSOR:
      begin
        if (Display.Active) and (Word(lparam) = 1) and (not Display.Cursor) Then
          SetCursor(0)
        else
          SetCursor(LoadCursor(0, PWideChar(32512)));
      end;

    WM_MOVE, WM_SIZE :
    begin
      if not Display.FullScreen then
      begin
        GetClientRect(Display.Handle, Rect);
        Display.Resize(Rect.Right - Rect.Left, Rect.Bottom - Rect.Top);
      end;
    end;

    WM_SYSKEYUP, WM_KEYUP:
      Engine.DispatchEvent(evKeyUp, WParam);

    WM_SYSKEYDOWN, WM_KEYDOWN:
    begin
      Engine.DispatchEvent(evKeyDown, WParam);
      if (Msg = WM_SYSKEYDOWN) and (Wparam = LongInt(ikF4)) Then
        TJenEngine.Quit := True;
    end;

  // Mouse
    WM_LBUTTONUP:
      Engine.DispatchEvent(evKeyUp, LongInt(ikMouseL));

    WM_RBUTTONUP:
      Engine.DispatchEvent(evKeyUp, LongInt(ikMouseR));

    WM_MBUTTONUP:
      Engine.DispatchEvent(evKeyUp, LongInt(ikMouseM));

    WM_LBUTTONDOWN:
      Engine.DispatchEvent(evKeyDown, LongInt(ikMouseL));

    WM_RBUTTONDOWN:
      Engine.DispatchEvent(evKeyDown, LongInt(ikMouseR));

    WM_MBUTTONDOWN:
      Engine.DispatchEvent(evKeyDown, LongInt(ikMouseM));

    WM_MOUSEWHEEL:
      Engine.DispatchEvent(evMouseWhell, LongInt(SmallInt(wParam shr 16) div 120));

  else
    if Display.Custom then
      Result := TWndProc(GetWindowLongW(Hwnd, GWL_USERDATA))(Hwnd, Msg, LongWord(wParam), LParam)
    else
      Result := DefWindowProc(hWnd, Msg, LongWord(wParam), lParam);
  end;

end;

function TDisplay.Init(Width: LongWord; Height: LongWord; Refresh: Byte; FullScreen: Boolean): Boolean;
var
  WinClass: TWndClassEx;
begin
  if (Width = Helpers.SystemInfo.Screen.Width) and (Height = Helpers.SystemInfo.Screen.Height) then
    FullScreen := True;

  Result := False;

  FCustomHandle := False;
  FWidth      := Width;
  FHeight     := Height;
  FRefresh    := Refresh;
  FFullScreen := FullScreen;
  FValid      := False;
  FActive     := True;
  FCursor     := True;

  if FullScreen then
    if Helpers.SystemInfo.Screen.SetMode(Width, Height, Refresh) then
    begin
      FWidth   := Helpers.SystemInfo.Screen.Width;
      FHeight  := Helpers.SystemInfo.Screen.Height;
      FRefresh := Helpers.SystemInfo.Screen.Refresh;
    end else
      Exit;

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

  Engine.Log('Register window class.');
  if RegisterClassEx(WinClass) = 0 Then
  begin
    Engine.Error('Cannot register window class.');
    Exit;
  end;

  FHandle := CreateWindowEx(WS_EX_APPWINDOW, WINDOW_CLASS_NAME, '', WS_SYSMENU, 0, 0, 0, 0, 0, 0, 0, nil);
  SetCaption('JEN Engine application');

  Engine.Log('Create window.');
  if FHandle = 0 Then
    begin
      Engine.Error('Cannot create window.');
      Exit;
    end;

  SendMessage(FHandle, WM_SETICON, 1, LPARAM(LoadIconW(HInstance, 'MAINICON')));
  FDC := GetDC(FHandle);
  FValid := True;
  Result := True;
  Restore;
end;

function TDisplay.Init(Handle: HWND): Boolean;
var
  Rect : TRect;
begin
  Result      := True;
  FCustomHandle := True;
  FHandle       := Handle;
  SetCaption('JEN Engine application');
  GetClientRect(FHandle, Rect);
  FWidth      := Rect.Right - Rect.Left;
  FHeight     := Rect.Bottom - Rect.Top;
  FValid      := True;
  FActive     := True;
  FCursor     := True;

  SendMessage(FHandle, WM_SETICON, 1, LPARAM(LoadIconW(HInstance, 'MAINICON')));
  SetWindowLongW(FHandle, GWL_USERDATA, SetWindowLongW(FHandle, GWL_WNDPROC, LongInt({$IFDEF FPC}Pointer(WndProc){$ELSE}@WndProc{$ENDIF})));
  SetFocus(FHandle);
  FDC := GetDC(FHandle);
  Restore;
end;

procedure TDisplay.Free;
begin
  if not FValid then Exit;

  if ReleaseDC(FHandle, FDC) = 0 Then
    Engine.Error('Cannot release device context.')
  else
    Engine.Log('Release device context.');

  if not FCustomHandle then
  begin
    if(FHandle <> 0) and (not DestroyWindow(FHandle)) Then
    begin
      Engine.Error('Cannot destroy window.');
      FHandle := 0;
    end else
      Engine.Log('Destroy window.');

    if not UnRegisterClass(WINDOW_CLASS_NAME, 0) Then
      Engine.Error('Cannot unregister window class.')
    else
      Engine.Log('Unregister window class.');

    if FFullScreen then
      Helpers.SystemInfo.Screen.ResetMode;
  end else
    SetWindowLongW(FHandle, GWL_WNDPROC, GetWindowLongW(FHandle, GWL_USERDATA));

end;

procedure TDisplay.Swap;
begin
  SwapBuffers(FDC);
end;

procedure TDisplay.SetFullScreen(Value: Boolean);
begin
  if (FFullScreen <> Value) and (FCustomHandle = False) then
  begin
    FFullScreen := Value;

    if Value then
      FValid := FValid and Helpers.SystemInfo.Screen.SetMode(FWidth, FHeight, FRefresh)
    else
      Helpers.SystemInfo.Screen.ResetMode;

    Restore;
  end;
end;

procedure TDisplay.SetActive(Value: Boolean);
begin
  if (FActive <> Value) and (FCustomHandle = False) then
  begin
    FActive := Value;

    if FFullScreen then
    begin
      if Value then
        FValid := FValid and Helpers.SystemInfo.Screen.SetMode(FWidth, FHeight, FRefresh)
      else
        Helpers.SystemInfo.Screen.ResetMode;
      Restore;
    end;

  end;
end;

procedure TDisplay.SetCaption(Value: PWideChar);
begin
  FCaption := Copy(Value, 1, Length(Value));
  SetWindowTextW(FHandle, PWideChar(FCaption));
end;

procedure TDisplay.Restore;
var
  Style : LongWord;
  Rect  : TRecti;
begin
  if not FCustomHandle then
  begin

    if FFullScreen then
    begin
      Rect.Location := ZeroPoint;
      Style := WS_POPUP;
      Rect := Recti(0, 0, FWidth, FHeight);
    end else
    begin
      Style := WS_CAPTION or WS_MINIMIZEBOX;
      with Helpers.SystemInfo do
        Rect := Recti(Max((Screen.Width - FWidth) div 2, Screen.DesktopRect.Location.x), Max((Helpers.SystemInfo.Screen.Height - FHeight) div 2, Screen.DesktopRect.Location.y), FWidth, FHeight);
      Rect.Inflate(GetSystemMetrics(SM_CXDLGFRAME), GetSystemMetrics(SM_CYDLGFRAME) + GetSystemMetrics(SM_CYCAPTION) div 2);
    end;

    SetWindowPos(FHandle, 0, Rect.Location.x, Rect.Location.y, Rect.Width, Rect.Height, $220);
    ShowWindow(FHandle, SW_SHOWNORMAL);
    SetWindowLongW(FHandle, GWL_STYLE, Longint(Style or WS_SYSMENU or WS_VISIBLE));
  end;

  Update;
  Engine.DispatchEvent(evDisplayRestore);
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

procedure TDisplay.Resize(Width, Height: LongWord);
begin
  FWidth  := Width;
  FHeight := Height;
  if FFullScreen and FActive then
    Helpers.SystemInfo.Screen.SetMode(FWidth, FHeight, FRefresh);
  Engine.DispatchEvent(evDisplayRestore);
end;

procedure TDisplay.ShowCursor(Value: Boolean);
begin
  FCursor := Value;
end;

function TDisplay.GetValid: Boolean;
begin
  Result := FValid;
end;

function TDisplay.GetCustom: Boolean;
begin
  Result := FCustomHandle;
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

function TDisplay.GetWidth: LongInt;
begin
  Result := FWidth;
end;

function TDisplay.GetHeight: LongInt;
begin
  Result := FHeight;
end;

end.
