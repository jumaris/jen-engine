unit JEN_Math;

interface

Type
  TPoint2i  = record
    x, y : LongInt;
    class operator Equal(const a, b: TPoint2i): Boolean;
    class operator NotEqual(const a, b: TPoint2i): Boolean;
  end;

  TRecti    = record
    x, y          : LongInt;
    Width, Height : LongInt;
    private
      function  GetLocation: TPoint2i;
      procedure SetLocation(Location: TPoint2i);
      function  GetCenter: TPoint2i;
    public
      function Left     : LongInt;
      function Right    : LongInt;
      function Top      : LongInt;
      function Bottom   : LongInt;

      property Location : TPoint2i read GetLocation write SetLocation;
      property Center   : TPoint2i read GetCenter;

      function IsEmpty  : Boolean;

      procedure Offset(const Point: TPoint2i); overload;
      procedure Offset(offsetX, offsetY: LongInt); overload;

      procedure Inflate(HAmount, VAmount: LongInt); overload;

      function Contains(x, y: LongInt): Boolean; overload;
      function Contains(const Point: TPoint2i): Boolean; overload;
//    function Contains(const Point: TPoint2f): Boolean; overload;
      function Contains(const Rect: TRecti): Boolean; overload;
//    function Contains(const Rect : TRectf)  : Boolean; overload;

      function Intersects(const Rect: TRecti): Boolean; overload;
//    function Intersects(const Rect : TRectf)  : Boolean; overload;
      function Intersect(const Rect1, Rect2: TRecti): TRecti ; overload;

//    function Intersect(const Rect : TRectf)  : TRectf ;
      function Union(const Rect1, Rect2 : TRecti): TRecti ; overload;
//    function Union(const Rect1, Rect2 : TRectf): TRectf ; overload;

      class operator Equal(const Rect1, Rect2: TRecti): Boolean;
      class operator NotEqual(const Rect1, Rect2: TRecti): Boolean;
  end;

  TVec2f = record
    x, y : Single;
    class operator Equal(const a, b: TVec2f): Boolean;
    class operator Add(const a, b: TVec2f): TVec2f;
    class operator Subtract(const a, b: TVec2f): TVec2f;
    class operator Multiply(const a, b: TVec2f): TVec2f;
    class operator Multiply(const v: TVec2f; x: Single): TVec2f;
    function Dot(const v: TVec2f): Single;
    function Reflect(const n: TVec2f): TVec2f;
    function Refract(const n: TVec2f; Factor: Single): TVec2f;
    function Length: Single;
    function LengthQ: Single;
    function Normal: TVec2f;
    function Dist(const v: TVec2f): Single;
    function DistQ(const v: TVec2f): Single;
    function Lerp(const v: TVec2f; t: Single): TVec2f;
    function Min(const v: TVec2f): TVec2f;
    function Max(const v: TVec2f): TVec2f;
    function Clamp(const MinClamp, MaxClamp: TVec2f): TVec2f;
    function Rotate(Angle: Single): TVec2f;
    function Angle(const v: TVec2f): Single;
  end;

  PVec3f = ^TVec3f;
  TVec3f = record
    x, y, z : Single;
    class operator Equal(const a, b: TVec3f): Boolean;
    class operator Add(const a, b: TVec3f): TVec3f;
    class operator Subtract(const a, b: TVec3f): TVec3f;
    class operator Multiply(const a, b: TVec3f): TVec3f;
    class operator Multiply(const v: TVec3f; x: Single): TVec3f;
    function Dot(const v: TVec3f): Single;
    function Cross(const v: TVec3f): TVec3f;
    function Reflect(const n: TVec3f): TVec3f;
    function Refract(const n: TVec3f; Factor: Single): TVec3f;
    function Length: Single;
    function LengthQ: Single;
    function Normal: TVec3f;
    function Dist(const v: TVec3f): Single;
    function DistQ(const v: TVec3f): Single;
    function Lerp(const v: TVec3f; t: Single): TVec3f;
    function Min(const v: TVec3f): TVec3f;
    function Max(const v: TVec3f): TVec3f;
    function Clamp(const MinClamp, MaxClamp: TVec3f): TVec3f;
    function Rotate(Angle: Single; const Axis: TVec3f): TVec3f;
    function Angle(const v: TVec3f): Single;
    function MultiOp(out r: TVec3f; const v1, v2, op1, op2: TVec3f): Single;
  end;

  TVec4f = record
    x, y, z, w : Single;
    class operator Equal(const a, b: TVec4f): Boolean;
    class operator Add(const a, b: TVec4f): TVec4f;
    class operator Subtract(const a, b: TVec4f): TVec4f;
    class operator Multiply(const a, b: TVec4f): TVec4f;
    class operator Multiply(const v: TVec4f; x: Single): TVec4f;
    function Dot(const v: TVec3f): Single;
    function Lerp(const v: TVec4f; t: Single): TVec4f;
  end;

  TQuat = record
    x, y, z, w : Single;
    class operator Equal(const q1, q2: TQuat): Boolean;
    class operator Add(const q1, q2: TQuat): TQuat;
    class operator Subtract(const q1, q2: TQuat): TQuat;
    class operator Multiply(const q: TQuat; x: Single): TQuat;
    class operator Multiply(const q1, q2: TQuat): TQuat;
    class operator Multiply(const q: TQuat; const v: TVec3f): TVec3f;
    function Invert: TQuat; inline;
    function Lerp(const q: TQuat; t: Single): TQuat;
    function Dot(const q: TQuat): Single; inline;
    function Normal: TQuat;
    function Euler: TVec3f;
  end;

  TMat4f = record
  private
    function  GetPos: TVec3f;
    procedure SetPos(const v: TVec3f);
    function  GetRot: TQuat;
    procedure SetRot(const q: TQuat);
  public
    e00, e10, e20, e30,
    e01, e11, e21, e31,
    e02, e12, e22, e32,
    e03, e13, e23, e33: Single;
    class operator Add(const a, b: TMat4f): TMat4f;
    class operator Multiply(const a, b: TMat4f): TMat4f;
    class operator Multiply(const m: TMat4f; const v: TVec3f): TVec3f;
