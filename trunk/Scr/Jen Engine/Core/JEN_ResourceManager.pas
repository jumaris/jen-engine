unit JEN_ResourceManager;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils,
  JEN_Header,
  JEN_Helpers,
  JEN_Shader,
  JEN_Texture,
  JEN_GeometryBuffer,
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
    procedure Load(const FilePath: UnicodeString; var Resource: IResource); overload;

    function GetRef(const FilePath: UnicodeString; ResType: TResourceType): IResource;
    procedure RegisterLoader(Loader: TResLoader);
  end;

  TResourceManager = class(TInterfacedObject, IResourceManager)
  constructor Create;
  procedure Free; stdcall;
  private
    FLoaderList         : TList;
    FErrorTexture       : TTexture;
    FResourceCache      : array [TResourceType] of TInterfaceList;
    FActiveRes          : array [TResourceType] of IUnknown;
    FActiveResID        : array [TResourceType] of LongWord;
  public
    function GetActiveRes(RT: TResourceType): IUnknown;
    procedure SetActiveRes(RT: TResourceType; Value: IUnknown);
    function GetActiveResID(RT: TResourceType): LongWord;
    procedure SetActiveResID(RT: TResourceType; Value: LongWord);

    function Load(FilePath: PWideChar; ResType: TResourceType): IResource; overload; stdcall;
    procedure Load(FilePath: PWideChar; out Resource: JEN_Header.IShaderResource); overload; stdcall;
    procedure Load(FilePath: PWideChar; out Resource: JEN_Header.ITexture); overload; stdcall;
    procedure Load(FilePath: PWideChar; out Resource: JEN_Header.IFont); overload; stdcall;
    procedure Load(const FilePath: UnicodeString; var Resource: IResource); overload;
    procedure AddResource(Resource: IResource);

    function CreateTexture(Width, Height: LongWord; Format: TTextureFormat): JEN_Header.ITexture; stdcall;

    procedure RegisterLoader(Loader: TResLoader);
    function GetRef(const FilePath: UnicodeString; ResType: TResourceType): IResource;

    property ErrorTexture : TTexture read FErrorTexture;
  end;

implementation

uses
  JEN_DDSTexture,
  JEN_Font,
  JEN_Main;

constructor TResourceManager.Create;
var
  res : TResourceType;
begin
  for res := Low(TResourceType) to High(TResourceType) do
    FResourceCache[res] := TInterfaceList.Create;
  FLoaderList := TList.Create;

  RegisterLoader(TShaderLoader.Create);
  RegisterLoader(TDDSLoader.Create);
  RegisterLoader(TFontLoader.Create);
  //DebugTexture := TTexture.Create('DEBUG');
end;

procedure TResourceManager.Free;
var
  i : LongInt;
  res : TResourceType;
begin
  for I := 0 to FLoaderList.Count - 1 do
    TResLoader(FLoaderList[i]).Free;

  for res := Low(TResourceType) to High(TResourceType) do
    FActiveRes[res] := nil;

  TFont.Shader := nil;
  TFont.ParamsUniform := nil;
                   {
  for I := 0 to FResList.Count - 1 do
    if FResList[i]._AddRef > 4 then
    begin
      Engine.Error('Do not all reference to resource' + IResource(FResList[i]).Name + ' released');
      while FResList[i]._Release > 4 do;
    end else
    begin
      FResList[i]._Release;
      FResList.Del(I);
    end;             }

  for res := Low(TResourceType) to High(TResourceType) do
    FResourceCache[res].Free;
  FLoaderList.Free;
end;

function TResourceManager.GetActiveRes(RT: TResourceType): IUnknown;
begin
  Result := FActiveRes[RT];
end;

procedure TResourceManager.SetActiveRes(RT: TResourceType; Value: IUnknown);
begin
  FActiveRes[RT] := Value;
end;

function TResourceManager.GetActiveResID(RT: TResourceType): LongWord;
begin
  Result := FActiveResID[RT];
end;

