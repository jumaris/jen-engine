unit JEN_SystemInfo;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_Utils,
  Windows;

type
  TRefreshRates = record
    FRefreshRates : array of Byte;

    procedure Clear;
    procedure Add(Value: Byte);
    function Count: LongInt;
    function GetRefresh(Idx: LongInt): Byte;
    function IsExist(Value: Byte): Boolean;

    property Rates[Idx: LongInt]: Byte read GetRefresh; default;
  end;

  PDisplayMode = ^TDisplayMode;
  TDisplayMode = record
    Width        : LongInt;
    Height       : LongInt;
    RefreshRates : TRefreshRates;
  end;

  TDisplayModes = record
    FModes : array of TDisplayMode;

    procedure Clear;
    function Add(Width, Height: LongInt; Refresh: Byte): LongInt;
    function GetMode(Idx: LongInt): PDisplayMode; overload;
    function GetMode(Width, Height: LongInt): PDisplayMode; overload;

    property Modes[Idx: Integer]: PDisplayMode read GetMode; default;
  end;

  type TScreen = class(TInterfacedObject, IScreen)
    constructor Create;
    destructor Destroy; override;
  private
    FModes        : TDisplayModes;
    FStartWidth   : LongInt;
    FStartHeight  : LongInt;
    FStartBPS     : Byte;
    FStartRefresh : Byte;
    function GetWidth  : LongInt; stdcall;
    function GetHeight : LongInt; stdcall;
    function GetBPS    : Byte; stdcall;
    function GetRefresh: Byte; stdcall;
    function GetDesktopRect : TRecti; stdcall;
  public
    function SetMode(W, H, R: LongInt): TSetModeResult; stdcall;
    procedure ResetMode; stdcall;
  end;

  TSystem = class(TInterfacedObject, ISystemInfo)
    constructor Create;
    destructor Destroy; override;
  private
  var
    FCPUName  : String;
    FCPUSpeed : LongWord;
    FScreen   : IScreen;
    FGPUList  : IList;

    function GetGpuList: IList; stdcall;
    function GetRAMTotal: LongWord; stdcall;
    function GetRAMFree: LongWord; stdcall;
    function GetCPUCount: LongInt; stdcall;
    function GetCPUName: String; stdcall;
    function GetCPUSpeed: LongWord; stdcall;
    function GetScreen: IScreen; stdcall;
  public
    procedure WindowsVersion(out Major: LongInt;out Minor: LongInt;out Build: LongInt); stdcall;
  end;

implementation

uses
  JEN_MAIN;

procedure TRefreshRates.Add(Value: Byte);
var
  Idx, i: LongInt;
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

function TRefreshRates.Count: LongInt;
begin
  Result := Length(FRefreshRates);
end;

function TRefreshRates.GetRefresh(Idx: LongInt): Byte;
begin
  if (Idx < 0) or (Idx > High(FRefreshRates)) then Exit(0);
  Result := FRefreshRates[Idx];
end;

function TRefreshRates.IsExist(Value: Byte): Boolean;
var
  i: LongInt;
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
  i : LongInt;
begin
  for i := 0 to High(FModes) do
    FModes[i].RefreshRates.Clear;
  SetLength(FModes, 0);
end;

function TDisplayModes.Add(Width, Height: LongInt; Refresh: Byte): LongInt;
var
  i : LongInt;
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

function TDisplayModes.GetMode(Idx: LongInt): PDisplayMode;
begin
  if (Idx < 0) or (Idx > High(FModes)) then
    Exit(nil);
  Result := @FModes[Idx];
end;

function TDisplayModes.GetMode(Width, Height: LongInt): PDisplayMode;
var
  i : LongInt;
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
  i : LongInt;
begin
  i := 0;
  SetLength(FModes.FModes, 0);

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

      FModes.Add(dmPelsWidth, dmPelsHeight, dmDisplayFrequency);
     end;
end;

destructor TScreen.Destroy;
begin
  FModes.Clear;
  inherited;
end;

function TScreen.SetMode(W, H, R: LongInt): TSetModeResult;
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

  Str := ' ' + Utils.IntToStr(Mode.Width) + 'x' + Utils.IntToStr(Mode.Height) + 'x' + Utils.IntToStr(R);

  case ChangeDisplaySettingsEx(nil, DevMode, 0, $04, nil) of
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
  LogOut('Reset display mode to default', lmNotify);
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
  SystemParametersInfo(SPI_GETWORKAREA, 0, DR, 0);
  Result.X := Dr.Left;
  Result.Y := Dr.Top;
  Result.Width := Dr.Right - Dr.Left;
  Result.Height := Dr.Bottom - Dr.Top;
end;

