unit JEN_SystemInfo;

interface

uses
  JEN_Header,
  XSystem;

type
  TRefreshRates = record
    FRefreshRates : array of Byte;

    procedure Clear;
    procedure Add(Value: Byte);
    function Count: Integer;
    function GetRefresh(Idx: Integer): Byte;
    function IsExist(Value: Byte): Boolean;

    property Rates[Idx: Integer]: Byte read GetRefresh; default;
  end;

  PDisplayMode = ^TDisplayMode;
  TDisplayMode = record
    Width        : Integer;
    Height       : Integer;
    RefreshRates : TRefreshRates;
  end;

  TDisplayModes = record
    FModes : array of TDisplayMode;

    procedure Clear;
    function Add(Width, Height: Integer; Refresh: Byte): Integer;
    function GetMode(Idx: Integer): PDisplayMode; overload;
    function GetMode(Width, Height: Integer): PDisplayMode; overload;

    property Modes[Idx: Integer]: PDisplayMode read GetMode; default;
  end;

  type IScreen = interface(JEN_Header.IScreen)
    procedure ResetMode;
  end;

  type TScreen = class(TInterfacedObject, IScreen)
    constructor Create;
    destructor Destroy; override;
  private
    var
      FModes        : TDisplayModes;
      FStartWidth   : Integer;
      FStartHeight  : Integer;
      FStartBPS     : Byte;
      FStartRefresh : Byte;
  public
    function GetWidth  : Integer; stdcall;
    function GetHeight : Integer; stdcall;
    function GetBPS    : Byte; stdcall;
    function GetRefresh: Byte; stdcall;

    function SetMode(W, H, R: integer): TSetModeResult; stdcall;
    procedure ResetMode;
  end;

  ISystemParams = interface(JEN_Header.ISystemParams)
    procedure WindowsVersion(var Major: LongInt; var Minor: LongInt; var Build: LongInt);
    function GetScreen: IScreen; stdcall;
    property Screen: IScreen read GetScreen;
  end;

  TSystem = class(TInterfacedObject, ISystemParams)
    constructor Create;
    destructor Destroy; override;
  private
  var
    fCPUName  : String;
    fCPUSpeed : LongWord;
    fScreen   : IScreen;

    function GetRAMTotal: Cardinal; stdcall;
    function GetRAMFree: Cardinal; stdcall;
    function GetCPUCount: Integer; stdcall;
    function GetCPUName: String; stdcall;
    function GetCPUSpeed: LongWord; stdcall;
    function GetScreen: IScreen; stdcall;
  public
    procedure WindowsVersion(var Major: LongInt; var Minor: LongInt; var Build: LongInt);
  end;

implementation

uses
  JEN_MAIN;

procedure TRefreshRates.Add(Value: Byte);
var
  Idx, i: integer;
begin
  Idx := -1;

  for i := 0 to High(FRefreshRates) do
    if FRefreshRates[i] = Value then
      Idx := i;

  if Idx = -1 then
  begin
    Idx := High(FRefreshRates) + 1;
    SetLength(FRefreshRates, Idx + 1);
  end;

  FRefreshRates[Idx] := Value;
end;

function TRefreshRates.Count: Integer;
begin
  Result := Length(FRefreshRates);
end;

function TRefreshRates.GetRefresh(Idx: Integer): Byte;
begin
  if (Idx < 0) or (Idx > High(FRefreshRates)) then Exit(0);
  Result := FRefreshRates[Idx];
end;

function TRefreshRates.IsExist(Value: Byte): Boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to High(FRefreshRates) do
    if FRefreshRates[i] = Value then
      Exit(True);
end;

procedure TRefreshRates.Clear;
begin
  SetLength(FRefreshRates,0);
end;

procedure TDisplayModes.Clear;
var
  i : integer;
begin
  for i := 0 to High(FModes) do
    FModes[i].RefreshRates.Clear;
  SetLength(FModes, 0);
end;

function TDisplayModes.Add(Width, Height: Integer; Refresh: Byte): integer;
var
  i : integer;
