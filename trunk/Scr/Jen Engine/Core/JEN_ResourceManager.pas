unit JEN_ResourceManager;

interface

uses
  JEN_Utils,
  JEN_OpenglHeader;

type
  TResourceType = (rtTexture);

  TResource = class
    constructor Create(Name: string);
  public
    Name : string;
    Ref  : LongInt;
  end;

  TTexture = class(TResource)
    FID : GLEnum;
    Sampler : GLEnum;
  end;

  TResLoader = class
  public
    Ext : string;
    Resource : TResourceType;
    procedure Load(Stream : TStream;var Resource : TResource); virtual; abstract;
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

constructor TResourceManager.Create;
begin
  ResMan := Self;
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
