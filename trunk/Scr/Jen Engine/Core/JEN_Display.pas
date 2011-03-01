unit JEN_Display;

interface

uses
  JEN_Header,
  XSystem,
  JEN_SystemInfo,
  JEN_Render,
  JEN_OpenGLHeader;

const
  WINDOW_CLASS_NAME = 'JEngineWindowClass';

function Display_SetFullScreen(Value: Boolean): HRESULT; stdcall;

type
  TDisplay = class
    constructor Create;
    destructor Destroy;
    function Init(Width: Cardinal; Height: Cardinal; Refresh: Byte; FullScreen: Boolean): HRESULT; stdcall; export;
    private
      FValid      : Boolean;
      FVSync      : Boolean;
      FFPS        : LongInt;
      FFPSTime    : LongInt;
      FFPSCount   : LongInt;
      FCaption    : String;
      FHandle     : HWND;
      FDC         : HDC;
      FWidth      : Cardinal;
      FHeight     : Cardinal;
      FRefresh    : Byte;
      FFullScreen : Boolean;
      FActive     : Boolean;
      FCursor     : Boolean;

    function SetActive(Value: Boolean): HRESULT; stdcall;
    function SetCaption(const Value: string): HRESULT; stdcall;
    function SetVSync(Value: Boolean): HRESULT; stdcall;

    function GetFullScreen: LongBool; stdcall;
    function GetActive: LongBool; stdcall;
    function GetCursorState: LongBool; stdcall;
    function GetHDC(out Value: HDC) : HRESULT; stdcall;
    function GetHandle(out Value: HWND): HRESULT; stdcall;
    function GetWidth(out Value: LongWord): HRESULT; stdcall;
    function GetHeight(out Value: LongWord): HRESULT; stdcall;

    procedure oSetFullScreen(Value: Boolean);
    procedure oSetActive(Value: Boolean);
    procedure oSetCaption(const Value: string);
    procedure oSetVSync(Value: Boolean);

    class function WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall; static;
  public
    const SetFullScreen: function(Value: Boolean): HRESULT stdcall = Display_SetFullScreen;

    procedure Swap;
    procedure Resize(W, H: Cardinal);
    procedure ShowCursor(Value: Boolean);
    procedure Restore;
    procedure Update;

    property Valid: Boolean read FValid;
    property Active: Boolean read FActive write oSetActive;
    property Cursor: Boolean read FCursor write ShowCursor;
    property FullScreen: Boolean read FFullScreen write oSetFullScreen;
    property VSync: Boolean read FVSync write oSetVSync;

    property Handle: HWND  read FHandle;
    property DC: HDC read FDC;
    property Width: Cardinal read FWidth;
    property Height: Cardinal read FHeight;
    property Caption: String write oSetCaption;
    property FPS: LongInt read FFPS;
  end;



implementation

uses
  JEN_MAIN,
  JEN_MATH;

  function Display_SetFullScreen(Value: Boolean): HRESULT; stdcall;
  begin

  end;
class function TDisplay.WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): Integer; stdcall;
begin
// Assert(expr : Boolean [; const msg: string]
//  LogOut('message');
  Result := 0;
  case Msg of
    WM_CLOSE:
       Engine.Finish;

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

constructor TDisplay.Create;
begin
  inherited;
end;

function TDisplay.Init(Width: Cardinal; Height: Cardinal; Refresh: Byte; FullScreen: Boolean) : HRESULT;
var
  WinClass      : TWndClassEx;
begin
  Result := S_FALSE;
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
	  lpfnWndProc   := @TDisplay.WndProc;
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
  Result := S_OK;
  Restore;
end;

destructor TDisplay.Destroy;
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

procedure TDisplay.Swap;
begin
  SwapBuffers(DC);

  Inc(FFPSCount);
  if Utils.Time - FFPSTime >= 1000 then
  begin
    FFPS      := FFPSCount;
    FFPSCount := 0;
    FFPSTime  := Utils.Time;
  end;
end;

procedure TDisplay.oSetVSync(Value: Boolean);
begin
  FVSync := Value;
  if FullScreen then
    wglSwapIntervalEXT(Ord(FVSync))
  else
    wglSwapIntervalEXT(0);
end;

procedure TDisplay.oSetFullScreen(Value: Boolean);
begin
  if (FFullScreen = Value) or (FValid = false) then Exit;
  FFullScreen := Value;

  if Value then
    FValid := FValid and (SystemParams.Screen.SetMode(FWidth, FHeight, FRefresh) <> SM_Error)
  else
    SystemParams.Screen.ResetMode;

  Restore;
end;

procedure TDisplay.oSetActive(Value: Boolean);
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

procedure TDisplay.oSetCaption(const Value: String);
begin
  if (FValid = false) then Exit;
  FCaption := Value;
  SetWindowTextW(Handle, PWideChar(Value));
end;

procedure TDisplay.Restore;
var
  Style : LongWord;
  Rect  : TRecti;
begin
  if (FValid = false) then Exit;

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
  while PeekMessageW(Msg, 0, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessageW(Msg);
  end;
end;

procedure TDisplay.Resize(W, H: Cardinal);
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
            {
class function TDisplay.SetFullScreen(Value: Boolean): HRESULT;
begin
 // FullScreen := Value;
end;
               }
function TDisplay.SetActive(Value: Boolean): HRESULT;
begin
  Active := Value;
end;

function TDisplay.SetCaption(const Value: string): HRESULT;
begin
  Caption := Value;
end;

function TDisplay.SetVSync(Value: Boolean): HRESULT;
begin
  VSync := Value;
end;

function TDisplay.GetFullScreen: LongBool;
begin
  Result := FullScreen;
end;

function TDisplay.GetActive: LongBool;
begin
  Result := Active;
end;

function TDisplay.GetCursorState: LongBool;
begin
  Result := Cursor;
end;

function TDisplay.GetHDC(out Value: HDC) : HRESULT;
begin
  Result := DC;
end;

function TDisplay.GetHandle(out Value: HWND): HRESULT;
begin
  Result := Handle;
end;

function TDisplay.GetWidth(out Value: LongWord): HRESULT;
begin
  Result := Width;
end;

function TDisplay.GetHeight(out Value: LongWord): HRESULT;
begin
  Result := Height;
end;



end.
