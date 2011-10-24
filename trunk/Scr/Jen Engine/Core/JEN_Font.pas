unit JEN_Font;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_Utils,
  JEN_Resource;

type
  TCharInfo = packed record
    TexCoords     : TVec4f;
    Page          : Word;
    BlackBoxX     : LongWord;
    BlackBoxY     : LongWord;
    OriginX       : LongInt;
    OriginY       : LongInt;
    CellWidht     : SmallInt;
    CellHeight    : SmallInt;
  end;
  PCharInfo = ^TCharInfo;

  IFont = interface(JEN_Header.IFont)
  ['{A0099F94-3B64-45B6-971A-606E97CA4D44}']
    procedure Init(PagesCount: Word; Height: LongInt; MaxDist: Word; MaxDistTC: Single);
    procedure AddChar(Char: WideChar;const Info: TCharInfo);
  end;

  TFont = class(TResource, IResource, IFont)
    constructor Create(const FilePath: string);
    destructor Destroy; override;
  private
    class var Shader : IShaderProgram;
    class var ParamsUniform : IShaderUniform;
    FHeight     : LongInt;
    FMaxDist    : Word;
    FMaxDistTC  : Single;
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
    procedure Init(PagesCount: Word; Height: LongInt; MaxDist: Word; MaxDistTC: Single);
    procedure AddChar(Char: WideChar;const Info: TCharInfo);

    function GetTextWidth(const Text: String): Single; stdcall;
    procedure Print(const Text: String; X, Y: Single); stdcall;
  end;

  TFontLoader = class(TResLoader)
    constructor Create;
  public
    function Load(Stream: IStream; var Resource: IResource): Boolean; override;
  end;

implementation

uses
  JEN_Main;

const
  JFIMagic = $544e4f465f4e454a;

constructor TFont.Create;
var
  Res : IShaderResource;
begin
  inherited Create(FilePath, rtFont);
  FScale        := 1.0;
  FColor1       := clWhite;
  FColor2       := clWhite;
  FOutlineColor := clWhite;
  FOutlineSize  := 0;
  FEdgeSmooth   := 1;
  if not Assigned(Shader) then
  begin
    ResMan.Load('|TextShader.xml', Res);
    Shader := Res.Compile;
    ParamsUniform := Shader.Uniform('Params', utVec4);
  end;
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

procedure TFont.Init(PagesCount: Word; Height: LongInt; MaxDist: Word; MaxDistTC: Single);
var
  I : Integer;
begin
  FPagesCount := PagesCount;
  FHeight := Height;
  FMaxDist := MaxDist;
  FMaxDistTC := MaxDistTC;

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
  Mat      : TMat4f;
  Rect     : TRecti;
  Scale    : Single;
  Params   : array[0..3] of TVec4f;
begin
  PosX := X;
  Render.AlphaTest := 1;
  Mat   := Render.Matrix[mt2DMat];
  Scale := Sqrt(Sqr(Mat.e00 + Mat.e01)+Sqr(Mat.e10 + Mat.e11));
  Rect  := Render2D.RCRect;
  Scale := Sqrt(Sqr(2/Rect.Width)+Sqr(2/Rect.Height))/Scale;
  EdgeSmooth   := FEdgeSmooth/(FMaxDist)/FScale*Scale*0.5;
  OutlineSize  := FOutlineSize/(FMaxDist)*0.5;

  Shader.Bind;
  Params[0] := Vec4f(EdgeSmooth, OutlineSize, 10/1024, 1);
  Params[1] := FColor1;
  Params[2] := FColor2;
  Params[3] := FOutLineColor;
  ParamsUniform.Value(Params,4);

  Render2d.BatchBegin;
  for i := 1 to Length(Text) do
  begin
    CharInfo := FChars[Text[i]];
    if not Assigned(CharInfo) then Continue;

    with CharInfo^ do
    begin
      Pos1 := Vec2f(PosX, Y) + Vec2f(OriginX, OriginY) * FScale - Vec2f(FMaxDist, FMaxDist) * FScale;
      Pos2 := Pos1 + Vec2f(BlackBoxX, BlackBoxY) * FScale + Vec2f(FMaxDist, FMaxDist) * FScale * 2;
              {
      Render2D.DrawSprite(Shader, FPages[0], nil, nil, Vec2f(Pos1.X, Pos2.Y), Pos2, Vec2f(Pos2.X, Pos1.Y), Vec2f(Pos1.X, Pos1.Y),
          Vec4f(EdgeSmooth, OutlineSize, (128)/8192, 1), FColor1, FColor2, FOutLineColor, 0, Vec2f(0,0),0);
                    }

      Render2D.DrawSprite(Shader, FPages[0], nil, nil, Vec2f(Pos1.X, Pos2.Y), Pos2, Vec2f(Pos2.X, Pos1.Y), Pos1,
          TexCoords, clWhite, clWhite, clWhite, 0, Vec2f(0,0),0);

      PosX := PosX + (CharInfo^.CellWidht) * FScale + FEdgeSmooth + FOutlineSize * FScale;
    end;
  end;
  Render2d.BatchEnd;
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
      Result := Result + (CharInfo^.CellWidht) * FScale + FEdgeSmooth + FOutlineSize * FScale;
  end;
end;

constructor TFontLoader.Create;
begin
  ExtString := 'jfi';
  ResType := rtFont;
end;

function TFontLoader.Load(Stream: IStream; var Resource: IResource): Boolean;
var
  Font       : IFont;
  Magic      : Int64;

  CharsCount : Word;
  PagesCount : Word;
  Height     : LongInt;
  MaxDist    : Word;
  MaxDistTC  : Single;

  I          : LongInt;
  Char       : WideChar;
  CharInfo   : TCharInfo;
begin
  Result := False;
  if not Assigned(Resource) then Exit;
  Font := Resource as IFont;

  Stream.Read(Magic, 8);
  if (JFIMagic <> Magic) then Exit;
  Stream.Read(Height, SizeOf(Height));
  Stream.Read(MaxDist, SizeOf(MaxDist));
  Stream.Read(MaxDistTC, SizeOf(MaxDistTC));
  Stream.Read(PagesCount, SizeOf(PagesCount));
  Stream.Read(CharsCount, SizeOf(CharsCount));

  Font.Init(PagesCount, Height, MaxDist, MaxDistTC);
  for I := 0 to CharsCount - 1 do
  begin
    Stream.Read(Char, SizeOf(Char));
    Stream.Read(CharInfo, SizeOf(CharInfo));
    Font.AddChar(Char, CharInfo);
  end;

  Result := True;
end;

end.
