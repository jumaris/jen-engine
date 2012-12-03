unit JEN_Console;

interface

uses
  Windows,
  Messages,
  JEN_Math,
  JEN_Header;

const
  CONSOLE_WINDOW_CLASS_NAME = 'JENConsoleWnd';

type TConsole = class(TInterfacedObject, IConsole)
  constructor Create;
  destructor Destroy; override;
  private
    class function WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall; static;
    class var
    FConsoleWnd : HWND;
    FMemoWnd    : HWND;
    FFont      : LongWord;
  public
    function InitWindow: Boolean; stdcall;
    procedure AddMessage(Text: PWideChar); stdcall;
    function GetHandle : HWND; stdcall;
  end;

implementation

uses
  JEN_MAIN;

constructor TConsole.Create;
begin

end;

destructor TConsole.Destroy;
begin
  if (not (DestroyWindow(FMemoWnd) and DestroyWindow(FConsoleWnd) and DeleteObject(FFont))) then
    Engine.Error('Cannot destroy console window.');
end;

function TConsole.InitWindow: Boolean;
var
  WinClass   : TWndClassEx;
  DC         : HDC;
  Rect       : TRecti;
  Msg        : TMsg;
  LF         : LOGFONTA;
begin
  Result := False;

  FillChar(WinClass, SizeOf(TWndClassEx), 0);
  with WinClass do
  begin
    cbsize        := SizeOf(TWndClassExW);
    style         := CS_DBLCLKS or CS_OWNDC{ or CS_HREDRAW or CS_VREDRAW};
    lpfnWndProc   := {$IFDEF FPC}Pointer(WndProc){$ELSE}@WndProc{$ENDIF};
    //hCursor		    := LoadCursor(NULL, IDC_ARROW);
    hbrBackground	:= GetStockObject(NULL_BRUSH);
    lpszClassName	:= CONSOLE_WINDOW_CLASS_NAME;
  end;

  if RegisterClassEx(WinClass) = 0 Then
    Exit;

  Rect := Helpers.SystemInfo.Screen.DesktopRect;
  FConsoleWnd := CreateWindowEx(WS_EX_APPWINDOW{or WS_EX_TOPMOST}, CONSOLE_WINDOW_CLASS_NAME, 'JEN Console',
                            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_SIZEBOX,
                            Rect.Location.x, Rect.Location.y + Rect.Height - 300 - GetSystemMetrics(SM_CYDLGFRAME), 500, 300, 0, 0, 0, nil);

  FMemoWnd := CreateWindow('EDIT','',
                         WS_VISIBLE or WS_CHILD or WS_BORDER or WS_VSCROLL or WS_HSCROLL or
                         ES_MULTILINE or ES_READONLY, 0, 0, Rect.Width, Rect.Height, FConsoleWnd, 0, 0, nil);


  DC := GetDC(FMemoWnd);
  FillChar(LF, SizeOf(LOGFONTA), 0);
  LF.lfHeight := -MulDiv(9, GetDeviceCaps(DC, LOGPIXELSY), 72);
  LF.lfFaceName := 'Lucida Console';
  FFont := CreateFontIndirectA(LF);
  ReleaseDC(FMemoWnd, DC);

  if ((FConsoleWnd = 0) or (FMemoWnd = 0) or (FFont = 0))  Then
    Exit;

  SendMessageW(FConsoleWnd, WM_SETICON, 1, WPARAM(LoadIconW(HInstance, 'MAINICON')));
  ShowWindow(FConsoleWnd, SW_SHOWNORMAL);
  SendMessageW(FMemoWnd, WM_SETFONT, WPARAM(FFont), 1);

  Result := True;
end;

class function TConsole.WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt;
var
  rect : TRect;
begin
  Result := 0;
  case Msg of
    WM_CLOSE:;{ SetEvent(QuitEvent);   }

    WM_COMMAND:ShowWindow(FConsoleWnd, SW_SHOWNA);
    WM_SHOWWINDOW:;
    WM_SIZE:
    begin
    	GetClientRect(FConsoleWnd, rect);
      MoveWindow(FMemoWnd, 0, 0, rect.right, rect.bottom, True);
    end;
  else
    Result := DefWindowProc(hWnd, Msg, wParam, lParam);
  end;
