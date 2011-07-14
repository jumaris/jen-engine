unit JEN_ResourceManager;

interface

uses
  JEN_Header,
  JEN_Utils,
  JEN_Shader,
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
    procedure RegisterLoader(Loader: TResLoader);
    function GetRef(const Name: string): IResource;
    procedure SetResChangeCallBack(Proc: Pointer);

    function GetActiveRes(RT: TResourceType): IUnknown;
    procedure SetActiveRes(RT: TResourceType; Value: IUnknown);

    property Active[RT :TResourceType]: IUnknown read GetActiveRes write SetActiveRes;
  end;

  TResourceManager = class(TInterfacedObject, IResourceManager)
  constructor Create;
  destructor Destroy; override;
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

    function Load(const FileName: string; ResType: TResourceType): JEN_Header.IResource; overload; stdcall;
    procedure Load(const FileName: string; out Resource: JEN_Header.IShaderResource); overload; stdcall;
    procedure Load(const FileName: string; out Resource: JEN_Header.ITexture); overload; stdcall;
    {
    function LoadShader(const FileName: string): JEN_Header.IShaderResource; stdcall;
    function LoadTexture(const FileName: string): JEN_Header.ITexture; stdcall;
             }
    procedure RegisterLoader(Loader: TResLoader);
    function GetRef(const Name: string): IResource;

    property ErrorTexture : TTexture read FErrorTexture;
  end;

implementation

uses
  JEN_DDSTexture,
  JEN_Main;

constructor TResourceManager.Create;
begin
  FResList := TInterfaceList.Create;
  FLoaderList := TList.Create;

  RegisterLoader(TShaderLoader.Create);
  RegisterLoader(TDDSLoader.Create);
  //DebugTexture := TTexture.Create('DEBUG');
end;

destructor TResourceManager.Destroy;
var
  i : LongInt;
begin
  for I := 0 to FLoaderList.Count - 1 do
    TResLoader(FLoaderList[i]).Free;

  FResList.Free;
  FLoaderList.Free;
  inherited;
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

procedure TResourceManager.Load(const FileName: string; out Resource: JEN_Header.IShaderResource);
begin
  Resource := IShaderResource(Load(FileName, rtShader));
end;

procedure TResourceManager.Load(const FileName: string; out Resource: JEN_Header.ITexture);
begin
  Resource := ITexture(Load(FileName, rtTexture));
end;

function TResourceManager.Load(const FileName: string; ResType: TResourceType): JEN_Header.IResource;
var
  I : LongInt;
  Ext : String;
  eFileName : String;
  RL : TResLoader;
  Stream : TStream;
  Resource : IResource;
begin
  Result := nil;
  Resource := nil;
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
    if(TResLoader(FLoaderList[i]).ExtString = Ext) and (TResLoader(FLoaderList[i]).ResType = ResType) then
       RL := TResLoader(FLoaderList[i]);

  if not Assigned(RL) then
  begin
    Logout('Don''t find loader for file ' + eFileName, lmWarning);
    Exit;
  end;

  case ResType of
    rtShader:  Resource := TShaderResource.Create(eFileName);
    rtTexture: Resource := TTexture.Create(eFileName);
  end;

  Result := Resource;

  Stream := TFileStream.Open(FileName);
  if not Assigned(Stream) then
  begin
    Logout('Can''t open file ' + eFileName, lmWarning);
    Stream.Free;
    Exit;
  end;

  if not RL.Load(Stream, IResource(Resource)) then
  begin
    Stream.Free;
   { Resource := nil;
   { if ResType = ResType then
    begin

     // Resource := DebugTexture;
    end;      }
    Logout('Error while loading file ' + eFileName, lmWarning);
    Exit;
  end;

  FResList.Add(Resource);
  LogOut('Loading '+ (Resource as IResource).Name, lmNotify);
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
