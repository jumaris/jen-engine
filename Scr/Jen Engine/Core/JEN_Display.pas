unit JEN_Display;

interface

uses
  JEN_Header,
  Windows,
  messages,
  JEN_SystemInfo,
  JEN_OpenGLHeader;

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
    FVSync      : Boolean;
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
    procedure SetVSync(Value: Boolean); stdcall;
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
          SetCursor(LoadCursor(0, PWideChar(32512)));
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
    Result := DefWindowProc(hWnd, Msg, wParam, lParam);
  end;

end;

function TDisplay.Init(Width: LongWord; Height: LongWord; Refresh: Byte; FullScreen: Boolean): Boolean;
var
  WinClass: TWndClassEx;
begin
  if (Width = SystemParams.Screen.Width) and (Height = SystemParams.Screen.Height) then
    FullScreen := true;

  Result := false;

  FCaption    := 'JEN Engine application';
  FWidth      := Width;
  FHeight     := Height;
  FRefresh    := Refresh;
  FFullScreen := FullScreen;
  FValid      := False;
  FActive     := True;
  FCursor     := True;

  if FullScreen then
    case SystemParams.Screen.SetMode(Width, Height, Refresh) of
      SM_SetDefault:
        begin
          FWidth      := SystemParams.Screen.Width;
          FHeight     := SystemParams.Screen.Height;
          FRefresh    := SystemParams.Screen.Refresh;
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

  FHandle := CreateWindowEx(0, WINDOW_CLASS_NAME,@FCaption[1], 0, 0, 0,
                             0, 0, 0, 0, 0, nil);

  if FHandle = 0 Then
    begin
      LogOut('Cannot create window.', lmError);
      Exit;
    end else
      LogOut('Create window.', lmNotify);

  SendMessage(FHandle, WM_SETICON, 1, LoadIconW(HInstance, 'MAINICON'));
  FDC := GetDC(FHandle);
  FValid := true;
  Result := true;
  Restore;
end;

destructor TDisplay.Destroy;
begin
  if not FValid then Exit;

  if ReleaseDC( FHandle, FDC ) <> 0 Then
    LogOut('Cannot release device context.', lmError)
  else
    LogOut('Release device context.', lmNotify);

  if(FHandle <> 0) and (not DestroyWindow(FHandle)) Then
  begin
    LogOut('Cannot destroy window.', lmError);
    FHandle := 0;
  end else
    LogOut('Destroy window.', lmNotify);

  if not UnRegisterClass(WINDOW_CLASS_NAME, HInstance) Then
    LogOut('Cannot unregister window class.', lmError)
  else
    LogOut('Unregister window class.', lmNotify);

  if FFullScreen then
    SystemParams.Screen.ResetMode;

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

procedure TDisplay.SetVSync(Value: Boolean);
begin
  FVSync := Value;
  if FFullScreen then
    wglSwapIntervalEXT(Ord(FVSync))
  else
    wglSwapIntervalEXT(0);
end;

procedure TDisplay.SetFullScreen(Value: Boolean);
begin
  if (FFullScreen <> Value) then
  begin
    FFullScreen := Value;

    if Value then
      FValid := FValid and (SystemParams.Screen.SetMode(FWidth, FHeight, FRefresh) <> SM_Error)
    else
      SystemParams.Screen.ResetMode;

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
        FValid := FValid and (SystemParams.Screen.SetMode(FWidth, FHeight, FRefresh) <> SM_Error)
      else
        SystemParams.Screen.ResetMode;
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
    SystemParams.Screen.SetMode(FWidth, FHeight, FRefresh);
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
