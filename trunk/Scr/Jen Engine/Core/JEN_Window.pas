unit JEN_Window;

interface

uses
  JEN_Display,
  XSystem;

const
  WINDOW_CLASS_NAME = 'JEngineWindowClass';

type
  PWindow = ^TWindow;
  TWindow = class
    constructor Create(Display: TDisplay; FullScreen: Boolean; Width: Integer; Height: Integer; FSSA: Byte);
    destructor  Destroy; override;
  private
    FDisplay    : TDisplay;
    FCaption    : String;
    FHandle     : HWND;
    FDC         : HDC;
    FValid      : Boolean;
    FFullScreen : Boolean;
    FCursor     : Boolean;
    class var FCurrentWindow : TWindow;
    class function WndProc(hWnd: HWND; Msg: Cardinal; wParam: Integer; lParam: Integer): Integer; stdcall; static;
    procedure SetCaption(const Value: String);
    procedure SetFullScreen(Value : Boolean);
  public
    property IsValid: Boolean read FValid;
    property Caption: String read FCaption write SetCaption;
    property Handle: HWND read FHandle;
    property DC: HDC read FDC;
    property Display: TDisplay read FDisplay;
    property FullScreen: Boolean read FFullScreen write SetFullScreen;
    class property CurrentWindow: TWindow read FCurrentWindow;

  //  procedure HandleFree;
    procedure Update;
    procedure Restore;
    procedure ShowCursor(Value: Boolean);
  end;

implementation

uses
  JEN_Main,
  JEN_OpenGLHeader,
  JEN_Utils,
  JEN_SystemInfo,
  JEN_Log,
  JEN_Math,
  JEN_Game;

class function TWindow.WndProc(hWnd: HWND; Msg: Cardinal; wParam: Integer; lParam: Integer): Integer; stdcall;
begin
// Assert(expr : Boolean [; const msg: string]
//  LogOut('message');
  Result := 0;
  case Msg of
    WM_CLOSE:
      TGame.Finish;

    WM_ACTIVATEAPP:
      begin
        FCurrentWindow.Display.Active := Word(wParam) <> 0;

        if CurrentWindow.FFullScreen then
          if FCurrentWindow.Display.Active then
            ShowWindow(hWnd, SW_SHOW)
          else
            ShowWindow(hWnd, SW_MINIMIZE);
         {
        if CInput <> nil then
          CInput.Reset;   }
      end;

    WM_SETCURSOR:
      begin
        if (FCurrentWindow.Display.Active) and (Word(lparam) = 1) and (not CurrentWindow.FCursor) Then
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

constructor TWindow.Create(Display : TDisplay; FullScreen: Boolean; Width: Integer; Height: Integer; FSSA: Byte);
var
  WinClass      : TWndClassEx;
begin
  FValid   := False;
  FDisplay := Display;
  FCaption := 'JEN Engine application';
  FFullScreen := FullScreen;
  FCursor := True;

  if not Assigned(Display) then
  begin
    LogOut('Cannot create window, display is not correct', lmError);
    Exit;
  end;

  FillChar(WinClass, SizeOf(TWndClassEx), 0);
  with WinClass do
  begin
    cbsize        := SizeOf(TWndClassEx);
 	  style         := CS_DBLCLKS or CS_OWNDC or CS_HREDRAW or CS_VREDRAW;
	  lpfnWndProc   := @TWindow.WndProc;
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
                       {
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

  Restore;
  FValid := true;       }
end;

destructor TWindow.Destroy;
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

  inherited;
end;

procedure TWindow.SetCaption(const Value: String);
begin
  SetWindowTextW(Handle, PWideChar(Value));
end;

procedure TWindow.Restore;
var
  Style : LongWord;
  Rect  : TRecti;
begin
  Rect := Recti((SystemParams.Screen.Width - FDisplay.Width) div 2, (SystemParams.Screen.Height - FDisplay.Height) div 2, FDisplay.Width, FDisplay.Height);

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
end;

procedure TWindow.ShowCursor(Value: Boolean);
begin
  FCursor := Value;
end;

procedure TWindow.SetFullScreen(Value : Boolean);
begin
  FFullScreen := Value;
  Restore;
end;
        {
procedure TWindow.HandleFree;
begin
  //FHandle := 0;
end;      }

procedure TWindow.Update;
var
  Msg : TMsg;
begin
  FCurrentWindow := self;
  while PeekMessageW(Msg, 0, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessageW(Msg);
  end;
end;

end.
