unit JEN_Camera3D;

interface

uses
  JEN_Header,
  JEN_Math;

type
  TCamera3D = class(TInterfacedObject, ICamera3D)
    constructor Create;
  private
    FFOV      : Single;
    FPos      : TVec3f;
    FAngle    : TVec3f;
    FSpeed    : TVec3f;
    FMaxSpeed : Single;
    FProj     : TMat4f; // projection
    FView     : TMat4f;
    FZNear    : Single;
    FZFar     : Single;
    function GetFOV: Single; stdcall;
    procedure SetFOV(Value: Single); stdcall;
    function GetPos: TVec3f; stdcall;
    procedure SetPos(const Value: TVec3f); stdcall;
    function GetAngle: TVec3f; stdcall;
    procedure SetAngle(const Value: TVec3f); stdcall;
    function GetDir: TVec3f; stdcall;
    function GetMaxSpeed: Single; stdcall;
    procedure SetMaxSpeed(Value: Single); stdcall;
    function GetZNear: Single; stdcall;
    procedure SetZNear(Value: Single); stdcall;
    function GetZFar: Single; stdcall;
    procedure SetZFar(Value: Single); stdcall;
  public
    procedure onUpdate(DeltaTime: Single); stdcall;
    procedure CalcMatrix;
  end;

implementation

uses
  JEN_MAIN;

{ TCamera }
constructor TCamera3D.Create;
begin
  inherited;
  FPos   := Vec3f(0, 0, 0);
  FAngle := Vec3f(0, 0, 0);
  FFOV   := 50;
  FZNear  := 1;
  FZFar   := 10000;
  FMaxSpeed := 16;
end;

function TCamera3D.GetFOV: Single;
begin
  Result := FFov;
end;

procedure TCamera3D.SetFOV(Value: Single);
begin
  FFov := Value;
end;

function TCamera3D.GetPos: TVec3f;
begin
  Result := FPos;
end;

procedure TCamera3D.SetPos(const Value: TVec3f);
begin
  FPos := Value;
end;

function TCamera3D.GetAngle: TVec3f;
begin
  Result := FAngle;
end;

procedure TCamera3D.SetAngle(const Value: TVec3f);
begin
  FAngle := Value;
end;

function TCamera3D.GetDir: TVec3f;
begin
  Result.x := sin(pi - FAngle.y * deg2rad) * cos(FAngle.x * deg2rad);
  Result.y := -sin(FAngle.x * deg2rad);
  Result.z := cos(pi - FAngle.y * deg2rad) * cos(FAngle.x * deg2rad);
end;

function TCamera3D.GetMaxSpeed: Single;
begin
  Result := FMaxSpeed;
end;

procedure TCamera3D.SetMaxSpeed(Value: Single);
begin
  FMaxSpeed := Value;
end;

function TCamera3D.GetZNear: Single;
begin
  Result := FZNear;
end;

procedure TCamera3D.SetZNear(Value: Single);
begin
  FZNear := Value;
end;

function TCamera3D.GetZFar: Single;
begin
  Result := FZFar;
end;

procedure TCamera3D.SetZFar(Value: Single);
begin
  FZFar := Value;
end;

procedure TCamera3D.onUpdate(DeltaTime: Single);
//var
//  Dir    : TVec3f;
//  VSpeed : TVec3f;
begin
//  DeltaTime := DeltaTime/100;
  with Input.Mouse do
  begin
  FAngle.x := FAngle.x + Delta.y * 0.1;
  FAngle.y := FAngle.y + Delta.x * 0.1;
  end;


     // ограничение угла поворота (вниз/вверх)
      {
     if FAngle.x <  90 then FAngle.x := 90;
     if FAngle.x >  270 then FAngle.x :=  270;   }

     if FAngle.x <  -90 then FAngle.x := -90;
      if FAngle.x >  90 then FAngle.x :=  90;
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
  FPos := FPos + FSpeed*DeltaTime;  }

  CalcMatrix;
end;

procedure TCamera3D.CalcMatrix;
begin
// calc View matrix
  FView.Identity;
  FView.Rotate(FAngle.z * deg2rad, Vec3f(0, 0, 1));
  FView.Rotate(FAngle.x * deg2rad, Vec3f(1, 0, 0));
  FView.Rotate(FAngle.y * deg2rad, Vec3f(0, 1, 0));

  FView.Translate(FPos * (-1));

  with Display do
    FProj.Perspective(FFOV, Width / Height, FZNear, FZFar);

  //CalcPlanes;

// Set render states
  Render.Matrix[mtViewProj] := FView * FProj;
  Render.Matrix[mtModel] := IdentMat;
  Render.Matrix[mtProj] := FProj;
  Render.Matrix[mtView] := FView;
  Render.CameraPos := FPos;
  Render.CameraDir := GetDir;
end;

end.
