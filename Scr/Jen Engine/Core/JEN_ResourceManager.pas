unit JEN_ResourceManager;

interface

uses
  JEN_Header,
  JEN_Utils,
  JEN_Shader,
  JEN_Texture,
  JEN_Resource;

type
  TMipMap = record
    Size : LongWord;
    Data : Pointer;
  end;

  TTextureInfo = record
    Format  : LongWord;
    Format2 : LongWord;
    MipMaps : array of TMipMap;
  end;

  IResourceManager = interface(JEN_Header.IResourceManager)
    procedure Load(const FilePath: string; var Resource: IResource); overload;

    function GetRef(const Name: string): IResource;
    procedure RegisterLoader(Loader: TResLoader);
    procedure SetResChangeCallBack(Proc: Pointer);

    function GetActiveRes(RT: TResourceType): IUnknown;
    procedure SetActiveRes(RT: TResourceType; Value: IUnknown);

    property Active[RT :TResourceType]: IUnknown read GetActiveRes write SetActiveRes;
  end;

  TResourceManager = class(TInterfacedObject, IResourceManager)
  constructor Create;
  procedure Free; stdcall;
  private
    FResList : TInterfaceList;
    FLoaderList : TList;
    FErrorTexture : TTexture;
    FResChangeCallBack : Pointer;
    FActiveRes: array [TResourceType] of IUnknown;
  public
    DebugTexture : TTexture;

    procedure SetResChangeCallBack(Proc: Pointer);

    function GetActiveRes(RT: TResourceType): IUnknown;
    procedure SetActiveRes(RT: TResourceType; Value: IUnknown);

    function Load(const FilePath: string; ResType: TResourceType): IResource; overload; stdcall;
    procedure Load(const FilePath: string; out Resource: JEN_Header.IShaderResource); overload; stdcall;
    procedure Load(const FilePath: string; out Resource: JEN_Header.ITexture); overload; stdcall;
    procedure Load(const FilePath: string; out Resource: JEN_Header.IFont); overload; stdcall;
    procedure Load(const FilePath: string; var Resource: IResource); overload;

    procedure RegisterLoader(Loader: TResLoader);
    function GetRef(const Name: string): IResource;

    property ErrorTexture : TTexture read FErrorTexture;
  end;

implementation

uses
  JEN_DDSTexture,
  JEN_Font,
  JEN_Main;

constructor TResourceManager.Create;
begin
  FResList := TInterfaceList.Create;
  FLoaderList := TList.Create;

  RegisterLoader(TShaderLoader.Create);
  RegisterLoader(TDDSLoader.Create);
  RegisterLoader(TFontLoader.Create);
  //DebugTexture := TTexture.Create('DEBUG');
end;

procedure TResourceManager.Free;
var
  i : LongInt;
begin
  for I := 0 to FLoaderList.Count - 1 do
    TResLoader(FLoaderList[i]).Free;

  FResList.Free;
  FLoaderList.Free;
end;

procedure TResourceManager.SetResChangeCallBack(Proc: Pointer);
begin
  FResChangeCallBack := Proc;
end;

function TResourceManager.GetActiveRes(RT: TResourceType): IUnknown;
begin
  Result := FActiveRes[RT];
end;

procedure TResourceManager.SetActiveRes(RT: TResourceType; Value: IUnknown);
begin
  FActiveRes[RT] := Value;
end;

procedure TResourceManager.Load(const FilePath: string; out Resource: JEN_Header.IShaderResource);
begin
  Resource := IShaderResource(Load(FilePath, rtShaderRes));
end;

procedure TResourceManager.Load(const FilePath: string; out Resource: JEN_Header.ITexture);
begin
  Resource := ITexture(Load(FilePath, rtTexture));
end;

procedure TResourceManager.Load(const FilePath: string; out Resource: JEN_Header.IFont);
begin
  Resource := IFont(Load(FilePath, rtFont));
end;

procedure TResourceManager.Load(const FilePath: string; var Resource: IResource);
var
  I         : LongInt;
  FileExt   : String;
  FileName  : String;
  Loader    : TResLoader;
  Stream    : TStream;
begin
  if not Assigned(Resource) then
    Exit;

  FileExt := Utils.ExtractFileExt(FilePath);
  FileName := Utils.ExtractFileName(FilePath);

       {
  if not FileExist(
  begin
    Logout( 'Don''t find loader for file ' + Utils.ExtractFileName(FileName), lmError);
    Exit;
  end;    }

  Loader := nil;
  for I := 0 to FLoaderList.Count - 1 do
    if(TResLoader(FLoaderList[i]).ExtString = FileExt) and (TResLoader(FLoaderList[i]).ResType = Resource.ResType) then
       Loader := TResLoader(FLoaderList[i]);

  if not Assigned(Loader) then
  begin
    Logout('Don''t find loader for file ' + FileName, lmWarning);
    Exit;
  end;

  Stream := TFileStream.Open(FilePath);
  if not Assigned(Stream) then
  begin
    Logout('Can''t open file ' + FileName, lmWarning);
    Stream.Free;
    Exit;
  end;

  if not Loader.Load(Stream, Resource) then
  begin
    Stream.Free;
   { Resource := nil;
   { if ResType = ResType then
    begin

     // Resource := DebugTexture;
    end;      }
    Logout('Error while loading file ' + FileName, lmWarning);
    Exit;
  end;

  FResList.Add(Resource);
  LogOut('Loading '+ (Resource as IResource).Name, lmNotify);
end;

function TResourceManager.Load(const FilePath: string; ResType: TResourceType): JEN_Header.IResource;
var
  Resource : IResource;
begin
  case ResType of
    rtShaderRes : Resource := TShaderResource.Create(Utils.ExtractFileName(FilePath), Utils.ExtractFileDir(FilePath));
    rtTexture   : Resource := TTexture.Create(Utils.ExtractFileName(FilePath), Utils.ExtractFileDir(FilePath), tfoNone, 0, 0);
    rtFont      : Resource := TFont.Create(Utils.ExtractFileName(FilePath), Utils.ExtractFileDir(FilePath));
  end;

  Load(FilePath, Resource);
  Result := Resource;
end;

procedure TResourceManager.RegisterLoader(Loader : TResLoader);
begin
  FLoaderList.Add(Loader);
  LogOut('Register '+ TResourceStringName[Loader.ResType] + ' loader. Ext string: ' + Loader.ExtString, lmNotify);
end;

function TResourceManager.GetRef(const Name: string): IResource;
begin

end;

end.
