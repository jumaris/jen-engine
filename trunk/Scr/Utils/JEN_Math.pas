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

Const PointZero : TPoint2i = (x: 0; y: 0;);
      RectEmpty : TRecti   = (x: 0; y: 0; Width: 0; Height: 0);

  function Max(x, y: Single): Single; overload; inline;
  function Min(x, y: Single): Single; overload; inline;
  function Max(x, y: Integer): Integer; overload; inline;
  function Min(x, y: Integer): Integer; overload; inline;
  function Sign(x: Single): Integer; inline;

  function Point2i(const x, y : Integer) : TPoint2i;
  function Point2f(const x, y : Single) : TPoint2f;
  function Recti  (const x, y, Width, Height : Integer) : TRecti;

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
{$ENDREGION}

{$REGION 'Creation'}
function Point2i(const x, y : Integer) : TPoint2i;
begin
  Result.x := x;
  Result.y := y;
end;

function Point2f(const x, y : Single) : TPoint2f;
begin
  Result.x := x;
  Result.y := y;
end;

function Recti(const x, y, Width, Height : Integer) : TRecti;
begin
  Result.x := x;
  Result.y := y;
  Result.Height := Height;
  Result.Width := Width;
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
  Result := RectEmpty;
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

end.
