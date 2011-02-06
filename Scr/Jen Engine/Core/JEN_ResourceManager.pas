unit JEN_ResourceManager;

interface

uses
  JEN_Utils,
  JEN_OpenglHeader;

type
  TResourceType = (rtTexture);

  TResource = class
    constructor Create(const Name: string);
  public
    Name : string;
    Ref  : LongInt;
  end;

  TTextureFilter =  (tfNone, tfBilinear, tfTrilinear, tfAniso);

  TTexture = class(TResource)
    constructor Create(const Name: string);
    destructor Destroy; override;
  private
  public
    FID : GLEnum;
    FSampler : GLEnum;
    FWidth  : Integer;
    FHeight : Integer;
    FFilter : TTextureFilter;
    FClamp  : Boolean;
    FMipMap : Boolean;
    procedure SetFilter(Value: TTextureFilter);
    procedure SetClamp(Value: Boolean);
  {
    procedure GenLevels;
    procedure DataGet(Data: Pointer; Level: LongInt = 0; CFormat: TGLConst = GL_RGBA; DFormat: TGLConst = GL_UNSIGNED_BYTE);
    procedure DataSet(X, Y, Width, Height: LongInt; Data: Pointer; Level: LongInt = 0; CFormat: TGLConst = GL_RGBA; DFormat: TGLConst = GL_UNSIGNED_BYTE);
    procedure DataCopy(XOffset, YOffset, X, Y, Width, Height: LongInt; Level: LongInt = 0);   }
    procedure Bind(Channel: Byte = 0);
    property Width: LongInt read FWidth;
    property Height: LongInt read FHeight;
    property Filter: TTextureFilter read FFilter write SetFilter;
    property Clamp: Boolean read FClamp write SetClamp;
  end;

  TResLoader = class
  public
    Ext : string;
    Resource : TResourceType;
    function Load(const Stream : TStream;var Resource : TResource) : Boolean; virtual; abstract;
  end;

  TMipMap = record
    Size : LongWord;
    Data : Pointer;
  end;

  TTextureInfo = record
    Format  : LongWord;
    Format2 : LongWord;
    MipMaps : array of TMipMap;
  end;

  TResourceManager = class
  constructor Create;
  destructor Destroy; override;
  private
    FResList : TList;
    FLoaderList : TList;
    FErrorTexture : TTexture;
    function Load(const FileName: string; Resource : TResourceType) : TResource; overload;
  public
    function Load(const FileName: string) : TTexture; overload;
    procedure AddResLoader(Loader : TResLoader);
    function Add(Resource: TResource): TResource;
    procedure Delete(Resource: TResource);
    function GetRef(const Name: string): TResource;

    property ErrorTexture : TTexture read FErrorTexture;
  end;

implementation

uses
  JEN_Main;

constructor TResource.Create;
begin
  Self.Name := Name;
  Ref := 1;
end;

constructor TTexture.Create;
begin
  inherited;
  glGenTextures(1, @FID);
end;

destructor TTexture.Destroy;
begin
  glDeleteTextures(1, @FID);
  inherited;
end;

procedure TTexture.SetFilter(Value: TTextureFilter);
const
  FilterMode : array [Boolean, TTextureFilter, 0..1] of GLEnum =
    (((GL_NEAREST, GL_NEAREST), (GL_LINEAR, GL_LINEAR), (GL_LINEAR, GL_LINEAR), (GL_LINEAR, GL_LINEAR)),
     ((GL_NEAREST_MIPMAP_NEAREST, GL_NEAREST), (GL_LINEAR_MIPMAP_NEAREST, GL_LINEAR), (GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR), (GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR)));
