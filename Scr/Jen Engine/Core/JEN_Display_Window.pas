unit JEN_Display_Window;

interface

uses
  XSystem,
  JEN_SystemInfo,
  JEN_Display,
  JEN_Window;

type
  TDisplayWindow = class(TDisplay)
    constructor Create( Width : Cardinal = 800; Height : Cardinal = 600; Refresh : Byte = 0; FullScreen : Boolean = False);
    destructor Destroy; override;
  private
    FWindow     : TWindow;
    FWidth      : Cardinal;
    FHeight     : Cardinal;
    FRefresh    : Byte;
    FFullScreen : Boolean;
    FActive     : Boolean;
    FValid      : Boolean;
    function  GetValid : Boolean; override;
    function  GetFullScreen : Boolean; override;
    procedure SetActive(Value : Boolean); override;
    function  GetActive : Boolean; override;
    function  GetHandle : HWND; override;
    function  GetDC : HDC; override;
  public
    procedure Update; override;
  end;

implementation

uses
  JEN_MAIN;

constructor TDisplayWindow.Create(Width : Cardinal; Height : Cardinal; Refresh : Byte; FullScreen : Boolean);
begin
  inherited Create;
  FWidth      := Width;
  FHeight     := Height;
  FRefresh    := Refresh;
  FFullScreen := FullScreen;

  FActive     := True;
  if FullScreen then
    FValid := SystemParams.Screen.SetMode(Width, Height, Refresh) <> SM_Error;
  FWindow  := TWindow.Create(Self, FullScreen, Width, Height, 0);

  FValid   := FValid and FWindow.isValid;
end;

destructor TDisplayWindow.Destroy;
begin
  FWindow.Free;
  inherited;
end;

function TDisplayWindow.GetValid : Boolean;
begin
  result := FValid;
end;

function TDisplayWindow.GetFullScreen : Boolean;
begin
  result := FFullScreen;
end;

procedure TDisplayWindow.SetActive(Value : Boolean);
begin
  if FFullScreen then
  begin

    if Value then
      SystemParams.Screen.SetMode(FWidth, FHeight, FRefresh)
    else
      SystemParams.Screen.ResetMode;
  end;
  FActive := Value;
end;

function  TDisplayWindow.GetActive : Boolean;
begin
  Result := FActive;
end;

procedure TDisplayWindow.Update;
begin
  FWindow.Update;
end;

function  TDisplayWindow.GetHandle : HWND;
begin
  Result := FWindow.Handle;
end;

function  TDisplayWindow.GetDC : HDC;
begin
  Result := FWindow.DC;
end;

end.
