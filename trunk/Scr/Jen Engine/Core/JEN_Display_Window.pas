unit JEN_Display_Window;

interface

uses
  XSystem,
  JEN_SystemInfo,
  JEN_Display,
  JEN_Window;

const
  WINDOW_CLASS_NAME = 'JEngineWindowClass';

type
  TDisplayWindow = class(TDisplay)
    constructor Create(Width: Cardinal = 800; Height: Cardinal = 600; Refresh: Byte = 0; FullScreen: Boolean = False);
    destructor Destroy; override;
  private
    FCaption    : String;
    FHandle     : HWND;
    FDC         : HDC;
    FWidth      : Cardinal;
    FHeight     : Cardinal;
    FRefresh    : Byte;
    FFullScreen : Boolean;
    FActive     : Boolean;
    FCursor     : Boolean;
    procedure SetFullScreen(Value: Boolean); override;
    procedure SetActive(Value: Boolean); override;
    procedure SetCaption(const Value: string); override;

    function GetFullScreen: Boolean; override;
    function GetActive: Boolean; override;
    function GetCursorState: Boolean; override;
    function GetHandle: HWND; override;
    function GetHDC: HDC; override;
    function GetWidth: Cardinal; override;
    function GetHeight: Cardinal; override;
  public
    procedure Restore; override;
    procedure Update; override;
    procedure Resize(W, H: Cardinal); override;
    procedure ShowCursor(Value: Boolean); override;

    class function WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall; static;
  end;

implementation

uses
  JEN_MAIN,
  JEN_MATH;

class function TDisplayWindow.WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): Integer; stdcall;
begin
// Assert(expr : Boolean [; const msg: string]
//  LogOut('message');
  Result := 0;
  case Msg of
    WM_CLOSE:
      TGame.Finish;

    WM_ACTIVATEAPP:
      begin
        Display.Active := Word(wParam) <> 0;

        if Display.FullScreen then
          if Display.Active then
            ShowWindow(hWnd, SW_SHOW)
          else
            ShowWindow(hWnd, SW_MINIMIZE);
         {
        if CInput <> nil then
          CInput.Reset;   }
      end;

    WM_SETCURSOR:
      begin
        if (Display.Active) and (Word(lparam) = 1) and (not Display.Cursor) Then
          SetCursor(0)
        else
          SetCursor(LoadCursorW(0, PWideChar(32512)));
      end;
      {
}

  //  WM_MOVE, WM_SIZE :;
     { GetWindowRect(hWnd, CDisplay.FRect);
         }
  // Keyboard
 //   WM_KEYUP, WM_SYSKEYUP :;
     { CInput.Down[Ord2Key(wParam)] := False;   }
 //   WM_KEYDOWN, WM_SYSKEYDOWN : ;
   {   begin
        CInput.Down[Ord2Key(wParam)] := True;
        if (wParam = 13) and (Msg = WM_SYSKEYDOWN) then // Alt + Enter
          with CDisplay do
            Mode(not FullScreen, Width, Height, Freq);
      end;
                 }
  // Mouse

    WM_LBUTTONUP   :;// CInput.Down[KM_1] := False;
    WM_LBUTTONDOWN :;//  CInput.Down[KM_1] := True;
    WM_RBUTTONUP   :;//  CInput.Down[KM_2] := False;
    WM_RBUTTONDOWN :;//  CInput.Down[KM_2] := True;
    WM_MBUTTONUP   :;//  CInput.Down[KM_3] := False;
    WM_MBUTTONDOWN :;//  CInput.Down[KM_3] := True;

    WM_MOUSEWHEEL  :;{
      begin
        with CMouse.FDelta do
          Inc(Wheel, SmallInt(wParam  shr 16) div 120);
        if SmallInt(wParam shr 16) > 0 then CInput.Down[KM_WHUP] := True;
        if SmallInt(wParam shr 16) < 0 then CInput.Down[KM_WHDN] := True;
      end     }
  else
    Result := DefWindowProcW(hWnd, Msg, wParam, lParam);
  end;
end;

constructor TDisplayWindow.Create(Width: Cardinal; Height: Cardinal; Refresh: Byte; FullScreen: Boolean);
var
  WinClass      : TWndClassEx;
