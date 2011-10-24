unit JEN_Camera2D;

interface

uses
  JEN_Header,
  JEN_Math;

type
  TCamera2D = class(TInterfacedObject, ICamera2D)
    constructor Create;
  private
    FEnable   : Boolean;
    FPos      : TVec2f;
    FAngle    : Single;
    FScale    : Single;
//    FSpeed    : TVec2f;
//    FMaxSpeed : Single;
    function GetEnable: Boolean; stdcall;
    procedure SetEnable(Value: Boolean); stdcall;
    function GetPos: TVec2f; stdcall;
    procedure SetPos(const Value: TVec2f); stdcall;
    function GetAngle: Single; stdcall;
    procedure SetAngle(Value: Single); stdcall;
    function GetScale: Single; stdcall;
    procedure SetScale(Value: Single); stdcall;
//    function GetDir: TVec3f; stdcall;
 //   function GetMaxSpeed: Single; stdcall;
//    procedure SetMaxSpeed(Value: Single); stdcall;
    procedure SetCam; stdcall;
  //  procedure onUpdate(DeltaTime: Single); stdcall;
  end;

implementation

uses
  JEN_MAIN;

{ TCamera }
constructor TCamera2D.Create;
begin
  inherited;
  FPos      := Vec2f(0, 0);
  FAngle    := 0;
  //FMaxSpeed := 16;
  FScale    := 1;
end;

function TCamera2D.GetEnable: Boolean;
begin
  Result := FEnable;
end;

procedure TCamera2D.SetEnable(Value: Boolean);
begin
  if FEnable = Value then
    Exit;
  FEnable := Value;
  SetCam;
end;

function TCamera2D.GetPos: TVec2f;
begin
  Result := FPos;
end;

procedure TCamera2D.SetPos(const Value: TVec2f);
begin
  FPos := Value;
end;

function TCamera2D.GetAngle: Single;
begin
  Result := FAngle;
end;

procedure TCamera2D.SetAngle(Value: Single);
begin
  FAngle := Value;
end;

function TCamera2D.GetScale: Single;
begin
  Result := FScale;
end;

procedure TCamera2D.SetScale(Value: Single);
begin
  FScale := Value;
end;

                   {
function TCamera2D.GetDir: TVec3f;
begin
  Result.x := sin(pi - FAngle.y * deg2rad) * cos(FAngle.x * deg2rad);
  Result.y := -sin(FAngle.x * deg2rad);
  Result.z := cos(pi - FAngle.y * deg2rad) * cos(FAngle.x * deg2rad);
end;
                      }   {
function TCamera2D.GetMaxSpeed: Single;
begin
  Result := FMaxSpeed;
end;

procedure TCamera2D.SetMaxSpeed(Value: Single);
begin
  FMaxSpeed := Value;
end;

procedure TCamera2D.onUpdate(DeltaTime: Single);
{var
  Dir    : TVec3f;
  VSpeed : TVec3f;
begin
  DeltaTime := DeltaTime/100;

    // летим куда хотим
 {Dir.x := sin(pi - FAngle.y * deg2rad) * cos(FAngle.x * deg2rad);
  Dir.y := -sin(FAngle.x * deg2rad);
  Dir.z := cos(pi - FAngle.y * deg2rad) * cos(FAngle.x * deg2rad);
  VSpeed := Vec3f(0, 0, 0);
        if Input.Down[ikW] then VSpeed := VSpeed + Dir;
        if Input.Down[ikS] then VSpeed := VSpeed - Dir;
        if Input.Down[ikA] then VSpeed := VSpeed - Dir.Cross(Vec3f(0, 1, 0));
        if Input.Down[ikD] then VSpeed := VSpeed + Dir.Cross(Vec3f(0, 1, 0));
  FSpeed := FSpeed.Lerp(VSpeed.Normal * FMaxSpeed, DeltaTime);
  if FSpeed.Length < 0.001 then
    FSpeed := Vec3f(0, 0, 0);
  FPos := FPos + FSpeed*DeltaTime;

 // CalcMatrix;
end;
               }
procedure TCamera2D.SetCam; stdcall;
var
  Mat : TMat4f;
begin
  Mat := Render2d.RCMatrix;

  if FEnable then
  begin
    Mat.Translate(Vec3f(-FPos.x, -FPos.y, 0));
    Mat.Translate(Vec3f(Render2d.RCWidth/2, Render2d.RCHeight/2, 0));
    Mat.Scale(Vec3f(FScale, FScale, 0));
    Mat.Rotate(FAngle, Vec3f(0, 0, 1));
    Mat.Translate(Vec3f(-Render2d.RCWidth/2, -Render2d.RCHeight/2, 0));
  end;

  Render.Matrix[mt2DMat] := Mat;
//Render.CameraPos := FPos;
//Render.CameraDir := GetDir;
end;

end.
