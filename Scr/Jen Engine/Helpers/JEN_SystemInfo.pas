unit JEN_SystemInfo;

interface

uses
  JEN_Header,
  JEN_Math,
  Windows,
  SysUtils;

type
  PDisplayMode = ^TDisplayMode;
  TDisplayMode = record
    Width        : LongInt;
    Height       : LongInt;
    RefreshRates : IList;
  end;

  type TScreen = class(TInterfacedObject, IScreen)
    constructor Create;
    destructor Destroy; override;
  private
    FModes        : IList;
    FStartWidth   : LongInt;
    FStartHeight  : LongInt;
    FStartBPS     : Byte;
    FStartRefresh : Byte;
    function GetWidth: LongInt; stdcall;
    function GetHeight: LongInt; stdcall;
    function GetBPS: Byte; stdcall;
    function GetRefresh: Byte; stdcall;
    function GetDesktopRect: TRecti; stdcall;
  public
    function SetMode(W, H, R: LongInt): Boolean; stdcall;
    procedure ResetMode; stdcall;
  end;

  TRegHandle = class
    destructor Destroy; override;
  private
    Handle: HKEY;
    FValid: Boolean;
  public
    function OpenPath(const Path: UnicodeString): Boolean;
    function ReadWord(const Name: UnicodeString): LongWord;
    function ReadString(const Name: UnicodeString): UnicodeString; overload;
    procedure ReadString(const Name: UnicodeString; out Value: PWideChar); overload;
  end;

  TSystem = class(TInterfacedObject, ISystemInfo)
    constructor Create;
    destructor Destroy; override;
  private
    FCPUName  : UnicodeString;
    FCPUCount : LongInt;
    FCPUSpeed : LongWord;
    FScreen   : IScreen;
    FGPUList  : IList;

    function GetGpuList: IList; stdcall;
    function GetRAMTotal: LongWord; stdcall;
    function GetRAMFree: LongWord; stdcall;
    function GetCPUCount: LongInt; stdcall;
    function GetCPUName: PWideChar; stdcall;
    function GetCPUSpeed: LongWord; stdcall;
    function GetScreen: IScreen; stdcall;
  public
    procedure WindowsVersion(out Major: LongInt;out Minor: LongInt;out Build: LongInt); stdcall;
  end;

implementation

uses
  JEN_Helpers,
  JEN_MAIN;

{$REGION 'TScreen'}
constructor TScreen.Create;
var
  DevMode : TDeviceMode;
  i,j     : LongInt;
  Add     : Boolean;
  PMode   : PDisplayMode;
  PRefresh : PByte;

  procedure AddRefresh(mode : PDisplayMode; refresh: Byte);
  var
    k : LongInt;
  begin
    with(PDisplayMode(mode)^) do
    begin
      Add := True;
      for K := 0 to RefreshRates.Count - 1 do
        if(PByte(RefreshRates[K])^ = refresh) then
          Exit;

      GetMem(PRefresh, 1);
      PRefresh^ := refresh;
      RefreshRates.Add(PRefresh);
    end;
  end;

begin
  i := 0;
  FModes := TList.Create;

  FStartWidth   := GetWidth;
  FStartHeight  := GetHeight;
  FStartBPS     := GetBPS;
  FStartRefresh := GetRefresh;

  FillChar(DevMode, SizeOf(TDeviceMode), 0);
  DevMode.dmSize := SizeOf(TDeviceMode);

  while EnumDisplaySettings(nil, i, DevMode) <> FALSE do
  with DevMode do
  begin
    INC(i);

    if dmBitsPerPel <> 32 then
      Continue;

    Add := True;
    for J := 0 to FModes.Count - 1 do
      with(PDisplayMode(FModes[j])^) do
      if (Width = dmPelsWidth) and (Height = dmPelsHeight) then
      begin
        Add := False;
        AddRefresh(FModes[j], dmDisplayFrequency);
        Break;
      end;

    if Add then
    begin
      GetMem(PMode, SizeOf(TDisplayMode));

      PMode^.Width := dmPelsWidth;
      PMode^.Height := dmPelsHeight;
      PMode^.RefreshRates := TList.Create;
      FModes.Add(PMode);
      AddRefresh(PMode, dmDisplayFrequency);
    end;

  end;