begin
  if (Width = SystemParams.Screen.Width) and (Height = SystemParams.Screen.Height) then
    FullScreen := true;

  FCaption    := 'JEN Engine application';
  FWidth      := Width;
  FHeight     := Height;
  FRefresh    := Refresh;
  FFullScreen := FullScreen;
  FValid      := False;
  FActive     := True;
  FCursor     := True;

  if FullScreen and (SystemParams.Screen.SetMode(Width, Height, Refresh) = SM_Error) then
    Exit;

  FillChar(WinClass, SizeOf(TWndClassEx), 0);
  with WinClass do
  begin
    cbsize        := SizeOf(TWndClassEx);
 	  style         := CS_DBLCLKS or CS_OWNDC or CS_HREDRAW or CS_VREDRAW;
	  lpfnWndProc   := @TDisplayWindow.WndProc;
	  //hCursor		    := LoadCursor(NULL, IDC_ARROW);
	  hbrBackground	:= GetStockObject(BLACK_BRUSH);
	  lpszClassName	:= WINDOW_CLASS_NAME;
  end;

  if RegisterClassExW(WinClass) = 0 Then
  begin
    LogOut('Cannot register window class.', lmError);
    Exit;
  end else
    LogOut('Register window class.', lmNotify);

  FHandle := CreateWindowExW(0, WINDOW_CLASS_NAME, @FCaption[1], 0, 0, 0,
                             0, 0, 0, 0, HInstance, nil);

  if FHandle = 0 Then
    begin
      LogOut('Cannot create window.', lmError);
      Exit;
    end else
      LogOut('Create window.', lmNotify);

  SendMessageW(Handle, WM_SETICON, 1, LoadIconW(HInstance, 'MAINICON'));
  FDC := GetDC(FHandle);
  FValid := true;

  Restore;
end;

destructor TDisplayWindow.Destroy;
begin
   if not FValid then Exit;

  if not ReleaseDC( FHandle, FDC ) Then
    LogOut('Cannot release device context.', lmError)
  else
    LogOut('Release device context.', lmNotify);

  if(FHandle <> 0) and (not DestroyWindow(FHandle)) Then
  begin
    LogOut('Cannot destroy window.', lmError);
    FHandle := 0;
  end else
    LogOut('Destroy window.', lmNotify);

  if not UnRegisterClassW(WINDOW_CLASS_NAME, HInstance) Then
    LogOut('Cannot unregister window class.', lmError)
  else
    LogOut('Unregister window class.', lmNotify);

  if FFullScreen then
    SystemParams.Screen.ResetMode;

  inherited;
end;

function TDisplayWindow.GetFullScreen: Boolean;
begin
  result := FFullScreen;
end;

procedure TDisplayWindow.SetFullScreen(Value: Boolean);
begin
  if (FFullScreen = Value) or (FValid = false) then Exit;
  FFullScreen := Value;

  if Value then
    FValid := FValid and (SystemParams.Screen.SetMode(FWidth, FHeight, FRefresh) <> SM_Error)
  else
    SystemParams.Screen.ResetMode;

  Restore;
end;

procedure TDisplayWindow.SetActive(Value: Boolean);
begin
  if (FActive = Value) or (FValid = false) then Exit;
  FActive := Value;

  if FFullScreen then
  begin
    if Value then
      FValid := FValid and (SystemParams.Screen.SetMode(FWidth, FHeight, FRefresh) <> SM_Error)
    else
      SystemParams.Screen.ResetMode;
    Restore;
  end;

end;

function TDisplayWindow.GetActive: Boolean;
begin
  Result := FActive;
end;

function TDisplayWindow.GetCursorState: Boolean;
begin
  Result := FCursor;
end;

procedure TDisplayWindow.SetCaption(const Value: String);
begin
  if (FValid = false) then Exit;
  FCaption := Value;
  SetWindowTextW(Handle, PWideChar(Value));
end;

procedure TDisplayWindow.Restore;
var
  Style : LongWord;
  Rect  : TRecti;
begin
  if (FValid = false) then Exit;
  inherited;
    Rect := Recti((SystemParams.Screen.Width - FWidth) div 2, (SystemParams.Screen.Height - FHeight) div 2, FWidth, FHeight);

  if FFullScreen then
  begin
    Rect.Location := ZeroPoint;
    Style := WS_POPUP
  end else
  begin
    Style := WS_CAPTION or WS_MINIMIZEBOX;
    Rect.Inflate(GetSystemMetrics(SM_CXDLGFRAME), GetSystemMetrics(SM_CYDLGFRAME) + GetSystemMetrics(SM_CYCAPTION) div 2);
  end;

  SetWindowLongA(FHandle, GWL_STYLE, Style or WS_VISIBLE or WS_SYSMENU);
  SetWindowPos(FHandle, 0, Rect.x, Rect.y, Rect.Width, Rect.Height, $220);

  //Render.Viewport := Recti(0, 0, FWidth, FHeight);
end;

procedure TDisplayWindow.Update;
var
  Msg : TMsg;
begin
  while PeekMessageW(Msg, 0, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessageW(Msg);
  end;
end;

procedure TDisplayWindow.Resize(W, H: Cardinal);
begin
  FWidth  := W;
  FHeight := H;
  if FFullScreen and FActive then
    SystemParams.Screen.SetMode(FWidth, FHeight, FRefresh);
  Restore;
end;

procedure TDisplayWindow.ShowCursor(Value: Boolean);
begin
  FCursor := Value;
end;

function TDisplayWindow.GetHandle: HWND;
begin
  Result := FHandle;
end;

function TDisplayWindow.GetHDC: HDC;
begin
  Result := FDC;
end;

function TDisplayWindow.GetWidth: Cardinal;
begin
  Result := FWidth;
end;

function TDisplayWindow.GetHeight: Cardinal;
begin
  Result := FHeight;
end;

end.