end;

procedure TConsole.AddMessage(Text: PWideChar);
var
  str ,line       : UnicodeString;
  tstr            : UnicodeString;
  TimeStr         : UnicodeString;
  h,m,s,start,i,j : LongInt;
  TextLength      : LongInt;
  WndTextLength   : LongInt;
  d : PWideChar;
begin
  if Pointer(Text) = nil then
    Exit;

  WndTextLength := GetWindowTextLength(FMemoWnd);
  TextLength := Length(Text);

  if (WndTextLength + TextLength + 3 >= 30000) then
  begin
    str := 'Console auto clean.' + sLineBreak;
    SendMessageW(FMemoWnd, WM_SETTEXT, 0, LPARAM(PWideChar(str)));
    WndTextLength := GetWindowTextLength(FMemoWnd);
  end;

  str := Text + sLineBreak;

  SendMessageW(FMemoWnd, EM_SETSEL, WndTextLength, WndTextLength);
  SendMessageW(FMemoWnd, EM_REPLACESEL, 0, LPARAM(PWideChar(str)));
  SendMessageW(FMemoWnd, EM_SCROLL, SB_BOTTOM, 0);


     {

  WndTextLength := GetWindowTextLength(HMemo);
  TextLength := Length(Text);

  if (WndTextLength + TextLength + 3 >= 30000) then
  begin
	  SetWindowText(HMemo, 'Console auto clean.');
    WndTextLength := GetWindowTextLength(HMemo);
  end;

  h := Trunc(Helpers.RealTime/3600000);
  m := Trunc(Helpers.RealTime/60000);
  s := Trunc(Helpers.RealTime/1000) - m*60;
  m := m - h*60;

  TimeStr := '';
  if h > 0 then
    TimeStr := IntToStr(h) + ':';

  tstr := '0' + IntToStr(m);
  TimeStr := TimeStr + Copy(tstr, Length(tstr)-1, 2) + ':';

  tstr := '0' + IntToStr(s);
  TimeStr := TimeStr + Copy(tstr, Length(tstr)-1, 2);
                     {
  if (Utils.Time - LastUpdate > 9999) then
    tstr := '9999'
  else
    tstr := '0000' + Utils.IntToStr(Utils.Time - LastUpdate);

  TimeStr := TimeStr + Copy(tstr, Length(tstr)-3, 4);} {

  case MType of
    lmHeaderMsg:
      str := Text+#13#10;

    lmNotify :
      str := '[' + TimeStr + '] ' + Text+#13#10;

    lmCode:
      begin
        i := 1;
        j := 1;
        str := 'Source code:'+#13#10;

        while i <= TextLength do
        begin
          start := i;
          while not (AnsiChar(Text[i]) in [#0, #09, #10, #13]) do Inc(i);

          if Text[i] = #0 then
            break;

          if Text[i] = #09 then
          begin
            line := line + Copy(Text, start, i-start) + '   ';
            Inc(i);
            Continue;
          end;

          tstr := '000'+ IntToStr(j);
          str := str + Copy(tstr, Length(tstr)-2, 3) + ':' + Line + Copy(Text, start, i-start +1) + #13#10;
          Line := '';
          Inc(j);

          if Text[i] = #13 then Inc(i);
          if Text[i] = #10 then Inc(i);
        end;

      end;

    lmWarning :
      str := '[' + TimeStr + '] WARNING: ' + Text + #13#10;

    lmError :
      str := '[' + TimeStr + '] ERROR: ' + Text + #13#10;
  end;

  SendMessage(HMemo, EM_SETSEL, WndTextLength, WndTextLength);
  SendMessage(HMemo, EM_REPLACESEL, 0, LongInt(PChar(str)));
  SendMessage(HMemo, EM_SCROLL, SB_BOTTOM, 0);  }
end;

function TConsole.GetHandle: HWND;
begin
  Result := FConsoleWnd;
end;

end.