begin
  if FFilter <> Value then
  begin
    FFilter := Value;
    Bind;
    glTexParameteri(FSampler, GL_TEXTURE_MIN_FILTER, FilterMode[FMipMap, FFilter, 0]);
    glTexParameteri(FSampler, GL_TEXTURE_MAG_FILTER, FilterMode[FMipMap, FFilter, 1]);
    //if Render.MaxAniso > 0 then
   {   if FFilter = tfAniso then
        glTexParameteri(Sampler, GL_TEXTURE_MAX_ANISOTROPY, TGLConst(Render.MaxAniso))
      else
        glTexParameteri(Sampler, GL_TEXTURE_MAX_ANISOTROPY, TGLConst(1)); }
  end;
end;

procedure TTexture.SetClamp(Value: Boolean);
const
  ClampMode : array [Boolean] of GLEnum = (GL_REPEAT, GL_CLAMP_TO_EDGE);
begin
  if FClamp <> Value then
  begin
    FClamp := Value;
    Bind;
    glTexParameteri(FSampler, GL_TEXTURE_WRAP_S, ClampMode[Clamp]);
    glTexParameteri(FSampler, GL_TEXTURE_WRAP_T, ClampMode[Clamp]);
    glTexParameteri(FSampler, GL_TEXTURE_WRAP_R, ClampMode[Clamp]);
  end;
end;

procedure TTexture.Bind(Channel: Byte = 0);
begin
 // if ResManager.Active[TResType(Channel + Ord(rtTexture))] <> Self then
 // begin
    glActiveTexture(GL_TEXTURE0 + Channel);
    glBindTexture(FSampler, FID);
  // ResManager.Active[TResType(Channel + Ord(rtTexture))] := Self;
//  end;
end;

constructor TResourceManager.Create;
begin
  FResList := TList.Create;
  FLoaderList := TList.Create;
end;

destructor TResourceManager.Destroy;
var
  i : integer;
begin
  for I := 0 to FResList.Count - 1 do
    TResource(FResList[i]).Free;

  for I := 0 to FLoaderList.Count - 1 do
    TResLoader(FLoaderList[i]).Free;

  FResList.Free;
  FLoaderList.Free;

  inherited;
end;

function TResourceManager.Load(const FileName: string) : TTexture;
begin
  Result := TTexture(Load(FileName, rtTexture));
end;

function TResourceManager.Load(const FileName: string; Resource : TResourceType)  : TResource;
var
  I : integer;
  Ext : String;
  eFileName : String;
  RL : TResLoader;
  Stream : TStream;
begin
  Result := nil;
  Ext := Utils.ExtractFileExt(FileName);
  eFileName := Utils.ExtractFileName(FileName);

             {
  if not FileExist(
  begin
    Logout( 'Don''t find loader for file ' + Utils.ExtractFileName(FileName), lmError);
    Exit;
  end;    }

  RL := nil;
  for I := 0 to FLoaderList.Count - 1 do
    if(TResLoader(FLoaderList[i]).Ext = Ext) and (TResLoader(FLoaderList[i]).Resource = Resource) then
       RL := TResLoader(FLoaderList[i]);

  if not Assigned(RL) then
  begin
    Logout('Don''t find loader for file ' + eFileName, lmWarning);
    Exit;
  end;

  Stream := TFileStream.Open(FileName);
  if Assigned(Stream) then
  begin
    case Resource of
      rtTexture: Result := TTexture.Create(eFileName);
    end;
  end else
    Logout('Can''t open file ' + eFileName, lmWarning);

  RL.Load(Stream, Result);
  Add(Result);

  Stream.Free;
      {
  if not Assigned(Result) then
    Logout('Error while loading file ' + eFileName, lmWarning);
          }

end;

procedure TResourceManager.AddResLoader(Loader : TResLoader);
begin
  FLoaderList.Add(Loader);
end;

function TResourceManager.Add(Resource: TResource): TResource;
begin
  FResList.Add(Resource);
end;

procedure TResourceManager.Delete(Resource: TResource);
begin

end;

function TResourceManager.GetRef(const Name: string): TResource;
begin

end;


end.
