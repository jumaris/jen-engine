unit JEN_Display_Window;

interface

uses
  XSystem,
  JEN_SystemInfo,
  JEN_Display,
  JEN_Window;

type
  TDisplayWindow = class(TDisplay)
    constructor Create(Width: Cardinal = 800; Height: Cardinal = 600; Refresh: Byte = 0; FullScreen: Boolean = False);
    destructor Destroy; override;
  private
    FWindow     : TWindow;
    FWidth      : Cardinal;
    FHeight     : Cardinal;
    FRefresh    : Byte;
    FFullScreen : Boolean;
    FActive     : Boolean;
    function  GetFullScreen: Boolean; override;
    procedure SetFullScreen(Value: Boolean); override;
    procedure SetActive(Value: Boolean); override;
    function  GetActive: Boolean; override;
    function  GetHandle: HWND; override;
    function  GetDC: HDC; override;
    function  GetWidth: Cardinal; override;
    function  GetHeight: Cardinal; override;
  public
    procedure Restore; override;
    procedure Update; override;
  end;

implementation

uses
  JEN_MAIN,
  JEN_MATH;

constructor TDisplayWindow.Create(Width: Cardinal; Height: Cardinal; Refresh: Byte; FullScreen: Boolean);
begin
  inherited Create;

  if (Width = SystemParams.Screen.Width) and (Height = SystemParams.Screen.Height) then
    FullScreen := true;

  FWidth      := Width;
  FHeight     := Height;
  FRefresh    := Refresh;
  FFullScreen := FullScreen;
  FValid      := True;
  FActive     := True;

  if FullScreen then
    FValid := SystemParams.Screen.SetMode(Width, Height, Refresh) <> SM_Error;

  if FValid then
    FWindow  := TWindow.Create(Self, FullScreen, Width, Height, 0)
  else
    Exit;

  FValid := FValid and FWindow.isValid;
end;

destructor TDisplayWindow.Destroy;
begin
  FWindow.Free;
  inherited;
end;

function TDisplayWindow.GetFullScreen: Boolean;
begin
  result := FFullScreen;
end;

procedure TDisplayWindow.SetFullScreen(Value: Boolean);
begin
  if (FFullScreen = Value) or (FValid = false) then Exit;
  FFullScreen := Value;

  if Value then
    FValid := FValid and (SystemParams.Screen.SetMode(FWidth, FHeight, FRefresh) <> SM_Error)
  else
    SystemParams.Screen.ResetMode;

  if FValid then
    FWindow.FullScreen := Value;
end;

procedure TDisplayWindow.SetActive(Value: Boolean);
begin
  if FFullScreen then
  begin
    if Value then
      SystemParams.Screen.SetMode(FWidth, FHeight, FRefresh)
    else
      SystemParams.Screen.ResetMode;
  end;
  FActive := Value;
  Restore;
end;

function TDisplayWindow.GetActive: Boolean;
begin
  Result := FActive;
end;

procedure TDisplayWindow.Restore;
begin
  FRender.Viewport := Recti(0, 0, FWidth, FHeight);
end;

procedure TDisplayWindow.Update;
begin
  FWindow.Update;
end;

function TDisplayWindow.GetHandle: HWND;
begin
  Result := FWindow.Handle;
end;

function TDisplayWindow.GetDC: HDC;
begin
  Result := FWindow.DC;
end;

function TDisplayWindow.GetWidth: Cardinal;
begin
  Result := FWidth;
end;

function TDisplayWindow.GetHeight: Cardinal;
begin
  Result := FHeight;
end;

end.
