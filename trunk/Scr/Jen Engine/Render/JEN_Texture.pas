unit JEN_Texture;

interface

uses
  JEN_Header,
  JEN_Resource,
  JEN_OpenglHeader,
  JEN_Utils,
  JEN_Math;

type
                 {
  ITexture = interface(JEN_Header.ITexture)
  ['{5EC7ADB4-2241-46EE-B5BE-4959B06EA364}{]

  end;                                     }

  TTexture = class(TResource, IResource, ITexture)
    constructor Create(const FilePath: string; Width, Height: LongWord; Format: TTextureFormat); overload;
    constructor Create(Parent: ITexture; S, T, SW, TH: Single); overload;
    destructor Destroy; override;
  private
    FIsSubTex : Boolean;
    FID       : GLhandle;
    FFormat   : TTextureFormat;
    FSampler  : GLEnum;
    FWidth    : LongInt;
    FHeight   : LongInt;
    FS, FT    : Single;
    FSW, FTH  : Single;
    FFilter   : TTextureFilter;
    FClamp    : Boolean;
    FMipMap   : Boolean;
    FMipMapLevels : LongInt;
    FSubTexList : TInterfaceList;
    function GetID: LongWord; stdcall;
    function GetCoordParams: TVec4f; stdcall;
    function GetFormat: TTextureFormat; stdcall;
    procedure SetFormat(Value: TTextureFormat); stdcall;
    function GetWidth: LongWord; stdcall;
    function GetHeight: LongWord; stdcall;
    function GetSampler: LongWord; stdcall;
    procedure SetSampler(Value: LongWord); stdcall;
    function GetFilter: TTextureFilter; stdcall;
    procedure SetFilter(Value: TTextureFilter); stdcall;
    function GetClamp: Boolean; stdcall;
    procedure SetClamp(Value: Boolean); stdcall;
    procedure SetCompare(Value: TTextureCompareMode); stdcall;
    function GettSubTexCount: LongInt; stdcall;
    function GetSubTex(idx: LongInt): ITexture; stdcall;
  public
    procedure Reload; stdcall;
    procedure Flip(Vertical, Horizontal: Boolean); stdcall;
    procedure Split(Vertical, Horizontal: LongWord); stdcall;
    procedure DataSet(Width, Height, Size: LongInt; Data: Pointer; Level: LongInt); stdcall;
  {
    procedure GenLevels;
    procedure DataGet(Data: Pointer; Level: LongInt = 0; CFormat: TGLConst = GL_RGBA; DFormat: TGLConst = GL_UNSIGNED_BYTE);
       procedure DataCopy(XOffset, YOffset, X, Y, Width, Height: LongInt; Level: LongInt = 0);   }
    procedure Bind(Channel: Byte = 0); stdcall;
  end;

const
  TextureFormatInfo : array[TTextureFormat] of record
    Compressed : boolean;
    Swap : boolean;
    DivSize : Byte;
    BlockBytes : Byte;
    InternalFormat : GLenum;
    ExternalFormat : GLenum;
    DataType : GLenum;
  end = (
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  1; InternalFormat: GL_FALSE; ExternalFormat: GL_FALSE; DataType: GL_FALSE),
    (Compressed: True;  Swap : False; DivSize: 4; BlockBytes:  8; InternalFormat: GL_COMPRESSED_RGB_S3TC_DXT1; ExternalFormat: GL_FALSE; DataType: GL_FALSE),
    (Compressed: True;  Swap : False; DivSize: 4; BlockBytes:  8; InternalFormat: GL_COMPRESSED_RGBA_S3TC_DXT1; ExternalFormat: GL_FALSE; DataType: GL_FALSE),
    (Compressed: True;  Swap : False; DivSize: 4; BlockBytes: 16; InternalFormat: GL_COMPRESSED_RGBA_S3TC_DXT3; ExternalFormat: GL_FALSE; DataType: GL_FALSE),
    (Compressed: True;  Swap : False; DivSize: 4; BlockBytes: 16; InternalFormat: GL_COMPRESSED_RGBA_S3TC_DXT5; ExternalFormat: GL_FALSE; DataType: GL_FALSE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  1; InternalFormat: GL_DEPTH_COMPONENT; ExternalFormat: GL_DEPTH_COMPONENT; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  1; InternalFormat: GL_DEPTH_COMPONENT; ExternalFormat: GL_DEPTH_COMPONENT16; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  1; InternalFormat: GL_DEPTH_COMPONENT; ExternalFormat: GL_DEPTH_COMPONENT24; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  1; InternalFormat: GL_DEPTH_COMPONENT; ExternalFormat: GL_DEPTH_COMPONENT32; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  1; InternalFormat: GL_ALPHA8; ExternalFormat: GL_ALPHA; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  1; InternalFormat: GL_LUMINANCE8; ExternalFormat: GL_LUMINANCE; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  2; InternalFormat: GL_LUMINANCE8_ALPHA8; ExternalFormat: GL_LUMINANCE_ALPHA; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  4; InternalFormat: GL_RGBA8; ExternalFormat: GL_BGRA; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  3; InternalFormat: GL_RGB8; ExternalFormat: GL_BGR; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : True;  DivSize: 1; BlockBytes:  2; InternalFormat: GL_RGB5_A1; ExternalFormat: GL_BGRA; DataType: GL_UNSIGNED_SHORT_1_5_5_5_REV),
    (Compressed: False; Swap : True;  DivSize: 1; BlockBytes:  2; InternalFormat: GL_RGB5; ExternalFormat: GL_RGB; DataType: GL_UNSIGNED_SHORT_5_6_5),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  2; InternalFormat: GL_RGBA4; ExternalFormat: GL_BGRA; DataType: GL_UNSIGNED_SHORT_4_4_4_4_REV),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  2; InternalFormat: GL_R16F; ExternalFormat: GL_RED; DataType: GL_HALF_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  4; InternalFormat: GL_R32F; ExternalFormat: GL_RED; DataType: GL_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  4; InternalFormat: GL_RG16F; ExternalFormat: GL_RG; DataType: GL_HALF_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  8; InternalFormat: GL_RG32F; ExternalFormat: GL_RG; DataType: GL_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  8; InternalFormat: GL_RGBA16F; ExternalFormat: GL_RGBA; DataType: GL_HALF_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes: 16; InternalFormat: GL_RGBA32F; ExternalFormat: GL_RGBA; DataType: GL_FLOAT)
  );