//    class operator Multiply(const m: TMat4f; const v: TVec4f): TVec4f;
    class operator Multiply(const m: TMat4f; x: Single): TMat4f;

    procedure Identity;
    function Det: Single;
    function Inverse: TMat4f;
    function Transpose: TMat4f;
    procedure Translate(const v: TVec3f);
    procedure Rotate(Angle: Single; const Axis: TVec3f);
    procedure Scale(const v: TVec3f);
    procedure LookAt(const Pos, Target, Up: TVec3f);
    procedure Ortho(Left, Right, Bottom, Top, ZNear, ZFar: Single);
    procedure Frustum(Left, Right, Bottom, Top, ZNear, ZFar: Single);
    procedure Perspective(FOV, Aspect, ZNear, ZFar: Single);
    function GetRotPart: TMat4f;

    property Pos: TVec3f read GetPos write SetPos;
    property Rot: TQuat read GetRot write SetRot;
  end;

const
  INF     = 1 / 0;
  NAN     = 0 / 0;
  EPS     = 1.E-05;
  deg2rad = pi / 180;
  rad2deg = 180 / pi;
  ZeroPoint : TPoint2i = (x: 0; y: 0;);
  EmptyRect: TRecti = (x: 0; y: 0; Width: 0; Height: 0);
  NullVec3f : TVec3f = (x: 0; y: 0; z: 0);
  clWhite : TVec4f = (x: 1; y: 1; z: 1; w: 1);

function Max(x, y: Single): Single; overload; inline;
function Min(x, y: Single): Single; overload; inline;
function Max(x, y: LongInt): LongInt; overload; inline;
function Min(x, y: LongInt): LongInt; overload; inline;
function Sign(x: Single): LongInt; inline;
function Clamp(x, Min, Max: LongInt): LongInt; overload; inline;
function Clamp(x, Min, Max: Single): Single; overload; inline;
function Tan(x: Single): Single; assembler;
procedure SinCos(Theta: Single; out Sin, Cos: Single); assembler;
function ArcTan2(y, x: Single): Single; assembler;
function ArcCos(x: Single): Single; assembler;
function ArcSin(x: Single): Single; assembler;
function Log2(const X: Single): Single;
function Pow(x, y: Single): Single;
function ToPow2(x: LongInt): LongInt;

function Point2i(x, y : LongInt) : TPoint2i; inline;
function Recti(x, y, Width, Height : LongInt): TRecti; overload; inline;
function Vec2f(x, y: Single): TVec2f; inline;
function Vec3f(x, y, z: Single): TVec3f; inline;
function Vec4f(x, y, z, w: Single): TVec4f; inline;
function Quat(x, y, z, w: Single): TQuat; overload; inline;
function Quat(Angle: Single; const Axis: TVec3f): TQuat; overload;
function Mat4f(Angle: Single; const Axis: TVec3f): TMat4f; inline;

implementation

{$REGION 'MinMax'}
function Max(x, y: Single): Single;
begin
  if x > y then
    Result := x
  else
    Result := y;
end;

function Min(x, y: Single): Single;
begin
  if x < y then
    Result := x
  else
    Result := y;
end;

function Max(x, y: LongInt): LongInt;
begin
  if x > y then
    Result := x
  else
    Result := y;
end;

function Min(x, y: LongInt): LongInt;
begin
  if x < y then
    Result := x
  else
    Result := y;
end;

function Sign(x: Single): LongInt;
begin
  if x > 0 then
    Result := 1
  else
    if x < 0 then
      Result := -1
    else
      Result := 0;
end;

function Clamp(x, Min, Max: LongInt): LongInt;
begin
  if x < min then
    Result := min
  else
    if x > max then
      Result := max
    else
      Result := x;
end;

function Clamp(x, Min, Max: Single): Single;
begin
  if x < min then
    Result := min
  else
    if x > max then
      Result := max
    else
      Result := x;
end;

function ClampAngle(Angle: Single): Single;
begin
  if Angle > pi then
    Result := (Frac(Angle / pi) - 1) * pi
  else
    if Angle < -pi then
      Result := (Frac(Angle / pi) + 1) * pi
    else
      Result := Angle;
end;


function Tan(x: Single): Single; assembler;
asm
  fld x
  fptan
  fstp st(0)
  fwait
end;

procedure SinCos(Theta: Single; out Sin, Cos: Single); assembler;
asm
  fld Theta
  fsincos
  fstp dword ptr [edx]
  fstp dword ptr [eax]
  fwait
end;

function ArcTan2(y, x: Single): Single; assembler;
asm
  fld y
  fld x
  fpatan
  fwait
end;

function ArcCos(x: Single): Single; assembler;
asm
{
  fld x
  fmul st, st
  fsubr ONE
  fsqrt
  fld x
  fpatan
}
  fld1
  fld    x
  fst    st(2)
  fmul   st(0), st(0)
  fsubp
  fsqrt
  fxch
  fpatan
end;

function ArcSin(x: Single): Single; assembler;
asm
{
  fld x
  fld st
  fmul st, st
  fsubr ONE
  fsqrt
  fpatan
}
  fld1
  fld    X
  fst    st(2)
  fmul   st(0), st(0)
  fsubp
  fsqrt
  fpatan
end;

function Log2(const X: Single): Single; assembler;
asm
  fld1
  fld X
  fyl2x
  fwait
end;

function Pow(x, y: Single): Single;
begin
  Result := exp(ln(x) * y);
end;

function ToPow2(x: LongInt): LongInt;
begin
  Result := x - 1;
  Result := Result or (Result shr 1);
  Result := Result or (Result shr 2);
  Result := Result or (Result shr 4);
  Result := Result or (Result shr 8);
  Result := Result or (Result shr 16);
  Result := Result + 1;
end;
{$ENDREGION}