procedure TResourceManager.SetActiveResID(RT: TResourceType; Value: LongWord);
begin
  FActiveResID[RT] := Value;
end;

procedure TResourceManager.Load(FilePath: PWideChar; out Resource: JEN_Header.IShaderResource);
begin
  Resource := IShaderResource(Load(FilePath, rtShader));
end;

procedure TResourceManager.Load(FilePath: PWideChar; out Resource: JEN_Header.ITexture);
begin
  Resource := ITexture(Load(FilePath, rtTexture));
end;

procedure TResourceManager.Load(FilePath: PWideChar; out Resource: JEN_Header.IFont);
begin
  Resource := IFont(Load(FilePath, rtFont));
end;

procedure TResourceManager.Load(const FilePath: UnicodeString; var Resource: IResource);
var
  I         : LongInt;
  FileExt   : UnicodeString;
  FileName  : UnicodeString;
  Loader    : TResLoader;
  Stream    : IStream;
begin
  if not Assigned(Resource) then
    Exit;

  FileExt := ExtractFileExt(FilePath);
  FileName := ExtractFileName(FilePath);

       {
  if not FileExist(
  begin
    Logout( 'Don''t find loader for file ' + Utils.ExtractFileName(FileName), lmError);
    Exit;
  end;    }

  Loader := nil;
  for I := 0 to FLoaderList.Count - 1 do      //COMPARE
    if(TResLoader(FLoaderList[i]).ExtString = FileExt) and (TResLoader(FLoaderList[i]).ResType = Resource.ResType) then
       Loader := TResLoader(FLoaderList[i]);

  if not Assigned(Loader) then
  begin
    Engine.Warning('Don''t find loader for file ' + FileName);
    Exit;
  end;

  Helpers.CreateStream(Stream, PWideChar(FilePath), False);
  if not (Assigned(Stream) and Stream.Valid) then
  begin
    Engine.Warning('Can''t open file ' + FileName);
    Exit;
  end;

  if not Loader.Load(Stream, Resource) then
  begin
   {    if ResType = ResType then
    begin

     // Resource := DebuggerTexture;
    end;      }
    Engine.Warning('Error while loading file ' + FileName);
    Exit;
  end;

  AddResource(Resource);
  Engine.Log('Loading '+ (Resource as IResource).Name);
end;

function TResourceManager.Load(FilePath: PWideChar; ResType: TResourceType): JEN_Header.IResource;
var
  Resource : IResource;
begin
  Resource := GetRef(FilePath, ResType);
  if Assigned(Resource) then
    Exit(Resource);

  case ResType of
    rtShader : Resource := TShaderResource.Create(FilePath);
    rtTexture: Resource := TTexture.Create(FilePath);
    rtFont   : Resource := TFont.Create(FilePath);
  end;

  Load(FilePath, Resource);
  Result := Resource;
end;

procedure TResourceManager.AddResource(Resource: IResource);
begin
  if not Assigned(Resource) then
  begin
    Engine.Log('Resouce cannot be null');
    Exit;
  end;

  FResourceCache[Resource.ResType].Add(Resource);
end;

function TResourceManager.CreateTexture(Width, Height: LongWord; Format: TTextureFormat): JEN_Header.ITexture;
var
  Tex : ITexture;
begin
  Tex := TTexture.Create('');
  Tex.Init(Width, Height, Format);
  AddResource(Tex);
  Result := Tex;
end;

procedure TResourceManager.RegisterLoader(Loader : TResLoader);
begin
  FLoaderList.Add(Loader);
  Engine.Log('Register '+ TResourceStringName[Loader.ResType] + ' loader. Ext UnicodeString: ' + Loader.ExtString);
end;

function TResourceManager.GetRef(const FilePath: UnicodeString; ResType: TResourceType): IResource;
var
  i : LongInt;
begin
  Result := nil;
  with FResourceCache[ResType] do
  for I := 0 to Count - 1 do
    if (IResource(Items[i]).FilePath = FilePath) then
      Exit(IResource(Items[i]));
end;

end.
