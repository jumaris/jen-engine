unit JEN_Resource;

interface

uses
  JEN_Header,
  JEN_OpenglHeader,
  JEN_Utils,
  JEN_Math,
  CoreX_XML;


const
  TResourceStringName : array[TResourceType] of string = ('shader', 'texture', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '');

type
  TResLoader = class
  public
    ExtString : string;
    ResType : TResourceType;
    function Load(const Stream: TStream; var Resource: IResource): Boolean; virtual; abstract;
  end;

  ITexture = interface(JEN_Header.ITexture)
  ['{5EC7ADB4-2241-46EE-B5BE-4959B06EA364}']

  end;

  TTexture = class(TManagedInterface, IManagedInterface, IResource, ITexture)
    constructor Create(const Name: string);
    destructor Destroy; override;
  private
    FName : string;
    FID : GLEnum;
    FSampler : GLEnum;
    FWidth  : LongInt;
    FHeight : LongInt;
    FFilter : TTextureFilter;
    FClamp  : Boolean;
    FMipMap : Boolean;
    function GetName: string; stdcall;
  public
    function GetSampler: LongWord; stdcall;
    procedure SetSampler(Value: LongWord); stdcall;
    function GetFilter: TTextureFilter; stdcall;
    procedure SetFilter(Value: TTextureFilter); stdcall;
    function GetClamp: Boolean; stdcall;
    procedure SetClamp(Value: Boolean); stdcall;
//    procedure DataSet(X, Y, Width, Height: LongInt; Data: Pointer; Level: LongInt = 0; CFormat: TGLConst = GL_RGBA; DFormat: TGLConst = GL_UNSIGNED_BYTE);
  {
    procedure GenLevels;
    procedure DataGet(Data: Pointer; Level: LongInt = 0; CFormat: TGLConst = GL_RGBA; DFormat: TGLConst = GL_UNSIGNED_BYTE);
       procedure DataCopy(XOffset, YOffset, X, Y, Width, Height: LongInt; Level: LongInt = 0);   }
    procedure Bind(Channel: Byte = 0); stdcall;
  end;

implementation

uses JEN_Main;

constructor TTexture.Create;
begin
  inherited Create;
  FName := Name;
  glGenTextures(1, @FID);
end;

destructor TTexture.Destroy;
begin
  glDeleteTextures(1, @FID);
  LogOut('Texture ' + FName + ' destroyed',lmNotify);
  inherited;
end;

function TTexture.GetName: string;
begin
  Result := FName;
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
  if FFilter <> Value then
  begin
    FFilter := Value;
    Bind;
    glTexParameteri(FSampler, GL_TEXTURE_MIN_FILTER, FilterMode[FMipMap, FFilter, 0]);
    glTexParameteri(FSampler, GL_TEXTURE_MAG_FILTER, FilterMode[FMipMap, FFilter, 1]);
   // if Render.MaxAniso > 0 then

    glGetIntegerv(GL_MAX_TEXTURE_MAX_ANISOTROPY, @FMaxAniso);
    FMaxAniso := Min(FMaxAniso, 8);
      if FFilter = tfAniso then
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
  ClampMode : array [Boolean] of GLEnum = (GL_REPEAT, GL_CLAMP_TO_EDGE);
begin
  if FClamp <> Value then
  begin
    FClamp := Value;
    Bind;
    glTexParameteri(FSampler, GL_TEXTURE_WRAP_S, ClampMode[FClamp]);
    glTexParameteri(FSampler, GL_TEXTURE_WRAP_T, ClampMode[FClamp]);
    glTexParameteri(FSampler, GL_TEXTURE_WRAP_R, ClampMode[FClamp]);
  end;
end;
                     {
procedure TTexture.DataSet(X, Y, Width, Height: LongInt; Data: Pointer; Level: LongInt; CFormat, DFormat: TGLConst);
begin
  Bind;
  glTexSubImage2D(Sampler, Level, X, Y, Width, Height, CFormat, DFormat, Data);
end;
                 }
procedure TTexture.Bind(Channel: Byte = 0);
begin
  if ResMan.Active[TResourceType(Channel + Ord(rtTexture))] <> ITexture(Self) then
  begin
    glActiveTexture(GL_TEXTURE0 + Channel);
    glBindTexture(FSampler, FID);
    ResMan.Active[TResourceType(Channel + Ord(rtTexture))] := ITexture(Self);
  end;
end;

end.