{$REGION 'Creation'}
function Point2i(x, y: LongInt): TPoint2i;
begin
  Result.x := x;
  Result.y := y;
end;

function Recti(x, y, Width, Height: LongInt): TRecti;
begin
  Result.x := x;
  Result.y := y;
  Result.Height := Height;
  Result.Width := Width;
end;

function Vec2f(x, y: Single): TVec2f;
begin
  Result.x := x;
  Result.y := y;
end;

function Vec3f(x, y, z: Single): TVec3f;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
end;

function Vec4f(x, y, z, w: Single): TVec4f;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
  Result.w := w;
end;

function Quat(x, y, z, w: Single): TQuat;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
  Result.w := w;
end;

function Quat(Angle: Single; const Axis: TVec3f): TQuat;
var
  s, c : Single;
begin
  SinCos(Angle * 0.5, s, c);
  Result.x := Axis.x * s;
  Result.y := Axis.y * s;
  Result.z := Axis.z * s;
  Result.w := c;
end;

function Mat4f(Angle: Single; const Axis: TVec3f): TMat4f;
var
  s, c  : Single;
  ic : Single;
  xy, yz, zx, xs, ys, zs, icxy, icyz, iczx : Single;
begin
  SinCos(Angle, s, c);
  ic := 1 - c;

  with Result, Axis do
  begin
    xy := x * y;  yz := y * z;  zx := z * x;
    xs := x * s;  ys := y * s;  zs := z * s;
    icxy := ic * xy;  icyz := ic * yz;  iczx := ic * zx;
    e00 := ic * x * x + c;  e01 := icxy - zs;       e02 := iczx + ys;       e03 := 0.0;
    e10 := icxy + zs;       e11 := ic * y * y + c;  e12 := icyz - xs;       e13 := 0.0;
    e20 := iczx - ys;       e21 := icyz + xs;       e22 := ic * z * z + c;  e23 := 0.0;
    e30 := 0.0;             e31 := 0.0;             e32 := 0.0;             e33 := 1.0;
  end;
end;
{$ENDREGION}

{$REGION 'TPoint2i'}
class operator TPoint2i.Equal(const a, b: TPoint2i): Boolean;
begin
  Result := (a.x = b.x) and (a.y = b.y);
end;

class operator TPoint2i.NotEqual(const a, b: TPoint2i): Boolean;
begin
  Result := (a.x <> b.x) and (a.y <> b.y);
end;
{$ENDREGION}

{$REGION 'TRecti'}
function TRecti.Left: LongInt;
begin
  Result := x;
end;

function TRecti.Right: LongInt;
begin
  Result := x + Width;
end;

function TRecti.Top: LongInt;
begin
  Result := y;
end;

function TRecti.Bottom: LongInt;
begin
  Result := y + Height;
end;

function TRecti.GetLocation: TPoint2i;
begin
  Result := Point2i(x, y);
end;

procedure TRecti.SetLocation(Location: TPoint2i);
begin
  x := Location.x;
  y := Location.y;
end;

function TRecti.GetCenter: TPoint2i;
begin
  Result := Point2i(x, y);
end;

function TRecti.IsEmpty: Boolean;
begin
  Result := ((((Width = 0) and (Height = 0)) and (x = 0)) and (y = 0));
end;

procedure TRecti.Offset(const Point: TPoint2i);
begin
  inc(x, Point.x);
  inc(y, Point.y);
end;

procedure TRecti.Offset(offsetX, offsetY: LongInt);
begin
  inc(x, offsetX);
  inc(y, offsetY);
end;

procedure TRecti.Inflate(HAmount, VAmount: LongInt);
begin
  dec(x, HAmount);
  dec(y, VAmount);
  inc(Width, HAmount*2);
  inc(Height, VAmount*2);
end;

function TRecti.Contains(x, y:LongInt): Boolean;
begin
  Result := ((((self.x <= x) and (x < (self.x + Width))) and (self.y <= y)) and (y < (self.y + Height)));
end;

function TRecti.Contains(const Point: TPoint2i): Boolean;
begin
  Result := ((((x <= Point.x) and (Point.x < (x + Width))) and (y <= Point.y)) and (Point.y < (y + Height)));
end;
             {
function TRecti.Contains(const Point: TPoint2f): Boolean;
begin
  Result := ((((x <= Point.x) and (Point.x < (x + Width))) and (y <= Point.y)) and (Point.y < (y + Height)));
end;           }

function TRecti.Contains(const Rect: TRecti): Boolean;
begin
  Result := ((((x <= Rect.x) and ((Rect.x + Rect.Width) <= (x + Width))) and (x <= Rect.y)) and ((Rect.y + Rect.Height) <= (y + Height)));
end;

function TRecti.Intersects(const Rect: TRecti): Boolean;
begin
  Result := ((((Rect.X < (X + Width)) and (X < (Rect.X + Rect.Width))) and (Rect.Y < (Y + Height))) and (Y < (Rect.Y + Rect.Height)));
end;

function TRecti.Intersect(const Rect1,Rect2: TRecti): TRecti;
var
  X1, Y1, X2, Y2 : Integer;
begin
  Result := EmptyRect;
  X1 := Max(Rect1.x, Rect2.x);
  Y1 := Max(Rect1.y, Rect2.y);
  X2 := Min(Rect1.x + Rect1.Width, Rect2.x + Rect2.Width);
  Y2 := Min(Rect1.y + Rect1.Height, Rect2.y + Rect2.Height);
  if ((X2 > X1) and (Y2 > Y1)) then
  begin
    Result.X := X1;
    Result.Y := Y1;
    Result.Width := X2 - X1;
    Result.Height := Y2 - Y1;
  end;
end;

function TRecti.Union(const Rect1, Rect2: TRecti): TRecti;
var
  X1, Y1 : LongInt;
begin
  X1 := Min(Rect1.X,Rect2.X);
  Y1 := Min(Rect1.Y,Rect2.Y);
  Result.X := X1;
  Result.Y := Y1;
  Result.Width := Max(Rect1.X + Rect1.Width, Rect2.X + Rect2.Width) - X1;
  Result.Height := Max(Rect1.Y + Rect1.Height, Rect2.Y + Rect2.Height) - Y1;
