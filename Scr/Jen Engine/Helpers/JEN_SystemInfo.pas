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

constructor TScreen.Create;
var
  DevMode : TDeviceMode;
  i,j,k   : LongInt;
  PMode   : PDisplayMode;
  PRefresh : PByte;
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

    for J := 0 to FModes.Count - 1 do
      with(PDisplayMode(FModes[j])^) do
      if (Width = dmPelsWidth) and (Height = dmPelsHeight) then
      begin

        for K := 0 to RefreshRates.Count - 1 do
          if(PByte(RefreshRates[K])^ = dmDisplayFrequency) then
            Break;

        if K < RefreshRates.Count then
        begin
          GetMem(PRefresh, 1);
          PRefresh^ := dmDisplayFrequency;
          RefreshRates.Add(PRefresh);
        end;
      end;

    if K < FModes.Count then
    begin
      GetMem(PRefresh, 1);
      GetMem(PMode, SizeOf(TDisplayMode));

      PMode^.Width := dmPelsWidth;
      PMode^.Height := dmPelsHeight;
      PRefresh^ := dmDisplayFrequency;

      FModes.Add(PMode);
      PMode^.RefreshRates := TList.Create;
      PMode^.RefreshRates.Add(PRefresh);
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
  Result.X := Dr.Left;
  Result.Y := Dr.Top;
  Result.Width := Dr.Right - Dr.Left;
  Result.Height := Dr.Bottom - Dr.Top;
end;

constructor TSystem.Create;
var
  i           : Integer;
  Handle      : HKEY;
  Driver      : UnicodeString;
  Str         : UnicodeString;
  DeviceList  : IList;
  Path        : UnicodeString;
  GPUInfo     : PGPUInfo;
  SysInfo     : TSystemInfo;

  function RegReadString(Handle: HKEY; const Name: UnicodeString): UnicodeString;
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

  function RegReadWord(Handle: HKEY; const Name: UnicodeString): LongWord;
  var
    DataType : DWORD;
	  DataSize : DWORD;
  begin
    Result := 0;
    DataSize := SizeOf(LongWord);
    RegQueryValueExW(Handle, @Name[1], nil, @DataType, @Result, @DataSize);
  end;

  procedure EnumAllDevice(List: IList; const Path: UnicodeString; Depth: Byte = 1);
  var
    i        : Integer;
    Handle   : HKEY;
    Count    : DWORD;
    P, P2,p3    : PWideChar;
    Str      : UnicodeString;
    DataSize : DWORD;
    Size     : DWORD;
  begin
    DataSize := 0;
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS) and
       (RegQueryInfoKeyW(Handle, nil, nil, nil, @Count, @DataSize, nil, nil, nil, nil, nil, nil) = ERROR_SUCCESS) and
       (Count > 0) then
    begin
      inc(DataSize);
      GetMem(P, DataSize*2);
      for i := 0 to Count-1 do
      begin
        Size := DataSize;
        if RegEnumKeyExW(Handle, i, P, Size, nil, nil, nil, nil) = ERROR_SUCCESS then
        begin
          Str := Path + '\' + P;
          if Depth = 3 then
          begin
            GetMem(P2, (Length(Str)+1)*SizeOf(WideChar));
            Move(Str[1], P2^, (Length(Str)+1)*SizeOf(WideChar));
            List.Add(P2);
          end else
            EnumAllDevice(List, Str, Depth + 1);
        end;
      end;
      FreeMem(P);
    end;
    RegCloseKey(Handle);
  end;