begin
  Result := -1;

  for i := 0 to High(FModes) do
    if (FModes[i].Width = Width) and
       (FModes[i].Height = Height) then
      Result := i;

  if Result = -1  then
  begin
    Result := High(FModes)+1;
    SetLength(FModes, Result + 1);
    FModes[Result].Width := Width;
    FModes[Result].Height := Height;
  end;

  FModes[Result].RefreshRates.Add(Refresh);
end;

function TDisplayModes.GetMode(Idx: Integer): PDisplayMode;
begin
  if (Idx < 0) or (Idx > High(FModes)) then
    Exit(nil);
  Result := @FModes[Idx];
end;

function TDisplayModes.GetMode(Width, Height: Integer): PDisplayMode;
var
  i : Integer;
begin
  Result := nil;
  for i := 0 to High(FModes) do
    if (FModes[i].Width = Width) and
       (FModes[i].Height = Height) then
      Result := @FModes[i];
end;

constructor TScreen.Create;
var
  DevMode : TDeviceMode;
  i  : Integer;
begin
  i := 0;
  SetLength(FModes.FModes, 0);

  FStartWidth   := GetWidth;
  FStartHeight  := GetHeight;
  FStartBPS     := GetBPS;
  FStartRefresh := GetRefresh;

  FillChar(DevMode, SizeOf(TDeviceMode), 0);
  DevMode.dmSize := SizeOf(TDeviceMode);

  while EnumDisplaySettingsW(nil, i, DevMode) <> FALSE do
  with DevMode do
    begin
      INC(i);

      if dmBitsPerPel <> 32 then
        Continue;

      FModes.Add(dmPelsWidth, dmPelsHeight, dmDisplayFrequency);
     end;
end;

destructor TScreen.Destroy;
begin
  FModes.Clear;
  inherited;
end;

function TScreen.SetMode(W, H, R: integer): TSetModeResult;
var
  DevMode      : TDeviceMode;
 // RefreshRates : PRefreshRateArray;
  Mode         : PDisplayMode;
  Str          : String;
begin
  Mode := FModes.GetMode(W, H);

  if Mode <> nil then
  begin
    if not Mode^.RefreshRates.IsExist(R) then
      R := 0;
  end else
  begin
    LogOut('Error set display mode ' + Utils.IntToStr(W) + 'x' + Utils.IntToStr(H) + 'x' + Utils.IntToStr(R), lmWarning);
    LogOut('Change display mode to default 1024x768x60', lmNotify);

    if Assigned(FModes.GetMode(1024, 768)) then
    begin
      if SetMode(1024, 768, 60) = SM_Successful then
        Exit(SM_SetDefault)
      else
        Exit(SM_Error);
    end else
    begin
      LogOut('Display mode critical error', lmError);
      Exit(SM_Error);
    end;
  end;

  if R = 0 then
    with Mode^.RefreshRates do
      R := Rates[Count-1];

  if ( (GetWidth = Mode.Width) and
       (GetHeight = Mode.Height) and
       (GetBPS = 32) and
       (GetRefresh = R) ) then
       Exit(SM_Successful);

  FillChar(DevMode, SizeOf(TDeviceMode), 0);
  DevMode.dmSize := SizeOf(TDeviceMode);

  EnumDisplaySettingsW(nil, 0, DevMode);
  with DevMode do
  begin
    dmPelsWidth        := Mode.Width;
    dmPelsHeight       := Mode.Height;
    dmBitsPerPel       := 32;
    if R <> 0 then
      dmDisplayFrequency := R;
    dmFields           := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT or DM_DISPLAYFREQUENCY ;
  end;

  Str := ' ' + Utils.IntToStr(Mode.Width) + 'x' + Utils.IntToStr(Mode.Height) + 'x' + Utils.IntToStr(R);

  case ChangeDisplaySettingsExW( nil, @DevMode, 0, $04, nil ) of
    DISP_CHANGE_SUCCESSFUL :
    begin
      LogOut('Successful set display mode ' + Str, lmNotify);
      Exit(SM_Successful);
    end;
    DISP_CHANGE_FAILED :
      LogOut('Failed set display mode ' + Str, lmError);
    DISP_CHANGE_BADMODE :
      LogOut('Failed set display mode ' + Str + ' bad mode', lmError);
    else
      LogOut('Failed set display mode ' + Str + ' uncnown error', lmError);
  end;

  Result := SM_Error;