end;

class operator TRecti.Equal(const Rect1, Rect2: TRecti): Boolean;
begin
  Result := ((((Rect1.X = Rect2.X) and (Rect1.Y = Rect2.Y)) and (Rect1.Width = Rect2.Width)) and (Rect1.Height = Rect2.Height));
end;

class operator TRecti.NotEqual(const Rect1, Rect2: TRecti): Boolean;
begin
  Result := ((((Rect1.X <> Rect2.X) and (Rect1.Y <> Rect2.Y)) and (Rect1.Width <> Rect2.Width)) and (Rect1.Height <> Rect2.Height));
end;
{$ENDREGION}

{$REGION 'TVec2f'}
class operator TVec2f.Equal(const a, b: TVec2f): Boolean;
begin
  with b - a do
    Result := (abs(x) <= EPS) and (abs(y) <= EPS);
end;

class operator TVec2f.Add(const a, b: TVec2f): TVec2f;
begin
  Result.x := a.x + b.x;
  Result.y := a.y + b.y;
end;

class operator TVec2f.Subtract(const a, b: TVec2f): TVec2f;
begin
  Result.x := a.x - b.x;
  Result.y := a.y - b.y;
end;

class operator TVec2f.Multiply(const a, b: TVec2f): TVec2f;
begin
  Result.x := a.x * b.x;
  Result.y := a.y * b.y;
end;

class operator TVec2f.Multiply(const v: TVec2f; x: Single): TVec2f;
begin
  Result.x := v.x * x;
  Result.y := v.y * x;
end;

function TVec2f.Dot(const v: TVec2f): Single;
begin
  Result := x * v.x + y * v.y;
end;

function TVec2f.Reflect(const n: TVec2f): TVec2f;
begin
  Result := Self - n * (2 * Dot(n));
end;

function TVec2f.Refract(const n: TVec2f; Factor: Single): TVec2f;
var
  d, s : Single;
begin
  d := Dot(n);
  s := 1 - sqr(Factor) * (1 - sqr(d));
  if s < EPS then
    Result := Reflect(n)
  else
    Result := Self * Factor - n * (sqrt(s) + d * Factor);
end;

function TVec2f.Length: Single;
begin
  Result := sqrt(LengthQ);
end;

function TVec2f.LengthQ: Single;
begin
  Result := sqr(x) + sqr(y);
end;

function TVec2f.Normal: TVec2f;
var
  Len : Single;
begin
  Len := Length;
  if Len < EPS then
    Result := Vec2f(0, 0)
  else
    Result := Self * (1 / Len);
end;

function TVec2f.Dist(const v: TVec2f): Single;
var
  p : TVec2f;
begin
  p := v - Self;
  Result := p.Length;
end;

function TVec2f.DistQ(const v: TVec2f): Single;
var
  p : TVec2f;
begin
  p := v - Self;
  Result := p.LengthQ;
end;

function TVec2f.Lerp(const v: TVec2f; t: Single): TVec2f;
begin
  Result := Self + (v - Self) * t;
end;

function TVec2f.Min(const v: TVec2f): TVec2f;
begin
  Result.x := JEN_Math.Min(x, v.x);
  Result.y := JEN_Math.Min(y, v.y);
end;

function TVec2f.Max(const v: TVec2f): TVec2f;
begin
  Result.x := JEN_Math.Max(x, v.x);
  Result.y := JEN_Math.Max(y, v.y);
end;

function TVec2f.Clamp(const MinClamp, MaxClamp: TVec2f): TVec2f;
begin
  Result := Vec2f(JEN_Math.Clamp(x, MinClamp.x, MaxClamp.x),
                  JEN_Math.Clamp(y, MinClamp.y, MaxClamp.y));
end;

function TVec2f.Rotate(Angle: Single): TVec2f;
var
  s, c : Single;
begin
  SinCos(Angle, s, c);
  Result := Vec2f(x * c - y * s, x * s + y * c);
end;

function TVec2f.Angle(const v: TVec2f): Single;
begin
  Result := ArcTan2(x * v.y - y * v.x, x * v.x + y * v.y);
end;
{$ENDREGION}

{$REGION 'TVec3f'}
class operator TVec3f.Equal(const a, b: TVec3f): Boolean;
begin
  with b - a do
    Result := (abs(x) <= EPS) and (abs(y) <= EPS) and (abs(z) <= EPS);
end;

class operator TVec3f.Add(const a, b: TVec3f): TVec3f;
begin
  Result.x := a.x + b.x;
  Result.y := a.y + b.y;
  Result.z := a.z + b.z;
end;

class operator TVec3f.Subtract(const a, b: TVec3f): TVec3f;
begin
  Result.x := a.x - b.x;
  Result.y := a.y - b.y;
  Result.z := a.z - b.z;
end;

class operator TVec3f.Multiply(const a, b: TVec3f): TVec3f;
begin
  Result.x := a.x * b.x;
  Result.y := a.y * b.y;
  Result.z := a.z * b.z;
end;

class operator TVec3f.Multiply(const v: TVec3f; x: Single): TVec3f;
begin
  Result.x := v.x * x;
  Result.y := v.y * x;
  Result.z := v.z * x;
end;

function TVec3f.Dot(const v: TVec3f): Single;
begin
  Result := x * v.x + y * v.y + z * v.z;
end;

function TVec3f.Cross(const v: TVec3f): TVec3f;
begin
  Result.x := y * v.z - z * v.y;
  Result.y := z * v.x - x * v.z;
  Result.z := x * v.y - y * v.x;
end;

function TVec3f.Reflect(const n: TVec3f): TVec3f;
begin
  Result := Self - n * (2 * Dot(n));
end;

function TVec3f.Refract(const n: TVec3f; Factor: Single): TVec3f;
var
  d, s : Single;