constructor TSystem.Create;
var
  i           : Integer;
  Handle      : HKEY;
  Driver      : string;
  Str         : string;
  DeviceList  : IList;
  Path        : string;
  GPUInfo     : PGPUInfo;

  procedure RegReadString(Handle: HKEY; const Name: string; var Value: string);
  var
    DataType : DWORD;
	  DataSize : DWORD;
  begin
    Value := #0;
    DataSize := 0;
    if (RegQueryValueEx(Handle,	@Name[1], nil, @DataType, nil,	@DataSize) <> ERROR_SUCCESS){ or (DataType <> REG_SZ) }or (DataSize = 0) then
      Exit;

    SetLength(Value, DataSize div 2 - 1);
    RegQueryValueEx(Handle, @Name[1], nil, @DataType, @Value[1], @DataSize);
  end;

  procedure RegReadWord(Handle: HKEY; const Name: String; var Value: LongWord);
  var
    DataType : DWORD;
	  DataSize : DWORD;
  begin
    Value := 0;
    DataSize := SizeOf(LongWord);
    RegQueryValueEx(Handle, @Name[1], nil, @DataType, @Value, @DataSize);
  end;

  procedure EnumAllDevice(List: IList; const Path: string; Depth: Byte = 1);
  var
    i        : Integer;
    p        : Pointer;
    Handle   : HKEY;
    Count    : DWORD;
    Str      : String;
    DataSize : DWORD;
  begin
    DataSize := 0;
    if RegOpenKeyEx(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS then
    if RegQueryInfoKey(Handle, nil, nil, nil, @Count, @DataSize, nil, nil, nil, nil, nil, nil) = ERROR_SUCCESS then
      for i := 0 to Count-1 do
      begin
        Inc(DataSize);
        GetMem(p, DataSize*2);
        if RegEnumKeyEx(Handle, i, p, DataSize, nil, nil, nil, nil) = ERROR_SUCCESS then
        begin
          Str := Path + '\' + pchar(p);
          FreeMem(p);
          if Depth = 3 then
          begin
            GetMem(p, (Length(Str)+1)*2);
            CopyMemory(p, @Str[1], (Length(Str)+1)*2);
            List.Add(p);
          end else
            EnumAllDevice(List, Str, Depth + 1);
        end else
          FreeMem(p);
      end;
    RegCloseKey(Handle);
  end;

begin
  FScreen := TScreen.Create;
  FGPUList := TList.Create;

  FCPUSpeed := 0;
  FCPUName  :='Couldn''t get CPU name!';

  if RegOpenKeyEx(HKEY_LOCAL_MACHINE, 'HARDWARE\DESCRIPTION\System\CentralProcessor\0', 0, KEY_READ, Handle) = ERROR_SUCCESS then
  begin
    RegReadString(Handle, 'ProcessorNameString', FCPUName);
    RegReadWord(Handle, '~MHz', FCPUSpeed);
  end;
  RegCloseKey(Handle);

  DeviceList := TList.Create;
  EnumAllDevice(DeviceList, 'SYSTEM\CurrentControlSet\Enum');
  for i := 0 to DeviceList.Count - 1 do
  begin
    RegOpenKeyEx(HKEY_LOCAL_MACHINE, DeviceList[i], 0, KEY_READ, Handle);
    RegReadString(Handle, 'Class', Str);
    RegCloseKey(Handle);

    if LowerCase(Str) = 'display' then
    begin
      RegOpenKeyEx(HKEY_LOCAL_MACHINE, DeviceList[i], 0, KEY_READ, Handle);
      RegReadString(Handle, 'Service', Str);
      RegReadString(Handle, 'Driver', Driver);
      RegCloseKey(Handle);

      Path := 'SYSTEM\CurrentControlSet\Services\' + Str + '\Device0';
      if RegOpenKeyEx(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS then
      begin
        RegReadString(Handle, 'HardwareInformation.DacType', Str);
        if Str = #0 then
        begin
          Path := PChar(DeviceList[i]) + '\Device Parameters';
          RegCloseKey(Handle);
          if RegOpenKeyEx(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS then
            RegReadString(Handle, 'VideoID', Str);
          Path := 'SYSTEM\CurrentControlSet\Control\Video\' + Str + '\0000';
        end;
      end;
      RegCloseKey(Handle);

      GetMem(GPUInfo, SizeOf(TGPUInfo));
      GPUInfo^.Description:=nil;

      if RegOpenKeyEx(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS then
      with GPUInfo^ do
        begin
          RegReadString(Handle, 'Device Description', Str);
          GetMem(Description, (Length(Str)+1)*2);
          CopyMemory(Description, @Str[1], (Length(Str)+1)*2);

          RegReadString(Handle, 'HardwareInformation.ChipType', Str);
          GetMem(ChipType, (Length(Str)+1)*2);
          CopyMemory(ChipType, @Str[1], (Length(Str)+1)*2);

          RegReadWord(Handle, 'HardwareInformation.MemorySize', MemorySize);
          MemorySize := MemorySize div (1024*1024);
        end;
      RegCloseKey(Handle);

      Path := 'SYSTEM\CurrentControlSet\Control\Class\' + Driver;
      if RegOpenKeyEx(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS then
      with GPUInfo^ do
      begin
        RegReadString(Handle, 'DriverVersion', Str);
        GetMem(DriverVersion, (Length(Str)+1)*2);
        CopyMemory(DriverVersion, @Str[1], (Length(Str)+1)*2);

        RegReadString(Handle, 'DriverDate', Str);
        GetMem(DriverDate, (Length(Str)+1)*2);
        CopyMemory(DriverDate, @Str[1], (Length(Str)+1)*2);
      end;
      RegCloseKey(Handle);

      FGPUList.Add(GPUInfo);
    end;

    FreeMem(DeviceList[i]);
  end;

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
  Result := System.CPUCount;
end;

function TSystem.GetCPUName: String;
begin
  Result := FCPUName;
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

end.