end;

procedure TScreen.ResetMode;
begin
  if ( (GetWidth = fStartWidth) and
       (GetHeight = fStartHeight) and
       (GetBPS = fStartBPS) and
       (GetRefresh = fStartRefresh) ) then
        Exit;

  ChangeDisplaySettingsExW(nil, nil, 0, 0, nil);
  LogOut('Reset display mode to default', lmNotify);
end;

function TScreen.GetWidth: Integer;
begin
  Result := GetSystemMetrics(SM_CXSCREEN);
end;

function TScreen.GetHeight: Integer;
begin
  Result := GetSystemMetrics(SM_CYSCREEN);
end;

function TScreen.GetBPS: Byte;
var
  DC: HDC;
begin
  DC := GetDC(0);
  Result := GetDeviceCaps(DC, BITSPIXEL) * GetDeviceCaps(DC, PLANES);
  ReleaseDC(0, DC);
end;

function TScreen.GetRefresh : Byte;
var
  DC: HDC;
begin
  DC := GetDC(0);
  Result := GetDeviceCaps(DC, VREFRESH);
  ReleaseDC(0, DC);
end;

constructor TSystem.Create;
var
  Handle     : LongWord;
  DataType   : LongWord;
	DataSize   : LongWord;
  Res        : LongWord;
begin
  fScreen := TScreen.Create;

  FCPUSpeed := 0;
  FCPUName  :='Couldn''t get CPU name!';
  DataSize  := 0;

  Res := RegOpenKeyExW(HKEY_LOCAL_MACHINE, 'HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0', 0, KEY_READ, &Handle);
  if Res <> ERROR_SUCCESS then
  begin
    RegCloseKey(Handle);
    Exit;
  end;

	Res := RegQueryValueExW(Handle,	'ProcessorNameString', nil, @DataType, nil,	@DataSize);
  if (Res <> ERROR_SUCCESS) or (DataType <> REG_SZ) or (DataSize = 0)  then
  begin
    RegCloseKey(Handle);
    Exit;
  end;

  SetLength(FCPUName,DataSize div 2);
  RegQueryValueExW(Handle, 'ProcessorNameString', nil, @DataType, PByte(@FCPUName[1]), @DataSize);

	DataSize := SizeOf(LongWord);
	RegQueryValueExW(Handle, '~MHz', nil, @DataType, @FCPUSpeed,	@DataSize);
  RegCloseKey(Handle);
end;

destructor TSystem.Destroy;
begin
  inherited;
end;

procedure TSystem.WindowsVersion(var Major: LongInt; var Minor: LongInt; var Build: LongInt);
var
  OSVerInfo: TOSVERSIONINFO;
begin
  fillchar(OSVerInfo, SizeOf(TOSVERSIONINFO), 0);
  OSVerInfo.dwOSVersionInfoSize := SizeOf(TOSVERSIONINFO);
  GetVersionExW(@OSVerInfo);
  Major := OSVerInfo.dwMajorVersion;
  Minor := OSVerInfo.dwMinorVersion;
  Build := OSVerInfo.dwBuildNumber;
end;

function TSystem.GetCPUCount: integer;
begin
  Result := System.CPUCount;
end;

function TSystem.GetCPUName: String;
begin
  Result := fCPUName;
end;

function TSystem.GetCPUSpeed: LongWord;
begin
  Result := fCPUSpeed;
end;

function TSystem.GetScreen: IScreen;
begin
  Result := fScreen;
end;

function TSystem.GetRAMTotal: Cardinal;
var
  MemStatus : TMemoryStatusEx;
begin
  MemStatus.dwLength := SizeOf(TMemoryStatusEx);
  GlobalMemoryStatusEx(MemStatus);
  Result := Trunc(MemStatus.ullTotalPhys/(1024*1024)+1);
end;

function TSystem.GetRAMFree: Cardinal;
var
  MemStatus : TMemoryStatusEx;
begin
  MemStatus.dwLength := SizeOf(TMemoryStatusEx);
  GlobalMemoryStatusEx(MemStatus);
  Result := Trunc(MemStatus.ullAvailPhys/(1024*1024)+1);
end;

end.