begin
  d := Dot(n);
  s := (1 - sqr(Factor)) * (1 - sqr(d));
  if s < EPS then
    Result := Reflect(n)
  else
    Result := Self * Factor - n * (sqrt(s) + d * Factor);
end;

function TVec3f.Length: Single;
begin
  Result := sqrt(LengthQ);
end;

function TVec3f.LengthQ: Single;
begin
  Result := sqr(x) + sqr(y) + sqr(z);
end;

function TVec3f.Normal: TVec3f;
var
  Len : Single;
begin
  Len := Length;
  if Len < EPS then
    Result := Vec3f(0, 0, 0)
  else
    Result := Self * (1 / Len);
end;

function TVec3f.Dist(const v: TVec3f): Single;
var
  p : TVec3f;
begin
  p := v - Self;
  Result := p.Length;
end;

function TVec3f.DistQ(const v: TVec3f): Single;
var
  p : TVec3f;
begin
  p := v - Self;
  Result := p.LengthQ;
end;

function TVec3f.Lerp(const v: TVec3f; t: Single): TVec3f;
begin
  Result := Self + (v - Self) * t;
end;

function TVec3f.Min(const v: TVec3f): TVec3f;
begin
  Result.x := JEN_Math.Min(x, v.x);
  Result.y := JEN_Math.Min(y, v.y);
  Result.z := JEN_Math.Min(z, v.z);
end;

function TVec3f.Max(const v: TVec3f): TVec3f;
begin
  Result.x := JEN_Math.Max(x, v.x);
  Result.y := JEN_Math.Max(y, v.y);
  Result.z := JEN_Math.Max(z, v.z);
end;

function TVec3f.Clamp(const MinClamp, MaxClamp: TVec3f): TVec3f;
begin
  Result := Vec3f(JEN_Math.Clamp(x, MinClamp.x, MaxClamp.x),
                  JEN_Math.Clamp(y, MinClamp.y, MaxClamp.y),
		              JEN_Math.Clamp(z, MinClamp.z, MaxClamp.z));
end;

function TVec3f.Rotate(Angle: Single; const Axis: TVec3f): TVec3f;
var
  s, c : Single;
  v0, v1, v2 : TVec3f;
begin
  SinCos(Angle, s, c);
  v0 := Axis * Dot(Axis);
  v1 := Self - v0;
  v2 := Axis.Cross(v1);
  Result.x := v0.x + v1.x * c + v2.x * s;
  Result.y := v0.y + v1.y * c + v2.y * s;
  Result.z := v0.z + v1.z * c + v2.z * s;
end;

function TVec3f.Angle(const v: TVec3f): Single;
begin
  Result := ArcCos(Dot(v) / sqrt(LengthQ * v.LengthQ))
end;

function TVec3f.MultiOp(out r: TVec3f; const v1, v2, op1, op2: TVec3f): Single;
begin
  r.x := v1.x * op1.x + v2.x * op2.x;
  r.y := v1.y * op1.y + v2.y * op2.y;
  r.z := v1.z * op1.z + v2.z * op2.z;
  Result := r.x + r.y + r.z;
  // add   = (v1, v2, 1, 1)
  // sub   = (v1, v2, 1, -1)
  // neg   = (v1, 0, -1, 0)
  // dot   = (v1, 0, v2, 0)
  // cross = (v1.yzx, v2.yzx, v2.zxy, -v1.zxy)
  // lenq  = (v1, 0, v1, 0)
  // lerp  = (v1, v2, 1 - t, t)
  // etc.
end;
{$ENDREGION}

{$REGION 'TVec4f'}
class operator TVec4f.Equal(const a, b: TVec4f): Boolean;
begin
  with b - a do
    Result := (abs(x) <= EPS) and (abs(y) <= EPS) and (abs(z) <= EPS) and (abs(w) <= EPS);
end;

class operator TVec4f.Add(const a, b: TVec4f): TVec4f;
begin
  Result.x := a.x + b.x;
  Result.y := a.y + b.y;
  Result.z := a.z + b.z;
  Result.w := a.w + b.w;
end;

class operator TVec4f.Subtract(const a, b: TVec4f): TVec4f;
begin
  Result.x := a.x - b.x;
  Result.y := a.y - b.y;
  Result.z := a.z - b.z;
  Result.w := a.w - b.w;
end;

class operator TVec4f.Multiply(const a, b: TVec4f): TVec4f;
begin
  Result.x := a.x * b.x;
  Result.y := a.y * b.y;
  Result.z := a.z * b.z;
  Result.w := a.w * b.w;
end;

class operator TVec4f.Multiply(const v: TVec4f; x: Single): TVec4f;
begin
  Result.x := v.x * x;
  Result.y := v.y * x;
  Result.z := v.z * x;
  Result.w := v.w * x;
end;

function TVec4f.Dot(const v: TVec3f): Single;
begin
  Result := x * v.x + y * v.y + z * v.z + w;
end;

function TVec4f.Lerp(const v: TVec4f; t: Single): TVec4f;
begin
  Result := Self + (v - Self) * t;
end;
{$ENDREGION}

{$REGION 'TQuat'}
class operator TQuat.Equal(const q1, q2: TQuat): Boolean;
begin
  Result := (abs(q1.x - q2.x) <= EPS) and
            (abs(q1.y - q2.y) <= EPS) and
            (abs(q1.z - q2.z) <= EPS) and
            (abs(q1.w - q2.w) <= EPS);
end;

class operator TQuat.Add(const q1, q2: TQuat): TQuat;
begin
  Result.x := q1.x + q2.x;
  Result.y := q1.y + q2.y;
  Result.z := q1.z + q2.z;
  Result.w := q1.w + q2.w;
end;

class operator TQuat.Subtract(const q1, q2: TQuat): TQuat;
begin
  Result.x := q1.x - q2.x;
  Result.y := q1.y - q2.y;
  Result.z := q1.z - q2.z;
  Result.w := q1.w - q2.w;
end;

