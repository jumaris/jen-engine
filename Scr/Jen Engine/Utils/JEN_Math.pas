unit JEN_Math;

interface

Type
  TPoint2i  = record
    x, y : integer;
    class operator Equal(const a, b: TPoint2i): Boolean; inline;
    class operator NotEqual(const a, b: TPoint2i): Boolean; inline;
  end;

  TPoint2f  = record
    x, y : single;
    class operator Equal(const a, b: TPoint2f): Boolean; inline;
    class operator NotEqual(const a, b: TPoint2f): Boolean; inline;
  end;

  TRecti    = record
    x, y          : integer;
    Width, Height : integer;
    private
      function  GetLocation : TPoint2i; inline;
      procedure SetLocation(Location : TPoint2i); inline;
      function  GetCenter   : TPoint2i; inline;
    public
      function Left     : Integer; inline;
      function Right    : Integer; inline;
      function Top      : Integer; inline;
      function Bottom   : Integer; inline;

      property Location : TPoint2i read GetLocation write SetLocation;
      property Center   : TPoint2i read GetCenter;

      function IsEmpty  : Boolean; inline;

      procedure Offset(const Point : TPoint2i);           overload; inline;
      procedure Offset(const offsetX, offsetY: Integer);  overload; inline;

      procedure Inflate(const HAmount, VAmount: Integer); overload; inline;

      function Contains(const x, y : Integer)  : Boolean; overload; inline;
      function Contains(const Point: TPoint2i) : Boolean; overload; inline;
      function Contains(const Point: TPoint2f) : Boolean; overload; inline;
      function Contains(const Rect : TRecti)   : Boolean; overload; inline;
//    function Contains(const Rect : TRectf)  : Boolean; overload; inline;

      function Intersects(const Rect : TRecti) : Boolean; overload; inline;
//    function Intersects(const Rect : TRectf)  : Boolean; overload; inline;
      function Intersect(const Rect1, Rect2 : TRecti)  : TRecti ; overload;  inline;

  //  function Intersect(const Rect : TRectf)  : TRectf ; inline;
      function Union(const Rect1, Rect2 : TRecti): TRecti ; overload;  inline;
  //  function Union(const Rect1, Rect2 : TRectf): TRectf ; overload;  inline;

      class operator Equal(const Rect1, Rect2 : TRecti): Boolean; inline;
      class operator NotEqual(const Rect1, Rect2 : TRecti): Boolean; inline;
  end;

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

Const
  INF     = 1 / 0;
  NAN     = 0 / 0;
  EPS     = 1.E-05;
  deg2rad = pi / 180;
  rad2deg = 180 / pi;
  ZeroPoint : TPoint2i = (x: 0; y: 0;);
  EmptyRect: TRecti = (x: 0; y: 0; Width: 0; Height: 0);
  NullVec3f : TVec3f = (x: 0; y: 0; z: 0);

function Max(x, y: Single): Single; overload; inline;
function Min(x, y: Single): Single; overload; inline;
function Max(x, y: Integer): Integer; overload; inline;
function Min(x, y: Integer): Integer; overload; inline;
function Sign(x: Single): Integer; inline;
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

function Point2i(x, y : Integer) : TPoint2i; inline;
function Point2f(x, y : Single) : TPoint2f; inline;
function Recti(x, y, Width, Height : Integer) : TRecti; inline;
function Vec3f(x, y, z: Single): TVec3f; inline;

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

function Max(x, y: Integer): Integer;
begin
  if x > y then
    Result := x
  else
    Result := y;
end;

function Min(x, y: Integer): Integer;
begin
  if x < y then
    Result := x
  else
    Result := y;
end;

function Sign(x: Single): Integer;
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
function Point2i(x, y : Integer) : TPoint2i;
begin
  Result.x := x;
  Result.y := y;
end;

function Point2f(x, y : Single) : TPoint2f;
begin
  Result.x := x;
  Result.y := y;
end;

function Recti(x, y, Width, Height : Integer) : TRecti;
begin
  Result.x := x;
  Result.y := y;
  Result.Height := Height;
  Result.Width := Width;
end;

function Vec3f(x, y, z: Single) : TVec3f;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
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

{$REGION 'TPoint2f'}
class operator TPoint2f.Equal(const a, b: TPoint2f): Boolean;
begin
  Result := (a.x = b.x) and (a.y = b.y);
end;

class operator TPoint2f.NotEqual(const a, b: TPoint2f): Boolean;
begin
  Result := (a.x <> b.x) and (a.y <> b.y);
