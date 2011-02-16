unit JEN_ResourceManager;

interface

uses
  JEN_Utils,
  JEN_Shader,
  JEN_Resource,
  JEN_OpenglHeader;

type
  TTexture = class(TResource)
    constructor Create(const Name: string); override;
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
//    procedure DataSet(X, Y, Width, Height: LongInt; Data: Pointer; Level: LongInt = 0; CFormat: TGLConst = GL_RGBA; DFormat: TGLConst = GL_UNSIGNED_BYTE);
  {
    procedure GenLevels;
    procedure DataGet(Data: Pointer; Level: LongInt = 0; CFormat: TGLConst = GL_RGBA; DFormat: TGLConst = GL_UNSIGNED_BYTE);
       procedure DataCopy(XOffset, YOffset, X, Y, Width, Height: LongInt; Level: LongInt = 0);   }
    procedure Bind(Channel: Byte = 0);
    property Width: LongInt read FWidth;
    property Height: LongInt read FHeight;
    property Filter: TTextureFilter read FFilter write SetFilter;
    property Clamp: Boolean read FClamp write SetClamp;
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
  public
    DebugTexture : TTexture;

    function Load(const FileName: string; Resource : TResourceType) : TResource; overload;
    procedure Load(const FileName: string; var Resource : TTexture); overload;
    procedure Load(const FileName: string; var Resource : TShader); overload;
    function LoadTexture(const FileName: string): TTexture;
    function LoadShader(const FileName: string): TShader;

    procedure RegisterLoader(Loader : TResLoader);
    function Add(Resource: TResource): TResource;
    procedure Delete(Resource: TResource);
    function GetRef(const Name: string): TResource;

    property ErrorTexture : TTexture read FErrorTexture;
  end;

implementation

uses
  JEN_Main;

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
                     {
procedure TTexture.DataSet(X, Y, Width, Height: LongInt; Data: Pointer; Level: LongInt; CFormat, DFormat: TGLConst);
begin
  Bind;
  glTexSubImage2D(Sampler, Level, X, Y, Width, Height, CFormat, DFormat, Data);
end;
                 }
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

  RegisterLoader(TShaderLoader.Create);
  RegisterLoader(TDDSLoader.Create);
  DebugTexture := TTexture.Create('DEBUG');
  Add(DebugTexture);
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

function TResourceManager.LoadShader(const FileName: string) : TShader;
begin
  Result := TShader(Load(FileName, rtShader));
end;

function TResourceManager.LoadTexture(const FileName: string) : TTexture;
begin
  Result := TTexture(Load(FileName, rtTexture));
end;

procedure TResourceManager.Load(const FileName: string; var Resource : TShader);
begin
  Resource := TShader(Load(FileName, rtShader));
end;

procedure TResourceManager.Load(const FileName: string; var Resource : TTexture);
begin
  Resource := TTexture(Load(FileName, rtTexture));
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
    if(TResLoader(FLoaderList[i]).ExtString = Ext) and (TResLoader(FLoaderList[i]).Resource = Resource) then
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
      rtShader: Result := TShader.Create(eFileName);
      rtTexture: Result := TTexture.Create(eFileName);
    end;
  end else
  begin
    Logout('Can''t open file ' + eFileName, lmWarning);
    Stream.Free;
  end;

  if not RL.Load(Stream, Result) then
  begin
    Stream.Free;
    if Resource = rtTexture then
    begin
      Result.Free;
      Result := DebugTexture;
    end;

  end;
  Add(Result);

  if not Assigned(Result) then
    Logout('Error while loading file ' + eFileName, lmWarning);
end;

procedure TResourceManager.RegisterLoader(Loader : TResLoader);
begin
  FLoaderList.Add(Loader);
  Log.AddMsg('Register '+ TResourceStringName[Loader.Resource] + ' loader. Ext string: ' + Loader.ExtString, lmNotify);
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
