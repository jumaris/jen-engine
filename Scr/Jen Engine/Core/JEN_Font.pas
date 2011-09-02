unit JEN_Font;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_Utils,
  JEN_Resource;

type
  TCharInfo = packed record
    TexCoords : array[1..4] of record
      X, Y : single;
    end;
    Page         : Word;
    BlackBoxX    : LongWord;
    BlackBoxY    : LongWord;
    OriginX      : LongInt;
    OriginY      : LongInt;
    CellWidht    : SmallInt;
    CellHeight   : SmallInt;
  end;
  PCharInfo = ^TCharInfo;

  IFont = interface(JEN_Header.IFont)
  ['{A0099F94-3B64-45B6-971A-606E97CA4D44}']
    procedure Init(PagesCount: Word; Height: LongInt; MaxDist, DistCorr: Word);
    procedure AddChar(Char: WideChar;const Info: TCharInfo);
  end;

  TFont = class(TResource, IManagedInterface, IResource, IFont)
    constructor Create(const Name, FilePath: string);
    destructor Destroy; override;
  private
    FName     : string;
    FFilePath : string;
    FHeight     : LongInt;
    FMaxDist    : Word;
    FDistCorr   : Word;
    FPagesCount : Word;
    FChars      : Array[WideChar] of PCharInfo;
    FPages      : Array of JEN_Header.ITexture;

    FScale        : Single;
    FColor1       : TVec4f;
    FColor2       : TVec4f;
    FOutlineColor : TVec4f;
    FOutlineSize  : Single;
    FEdgeSmooth   : Single;
    function GetScale: Single; stdcall;
    procedure SetScale(Value: Single); stdcall;
    function GetColor: TVec4f; stdcall;
    procedure SetColor(const Value: TVec4f); stdcall;
    procedure SetGradColors(const Value1, Value2: TVec4f); stdcall;
    function GetOutlineColor: TVec3f; stdcall;
    procedure SetOutlineColor(Value: TVec3f); stdcall;
    function GetOutlineSize: Single; stdcall;
    procedure SetOutlineSize(const Value: Single); stdcall;
    function GetEdgeSmooth: Single; stdcall;
    procedure SetEdgeSmooth(Value: Single); stdcall;

  public
    procedure Reload; stdcall;
    procedure Init(PagesCount: Word; Height: LongInt; MaxDist, DistCorr: Word);
    procedure AddChar(Char: WideChar;const Info: TCharInfo);

    function GetTextWidth(const Text: String): Single; stdcall;
    procedure Print(const Text: String; X, Y: Single); stdcall;
  end;

  TFontLoader = class(TResLoader)
    constructor Create;
  public
    function Load(const Stream: TStream; var Resource: IResource): Boolean; override;
  end;

implementation

uses
  JEN_Main;

const
  JFIMagic = $544e4f465f4e454a;

constructor TFont.Create;
begin
  inherited Create(Name, FilePath, rtFont);
  FScale        := 1.0;
  FColor1       := clWhite;
  FColor2       := clWhite;
  FOutlineColor := clWhite;
  FOutlineSize  := 0;
  FEdgeSmooth   := 1;
end;

destructor TFont.Destroy;
var
  I : WideChar;
begin
  SetLength(FPages, 0);

  for I := WideChar(0) to High(WideChar) do
   if Assigned(FChars[i]) then
      FreeMem(FChars[i]);

  inherited;
end;

function TFont.GetScale: Single;
begin
  Result := FScale;
end;

procedure TFont.SetScale(Value: Single);
begin
  FScale := Value;
end;

function TFont.GetColor: TVec4f;
begin
  Result := FColor1;
end;

procedure TFont.SetColor(const Value: TVec4f);
begin
  FColor1 := Value;
  FColor2 := Value;
end;

procedure TFont.SetGradColors(const Value1, Value2: TVec4f);
begin
  FColor1 := Value1;
  FColor2 := Value2;
end;

function TFont.GetOutlineColor: TVec3f;
begin
  Result.X := FOutlineColor.X;
  Result.Y := FOutlineColor.Y;
  Result.Z := FOutlineColor.Z;
end;

procedure TFont.SetOutlineColor(Value: TVec3f);
begin
  FOutlineColor := Vec4f(Value.x, Value.y, Value.z, 1);
end;

function TFont.GetOutlineSize: Single;
begin
  Result := FOutlineSize;
end;

procedure TFont.SetOutlineSize(const Value: Single);
begin
  FOutlineSize := Value;
end;

function TFont.GetEdgeSmooth: Single;
begin
  Result := FEdgeSmooth;
end;