end;
{$ENDREGION}

{$REGION 'TRecti'}
function TRecti.Left : Integer;
begin
  Result := x;
end;

function TRecti.Right : Integer;
begin
  Result := x + Width;
end;

function TRecti.Top : Integer;
begin
  Result := y;
end;

function TRecti.Bottom : Integer;
begin
  Result := y + Height;
end;

function TRecti.GetLocation : TPoint2i;
begin
  Result := Point2i(x, y);
end;

procedure TRecti.SetLocation(Location : TPoint2i);
begin
  x := Location.x;
  y := Location.y;
end;

function TRecti.GetCenter : TPoint2i;
begin
  Result := Point2i(x, y);
end;

function TRecti.IsEmpty : Boolean;
begin
  Result := ((((Width = 0) and (Height = 0)) and (x = 0)) and (y = 0));
end;

procedure TRecti.Offset(const Point : TPoint2i);
begin
  inc(x, Point.x);
  inc(y, Point.y);
end;

procedure TRecti.Offset(const offsetX, offsetY: Integer);
begin
  inc(x, offsetX);
  inc(y, offsetY);
end;

procedure TRecti.Inflate(const HAmount, VAmount: Integer);
begin
  dec(x, HAmount);
  dec(y, VAmount);
  inc(Width, HAmount*2);
  inc(Height, VAmount*2);
end;

function TRecti.Contains(const x, y :integer)   : Boolean;
begin
  Result := ((((self.x <= x) and (x < (self.x + Width))) and (self.y <= y)) and (y < (self.y + Height)));
end;

function TRecti.Contains(const Point: TPoint2i) : Boolean;
begin
  Result := ((((x <= Point.x) and (Point.x < (x + Width))) and (y <= Point.y)) and (Point.y < (y + Height)));
end;

function TRecti.Contains(const Point: TPoint2f) : Boolean;
begin
  Result := ((((x <= Point.x) and (Point.x < (x + Width))) and (y <= Point.y)) and (Point.y < (y + Height)));
end;

function TRecti.Contains(const Rect : TRecti)   : Boolean;
begin
  Result := ((((x <= Rect.x) and ((Rect.x + Rect.Width) <= (x + Width))) and (x <= Rect.y)) and ((Rect.y + Rect.Height) <= (y + Height)));
end;

function TRecti.Intersects(const Rect : TRecti) : Boolean;
begin
  Result := ((((Rect.X < (X + Width)) and (X < (Rect.X + Rect.Width))) and (Rect.Y < (Y + Height))) and (Y < (Rect.Y + Rect.Height)));
end;

function TRecti.Intersect(const Rect1,Rect2 : TRecti) : TRecti;
var
  X1, Y1, X2, Y2 : Integer;
begin
  Result := EmptyRect;
  X1 := Max(Rect1.x, Rect2.x);
  Y1 := Max(Rect1.y, Rect2.y);
  X2 := Min(Rect1.x + Rect1.Width, Rect2.x + Rect2.Width);
  Y2 := Min(Rect1.y + Rect1.Height, Rect2.y + Rect2.Height);
  if ((X2 > X1) and (Y2 > Y1))then
  begin
    Result.X := X1;
    Result.Y := Y1;
    Result.Width := X2 - X1;
    Result.Height := Y2 - Y1;
  end;
end;

function TRecti.Union(const Rect1, Rect2 : TRecti): TRecti;
var
  X1, Y1 : Integer;
begin
  X1 := Min(Rect1.X,Rect2.X);
  Y1 := Min(Rect1.Y,Rect2.Y);
  Result.X := X1;
  Result.Y := Y1;
  Result.Width := Max(Rect1.X + Rect1.Width, Rect2.X + Rect2.Width) - X1;
  Result.Height := Max(Rect1.Y + Rect1.Height, Rect2.Y + Rect2.Height) - Y1;
end;

class operator TRecti.Equal(const Rect1, Rect2 : TRecti): Boolean;
begin
  Result := ((((Rect1.X = Rect2.X) and (Rect1.Y = Rect2.Y)) and (Rect1.Width = Rect2.Width)) and (Rect1.Height = Rect2.Height));
end;

class operator TRecti.NotEqual(const Rect1, Rect2 : TRecti): Boolean;
begin
  Result := ((((Rect1.X <> Rect2.X) and (Rect1.Y <> Rect2.Y)) and (Rect1.Width <> Rect2.Width)) and (Rect1.Height <> Rect2.Height));
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
end.
