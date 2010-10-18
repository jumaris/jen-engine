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
      function  IsExist(const R : Byte ) : Boolean; inline;
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
      type TScreen = class
        constructor Create;
        destructor Destroy; override;
      private
        fModes  : array of TDisplayMode;
        function GetMode(Idx: Integer) : PDisplayMode;
      public
        function Width  : Integer;
        function Height : Integer;

        procedure SetMode  (W, H, R : integer); overload;
        procedure SetMode  (Idx, R  : integer); overload;
        procedure ResetMode;

        function GetModesCount : Integer;
        property Modes[Idx: Integer]           : PDisplayMode read GetMode; default;
        function GetIdx(W, H : Integer)        : Integer; inline;
        function GetRefresh(W, H : Integer)    : PRefreshRateArray; overload; inline;
        function GetRefresh(Idx  : Integer)    : PRefreshRateArray; overload; inline;
        function IsModeExist(W, H : Integer)   : Boolean; overload; inline;
        function IsModeExist(W, H, R : Integer): Boolean; overload; inline;
      end;
  var
    fCPUName  : String;
    fCPUSpeed : LongWord;
    fScreen   : TScreen;
  public
    procedure WindowsVersion(var Major: LongInt; var Minor: LongInt; var Build: LongInt);

    function CPUCount  : Integer;
    property CPUName   : String read fCPUName;
    property CPUSpeed  : LongWord read fCPUSpeed;
    property Screen    : TScreen read fScreen;

    function RAMTotal  : Cardinal;
    function RAMFree   : Cardinal;
  end;

implementation

uses
  JEN_MAIN;

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
      Exit(i);
end;

procedure TRefreshRateArray.AddRefresh( R : Byte );
var Last : integer;
begin
  Last := High(FArray)+1;
  SetLength(FArray, Last + 1);
  FArray[Last] := R;
end;

function TRefreshRateArray.IsExist(const R : Byte ) : Boolean;
begin
  result := GetRefreshIdx( R ) <> -1;
end;

procedure TDisplayMode.Clear;
begin
  RefreshRates.Clear;
end;

constructor TSystem.TScreen.Create;
var
  DevMode    : TDeviceMode;
  i,Last,idx : Integer;
begin
  i := 0;
  SetLength(FModes, 0);

  FillChar(DevMode, SizeOf(TDeviceMode), 0);
  DevMode.dmSize := SizeOf(TDeviceMode);

  while EnumDisplaySettingsW( nil, i, DevMode ) <> FALSE do
    begin
      INC( i );
      idx := GetIdx(DevMode.dmPelsWidth, DevMode.dmPelsHeight);
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
        if not GetRefresh(idx).IsExist(DevMode.dmDisplayFrequency) then
           GetRefresh(idx).AddRefresh(DevMode.dmDisplayFrequency);
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

destructor TSystem.TScreen.Destroy;
var i : Integer;
begin
  for I := 0 to High(FModes) do
    FModes[i].Clear;
  SetLength(FModes, 0);
  inherited;
end;

procedure TSystem.TScreen.SetMode( W, H, R : integer );
var
  DevMode      : TDeviceMode;
  RefreshRates : PRefreshRateArray;
  Mode         : PDisplayMode;
  i  : integer;