implementation

uses
  JEN_Main;

constructor TTexture.Create(Parent: ITexture; S, T, SW, TH: Single);
begin
  inherited Create(Parent.Name + '|' + Utils.IntToStr(LongInt(Self)), rtTexture);
  FIsSubTex := True;
  FID     := Parent.ID;
  FWidth  := Round(Parent.Width * Abs(SW));
  FHeight := Round(Parent.Height * Abs(TH));
  FS      := S;
  FT      := T;
  FSW     := SW;
  FTH     := TH;
  FFormat := Parent.Format;
  FSampler := Parent.Sampler;
end;

constructor TTexture.Create(const FilePath: string; Width, Height: LongWord; Format: TTextureFormat);
begin
  inherited Create(FilePath, rtTexture);
  FWidth  := Width;
  FHeight := Height;
  FS      := 0;
  FT      := 0;
  FSW     := 1;
  FTH     := 1;
  FFormat := Format;
  FSampler := GL_TEXTURE_2D;
  glGenTextures(1, @FID);
  Bind;

  if Format <> tfoNone then
    with TextureFormatInfo[Format] do
    if Compressed then
      glCompressedTexImage2D(GL_TEXTURE_2D, 0, InternalFormat,  Width, Height, 0, 0, nil)
    else
      glTexImage2D(GL_TEXTURE_2D, 0, InternalFormat, Width, Height, 0, ExternalFormat, DataType, nil);

  if (Format = tfoDepth8) or (Format = tfoDepth16) or (Format = tfoDepth24) or (Format = tfoDepth32) then
  begin
    //SetCompare(tcmLEqual);
    glTexParameteri(GL_TEXTURE_2D, GL_DEPTH_TEXTURE_MODE, GL_LUMINANCE);
  end;

  FMipMap := False;
  FFilter := tfiBilinear;
  SetFilter(tfiNone);
  SetClamp(true);
end;

destructor TTexture.Destroy;
begin
  if Assigned(FSubTexList) then
    FSubTexList.Free;

  if FIsSubTex <> True then
    glDeleteTextures(1, @FID);
  LogOut('Texture ' + FName + ' destroyed', lmNotify);
  inherited;
end;

function TTexture.GetID: LongWord;
begin
  Result := FID;
end;

function TTexture.GetCoordParams: TVec4f;
begin
  Result := Vec4f(FS, FT, FSW, FTH);
end;

function TTexture.GetFormat: TTextureFormat;
begin
  Result := FFormat;
end;

procedure TTexture.SetFormat(Value: TTextureFormat);
begin
  FFormat := Value;
end;

function TTexture.GetWidth: LongWord; stdcall;
begin
  Result := FWidth;
end;

function TTexture.GetHeight: LongWord; stdcall;
begin
  Result := FHeight;
end;

function TTexture.GetSampler: LongWord;
begin
  Result := FSampler;
end;

procedure TTexture.SetSampler(Value: LongWord);
begin
  FSampler := Value;
end;

function TTexture.GetFilter: TTextureFilter;
begin
  Result := FFilter;
end;

procedure TTexture.SetFilter(Value: TTextureFilter);
const
  FilterMode : array [Boolean, TTextureFilter, 0..1] of GLEnum =
    (((GL_NEAREST, GL_NEAREST), (GL_LINEAR, GL_LINEAR), (GL_LINEAR, GL_LINEAR), (GL_LINEAR, GL_LINEAR)),
     ((GL_NEAREST_MIPMAP_NEAREST, GL_NEAREST), (GL_LINEAR_MIPMAP_NEAREST, GL_LINEAR), (GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR), (GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR)));
var
  FMaxAniso : LongInt;