class operator TQuat.Multiply(const q: TQuat; x: Single): TQuat;
begin
  Result.x := q.x * x;
  Result.y := q.y * x;
  Result.z := q.z * x;
  Result.w := q.w * x;
end;

class operator TQuat.Multiply(const q1, q2: TQuat): TQuat;
begin
  Result.x := q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y;
  Result.y := q1.w * q2.y + q1.y * q2.w + q1.z * q2.x - q1.x * q2.z;
  Result.z := q1.w * q2.z + q1.z * q2.w + q1.x * q2.y - q1.y * q2.x;
  Result.w := q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
end;

class operator TQuat.Multiply(const q: TQuat; const v: TVec3f): TVec3f;
begin
  with q * Quat(v.x, v.y, v.z, 0) * q.Invert do
    Result := Vec3f(x, y, z);
end;

function TQuat.Invert: TQuat;
begin
  Result := Quat(-x, -y, -z, w);
end;

function TQuat.Lerp(const q: TQuat; t: Single): TQuat;
begin
  if Dot(q) < 0 then
    Result := Self - (q + Self) * t
  else
    Result := Self + (q - Self) * t;
end;

function TQuat.Dot(const q: TQuat): Single;
begin
  Result := x * q.x + y * q.y + z * q.z + w * q.w;
end;

function TQuat.Normal: TQuat;
var
  Len : Single;
begin
  Len := sqrt(sqr(x) + sqr(y) + sqr(z) + sqr(w));
  if Len > 0 then
  begin
    Len := 1 / Len;
    Result.x := x * Len;
    Result.y := y * Len;
    Result.z := z * Len;
    Result.w := w * Len;
  end;
end;

function TQuat.Euler: TVec3f;
var
  D : Single;
begin
  D := 2 * x * z + y * w;
  if abs(D) > 1 - EPS then
  begin
    Result.x := 0;
    if D > 0 then
      Result.y := -pi * 0.5
    else
      Result.y :=  pi * 0.5;
    Result.z := ArcTan2(-2 * (y * z - w * x), 2 * (w * w + y * y) - 1);
  end else
  begin
    Result.x := -ArcTan2(2 * (y * z + w * x), 2 * (w * w + z * z) - 1);
    Result.y := ArcSin(-d);
    Result.z := -ArcTan2(2 * (x * y + w * z), 2 * (w * w + x * x) - 1);
  end;
end;
{$ENDREGION}

{$REGION 'TMat4f'}
function TMat4f.GetPos: TVec3f;
begin
  Result.x := e03;
  Result.y := e13;
  Result.z := e23;
end;

procedure TMat4f.SetPos(const v: TVec3f);
begin
  e03 := v.x;
  e13 := v.y;
  e23 := v.z;
end;

function TMat4f.GetRot: TQuat;
var
  t, s : Single;
begin
  t := e00 + e11 + e22 + 1;
  with Result do
    if t > EPS then
    begin
      s := 0.5 / sqrt(t);
      w := 0.25 / s;
      x := (e21 - e12) * s;
      y := (e02 - e20) * s;
      z := (e10 - e01) * s;
    end else
      if (e00 > e11) and (e00 > e22) then
      begin
        s := 2 * sqrt(1 + e00 - e11 - e22);
        w := (e21 - e12) / s;
        x := 0.25 * s;
        y := (e01 + e10) / s;
        z := (e02 + e20) / s;
      end else
        if e11 > e22 then
        begin
          s := 2 * sqrt(1 + e11 - e00 - e22);
          w := (e02 - e20) / s;
          x := (e01 + e10) / s;
          y := 0.25 * s;
          z := (e12 + e21) / s;
        end else
        begin
          s := 2 * sqrt(1 + e22 - e00 - e11);
          w := (e10 - e01) / s;
          x := (e02 + e20) / s;
          y := (e12 + e21) / s;
          z := 0.25 * s;
        end;
end;

procedure TMat4f.SetRot(const q: TQuat);
var
  sqw, sqx, sqy, sqz, invs : Single;
  tmp1, tmp2 : Single;
begin
  with q do
  begin
    sqw := w * w;
    sqx := x * x;
    sqy := y * y;
    sqz := z * z;

    invs := 1 / (sqx + sqy + sqz + sqw);
    e00 := ( sqx - sqy - sqz + sqw) * invs;
    e11 := (-sqx + sqy - sqz + sqw) * invs;
    e22 := (-sqx - sqy + sqz + sqw) * invs;

    tmp1 := x * y;
    tmp2 := z * w;
    e10 := 2 * (tmp1 + tmp2) * invs;
    e01 := 2 * (tmp1 - tmp2) * invs;

    tmp1 := x * z;
    tmp2 := y * w;
    e20 := 2 * (tmp1 - tmp2) * invs;
    e02 := 2 * (tmp1 + tmp2) * invs;

    tmp1 := y * z;
    tmp2 := x * w;
    e21 := 2 * (tmp1 + tmp2) * invs;
    e12 := 2 * (tmp1 - tmp2) * invs;
  end;
end;

class operator TMat4f.Add(const a, b: TMat4f): TMat4f;
begin
  with Result do
  begin
    e00 := a.e00 + b.e00; e10 := a.e10 + b.e10; e20 := a.e20 + b.e20; e30 := a.e30 + b.e30;
    e01 := a.e01 + b.e01; e11 := a.e11 + b.e11; e21 := a.e21 + b.e21; e31 := a.e31 + b.e31;
    e02 := a.e02 + b.e02; e12 := a.e12 + b.e12; e22 := a.e22 + b.e22; e32 := a.e32 + b.e32;
    e03 := a.e03 + b.e03; e13 := a.e13 + b.e13; e23 := a.e23 + b.e23; e33 := a.e33 + b.e33;
  end;
end;

