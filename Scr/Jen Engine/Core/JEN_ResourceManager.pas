unit JEN_ResourceManager;

interface

uses
  JEN_Utils,
  JEN_Texture;

type
  TResource = class
  constructor Create(Name: string);
  public
    Name : string;
    Ref  : LongInt;
  end;

  TResLoader = class
  public
    Ext : string;
    function Load(Stream : TStream; Name : String) : TResource; virtual; abstract;
  end;

  TResourceManager = class
  constructor Create;
  destructor Destroy; override;
  private
    FResList : TList;
    FLoaderList : TList;
  public
    function Load(const FileName: string) : TTexture;
    procedure AddResLoader(Loader : TResLoader);
    function Add(Resource: TResource): TResource;
    procedure Delete(Resource: TResource);
    function GetRef(const Name: string): TResource;
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
  FResList := TList.Create;
  FLoaderList := TList.Create;
end;

destructor TResourceManager.Destroy;
begin
  FResList.Free;
  FLoaderList.Free;
  inherited;
end;

function TResourceManager.Load(const FileName: string) : TResource;
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

  for I := 0 to FLoaderList.Count - 1 do
    if(TResLoader(FLoaderList[i]).Ext = Ext) then
       RL := TResLoader(FLoaderList[i]);

  if not Assigned(RL) then
  begin
    Logout('Don''t find loader for file ' + eFileName, lmWarning);
    Exit;
  end;

  Stream := TFileStream.Open(FileName);
  if Assigned(Stream) then
    Result := RL.Load(Stream, eFileName) else
  Logout('Can''t open file ' + eFileName, lmWarning);

  if not Assigned(Result) then
    Logout('Error while loading file ' + eFileName, lmWarning);


end;

procedure TResourceManager.AddResLoader(Loader : TResLoader);
begin
  FLoaderList.Add(Loader);
end;

function TResourceManager.Add(Resource: TResource): TResource;
begin

end;

procedure TResourceManager.Delete(Resource: TResource);
begin

end;

function TResourceManager.GetRef(const Name: string): TResource;
begin

end;


end.
