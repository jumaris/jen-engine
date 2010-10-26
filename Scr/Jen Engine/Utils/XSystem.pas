unit XSystem;

interface

{$REGION 'CONSTANS'}
const
  kernel32  = 'kernel32.dll';
  advapi32  = 'advapi32.dll';
  user32    = 'user32.dll';
  gdi32     = 'gdi32.dll';
  opengl32  = 'opengl32.dll';
  winmm     = 'winmm.dll';

const
  INVALID_HANDLE_VALUE  = LongWord(-1);
  INVALID_FILE_SIZE     = LongWord($FFFFFFFF);

  FILE_BEGIN = 0;
  FILE_CURRENT = 1;
  FILE_END = 2;

  GENERIC_READ          = LongWord($80000000);
  GENERIC_WRITE         = $40000000;
  GENERIC_EXECUTE       = $20000000;
  GENERIC_ALL           = $10000000;

  FILE_SHARE_READ       = $00000001;
  FILE_SHARE_WRITE      = $00000002;
  FILE_SHARE_DELETE     = $00000004;

  CREATE_NEW        = 1;
  CREATE_ALWAYS     = 2;
  OPEN_EXISTING     = 3;
  OPEN_ALWAYS       = 4;

  HKEY_CLASSES_ROOT     = LongWord($80000000);
  HKEY_CURRENT_USER     = LongWord($80000001);
  HKEY_LOCAL_MACHINE    = LongWord($80000002);
  HKEY_USERS            = LongWord($80000003);
  HKEY_PERFORMANCE_DATA = LongWord($80000004);
  HKEY_CURRENT_CONFIG   = LongWord($80000005);
  HKEY_DYN_DATA         = LongWord($80000006);

  REG_NONE                    = 0;
  REG_SZ                      = 1;
  REG_EXPAND_SZ               = 2;
  REG_BINARY                  = 3;
  REG_DWORD                   = 4;
  REG_DWORD_LITTLE_ENDIAN     = 4;
  REG_DWORD_BIG_ENDIAN        = 5;
  REG_LINK                    = 6;
  REG_MULTI_SZ                = 7;
  REG_RESOURCE_LIST           = 8;
  REG_FULL_RESOURCE_DESCRIPTOR = 9;
  REG_RESOURCE_REQUIREMENTS_LIST = 10;

    { Return values for ChangeDisplaySettings }
  DISP_CHANGE_SUCCESSFUL          = 0;
  DISP_CHANGE_FAILED              = -1;
  DISP_CHANGE_BADMODE             = -2;

  KEY_READ            = $20019;
  KEY_WRITE           = $20006;

  ERROR_SUCCESS       = 0;

  PM_NOREMOVE         = 0;
  PM_REMOVE           = 1;
  PM_NOYIELD          = 2;

  CS_DBLCLKS          = 8;
  CS_OWNDC            = $20;
  CS_VREDRAW          = LongWord(1);
  CS_HREDRAW          = LongWord(2);

  WHITE_BRUSH         = 0;
  LTGRAY_BRUSH        = 1;
  GRAY_BRUSH          = 2;
  DKGRAY_BRUSH        = 3;
  BLACK_BRUSH         = 4;
  NULL_BRUSH          = 5;

  SM_CXSCREEN         = 0;
  SM_CYSCREEN         = 1;
  SM_CYCAPTION        = 4;
  SM_CXDLGFRAME       = 7;
  SM_CYDLGFRAME       = 8;

  WM_QUIT             = $0012;
  WM_CLOSE            = $0010;
  WM_DESTROY          = $0002;
  WM_MOVE             = $0003;
  WM_SIZE             = $0005;
  WM_ACTIVATEAPP      = $001C;
  WA_ACTIVE           = 1;

  WM_SETICON          = $0080;
  WM_KEYDOWN          = $0100;
  WM_KEYUP            = $0101;
  WM_CHAR             = $0102;
  WM_SYSKEYDOWN       = $0104;
  WM_SYSKEYUP         = $0105;
  WM_LBUTTONDOWN      = $0201;
  WM_LBUTTONUP        = $0202;
  WM_RBUTTONDOWN      = $0204;
  WM_RBUTTONUP        = $0205;
  WM_MBUTTONDOWN      = $0207;
  WM_MBUTTONUP        = $0208;
  WM_MOUSEWHEEL       = $020A;
  WM_MOUSEMOVE        = $0200;
  WM_SETCURSOR        = $0020;
  WM_NCHITTEST        = $0084;

  WS_EX_TOPMOST       = 8;
  WS_EX_APPWINDOW     = $40000;

  WS_POPUP       = $80000000;
  WS_VISIBLE     = $10000000;
  WS_CAPTION     = $C00000;
  WS_SYSMENU     = $80000;
  WS_MINIMIZEBOX = $20000;

  GWL_STYLE = -16;

  SWP_FRAMECHANGED  = $20;
  SWP_NOOWNERZORDER = $200;

  SW_SHOW     = 5;
  SW_MINIMIZE = 6;

  CDS_TEST       = $00000002;
  CDS_FULLSCREEN = $00000004;

  DM_BITSPERPEL       = $40000;
  DM_PELSWIDTH        = $80000;
  DM_PELSHEIGHT       = $100000;
  DM_DISPLAYFREQUENCY = $400000;

  BITSPIXEL     = 12;
  PLANES        = 14;
  VREFRESH      = 116;

  // Joystick
  JOYCAPS_HASZ      = $0001;
  JOYCAPS_HASR      = $0002;
  JOYCAPS_HASU      = $0004;
  JOYCAPS_HASV      = $0008;
  JOYCAPS_HASPOV    = $0010;
  JOYCAPS_POVCTS    = $0040;

  JOY_RETURNX       = $00000001;
  JOY_RETURNY       = $00000002;
  JOY_RETURNZ       = $00000004;
  JOY_RETURNR       = $00000008;
  JOY_RETURNU       = $00000010;
  JOY_RETURNV       = $00000020;
  JOY_RETURNPOV     = $00000040;
  JOY_RETURNBUTTONS	= $00000080;
  JOY_RETURNPOVCTS	= $00000200;
  JOY_USEDEADZONE		= $00000800;
  JOY_RETURNALL     = (JOY_RETURNX or JOY_RETURNY or JOY_RETURNZ or
                       JOY_RETURNR or JOY_RETURNU or JOY_RETURNV or
                       JOY_RETURNPOV or JOY_RETURNBUTTONS);

  PFD_DOUBLEBUFFER                = $00000001;
  PFD_DRAW_TO_WINDOW              = $00000004;
  PFD_SUPPORT_OPENGL              = $00000020;

  // OpenGL
  GL_MODELVIEW                      = $1700;
  GL_PROJECTION                     = $1701;
  GL_TRIANGLES                      = $0004;
  GL_STENCIL_BUFFER_BIT             = $00000400;
  GL_DEPTH_BUFFER_BIT               = $00000100;
  GL_COLOR_BUFFER_BIT               = $00004000;
{$ENDREGION}
{$REGION 'TYPES'}
type
  HWND  = LongWord;
  HDC   = LongWord;
  HGLRC = LongWord;

  PSecurityAttributes = ^TSecurityAttributes;
  TSecurityAttributes  = record
    nLength: LongWord;
    lpSecurityDescriptor: Pointer;
    bInheritHandle: LongBool;
  end;

  POverlapped = ^TOverlapped;
  TOverlapped= record
    Internal: LongWord;
    InternalHigh: LongWord;
    Offset: LongWord;
    OffsetHigh: LongWord;
    hEvent: THandle;
  end;

  TWndClassEx = packed record
    cbSize        : LongWord;
    style         : LongWord;
    lpfnWndProc   : Pointer;
    cbClsExtra    : LongInt;
    cbWndExtra    : LongInt;
    hInstance     : LongWord;
    hIcon         : LongWord;
    hCursor       : LongWord;
    hbrBackground : LongWord;
    lpszMenuName  : PWideChar;
    lpszClassName : PWideChar;
    hIconSm       : LongWord;
  end;

  TPixelFormatDescriptor = packed record
    nSize           : Word;
    nVersion        : Word;
    dwFlags         : LongWord;
    iPixelType      : Byte;
    cColorBits      : Byte;
    Color           : array [0..7] of Byte;
    Accum           : array [0..4] of Byte;
    cDepthBits      : Byte;
    cStencilBits    : Byte;
    Other           : array [0..14] of Byte;
  end;

  POSVERSIONINFO = ^TOSVERSIONINFO;
  TOSVERSIONINFO = record
    dwOSVersionInfoSize: Longint;
    dwMajorVersion: Longint;
    dwMinorVersion: Longint;
    dwBuildNumber: Longint;
    dwPlatformId: Longint;
    szCSDVersion: array[0..127] of WideChar;
  end;

  PMemoryStatusEx = ^TMemoryStatusEx;
  TMemoryStatusEx = record
    dwLength: LongWord;
    dwMemoryLoad: LongWord;
    ullTotalPhys: UInt64;
    ullAvailPhys: UInt64;
    ullTotalPageFile: UInt64;
    ullAvailPageFile: UInt64;
    ullTotalVirtual: UInt64;
    ullAvailVirtual: UInt64;
    ullAvailExtendedVirtual: UInt64;
  end;

  TPoint = packed record
    X, Y : LongInt;
  end;

  TRect = packed record
    Left, Top, Right, Bottom : LongInt;
  end;

  TMsg = packed record
    hwnd    : HWND;
    message : LongWord;
    wParam  : LongInt;
    lParam  : LongInt;
    time    : LongWord;
    pt      : TPoint;
  end;

  PDeviceMode = ^TDeviceMode;
  TDeviceMode = record
    SomeData1 : array [0..67] of Byte;
    dmSize             : Word;
    dmDriverExtra      : Word;
    dmFields           : LongWord;
    SomeData2 : array [0..91] of Byte;
    dmBitsPerPel       : LongWord;
    dmPelsWidth        : LongWord;
    dmPelsHeight       : LongWord;
    dmDisplayFlags     : LongWord;
    dmDisplayFrequency : LongWord;
    SomeData3  : array [0..31] of Byte;
  end;

  TJoyCaps = record
    wMid, wPid   : Word;
    szPname      : array[0..31] of AnsiChar;
    wXmin, wXmax : LongWord;
    wYmin, wYmax : LongWord;
    wZmin, wZmax : LongWord;
    wNumButtons  : LongWord;
    wPMin, wPMax : LongWord;
    wRmin, wRmax : LongWord;
    wUmin, wUmax : LongWord;
    wVmin, wVmax : LongWord;
    wCaps        : LongWord;
    wMaxAxes     : LongWord;
    wNumAxes     : LongWord;
    wMaxButtons  : LongWord;
    szRegKey     : array[0..31] of AnsiChar;
    szOEMVxD     : array[0..259] of AnsiChar;
  end;

  TJoyInfoEx = record
    dwSize      : LongWord;
    dwFlags     : LongWord;
    wXpos       : LongWord;
    wYpos       : LongWord;
    wZpos       : LongWord;
    wRpos       : LongWord;
    wUpos       : LongWord;
    wVpos       : LongWord;
    wButtons    : LongWord;
    dwButtonNum : LongWord;
    dwPOV       : LongWord;
    dwRes       : array [0..1] of LongWord;
  end;
{$ENDREGION}
{$REGION 'WINDOWS API'}
  function CreateFileW(lpFileName: PWideChar; dwDesiredAccess, dwShareMode: LongWord; lpSecurityAttributes: PSecurityAttributes; dwCreationDisposition, dwFlagsAndAttributes: LongWord; hTemplateFile: THandle): THandle; stdcall; external kernel32;
  function GetFileSize(hFile: THandle; lpFileSizeHigh: Pointer): LongWord; stdcall; external kernel32;
  function CloseHandle(hObject: THandle): LongBool; stdcall; external kernel32;
  function WriteFile(hFile: THandle; const Buffer; nNumberOfBytesToWrite: LongWord; var lpNumberOfBytesWritten: LongWord; lpOverlapped: POverlapped): LongBool; stdcall; external kernel32;
  function ReadFile(hFile: THandle; var Buffer; nNumberOfBytesToRead: LongWord; var lpNumberOfBytesRead: LongWord; lpOverlapped: POverlapped): LongBool; stdcall; external kernel32;
  function SetFilePointer(hFile: THandle; lDistanceToMove: Longint; lpDistanceToMoveHigh: Pointer; dwMoveMethod: LongWord): LongWord; stdcall; external kernel32;

  function LoadCursorW(hInstance: LongInt; lpCursorName: PWideChar ): LongWord; stdcall; external user32;
  function LoadIconW(hInstance: LongInt; lpIconName: PWideChar): LongWord; stdcall; external user32;
  function RegisterClassExW(const WndClass: TWndClassEx): Word; stdcall; external user32;
  function UnregisterClassW(lpClassName: PWideChar; hInstance: HINST): LongBool; stdcall; external user32;
  function CreateWindowExW(dwExStyle: LongWord; lpClassName, lpWindowName: PWideChar;
    dwStyle: LongWord; X, Y, nWidth, nHeight: LongInt;
    hWndParent, hMenu, hInstance: LongWord; lpParam: Pointer): HWND; stdcall; external user32;
  function DestroyWindow(hWnd: HWND): Boolean; stdcall; external user32;
  function GetDC(hWnd: HWND): HDC; stdcall; external user32;
  function ReleaseDC(hWnd: HWND; hDC: HDC): LongBool; stdcall; external user32;
  function DefWindowProcW(hWnd, Msg: LongWord; wParam, lParam: LongInt): LongInt; stdcall; external user32;
  function PeekMessageW(var lpMsg: TMsg; hWnd: HWND; Min, Max, Remove: LongWord): Boolean; stdcall; external user32;
  function TranslateMessage(const lpMsg: TMsg): Boolean; stdcall; external user32;
  function DispatchMessageW(const lpMsg: TMsg): LongInt; stdcall; external user32;
  function SendMessageW(hWnd, Msg: LongWord; wParam, lParam: LongInt): LongInt; stdcall; external user32;
  function ShowWindow(hWnd: HWND; nCmdShow: LongInt): Boolean; stdcall; external user32;
  function SetWindowLongA(hWnd: HWND; nIndex, dwNewLong: LongInt): LongInt; stdcall; external user32;
  function AdjustWindowRect(var lpRect: TRect; dwStyle: LongWord; bMenu: Boolean): Boolean; stdcall; external user32;
  function SetWindowPos(hWnd, hWndInsertAfter: HWND; X, Y, cx, cy: LongInt; uFlags: LongWord): Boolean; stdcall; external user32;
  function GetWindowRect(hWnd: HWND; var lpRect: TRect): Boolean; stdcall; external user32;
  function SetWindowTextA(hWnd: HWND; Text: PAnsiChar): Boolean; stdcall; external user32;
  function GetSystemMetrics(nIndex: Integer): Integer; stdcall; external user32;

  function GetCursorPos(out Point: TPoint): Boolean; stdcall; external user32;
  function SetCursorPos(X, Y: Integer): Boolean; stdcall; external user32;
  function ShowCursor(bShow: Boolean): LongInt; stdcall; external user32;

  function EnumDisplaySettingsW(lpszDeviceName: PWideChar; iModeNum: LongWord; var lpDevMode: TDeviceMode): Boolean; stdcall; external user32;
  function ChangeDisplaySettingsExW(lpszDeviceName: PWideChar; lpDevMode: PDeviceMode;
        wnd: HWND; dwFlags: LongWord; lParam: Pointer): Longint; stdcall; external user32;

  function ChangeDisplaySettingsW(lpDevMode: PDeviceMode; dwFlags: LongWord): Longint; stdcall; external user32;

  function SwapBuffers(DC: HDC): Boolean; stdcall; external gdi32;
  function SetPixelFormat(DC: HDC; PixFormat: LongInt; FormatDef: Pointer): Boolean; stdcall; external gdi32;
  function ChoosePixelFormat(DC: HDC; FormatDef: Pointer): LongInt; stdcall; external gdi32;
  function GetStockObject(Index: Integer): LongWord; stdcall; external gdi32;
  function GetDeviceCaps(DC: HDC; Index: Integer): Integer; stdcall; external gdi32 name 'GetDeviceCaps';

  function wglCreateContext(DC: HDC): HGLRC; stdcall; external opengl32;
  function wglDeleteContext(RC: HGLRC): Boolean; stdcall; external opengl32;
  function wglMakeCurrent(DC: HDC; RC: HGLRC): Boolean; stdcall; external opengl32;
  function wglGetProcAddress(ProcName: PAnsiChar): Pointer; stdcall; external opengl32;