class operator TMat4f.Multiply(const a, b: TMat4f): TMat4f;
begin
  with Result do
  begin
    e00 := a.e00 * b.e00 + a.e01 * b.e10 + a.e02 * b.e20 + a.e03 * b.e30;
    e10 := a.e10 * b.e00 + a.e11 * b.e10 + a.e12 * b.e20 + a.e13 * b.e30;
    e20 := a.e20 * b.e00 + a.e21 * b.e10 + a.e22 * b.e20 + a.e23 * b.e30;
    e30 := a.e30 * b.e00 + a.e31 * b.e10 + a.e32 * b.e20 + a.e33 * b.e30;
    e01 := a.e00 * b.e01 + a.e01 * b.e11 + a.e02 * b.e21 + a.e03 * b.e31;
    e11 := a.e10 * b.e01 + a.e11 * b.e11 + a.e12 * b.e21 + a.e13 * b.e31;
    e21 := a.e20 * b.e01 + a.e21 * b.e11 + a.e22 * b.e21 + a.e23 * b.e31;
    e31 := a.e30 * b.e01 + a.e31 * b.e11 + a.e32 * b.e21 + a.e33 * b.e31;
    e02 := a.e00 * b.e02 + a.e01 * b.e12 + a.e02 * b.e22 + a.e03 * b.e32;
    e12 := a.e10 * b.e02 + a.e11 * b.e12 + a.e12 * b.e22 + a.e13 * b.e32;
    e22 := a.e20 * b.e02 + a.e21 * b.e12 + a.e22 * b.e22 + a.e23 * b.e32;
    e32 := a.e30 * b.e02 + a.e31 * b.e12 + a.e32 * b.e22 + a.e33 * b.e32;
    e03 := a.e00 * b.e03 + a.e01 * b.e13 + a.e02 * b.e23 + a.e03 * b.e33;
    e13 := a.e10 * b.e03 + a.e11 * b.e13 + a.e12 * b.e23 + a.e13 * b.e33;
    e23 := a.e20 * b.e03 + a.e21 * b.e13 + a.e22 * b.e23 + a.e23 * b.e33;
    e33 := a.e30 * b.e03 + a.e31 * b.e13 + a.e32 * b.e23 + a.e33 * b.e33;
  end;
end;

class operator TMat4f.Multiply(const m: TMat4f; const v: TVec3f): TVec3f;
begin
  with m do
  begin
    Result.x := e00 * v.x + e01 * v.y + e02 * v.z + e03;
    Result.y := e10 * v.x + e11 * v.y + e12 * v.z + e13;
    Result.z := e20 * v.x + e21 * v.y + e22 * v.z + e23;
  end;
end;
                             {
class operator TMat4f.Multiply(const m: TMat4f; const v: TVec4f): TVec4f;
begin
  with m do
  begin
    Result.x := e00 * v.x + e01 * v.y + e02 * v.z + e03 * v.w;
    Result.y := e10 * v.x + e11 * v.y + e12 * v.z + e13 * v.w;
    Result.z := e20 * v.x + e21 * v.y + e22 * v.z + e23 * v.w;
    Result.w := e30 * v.x + e31 * v.y + e32 * v.z + e33 * v.w;
  end;
end;                     }

class operator TMat4f.Multiply(const m: TMat4f; x: Single): TMat4f;
begin
  with Result do
  begin
    e00 := m.e00 * x; e10 := m.e10 * x; e20 := m.e20 * x; e30 := m.e30 * x;
    e01 := m.e01 * x; e11 := m.e11 * x; e21 := m.e21 * x; e31 := m.e31 * x;
    e02 := m.e02 * x; e12 := m.e12 * x; e22 := m.e22 * x; e32 := m.e32 * x;
    e03 := m.e03 * x; e13 := m.e13 * x; e23 := m.e23 * x; e33 := m.e33 * x;
  end;
end;

procedure TMat4f.Identity;
const
  IdentMat : TMat4f = (
    e00: 1; e10: 0; e20: 0; e30: 0;
    e01: 0; e11: 1; e21: 0; e31: 0;
    e02: 0; e12: 0; e22: 1; e32: 0;
    e03: 0; e13: 0; e23: 0; e33: 1;
  );
begin
  Self := IdentMat;
end;

function TMat4f.Det: Single;
begin
  Result := e00 * (e11 * (e22 * e33 - e32 * e23) - e21 * (e12 * e33 - e32 * e13) + e31 * (e12 * e23 - e22 * e13)) -
            e10 * (e01 * (e22 * e33 - e32 * e23) - e21 * (e02 * e33 - e32 * e03) + e31 * (e02 * e23 - e22 * e03)) +
            e20 * (e01 * (e12 * e33 - e32 * e13) - e11 * (e02 * e33 - e32 * e03) + e31 * (e02 * e13 - e12 * e03)) -
            e30 * (e01 * (e12 * e23 - e22 * e13) - e11 * (e02 * e23 - e22 * e03) + e21 * (e02 * e13 - e12 * e03));
end;

function TMat4f.Inverse: TMat4f;
var
  D : Single;
