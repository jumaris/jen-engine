unit JEN_SystemInfo;

interface

uses
  XSystem;

type
  PRefreshRateArray = ^TRefreshRateArray;
  TRefreshRateArray = record
    private
      FArray     : array of Byte;
      function GetRefresh(idx : Integer) : Byte;
      function GetRefreshIdx( R : Byte ) : Integer;
    public
      procedure Clear;
      function  Count : Integer;
      property  Refresh[idx : Integer] : Byte read GetRefresh; default;
      procedure AddRefresh( R : Byte );
      function  RefreshExist(const R : Byte ) : Boolean; inline;
  end;

  PDisplayMode = ^TDisplayMode;
  TDisplayMode = record
    Width         : Integer;
    Height        : Integer;
    RefreshRates  : TRefreshRateArray;
    procedure Clear; inline;
  end;

  TSystem = class
    constructor Create;
    destructor Destroy; override;
  private
    FCPUName  : String;
    FCPUSpeed : LongWord;
    FModes    : array of TDisplayMode;
    function GetMode(Idx: Integer) : PDisplayMode;
  public
    procedure WindowsVersion(var Major: LongInt; var Minor: LongInt; var Build: LongInt);

    function CPUCount     : Integer;
    property CPUName      : String read FCPUName;
    property CPUSpeed     : LongWord read FCPUSpeed;

    function RAMTotal : Cardinal;
    function RAMFree : Cardinal;

    function ScreenWidth  : Integer;
    function ScreenHeight : Integer;

    procedure SetMode( W, H, R : integer ); overload;
    procedure SetMode( const Idx, R  : integer ); overload; inline;

    function ModesCount   : Integer;
    property Modes[Idx: Integer]               : PDisplayMode  read GetMode; default;
    function ModeIdx(W, H : Integer)           : Integer;
    function ModeRefresh(const W, H : Integer) : PRefreshRateArray; overload; inline;
    function ModeRefresh(Idx  : Integer)       : PRefreshRateArray; overload;
    function ModeExist(const W, H : Integer)   : Boolean;           overload; inline;
    function ModeExist(W, H, R : Integer)      : Boolean;           overload;
  end;

var
  SystemInfo : TSystem;

implementation

uses
  JEN_Utils,
  JEN_Log;

procedure TRefreshRateArray.Clear;
begin
  SetLength(FArray,0);
end;

function TRefreshRateArray.Count : Integer;
begin
  result := High(FArray) + 1;
end;

function TRefreshRateArray.GetRefresh(idx: Integer) : Byte;
begin
  result := 0;
  if (Idx < 0) or (Idx > High(FArray)) then exit;
  result := FArray[Idx];
end;

function TRefreshRateArray.GetRefreshIdx(R : Byte) : Integer;
var i : Integer;
begin
  result := -1;
  for I := 0 to High(FArray) do
    if (FArray[i] = R) then
    begin
    result := i;
    exit;
    end;
end;

procedure TRefreshRateArray.AddRefresh( R : Byte );
var Last : integer;
begin
  Last := High(FArray)+1;
  SetLength(FArray, Last + 1);
  FArray[Last] := R;
end;

function TRefreshRateArray.RefreshExist(const R : Byte ) : Boolean;
begin
  result := GetRefreshIdx( R ) <> -1;
end;

procedure TDisplayMode.Clear;
begin
  RefreshRates.Clear;
end;

constructor TSystem.Create;
var
  Handle     : LongWord;
  DataType   : LongWord;
	DataSize   : LongWord;
  Res        : LongWord;
  DevMode    : TDeviceMode;
  i,Last,idx : Integer;
begin
  inherited;
  SystemInfo := self;

  Res := RegOpenKeyExW(HKEY_LOCAL_MACHINE, 'HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0', 0, KEY_READ, &Handle);
  if Res <> ERROR_SUCCESS then
    Exit;

  FCPUSpeed := 0;
  FCPUName  :='Couldn''t get CPU name!';
  DataSize  := 0;

	Res := RegQueryValueExW(Handle,	'ProcessorNameString', nil, @DataType, nil,	@DataSize);
  if (Res <> ERROR_SUCCESS) or (DataType <> REG_SZ) or (DataSize = 0)  then
  begin
    RegCloseKey(Handle);
    Exit;
  end;

  SetLength(FCPUName,DataSize div 2);
  RegQueryValueExW(Handle, 'ProcessorNameString', nil, @DataType, PByte(@FCPUName[1]), @DataSize);

	DataSize  := SizeOf( LongWord );
	Res := RegQueryValueExW(Handle,	'~MHz', nil, @DataType, @FCPUSpeed,	@DataSize);
  RegCloseKey(Handle);

  i := 0;
  SetLength(FModes, 0);

  FillChar(DevMode, SizeOf(TDeviceMode), 0);
  DevMode.dmSize := SizeOf(TDeviceMode);

  while EnumDisplaySettingsW( nil, i, DevMode ) <> FALSE do
    begin
      INC( i );
      idx := ModeIdx(DevMode.dmPelsWidth, DevMode.dmPelsHeight);
      if DevMode.dmBitsPerPel <> 32 then
        Continue;

      if idx = -1 Then
        begin
          Last:=High(FModes)+1;
          SetLength(FModes, Last + 1);
          FModes[Last].Clear;
          FModes[Last].Width  := DevMode.dmPelsWidth;
          FModes[Last].Height := DevMode.dmPelsHeight;
          FModes[Last].RefreshRates.AddRefresh(DevMode.dmDisplayFrequency);
        end else
        if not ModeRefresh(idx).RefreshExist(DevMode.dmDisplayFrequency) then
           ModeRefresh(idx).AddRefresh(DevMode.dmDisplayFrequency);
    end;

  {
  EnumDisplaySettingsA(nil, 0, @DevMode);
  with DevMode do
  begin
    dmPelsWidth  := Width;
    dmPelsHeight := Height;
    dmBitsPerPel := 32;
    dmFields     := $1C0000; // DM_BITSPERPEL or DM_PELSWIDTH  or DM_PELSHEIGHT;
  end;
  ChangeDisplaySettingsA(@DevMode, $04); // CDS_FULLSCREEN
                                 }