end;

destructor TScreen.Destroy;
var
  i,j : LongInt;
begin
  for I := 0 to FModes.Count - 1 do
  with(PDisplayMode(FModes[I])^) do
  begin
    for J := 0 to RefreshRates.Count - 1 do
      FreeMem(RefreshRates[J]);

    PDisplayMode(FModes[I])^.RefreshRates := nil;
    FreeMem(FModes[I]);
  end;
  FModes := nil;
  inherited;
end;

function TScreen.SetMode(W, H, R: LongInt): Boolean;
var
  DevMode : TDeviceMode;
  i       : LongInt;
  Mode    : PDisplayMode;
  Str     : UnicodeString;
begin
  Result := False;
  Mode   := nil;

  for I := 0 to FModes.Count - 1 do
    with(PDisplayMode(FModes[I])^) do
      if (Width = W) and (Height = H) then
      begin
        Mode := FModes[I];
        break;
      end;

  if Assigned(Mode) then
  begin
    for I := 0 to Mode^.RefreshRates.Count - 1 do
      if PByte(Mode^.RefreshRates[i])^ = R then
        break;

    if I = Mode^.RefreshRates.Count then
      R := 0;
  end else
  begin
    Engine.Warning('Failed to Set Display Mode' + IntToStr(W) + 'x' + IntToStr(H) + 'x' + IntToStr(R));
    Engine.Log('Change display mode to default 1024x768x60');

    if ((W = 1024) and (H = 768) and ((R = 60) or (R = 0))) then
      Engine.Error('Critical error set display mode')
    else
      SetMode(1024, 768, 60);
    Exit;
  end;

  if R = 0 then
    with Mode^.RefreshRates do
      R := PByte(Mode^.RefreshRates[Mode^.RefreshRates.Count-1])^;

  if((GetWidth = Mode.Width) and (GetHeight = Mode.Height) and (GetBPS = 32) and (GetRefresh = R)) then
    Exit(True);

  FillChar(DevMode, SizeOf(TDeviceMode), 0);
  DevMode.dmSize := SizeOf(TDeviceMode);

  EnumDisplaySettings(nil, 0, DevMode);
  with DevMode do
  begin
    dmPelsWidth        := Mode.Width;
    dmPelsHeight       := Mode.Height;
    dmBitsPerPel       := 32;
    if R <> 0 then
      dmDisplayFrequency := R;
    dmFields           := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT or DM_DISPLAYFREQUENCY ;
  end;

  Str := ' ' + IntToStr(Mode.Width) + 'x' + IntToStr(Mode.Height) + 'x' + IntToStr(R);

  case ChangeDisplaySettingsEx(nil, DevMode, 0, $04, nil) of
    DISP_CHANGE_SUCCESSFUL :
    begin
      Engine.Log('Successful set display mode ' + Str);
      Exit(True);
    end;
    DISP_CHANGE_FAILED :
      Engine.Error('Failed set display mode ' + Str);
    DISP_CHANGE_BADMODE :
      Engine.Error('Failed set display mode ' + Str + ' bad mode');
    else
      Engine.Error('Failed set display mode ' + Str + ' uncnown error');
  end;
end;

procedure TScreen.ResetMode;
var
  DevMode : TDeviceMode;
begin
  if ( (GetWidth = fStartWidth) and
       (GetHeight = fStartHeight) and
       (GetBPS = fStartBPS) and
       (GetRefresh = fStartRefresh) ) then
        Exit;

  FillChar(DevMode, SizeOf(TDeviceMode), 0);
  DevMode.dmSize := SizeOf(TDeviceMode);

  ChangeDisplaySettingsEx(nil, DevMode, 0, 0, nil);
  Engine.Log('Reset display mode to default');
end;

function TScreen.GetWidth: LongInt;
begin
  Result := GetSystemMetrics(SM_CXSCREEN);
end;

function TScreen.GetHeight: LongInt;
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

function TScreen.GetRefresh: Byte;
var
  DC: HDC;
begin
  DC := GetDC(0);
  Result := GetDeviceCaps(DC, VREFRESH);
  ReleaseDC(0, DC);
end;

function TScreen.GetDesktopRect: TRecti;
var
  DR: TRect;