// System Info
  function QueryPerformanceFrequency(out Freq: Int64): Boolean; stdcall; external kernel32;
  function QueryPerformanceCounter(out Count: Int64): Boolean; stdcall; external kernel32;
  function GetVersionExW(lpVersionInformation: POSVERSIONINFO): Longint; stdcall; external kernel32;
  function GlobalMemoryStatusEx(var lpBuffer : TMEMORYSTATUSEX): LongBool; stdcall; external kernel32 name 'GlobalMemoryStatusEx';

// Reg work
  function RegCloseKey(hKey: LongWord): Longint; stdcall; external advapi32;
  function RegOpenKeyExW(hKey: LongWord; lpSubKey: PWideChar;
  ulOptions: LongWord; samDesired: LongWord; var phkResult: LongWord): Longint; stdcall; external advapi32;
  function RegQueryValueExW(hKey: LongWord; lpValueName: PWideChar;
  lpReserved: Pointer; lpType: PLongWord; lpData: PByte; lpcbData: PLongWord): Longint; stdcall; external advapi32;

// Joystick
  function joyGetNumDevs: LongWord; stdcall; external winmm;
  function joyGetDevCapsA(uJoyID: LongWord; lpCaps: Pointer; uSize: LongWord): LongWord; stdcall; external winmm;
  function joyGetPosEx(uJoyID: LongWord; lpInfo: Pointer): LongWord; stdcall; external winmm;

  function FormatPath(const Path: string): string;
  function ExtractFileDir(const Path: string): string;
{$ENDREGION}
implementation

function FormatPath(const Path: string): string;
var
  i : Integer;
begin
// eXgine path format: bla\blabla\mr.Freeman\
// nix - replace '\' -> '/'
// win - replace '/' -> '\'
  Result := Path;
  for i := 1 to Length(Result) do
    if Result[i] = '/' then
      Result[i] := '\'; 
end;

function ExtractFileDir(const Path: string): string;
var
  i : Integer;
begin
  for i := Length(Path) downto 1 do
    if (Path[i] = '\') or (Path[i] = '/') then
    begin
      Result := Copy(Path, 1, i);
      Exit;
    end;
  Result := '';
end;

end.