end;

destructor TSystem.Destroy;
var i : Integer;
begin
  for I := 0 to High(FModes) do
    FModes[i].Clear;
  SetLength(FModes, 0);
  inherited;
end;

procedure TSystem.SetMode( W, H, R : integer );
var
  DevMode : TDeviceMode;
  Refresh : PRefreshRateArray;
begin
  FillChar(DevMode, SizeOf(DevMode), 0);
  DevMode.dmSize := SizeOf(DevMode);

  Refresh := ModeRefresh( W, H );
  if Refresh <> nil then
    begin
      if not Refresh^.RefreshExist( R ) then
        R := 0;
    end else
      LogOut('Error set mode ' + Utils.IntToStr(W) + 'x' + Utils.IntToStr(H), LM_WARNING);

  EnumDisplaySettingsW(nil, 0, DevMode);
  with DevMode do
    begin
      dmPelsWidth        := W;
      dmPelsHeight       := H;
      dmBitsPerPel       := 32;
      if R <> 0 then
      dmDisplayFrequency := R;
      dmFields           := $1C0000; // DM_BITSPERPEL or DM_PELSWIDTH  or DM_PELSHEIGHT;
    end;
  ChangeDisplaySettingsW(DevMode, $04); // CDS_FULLSCREEN
end;

procedure TSystem.SetMode( const Idx, R : integer );
var
  Mode : PDisplayMode;
begin
  Mode := GetMode( Idx );
  if Mode <> nil then
    SetMode( ModeIdx(Mode^.Width, Mode^.Height), R);
end;

function TSystem.ModesCount : integer;
begin
  result := High(FModes) + 1;
end;

function TSystem.GetMode(Idx: Integer) : PDisplayMode;
begin
  result := nil;
  if (Idx < 0) or (Idx > High(FModes)) then exit;
  result := @FModes[Idx];
end;

function TSystem.ModeIdx(W, H : Integer) : Integer;
var i : Integer;
begin
  result := -1;
  for I := 0 to High(FModes) do
    if (FModes[i].Width = W) and (FModes[i].Height = H) then
    begin
    result := i;
    exit;
    end;
end;

function TSystem.ModeRefresh(const W, H : Integer) : PRefreshRateArray;
begin
  result := ModeRefresh( ModeIdx(W, H) );
end;

function TSystem.ModeRefresh(Idx  : Integer) : PRefreshRateArray;
begin
  result := nil;
  if (Idx < 0) or (Idx > High(FModes)) then exit;
  result := @FModes[Idx].RefreshRates;
end;

function TSystem.ModeExist(const W, H : Integer) : Boolean;
begin
  result := ModeIdx(W, H)<>-1;
end;

function TSystem.ModeExist(W, H, R : Integer) : Boolean;
var RRA : PRefreshRateArray;
var i   : Integer;
begin
  result := false;
  RRA := ModeRefresh(ModeIdx(W, H));
  if Assigned(RRA) then
    RRA^.RefreshExist(R);
end;

function TSystem.ScreenWidth : Integer;
begin
  result := GetSystemMetrics( SM_CXSCREEN );
end;

function TSystem.ScreenHeight : Integer;
begin
  result := GetSystemMetrics( SM_CYSCREEN );
end;

procedure TSystem.WindowsVersion(var Major: LongInt; var Minor: LongInt; var Build: LongInt);
var
  OSVerInfo: TOSVERSIONINFO;
begin
  fillchar( OSVerInfo, SizeOf(TOSVERSIONINFO), 0 );
  OSVerInfo.dwOSVersionInfoSize := SizeOf(TOSVERSIONINFO);
  GetVersionExW(@OSVerInfo);
  Major := OSVerInfo.dwMajorVersion;
  Minor := OSVerInfo.dwMinorVersion;
  Build := OSVerInfo.dwBuildNumber;
end;

function TSystem.CPUCount : integer;
begin
  result:=System.CPUCount;
end;

function TSystem.RAMTotal : Cardinal;
var
  MemStatus : TMemoryStatusEx;
begin
  MemStatus.dwLength := SizeOf( TMemoryStatusEx );
  GlobalMemoryStatusEx(MemStatus);
  Result := Trunc(MemStatus.ullTotalPhys/(1024*1024)+1);
end;

function TSystem.RAMFree : Cardinal;
var
  MemStatus : TMemoryStatusEx;
begin
  MemStatus.dwLength := SizeOf( TMemoryStatusEx );
  GlobalMemoryStatusEx(MemStatus);
  Result := Trunc(MemStatus.ullAvailPhys/(1024*1024)+1);
end;

end.