begin
  SystemParametersInfo(SPI_GETWORKAREA, 0, @DR, 0);
  Result.Location.X := Dr.Left;
  Result.Location.Y := Dr.Top;
  Result.Width := Dr.Right - Dr.Left;
  Result.Height := Dr.Bottom - Dr.Top;
end;
{$ENDREGION}

{$REGION 'TRegHandle'}
destructor TRegHandle.Destroy;
begin
  if FValid then
    RegCloseKey(Handle);
end;

function TRegHandle.OpenPath(const Path: UnicodeString): Boolean;
begin
  if FValid then
    RegCloseKey(Handle);

  FValid := RegOpenKeyExW(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS;
  Result := FValid;
end;

function TRegHandle.ReadString(const Name: UnicodeString): UnicodeString;
var
  DataType : DWORD;
  DataSize : DWORD;
begin
  DataSize := 0;
  if (RegQueryValueExW(Handle, @Name[1], nil, @DataType, nil,	@DataSize) <> ERROR_SUCCESS){ or (DataType <> REG_SZ) }or (DataSize = 0) then
    Exit;

  Result := '';
  SetLength(Result, DataSize div 2 - 1);
  RegQueryValueExW(Handle, @Name[1], nil, @DataType, @Result[1], @DataSize);
end;

procedure TRegHandle.ReadString(const Name: UnicodeString; out Value: PWideChar);
var
  Str : UnicodeString;
begin
  Str := ReadString(Name);
  if Str <> '' then
  begin
    GetMem(Value, (Length(Str)+1)*SizeOf(WideChar));
    Move(Str[1], Value^, (Length(Str)+1)*SizeOf(WideChar));
  end;
end;

function TRegHandle.ReadWord(const Name: UnicodeString): LongWord;
var
  DataType : DWORD;
  DataSize : DWORD;
begin
  Result := 0;
  DataSize := SizeOf(LongWord);
  RegQueryValueExW(Handle, @Name[1], nil, @DataType, @Result, @DataSize);
end;
{$ENDREGION}

{$REGION 'TSystem'}
constructor TSystem.Create;
var
  i           : Integer;
  Handle      : TRegHandle;
  Driver      : UnicodeString;
  Str         : UnicodeString;
  DeviceList  : IList;
  Path        : UnicodeString;
  GPUInfo     : PGPUInfo;
  SysInfo     : TSystemInfo;

  procedure EnumAllDevice(List: IList; const Path: UnicodeString; Depth: Byte = 1);
  var
    i        : Integer;
    Handle   : TRegHandle;
    Count    : DWORD;
    P        : PWideChar;
    DataSize : DWORD;
    Size     : DWORD;
  begin

    if Depth = 4 then
    begin
      GetMem(P, (Length(Path)+1)*SizeOf(WideChar));
      Move(Path[1], P^, (Length(Path)+1)*SizeOf(WideChar));
      List.Add(P);
    end;

    Handle := TRegHandle.Create;
    DataSize := 0;

    if Handle.OpenPath(Path) and
       (RegQueryInfoKeyW(Handle.Handle, nil, nil, nil, @Count, @DataSize, nil, nil, nil, nil, nil, nil) = ERROR_SUCCESS) and
         (Count > 0) then
    begin
      inc(DataSize);
      GetMem(P, DataSize*2);

      for i := 0 to Count-1 do
      begin
        //Everytime Size be read and write new value in RegEnumKeyEx
        Size := DataSize; //We fix it
        if RegEnumKeyExW(Handle.Handle, i, P, Size, nil, nil, nil, nil) = ERROR_SUCCESS then
           EnumAllDevice(List, Path + '\' + P, Depth + 1);
      end;

      FreeMem(P);
    end;

    Handle.Free;
  end;

begin
  FScreen := TScreen.Create;
  FGPUList := TList.Create;
  DeviceList := TList.Create;

  GetSystemInfo(SysInfo);
  FCpuCount := SysInfo.dwNumberOfProcessors;
  FCPUSpeed := 0;
  FCPUName  := 'Couldn''t get CPU name!';

  Handle := TRegHandle.Create;
  if Handle.OpenPath('HARDWARE\DESCRIPTION\System\CentralProcessor\0') then
  begin
    FCPUName := Handle.ReadString('ProcessorNameString');
    FCPUSpeed := Handle.ReadWord('~MHz');
  end;

  EnumAllDevice(DeviceList, 'SYSTEM\CurrentControlSet\Enum');
  for i := 0 to DeviceList.Count - 1 do
  begin
    if (Handle.OpenPath(PWideChar(DeviceList[i]))) and
          (LowerCase(Handle.ReadString('ClassGUID')) = '{4d36e968-e325-11ce-bfc1-08002be10318}') then
    begin
      Driver := Handle.ReadString('Driver');

      Path := 'SYSTEM\CurrentControlSet\Services\' + Handle.ReadString('Service') + '\Device0';
      if Handle.OpenPath(Path) and (Handle.ReadString('HardwareInformation.DacType') = '') then
      begin
        if Handle.OpenPath(PWideChar(DeviceList[i]) + '\Device Parameters') then
          Path := 'SYSTEM\CurrentControlSet\Control\Video\' + Handle.ReadString('VideoID') + '\0000';
      end;

      if Handle.OpenPath(Path) then
      begin
        if Handle.ReadString('Device Description') = '' then
          Handle.OpenPath(Path + '\Settings\');

        if Handle.ReadString('Device Description') <> ''  then
        begin
          GetMem(GPUInfo, SizeOf(TGPUInfo));
          FillChar(GPUInfo^, SizeOf(TGPUInfo), 0);

          with GPUInfo^ do
          begin
            Handle.ReadString('Device Description', Description);
            Handle.ReadString('HardwareInformation.AdapterString', ChipType);
            MemorySize := Handle.ReadWord('HardwareInformation.MemorySize') div (1024*1024);

            if Handle.OpenPath('SYSTEM\CurrentControlSet\Control\Class\' + Driver) then
            begin
              Handle.ReadString('DriverVersion', DriverVersion);
              Handle.ReadString('DriverDate', DriverDate);
            end;
          end;

          FGPUList.Add(GPUInfo);
        end;
      end;
    end;

    FreeMem(DeviceList[i]);
  end;

  Handle.Free;
end;

destructor TSystem.Destroy;
var
  i : Integer;
begin
  for i := 0 to FGPUList.Count - 1 do
  begin
    with PGPUInfo(FGPUList[i])^ do
    begin
      FreeMem(Description);
      FreeMem(ChipType);
      FreeMem(DriverVersion);
      FreeMem(DriverDate);
    end;
    FreeMem(FGPUList[i]);
  end;

  FScreen := nil;
  inherited;
end;

procedure TSystem.WindowsVersion(out Major: LongInt;out Minor: LongInt;out Build: LongInt);
var
  OSVerInfo: TOSVERSIONINFO;
begin
  fillchar(OSVerInfo, SizeOf(TOSVERSIONINFO), 0);
  OSVerInfo.dwOSVersionInfoSize := SizeOf(TOSVERSIONINFO);
  GetVersionEx(OSVerInfo);
  Major := OSVerInfo.dwMajorVersion;
  Minor := OSVerInfo.dwMinorVersion;
  Build := OSVerInfo.dwBuildNumber;
end;

function TSystem.GetCPUCount: LongInt;
begin
  Result := FCPUCount;
end;

function TSystem.GetCPUName: PWideChar;
begin
  Result := PWideChar(FCPUName);
end;

function TSystem.GetCPUSpeed: LongWord;
begin
  Result := FCPUSpeed;
end;

function TSystem.GetScreen: IScreen;
begin
  Result := FScreen;
end;

function TSystem.GetGpuList: IList; stdcall;
begin
  Result := FGPUList;
end;

function TSystem.GetRAMTotal: LongWord;
var
  MemStatus : TMemoryStatusEx;
begin
  MemStatus.dwLength := SizeOf(TMemoryStatusEx);
  GlobalMemoryStatusEx(MemStatus);
  Result := Trunc(MemStatus.ullTotalPhys/(1024*1024)+1);
end;

function TSystem.GetRAMFree: LongWord;
var
  MemStatus : TMemoryStatusEx;
begin
  MemStatus.dwLength := SizeOf(TMemoryStatusEx);
  GlobalMemoryStatusEx(MemStatus);
  Result := Trunc(MemStatus.ullAvailPhys/(1024*1024)+1);
end;
{$ENDREGION}

end.
