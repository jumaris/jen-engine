unit JEN_Debugger;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Windows,
  Messages,
  JEN_Math,
  JEN_Header,
  JEN_Helpers;

const
  CONSOLE_WINDOW_CLASS_NAME = 'JENConsoleWnd';
       {
type
  TDebugger = class(TInterfacedObject, IJenDebugger)
    constructor Create(FileName : String);
    destructor Destroy; override;
  private
    class var Stream : IStream;
    Thread     : THandle;
    FHandle    : HWND;
    HMemo      : HWND;
    QuitEvent  : THandle;
    LoadEvent  : THandle;
    Quit       : Boolean;
  public
    procedure Log(Text: PWideChar); stdcall;
    procedure Error(Text: PWideChar); stdcall;
    procedure Warning(Text: PWideChar); stdcall;
    procedure CodeBlock(Text: PWideChar); stdcall;
    class procedure CreateWnd(lpParameter : Pointer); static; stdcall;
    class function WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall; static;
    class procedure AddMessage(MesType: TLogMsg; Text: PWideChar); static; stdcall;
  end;
         }
implementation

uses
  JEN_MAIN;
              {
constructor TDebugger.Create(FileName : String);
var
  i     : LongInt;
  S     : AnsiString;
  Major : LongInt;
  Minor : LongInt;
  Build : LongInt;
  lpThreadId : DWORD;
begin
  Stream := Helpers.CreateStream(PWideChar(FileName));

  QuitEvent := CreateEvent(nil, True, False, '');
  LoadEvent := CreateEvent(nil, True, False, '');
  Thread := CreateThread(nil, 0, @TDebugger.CreateWnd, nil, 0, lpThreadId);
  WaitForSingleObject(LoadEvent, INFINITE);
  CloseHandle(LoadEvent);

  Helpers.SystemInfo.WindowsVersion(Major, Minor, Build);
  SetLength(S,80);
  FillChar(S[1],80,ord('*'));
  AddMessage(lmHeaderMsg, PWideChar(WideString(s)));
  AddMessage(lmHeaderMsg, 'JenEngine');
  AddMessage(lmHeaderMsg, PWideChar('Windows version: '+IntToStr(Major)+'.'+IntToStr(Minor)+' (Buid '+IntToStr(Build)+')'+IntToStr(Helpers.SystemInfo.CPUCount)));
  AddMessage(lmHeaderMsg, PWideChar('CPU            : '+Helpers.SystemInfo.CPUName+'(~'+IntToStr(Helpers.SystemInfo.CPUSpeed)+')x'));
  AddMessage(lmHeaderMsg, PWideChar('RAM Total      : '+IntToStr(Helpers.SystemInfo.RAMTotal)+'Mb'));
  AddMessage(lmHeaderMsg, PWideChar('RAM Available  : '+IntToStr(Helpers.SystemInfo.RAMFree)+'Mb'));

  with Helpers.SystemInfo do
  for i := 0 to GPUList.Count - 1 do
    with PGPUInfo(GPUList[i])^ do
    begin
      AddMessage(lmHeaderMsg, PWideChar('GPU' + IntToStr(i) +'           : ' + Description));
      AddMessage(lmHeaderMsg, PWideChar('Chip           : ' + ChipType));
      AddMessage(lmHeaderMsg, PWideChar('MemorySize     : ' + IntToStr(MemorySize)+'Mb'));
      AddMessage(lmHeaderMsg, PWideChar('DriverVersion  : ' + DriverVersion + '(' + DriverDate + ')'));
    end;
  AddMessage(lmHeaderMsg, PWideChar(WideString(s)));
  Engine.AddEventListener(evLogMsg, @AddMessage);
end;

destructor TDebugger.Destroy;
begin
  SetEvent(QuitEvent);
  WaitForSingleObject(Thread, INFINITE);
  CloseHandle(QuitEvent);
  CloseHandle(Thread);
  inherited;
end;

class procedure TDebugger.CreateWnd(lpParameter : Pointer);
var
  WinClass   : TWndClassEx;
  HTimer     : HWND;
  DC         : HDC;
  Rect       : TRecti;
  Msg        : TMsg;
  HFont      : LongWord;
  LF         : LOGFONT;
begin
  FillChar(WinClass, SizeOf(TWndClassEx), 0);
  with WinClass do
  begin
    cbsize        := SizeOf(TWndClassEx);
 	  style         := CS_DBLCLKS or CS_OWNDC{ or CS_HREDRAW or CS_VREDRAW}{;
 	  lpfnWndProc   := @TDebugger.WndProc;
	  //hCursor		    := LoadCursor(NULL, IDC_ARROW);
    hbrBackground	:= GetStockObject(NULL_BRUSH);
	  lpszClassName	:= CONSOLE_WINDOW_CLASS_NAME;
  end;

  if RegisterClassEx(WinClass) = 0 Then
  begin
    Engine.Debugger.Error('Cannot register cosole window class.');
    SetEvent(LoadEvent);
    Exit;
  end;

  Rect := Helpers.SystemInfo.Screen.DesktopRect;

  FHandle := CreateWindowEx(WS_EX_APPWINDOW{or WS_EX_TOPMOST}{, CONSOLE_WINDOW_CLASS_NAME, 'JEN Console',
  		 	  			            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_SIZEBOX,
                            0, Rect.y + Rect.Height - 300 - GetSystemMetrics(SM_CYDLGFRAME), 500, 300, 0, 0, 0, nil);

  HMemo := CreateWindow('EDIT','',
                         WS_VISIBLE or WS_CHILD or WS_BORDER or WS_VSCROLL or WS_HSCROLL or
								         ES_MULTILINE or ES_READONLY, 0, 0, Rect.Width, Rect.Height, FHandle, 0, 0, nil);

  DC := GetDC(HMemo);
  FillChar(LF, SizeOf(LOGFONT), 0);
  LF.lfHeight := -MulDiv(9, GetDeviceCaps(DC, LOGPIXELSY), 72);
  LF.lfFaceName := 'Lucida Console';
  HFont := CreateFontIndirect(LF);
  ReleaseDC(HMemo, DC);

  HTimer := 1;
  if ((FHandle = 0) or (HMemo = 0) or (HFont = 0) or (SetTimer(FHandle, HTimer, 40, nil) = 0))  Then
  begin
    SetEvent(LoadEvent);
    Engine.Debugger.Log('Cannot create console window.');
    Exit;
  end;

  SendMessage(FHandle, WM_SETICON, 1, WPARAM(LoadIconW(HInstance, 'MAINICON')));
  ShowWindow(FHandle, SW_SHOWNORMAL);
  SendMessage(HMemo, WM_SETFONT, WPARAM(hFont), 1);

  Quit := False;
  SetEvent(LoadEvent);

  while GetMessage(Msg, 0, 0, 0) and (not Quit) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

  Helpers.Sleep(2500);
  KillTimer(FHandle, HTimer);

  if (not (DestroyWindow(HMemo) and DestroyWindow(FHandle) and DeleteObject(HFont))) then
    Engine.Debugger.Error('Cannot destroy console window.');
end;

class function TDebugger.WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall;
var
  rect : TRect;
begin
  Result := 0;
  case Msg of
    WM_CLOSE:;{ SetEvent(QuitEvent);   } {

    WM_COMMAND:ShowWindow(FHandle, SW_SHOWNA);
    WM_SHOWWINDOW:;
    WM_SIZE:
    begin
 	     GetClientRect(FHandle, rect);
	     MoveWindow(HMemo, 0, 0, rect.right, rect.bottom, True);
    end;

    WM_TIMER:
      Quit := not (WaitForSingleObject(QuitEvent,0) = WAIT_TIMEOUT);
  else
    Result := DefWindowProc(hWnd, Msg, wParam, lParam);
  end;
end;

class procedure TDebugger.AddMsg(MType: TLogMsg; Text: PWideChar);
var
  str ,line       : String;
  tstr            : String;
  TimeStr         : String;
  h,m,s,start,i,j : LongInt;
  TextLength      : LongInt;
  WndTextLength   : LongInt;
begin
  if Pointer(Text) = nil then
    Exit;

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

  TimeStr := TimeStr + Copy(tstr, Length(tstr)-3, 4);}
                                      {
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
  SendMessage(HMemo, EM_SCROLL, SB_BOTTOM, 0);
end;


procedure TDebugger.Log(Text: PWideChar);
begin
  Engine.DispatchEvent(evLogMsg, Ord(lmNotify), Text);
end;

procedure TDebugger.Error(Text: PWideChar); stdcall;
begin
  Engine.DispatchEvent(evLogMsg, Ord(lmError), Text);
end;

procedure TDebugger.Warning(Text: PWideChar); stdcall;
begin
  Engine.DispatchEvent(evLogMsg, Ord(lmWarning), Text);
end;

procedure TDebugger.CodeBlock(Text: PWideChar); stdcall;
begin
  Engine.DispatchEvent(evLogMsg, Ord(lmCode), Text);
end;

class procedure TDebugger.AddMessage(MesType: TLogMsg; Text: PWideChar);
var
  str,line : String;
  tstr : String;
  TimeStr : String;
  h,m,s,start,i,j : LongInt;
begin
  if Pointer(Text) = nil then
    Exit;

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

  TimeStr := TimeStr + Copy(tstr, Length(tstr)-3, 4);  }  {

  case MesType of
    lmHeaderMsg:
      str := Text+#13#10;

    lmNotify :
      str := '[' + TimeStr + '] ' + Text+#13#10;

    lmCode:
      begin
        i := 1;
        j := 1;
        str := 'Source code:'+#13#10;

        while Text[i] <> #0 do
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
          str := str + Copy(tstr, Length(tstr)-2, 3) + ':' + Line + Copy(Text, start, i-start+1) + #13#10;
          Line := '';
          Inc(j);

          if Text[i] = #13 then Inc(i);
          if Text[i] = #10 then Inc(i);
        end;

      end;

    lmWarning :
      str := '[' + TimeStr + '] WARNING: ' + Text+#13#10;

    lmError :
      str := '[' + TimeStr + '] ERROR: ' + Text+#13#10;
    else str := Text+#13#10;
  end;

  Stream.Write(str[1], Length(str)*2);
end;               }

end.