begin
  if (FFilter <> Value) and (FISSubTex <> True) then
  begin
    FFilter := Value;
    Bind;
    glTexParameteri(FSampler, GL_TEXTURE_MIN_FILTER, FilterMode[FMipMap, FFilter, 0]);
    glTexParameteri(FSampler, GL_TEXTURE_MAG_FILTER, FilterMode[FMipMap, FFilter, 1]);
   // if Render.MaxAniso > 0 then

    glGetIntegerv(GL_MAX_TEXTURE_MAX_ANISOTROPY, @FMaxAniso);
    FMaxAniso := Min(FMaxAniso, 8);
      if FFilter = tfiAniso then
        glTexParameteri(FSampler, GL_TEXTURE_MAX_ANISOTROPY, FMaxAniso)
      else
        glTexParameteri(FSampler, GL_TEXTURE_MAX_ANISOTROPY, FMaxAniso);
  end;
end;

function TTexture.GetClamp: Boolean;
begin
  Result := FClamp;
end;

procedure TTexture.SetClamp(Value: Boolean);
const
  ClampMode : array[Boolean] of GLEnum = (GL_REPEAT, GL_CLAMP_TO_EDGE);
begin
  if (FClamp <> Value) and (FISSubTex <> True) then
  begin
    FClamp := Value;
    Bind;
    glTexParameteri(FSampler, GL_TEXTURE_WRAP_S, ClampMode[FClamp]);
    glTexParameteri(FSampler, GL_TEXTURE_WRAP_T, ClampMode[FClamp]);
    glTexParameteri(FSampler, GL_TEXTURE_WRAP_R, ClampMode[FClamp]);
  end;
end;

procedure TTexture.SetCompare(Value: TTextureCompareMode);
const
  CompareFunc : array[1..Ord(High(TRenderChannel))] of GLenum = (GL_EQUAL, GL_GEQUAL, GL_LESS, GL_GREATER, GL_EQUAL, GL_NOTEQUAL, GL_ALWAYS, GL_NEVER);
begin
  if (Value <> tcmNone) and (FISSubTex <> True) then
  begin
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, CompareFunc[Ord(Value)]);
  end else
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_NONE);
end;

function TTexture.GettSubTexCount: LongInt;
begin
  if not Assigned(FSubTexList) then
    Exit(0);
  Result := FSubTexList.Count;
end;

function TTexture.GetSubTex(idx: LongInt): ITexture;
begin
  if not Assigned(FSubTexList) then
    Exit(nil);
  Result := FSubTexList[idx] as ITexture;
end;

procedure TTexture.Reload;
begin

end;

procedure TTexture.Flip(Vertical, Horizontal: Boolean);
begin
  if Vertical then
  begin
    FT  := 1 - FT;
    FTH := - FTH;
  end;
  if Horizontal then
  begin
    FS  := 1 - FS;
    FSW := - FSW;
  end;
end;

procedure TTexture.Split(Vertical, Horizontal: LongWord); stdcall;
var
  i, j  : Integer;
begin
  if Assigned(FSubTexList) then
    FSubTexList.Clear
  else
    FSubTexList := TInterfaceList.Create;

  for J := Vertical-1 downto 0 do
    for I :=0 to Horizontal-1 do
      FSubTexList.Add(TTexture.Create(Self, (I/Horizontal)*FSW + FS,(J/Vertical)*FTH + FT, FSW/Horizontal, FTH/Vertical));
end;

procedure TTexture.DataSet(Width, Height, Size: LongInt; Data: Pointer; Level: LongInt);
begin
  if (FFormat = tfoNone) or FIsSubTex then Exit;

  with TextureFormatInfo[FFormat] do
  if Compressed then
    glCompressedTexImage2D(FSampler, Level, InternalFormat, Width, Height, 0, Size, Data)
  else
    glTexImage2D(FSampler, Level, InternalFormat, Width, Height, 0, ExternalFormat, DataType, Data);

  FMipMapLevels := Max(FMipMapLevels, Level);
  FWidth := Max(FWidth, Width);
  FHeight := Max(FHeight, Height);
  glTexParameteri(FSampler, GL_TEXTURE_MAX_LEVEL, FMipMapLevels);
end;
                       {
procedure TTexture.DataSet(X, Y, Width, Height: LongInt; Data: Pointer; Level: LongInt; CFormat, DFormat: TGLConst);
begin
  Bind;
  glTexSubImage2D(FSampler, Level, X, Y, Width, Height, CFormat, DFormat, Data);
end;                 }

procedure TTexture.Bind(Channel: Byte);
begin
  if (ResMan.ActiveID[TResourceType(Channel + Ord(rtTexture))] <> FID) or
     (ResMan.Active[TResourceType(Channel + Ord(rtTexture))] <> ITexture(Self)) then
  begin
    glActiveTexture(GL_TEXTURE0 + Channel);
    glBindTexture(FSampler, FID);
    ResMan.Active[TResourceType(Channel + Ord(rtTexture))] := ITexture(Self);
    ResMan.ActiveID[TResourceType(Channel + Ord(rtTexture))] := FID;
  end;
end;

end.