procedure TFont.SetEdgeSmooth(Value: Single);
begin
  FEdgeSmooth := Value;
end;

procedure TFont.Reload;
begin

end;

procedure TFont.Init(PagesCount: Word; Height: LongInt; MaxDist, DistCorr: Word);
var
  I : Integer;
begin
  FPagesCount := PagesCount;
  FHeight := Height;
  FMaxDist := MaxDist;
  FDistCorr := DistCorr;

  SetLength(FPages, FPagesCount);
  for I := 0 to FPagesCount - 1 do
    ResMan.Load(FFilePath + Utils.ExtractFileName(FName, True) + '_' + Utils.IntToStr(I) + '.dds', FPages[i]);
end;

procedure TFont.AddChar(Char: WideChar;const Info: TCharInfo);
begin
  GetMem(FChars[Char], SizeOf(TCharInfo));
  FChars[Char]^ := Info;
  //Move(Info, FChars[Char], SizeOf(TCharInfo));
end;

procedure TFont.Print(const Text: String; X, Y: Single);
var
  i        : LongInt;
  PosX     : Single;
  Pos1,Pos2: TVec2f;
  CharInfo : PCharInfo;
  EdgeSmooth : Single;
  OutlineSize : Single;
begin
  PosX := X;
  Render.AlphaTest := 1;

  for i := 1 to Length(Text) do
  begin
    CharInfo := FChars[Text[i]];
    if not Assigned(CharInfo) then Continue;

    with CharInfo^ do
    begin
      EdgeSmooth  := FEdgeSmooth/ (128)/FScale/2;
      OutlineSize := FOutlineSize/ (128) /FScale/2;
      Pos1 := Vec2f(PosX, Y) + Vec2f(OriginX, OriginY) * FScale - Vec2f(128, 128)  * FScale;
      Pos2 := Pos1 + Vec2f(BlackBoxX, BlackBoxY) * FScale + Vec2f(128, 128) * FScale*2;
      Render2D.DrawSpriteAdv(Render2d.GetTextShader, FPages[0], nil, nil, Vec4f(Pos1.X, Pos2.Y, TexCoords[1].x, TexCoords[1].y), Vec4f(Pos2.X, Pos2.Y, TexCoords[2].x,TexCoords[2].y), Vec4f(Pos2.X, Pos1.Y, TexCoords[3].x, TexCoords[3].y), Vec4f(Pos1.X, Pos1.Y, TexCoords[4].x, TexCoords[4].y),
        Vec4f(EdgeSmooth, OutlineSize, (128)/8192, 1), FColor1, FColor2, FOutLineColor, Vec2f(0,0), 0);
          PosX := PosX+(CharInfo^.CellWidht)*FScale+FEdgeSmooth+FOutlineSize;
    end;

  end;
end;

function TFont.GetTextWidth(const Text: String): Single;
var
  i        : LongInt;
  CharInfo : PCharInfo;
begin
  Result := 0;

  for i := 1 to Length(Text) do
  begin
    CharInfo := FChars[Text[i]];
    if not Assigned(CharInfo) then Continue;

    with CharInfo^ do
      Result := Result+(CharInfo^.CellWidht)*FScale+FEdgeSmooth+FOutlineSize;
  end;
end;

constructor TFontLoader.Create;
begin
  ExtString := 'jfi';
  ResType := rtFont;
end;

function TFontLoader.Load(const Stream: TStream; var Resource: IResource): Boolean;
var
  Font       : IFont;
  Magic      : Int64;
  I          : LongInt;
  CharsCount : Word;
  PagesCount : Word;
  Height     : LongInt;
  MaxDist    : Word;
  DistCorr   : Word;
  Char       : WideChar;
  CharInfo   : TCharInfo;
begin
  Result := False;
  if not Assigned(Resource) then Exit;
  Font := Resource as IFont;

  Stream.Read(Magic, 8);
  if(JFIMagic <> Magic)then Exit;
  Stream.Read(Height, SizeOf(Height));
  Stream.Read(MaxDist, SizeOf(MaxDist));
  Stream.Read(DistCorr, SizeOf(DistCorr));
  Stream.Read(PagesCount, SizeOf(PagesCount));
  Stream.Read(CharsCount, SizeOf(CharsCount));

  Font.Init(PagesCount, Height, 60, 0);
  for I := 0 to CharsCount - 1 do
  begin
    Stream.Read(Char, SizeOf(Char));
    Stream.Read(CharInfo, SizeOf(CharInfo));
    Font.AddChar(Char, CharInfo);
  end;

  Result := True;
  Stream.Free;
end;

end.
