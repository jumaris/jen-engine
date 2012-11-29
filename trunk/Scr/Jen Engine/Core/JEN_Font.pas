unit JEN_Font;

interface

uses
  SysUtils,
  JEN_Header,
  JEN_Math,
  JEN_Helpers,
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
    constructor Create(const FilePath: UnicodeString);
    destructor Destroy; override;
  private
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
    class var Shader : IShaderProgram;
    class var ParamsUniform : IShaderUniform;

    procedure Reload; stdcall;
    procedure Init(PagesCount: Word; Height: LongInt; MaxDist: Word; MaxDistTC: Single);
    procedure AddChar(Char: WideChar;const Info: TCharInfo);

    function GetTextWidth(Text: PWideChar): Single; stdcall;
    procedure Print(Text: PWideChar; X, Y: Single); stdcall;
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

constructor TFont.Create(const FilePath: UnicodeString);
var
  Res : IShaderResource;
begin
  inherited Create(FilePath, rtFont);
  FScale        := 1.0;
  FColor1       := clWhite;
  FColor2       := clWhite;
  FOutlineColor := clWhite;
  FOutlineSize  := 0;
  FEdgeSmooth   := 0.5;
  if not Assigned(Shader) then
  begin
    ResMan.Load('|TextShader.xml', Res);
    Res.Compile(Shader);
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

  Engine.Log('Font ' + FName + ' destroyed');
  inherited;
end;

function TFont.GetScale: Single; stdcall;
begin
  Result := FScale;
end;

procedure TFont.SetScale(Value: Single); stdcall;
begin
  FScale := Value;
end;

function TFont.GetColor: TVec4f; stdcall;
begin
  Result := FColor1;
end;

procedure TFont.SetColor(const Value: TVec4f); stdcall;
begin
  FColor1 := Value;
  FColor2 := Value;
end;

procedure TFont.SetGradColors(const Value1, Value2: TVec4f); stdcall;
begin
  FColor1 := Value1;
  FColor2 := Value2;
end;

function TFont.GetOutlineColor: TVec3f; stdcall;
begin
  Result.X := FOutlineColor.X;
  Result.Y := FOutlineColor.Y;
  Result.Z := FOutlineColor.Z;
end;

procedure TFont.SetOutlineColor(Value: TVec3f); stdcall;
begin
  FOutlineColor := Vec4f(Value.x, Value.y, Value.z, 1);
end;

function TFont.GetOutlineSize: Single; stdcall;
begin
  Result := FOutlineSize;
end;

procedure TFont.SetOutlineSize(const Value: Single); stdcall;
begin
  FOutlineSize := Value;
end;

function TFont.GetEdgeSmooth: Single; stdcall;
begin
  Result := FEdgeSmooth;
end;

procedure TFont.SetEdgeSmooth(Value: Single); stdcall;
begin
  FEdgeSmooth := Value;
end;

procedure TFont.Reload; stdcall;
begin

end;

procedure TFont.Init(PagesCount: Word; Height: LongInt; MaxDist: Word; MaxDistTC: Single);
var
  I        : Integer;
  FileName : UnicodeString;
begin
  FPagesCount := PagesCount;
  FHeight := Height;
  FMaxDist := MaxDist;
  FMaxDistTC := MaxDistTC;

  SetLength(FPages, FPagesCount);
  for I := 0 to FPagesCount - 1 do
  begin
    FileName := FFilePath + '\' + ChangeFileExt(FName,'') + '_' + IntToStr(I) + '.dds';
    ResMan.Load(PWideChar(FileName), FPages[i]);
  end;
end;

procedure TFont.AddChar(Char: WideChar;const Info: TCharInfo);
begin
  GetMem(FChars[Char], SizeOf(TCharInfo));
  FChars[Char]^ := Info;
  //Move(Info, FChars[Char], SizeOf(TCharInfo));
end;

procedure TFont.Print(Text: PWideChar; X, Y: Single); stdcall;
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

  Render2d.Flush;

  Shader.Bind;
  Params[0] := Vec4f(EdgeSmooth, OutlineSize, 10/1024, 1);
  Params[1] := FColor1;
  Params[2] := FColor2;
  Params[3] := FOutLineColor;
  ParamsUniform.Value(Params,4);

  Render2d.BeginDraw(Shader, FPages[0]);
  for i := 0 to Length(Text)-1 do
  begin
    CharInfo := FChars[Text[i]];
    if not Assigned(CharInfo) then Continue;

    with CharInfo^ do
    begin
      Pos1 := Vec2f(PosX, Y) + Vec2f(OriginX, OriginY) * FScale - Vec2f(FMaxDist, FMaxDist) * FScale;
      Pos2 := Pos1 + Vec2f(BlackBoxX, BlackBoxY) * FScale + Vec2f(FMaxDist, FMaxDist) * FScale * 2;

      Render2d.SetData(TexCoords, clWhite, clWhite, clWhite);
      Render2d.DrawQuad(Vec2f(Pos1.X, Pos2.Y), Pos2, Vec2f(Pos2.X, Pos1.Y), Pos1, 0.0, Vec2f(0,0));

      PosX := PosX + (CharInfo^.CellWidht) * FScale + FEdgeSmooth + FOutlineSize * FScale;
    end;
  end;
  Render2d.EndDraw;
end;

function TFont.GetTextWidth(Text: PWideChar): Single; stdcall;
var
  i        : LongInt;
  CharInfo : PCharInfo;
begin
  Result := 0;

  for i := 0 to Length(Text)-1 do
  begin
    CharInfo := FChars[Text[i]];
    if not Assigned(CharInfo) then Continue;

    with CharInfo^ do
      Result := Result + (CharInfo^.CellWidht) * FScale + FEdgeSmooth + FOutlineSize * FScale;
  end;
end;

constructor TFontLoader.Create;
begin
  ExtString := '.jfi';
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


procedure ClearResources(Param: LongInt; Data: Pointer); stdcall;
begin
  TFont.Shader := nil;
  TFont.ParamsUniform := nil;
end;

initialization
begin
  CreateEngine;
  Engine.AddEventListener(evFinish, @ClearResources);
end;

end.
