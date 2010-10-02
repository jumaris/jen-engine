unit JEN_Window;
{$I Jen_config.INC}

interface

uses
  XSystem;

const
  WINDOW_CLASS_NAME = 'JEngineWindowClass';

type
  PWindow = ^TWindow;
  TWindow = class
  private
    FCaption      : String;
    FHandle       : HWND;
    FDC           : HDC;
    class function WndProc(hWnd: HWND; Msg: Cardinal; wParam: Integer; lParam: Integer): Integer; stdcall; static;
    procedure      SetCaption(const Value: String);
  public
    constructor Create(isFullScreen : Boolean; Width: Integer; Height: Integer; FSSA : Byte);
    destructor  Destroy; override;

    procedure   HandleFree;
    procedure   Update;

    property    Caption : String read FCaption write SetCaption;
    property    Handle  : HWND read FHandle;
    property    DC      : HDC read FDC;
end;

implementation

uses
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
      TGame.Exit;

  //  WM_ACTIVATEAPP :;
   {  with CDisplay do
      begin
        FActive := Word(wParam) = WA_ACTIVE;
        if FullScreen then
        begin
          Mode(FActive, Width, Height, Freq);
          if FActive then
            ShowWindow(FHandle, SW_SHOW)
          else
            ShowWindow(FHandle, SW_MINIMIZE);
          FFullScreen := True;
        end;
//        ShowCursor(not FActive);
        if CInput <> nil then
          CInput.Reset;
      end;  }

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

constructor TWindow.Create(isFullScreen: Boolean; Width: Integer; Height: Integer; FSSA: Byte);
var
  WinClass      : TWndClassEx;
  Window_Style  : LongWord;
  WindowRect    : TRecti;
begin
  inherited Create();

  FCaption := 'JEN Engine application';
  WindowRect := Recti((SystemInfo.ScreenWidth - Width) div 2, (SystemInfo.ScreenHeight - Height) div 2, Width, Height);

  FillChar(WinClass, SizeOf(TWndClassEx), 0);
  with WinClass do
  begin
    cbsize        := SizeOf( TWndClassEx );
	  style         := CS_DBLCLKS or CS_OWNDC or CS_HREDRAW or CS_VREDRAW;
	  lpfnWndProc   := @TWindow.WndProc;
	  //hCursor		    := LoadCursor(NULL, IDC_ARROW);
	  hbrBackground	:= GetStockObject(BLACK_BRUSH);
	  lpszClassName	:= WINDOW_CLASS_NAME;
  end;

  if RegisterClassExW( WinClass ) = 0 Then
  begin
    LogOut( 'Cannot register window class.', LM_ERROR );
    Exit;
  end else
    LogOut( 'Register window class.', LM_NOTIFY );

  if (Width = SystemInfo.ScreenWidth) and (Height = SystemInfo.ScreenHeight) then
    isFullScreen := true;

  if isFullScreen Then
    begin
      WindowRect.Location := PointZero;
      Window_Style        := WS_POPUP or WS_VISIBLE or WS_SYSMENU;
    end else
    begin
      WindowRect.Inflate(GetSystemMetrics(SM_CXDLGFRAME), GetSystemMetrics(SM_CYDLGFRAME) + GetSystemMetrics(SM_CYCAPTION) div 2);
      Window_Style        := WS_CAPTION or WS_MINIMIZEBOX or WS_SYSMENU or WS_VISIBLE;
    end;
     {
      SelectWindow( wnd_Handle );
  ShowWindow( wnd_Handle );
  if wnd_FullScreen Then
    wnd_SetPos( 0, 0 ); }

                  {
  Window_CpnSize  := GetSystemMetrics( SM_CYCAPTION  );
  Window_BrdSizeX := GetSystemMetrics( SM_CXDLGFRAME );
  Window_BrdSizeY := GetSystemMetrics( SM_CYDLGFRAME );
                       }
                       {
  FHandle := CreateWindowExW( WS_EX_APPWINDOW or WS_EX_TOPMOST * Byte( isFullScreen ), WINDOW_CLASS_NAME,  @FCaption[1], Window_Style, WindowRect.X, WindowRect.Y,
                                   wnd_Width  + ( wnd_BrdSizeX * 2 ) * Byte( not wnd_FullScreen ),
                                   wnd_Height + ( wnd_BrdSizeY * 2 + wnd_CpnSize ) * Byte( not isFullScreen ), 0, 0, HInstance, nil );
                          }
  FHandle := CreateWindowExW( WS_EX_APPWINDOW or WS_EX_TOPMOST * Byte( isFullScreen ), WINDOW_CLASS_NAME,  @FCaption[1], Window_Style, WindowRect.X, WindowRect.Y,
                              WindowRect.Width, WindowRect.Height, 0, 0, HInstance, nil );
                         {
  FHandle := CreateWindowExW(0, WINDOW_CLASS_NAME, @FCaption[1], WS_CAPTION or WS_MINIMIZEBOX or WS_SYSMENU or WS_VISIBLE,
                            0, 0, ScreenWidth, ScreenHeight, 0, 0, HInstance, nil);        }
  if FHandle = 0 Then
    begin
      LogOut( 'Cannot create window.', LM_ERROR );
      Exit;
    end else
      LogOut( 'Create window.', LM_NOTIFY );

  SendMessageW(Handle, WM_SETICON, 1, LoadIconW(HInstance, 'MAINICON'));
  FDC:= GetDC( FHandle );
end;

destructor TWindow.Destroy();
begin

  if not ReleaseDC( FHandle, FDC ) Then
    LogOut( 'Cannot release device context.', LM_ERROR )
  else
    LogOut( 'Release device context.', LM_NOTIFY );

  if ( FHandle <> 0 ) and ( not DestroyWindow( FHandle ) ) Then
  begin
    LogOut( 'Cannot destroy window.', LM_ERROR );
    FHandle := 0;
  end else
    LogOut( 'Destroy window.', LM_NOTIFY );

  if not UnRegisterClassW( WINDOW_CLASS_NAME, HInstance ) Then
    LogOut( 'Cannot unregister window class.', LM_ERROR )
  else
    LogOut( 'Unregister window class.', LM_NOTIFY );

  inherited;
end;

procedure TWindow.SetCaption(const Value: String);
begin

end;

procedure TWindow.HandleFree();
begin
  //FHandle := 0;
end;

procedure TWindow.Update();
var
  Msg : TMsg;
begin

  while PeekMessageW(Msg, 0, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessageW(Msg);
  end;

end;

end.