begin
  D := 1 / Det;
  Result.e00 :=  (e11 * (e22 * e33 - e32 * e23) - e21 * (e12 * e33 - e32 * e13) + e31 * (e12 * e23 - e22 * e13)) * D;
  Result.e01 := -(e01 * (e22 * e33 - e32 * e23) - e21 * (e02 * e33 - e32 * e03) + e31 * (e02 * e23 - e22 * e03)) * D;
  Result.e02 :=  (e01 * (e12 * e33 - e32 * e13) - e11 * (e02 * e33 - e32 * e03) + e31 * (e02 * e13 - e12 * e03)) * D;
  Result.e03 := -(e01 * (e12 * e23 - e22 * e13) - e11 * (e02 * e23 - e22 * e03) + e21 * (e02 * e13 - e12 * e03)) * D;
  Result.e10 := -(e10 * (e22 * e33 - e32 * e23) - e20 * (e12 * e33 - e32 * e13) + e30 * (e12 * e23 - e22 * e13)) * D;
  Result.e11 :=  (e00 * (e22 * e33 - e32 * e23) - e20 * (e02 * e33 - e32 * e03) + e30 * (e02 * e23 - e22 * e03)) * D;
  Result.e12 := -(e00 * (e12 * e33 - e32 * e13) - e10 * (e02 * e33 - e32 * e03) + e30 * (e02 * e13 - e12 * e03)) * D;
  Result.e13 :=  (e00 * (e12 * e23 - e22 * e13) - e10 * (e02 * e23 - e22 * e03) + e20 * (e02 * e13 - e12 * e03)) * D;
  Result.e20 :=  (e10 * (e21 * e33 - e31 * e23) - e20 * (e11 * e33 - e31 * e13) + e30 * (e11 * e23 - e21 * e13)) * D;
  Result.e21 := -(e00 * (e21 * e33 - e31 * e23) - e20 * (e01 * e33 - e31 * e03) + e30 * (e01 * e23 - e21 * e03)) * D;
  Result.e22 :=  (e00 * (e11 * e33 - e31 * e13) - e10 * (e01 * e33 - e31 * e03) + e30 * (e01 * e13 - e11 * e03)) * D;
  Result.e23 := -(e00 * (e11 * e23 - e21 * e13) - e10 * (e01 * e23 - e21 * e03) + e20 * (e01 * e13 - e11 * e03)) * D;
  Result.e30 := -(e10 * (e21 * e32 - e31 * e22) - e20 * (e11 * e32 - e31 * e12) + e30 * (e11 * e22 - e21 * e12)) * D;
  Result.e31 :=  (e00 * (e21 * e32 - e31 * e22) - e20 * (e01 * e32 - e31 * e02) + e30 * (e01 * e22 - e21 * e02)) * D;
  Result.e32 := -(e00 * (e11 * e32 - e31 * e12) - e10 * (e01 * e32 - e31 * e02) + e30 * (e01 * e12 - e11 * e02)) * D;
  Result.e33 :=  (e00 * (e11 * e22 - e21 * e12) - e10 * (e01 * e22 - e21 * e02) + e20 * (e01 * e12 - e11 * e02)) * D;
end;

function TMat4f.Transpose: TMat4f;
begin
  Result.e00 := e00; Result.e10 := e01; Result.e20 := e02; Result.e30 := e03;
  Result.e01 := e10; Result.e11 := e11; Result.e21 := e12; Result.e31 := e13;
  Result.e02 := e20; Result.e12 := e21; Result.e22 := e22; Result.e32 := e23;
  Result.e03 := e30; Result.e13 := e31; Result.e23 := e32; Result.e33 := e33;
end;

procedure TMat4f.Translate(const v: TVec3f);
var
  m : TMat4f;
begin
  m.Identity;
  m.Pos := v;
  Self := Self * m;
end;

procedure TMat4f.Rotate(Angle: Single; const Axis: TVec3f);
var
  m : TMat4f;
begin
  m := Mat4f(Angle, Axis);
  Self := Self * m;
end;

procedure TMat4f.Scale(const v: TVec3f);
var
  m : TMat4f;
begin
  m.Identity;
  m.e00 := v.x;
  m.e11 := v.y;
  m.e22 := v.z;
  Self := Self * m;
end;

procedure TMat4f.LookAt(const Pos, Target, Up: TVec3f);
var
  R, U, D : TVec3f;
begin
  D := (Pos - Target);
  D := D.Normal;
  R := Up.Cross(D);
  R := R.Normal;
  U := D.Cross(R);

  e00 := R.x; e01 := R.y; e02 := R.z; e03 := -Pos.Dot(R);
  e10 := U.x; e11 := U.y; e12 := U.z; e13 := -Pos.Dot(U);
  e20 := D.x; e21 := D.y; e22 := D.z; e23 := -Pos.Dot(D);
  e30 := 0;   e31 := 0;   e32 := 0;   e33 := 1;
end;

procedure TMat4f.Ortho(Left, Right, Bottom, Top, ZNear, ZFar: Single);
begin
  e00 := 2 / (Right - Left);
  e10 := 0;
  e20 := 0;
  e30 := 0;

  e01 := 0;
  e11 := 2 / (Top - Bottom);
  e21 := 0;
  e31 := 0;

  e02 := 0;
  e12 := 0;
  e22 := -2 / (ZFar - ZNear);
  e32 := 0;

  e03 := -(Right + Left) / (Right - Left);
  e13 := -(Top + Bottom) / (Top - Bottom);
  e23 := -(ZFar + ZNear) / (ZFar - ZNear);
  e33 := 1;
end;

procedure TMat4f.Frustum(Left, Right, Bottom, Top, ZNear, ZFar: Single);
begin
  e00 := 2 * ZNear / (Right - Left);
  e10 := 0;
  e20 := 0;
  e30 := 0;

  e01 := 0;
  e11 := 2 * ZNear / (Top - Bottom);
  e21 := 0;
  e31 := 0;

  e02 := (Right + Left) / (Right - Left);
  e12 := (Top + Bottom) / (Top - Bottom);
  e22 := -(ZFar + ZNear) / (ZFar - ZNear);
  e32 := -1;

  e03 := 0;
  e13 := 0;
  e23 := -2 * ZFar * ZNear / (ZFar - ZNear);
  e33 := 0;
end;

procedure TMat4f.Perspective(FOV, Aspect, ZNear, ZFar: Single);
var
  x, y : Single;
begin
  y := ZNear * Tan(FOV * 0.5 * deg2rad);
  x := y * Aspect;
  Frustum(-x, x, -y, y, ZNear, ZFar);
end;

function TMat4f.GetRotPart: TMat4f;
begin
  Result.e00 := e00;
  Result.e01 := e01;
  Result.e02 := e02;
  Result.e03 := 0;
  Result.e10 := e10;
  Result.e11 := e11;
  Result.e12 := e12;
  Result.e13 := 0;
  Result.e20 := e20;
  Result.e21 := e21;
  Result.e22 := e22;
  Result.e23 := 0;
  Result.e30 := 0;
  Result.e31 := 0;
  Result.e32 := 0;
  Result.e33 := 1;
end;
{$ENDREGION}
end.