begin

  Mode := Modes[GetIdx(W, H)];
  if Mode <> nil then
    begin
      if not Mode^.RefreshRates.IsExist( R ) then
        R := 0;
    end else
    begin
      LogOut('Error set display mode ' + Utils.IntToStr(W) + 'x' + Utils.IntToStr(H) + 'x' + Utils.IntToStr(R), LM_WARNING);
      LogOut('Change display mode to default 1024x768x60', LM_NOTIFY);
      if IsModeExist(1024, 768, 60) then
        SetMode(1024, 768, 60)
      else
        LogOut('Display mode critical error', LM_ERROR);
      Exit;
    end;

  if R = 0 then
    with Mode^.RefreshRates do
      R := GetRefresh(Count-1);

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
      dmFields           := $5C0000; // DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT or DM_DISPLAYFREQUENCY ;
    end;

  case ChangeDisplaySettingsW(@DevMode, $04) of
    DISP_CHANGE_SUCCESSFUL :
      LogOut('Successful set display mode ' + Utils.IntToStr(Mode.Width) + 'x' + Utils.IntToStr(Mode.Height) + 'x' + Utils.IntToStr(R), LM_NOTIFY);
    DISP_CHANGE_FAILED :
      LogOut('Failed set display mode ' + Utils.IntToStr(Mode.Width) + 'x' + Utils.IntToStr(Mode.Height) + 'x' + Utils.IntToStr(R), LM_ERROR);
    DISP_CHANGE_BADMODE :
      LogOut('Failed set display mode ' + Utils.IntToStr(Mode.Width) + 'x' + Utils.IntToStr(Mode.Height) + 'x' + Utils.IntToStr(R) + ' bad mode', LM_ERROR);
    else
      LogOut('Failed set display mode ' + Utils.IntToStr(Mode.Width) + 'x' + Utils.IntToStr(Mode.Height) + 'x' + Utils.IntToStr(R) + ' uncnown error', LM_ERROR);
  end;

end;


procedure TSystem.TScreen.SetMode( Idx, R : integer );
var
  Mode : PDisplayMode;
begin
  Mode := Modes[Idx];
  if Assigned(Mode) then
    SetMode( Mode.Width, Mode.Height, R)
  else
    SetMode( -1, -1, R);
end;

procedure TSystem.TScreen.ResetMode;
begin
  ChangeDisplaySettingsW(nil, 0);
  LogOut('Reset display mode to delfault', LM_NOTIFY);
end;

function TSystem.TScreen.GetModesCount : integer;
begin
  result := Length(FModes);
end;

function TSystem.TScreen.GetMode(Idx: Integer) : PDisplayMode;
begin
  result := nil;
  if (Idx < 0) or (Idx > High(FModes)) then exit;
  result := @FModes[Idx];
end;

function TSystem.TScreen.GetIdx(W, H : Integer) : Integer;
var i : Integer;
begin
  result := -1;
  for I := 0 to High(FModes) do
    if (FModes[i].Width = W) and (FModes[i].Height = H) then
      Exit(i);
end;

function TSystem.TScreen.GetRefresh(W, H : Integer) : PRefreshRateArray;
begin
  result := GetRefresh( GetIdx(W, H) );
end;

function TSystem.TScreen.GetRefresh(Idx : Integer) : PRefreshRateArray;
begin
  if (Idx < 0) or (Idx > High(FModes)) then
    Exit(nil);
  result := @FModes[Idx].RefreshRates;
end;

function TSystem.TScreen.IsModeExist(W, H : Integer) : Boolean;
begin
  result := GetIdx(W, H)<>-1;
end;

function TSystem.TScreen.IsModeExist(W, H, R : Integer) : Boolean;
var RRA : PRefreshRateArray;
var i   : Integer;
begin
  result := false;
  RRA := GetRefresh(GetIdx(W, H));
  if Assigned(RRA) then
    result := RRA^.IsExist(R);
end;

function TSystem.TScreen.Width : Integer;
begin
  result := GetSystemMetrics( SM_CXSCREEN );
end;

function TSystem.TScreen.Height : Integer;
begin
  result := GetSystemMetrics( SM_CYSCREEN );
end;

constructor TSystem.Create;
var
  Handle     : LongWord;
  DataType   : LongWord;
	DataSize   : LongWord;
  Res        : LongWord;
begin
  inherited;
  fScreen := TScreen.Create;

  FCPUSpeed := 0;
  FCPUName  :='Couldn''t get CPU name!';
  DataSize  := 0;

  Res := RegOpenKeyExW(HKEY_LOCAL_MACHINE, 'HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0', 0, KEY_READ, &Handle);
  if Res <> ERROR_SUCCESS then
    Exit;

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
end;

destructor TSystem.Destroy;
begin
  fScreen.Free;
  inherited;
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