begin
  FScreen := TScreen.Create;
  FGPUList := TList.Create;
  DeviceList := TList.Create;

  GetSystemInfo(SysInfo);
  FCpuCount := SysInfo.dwNumberOfProcessors;
  FCPUSpeed := 0;
  FCPUName  :='Couldn''t get CPU name!';

  if RegOpenKeyEx(HKEY_LOCAL_MACHINE, 'HARDWARE\DESCRIPTION\System\CentralProcessor\0', 0, KEY_READ, Handle) = ERROR_SUCCESS then
  begin
    FCPUName := RegReadString(Handle, 'ProcessorNameString');
    FCPUSpeed := RegReadWord(Handle, '~MHz');
  end;
  RegCloseKey(Handle);

  EnumAllDevice(DeviceList, 'SYSTEM\CurrentControlSet\Enum');
  for i := 0 to DeviceList.Count - 1 do
  begin
    RegOpenKeyExW(HKEY_LOCAL_MACHINE, DeviceList[i], 0, KEY_READ, Handle);
    Str := RegReadString(Handle, 'Class');
    RegCloseKey(Handle);

    if LowerCase(Str) = 'display' then
    begin
      RegOpenKeyExW(HKEY_LOCAL_MACHINE, DeviceList[i], 0, KEY_READ, Handle);
      Str := RegReadString(Handle, 'Service');
      Driver := RegReadString(Handle, 'Driver');
      RegCloseKey(Handle);

      Path := 'SYSTEM\CurrentControlSet\Services\' + Str + '\Device0';
      if RegOpenKeyExW(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS then
      begin
        Str := RegReadString(Handle, 'HardwareInformation.DacType');
        if Str = '' then
        begin
          Path := PWideChar(DeviceList[i]) + '\Device Parameters';
          RegCloseKey(Handle);
          if RegOpenKeyExW(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS then
            Str := RegReadString(Handle, 'VideoID');
          Path := 'SYSTEM\CurrentControlSet\Control\Video\' + Str + '\0000';
        end;
      end;
      RegCloseKey(Handle);

      GetMem(GPUInfo, SizeOf(TGPUInfo));
      FillChar(GPUInfo^, SizeOf(TGPUInfo), 0);
      GPUInfo^.Description:=nil;

      if RegOpenKeyExW(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS then
      with GPUInfo^ do
        begin
          Str := RegReadString(Handle, 'HardwareInformation.AdapterString');
          if Str<> '' then
          begin
          	GetMem(ChipType, (Length(Str)+1)*SizeOf(WideChar));
          	Move(Str[1], ChipType^, (Length(Str)+1)*SizeOf(WideChar));
          end;

          MemorySize := RegReadWord(Handle, 'HardwareInformation.MemorySize') div (1024*1024);

        	Str := RegReadString(Handle, 'Device Description');
          if Str = '' then
          begin
          	RegCloseKey(Handle);
            Path := Path + '\Settings\';
            if RegOpenKeyExW(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS then
             	Str := RegReadString(Handle, 'Device Description');
          end;

          if Str<> '' then
          begin
          	GetMem(Description, (Length(Str)+1)*SizeOf(WideChar));
          	Move(Str[1], Description^, (Length(Str)+1)*SizeOf(WideChar));
          end;
        end;
      RegCloseKey(Handle);

      Path := 'SYSTEM\CurrentControlSet\Control\Class\' + Driver;
      if RegOpenKeyExW(HKEY_LOCAL_MACHINE, @Path[1], 0, KEY_READ, Handle) = ERROR_SUCCESS then
      with GPUInfo^ do
      begin
        Str := RegReadString(Handle, 'DriverVersion');
        if Str<> '' then
        begin
        	GetMem(DriverVersion, (Length(Str)+1)*SizeOf(WideChar)); ;
        	Move(Str[1], DriverVersion^, (Length(Str)+1)*SizeOf(WideChar));
        end;

        Str := RegReadString(Handle, 'DriverDate');
        if Str<> '' then
        begin
        	GetMem(DriverDate, (Length(Str)+1)*SizeOf(WideChar));
        	Move(Str[1], DriverDate^, (Length(Str)+1)*SizeOf(WideChar));
        end;
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
  MemStatus : TMemoryStatus;
begin
  MemStatus.dwLength := SizeOf(TMemoryStatus);
  GlobalMemoryStatus(MemStatus);
  Result := Trunc(MemStatus.dwTotalPhys/(1024*1024)+1);
end;

function TSystem.GetRAMFree: LongWord;
var
  MemStatus : TMemoryStatus;
begin
  MemStatus.dwLength := SizeOf(TMemoryStatus);
  GlobalMemoryStatus(MemStatus);
  Result := Trunc(MemStatus.dwAvailPhys/(1024*1024)+1);
end;

end.
