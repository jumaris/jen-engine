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

    function GetRef(const Name: UnicodeString): IResource;
    procedure RegisterLoader(Loader: TResLoader);

    function GetActiveRes(RT: TResourceType): IUnknown;
    procedure SetActiveRes(RT: TResourceType; Value: IUnknown);
    function GetActiveResID(RT: TResourceType): LongWord;
    procedure SetActiveResID(RT: TResourceType; Value: LongWord);

    property Active[RT :TResourceType]: IUnknown read GetActiveRes write SetActiveRes;
    property ActiveID[RT :TResourceType]: LongWord read GetActiveResID write SetActiveResID;
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
    FActiveResID: array [TResourceType] of LongWord;
  public
    procedure SetResChangeCallBack(Proc: Pointer);

    function GetActiveRes(RT: TResourceType): IUnknown;
    procedure SetActiveRes(RT: TResourceType; Value: IUnknown);
    function GetActiveResID(RT: TResourceType): LongWord;
    procedure SetActiveResID(RT: TResourceType; Value: LongWord);

    function Load(FilePath: PWideChar; ResType: TResourceType): IResource; overload; stdcall;
    procedure Load(FilePath: PWideChar; out Resource: JEN_Header.IShaderResource); overload; stdcall;
    procedure Load(FilePath: PWideChar; out Resource: JEN_Header.ITexture); overload; stdcall;
    procedure Load(FilePath: PWideChar; out Resource: JEN_Header.IFont); overload; stdcall;
    procedure Load(const FilePath: UnicodeString; var Resource: IResource); overload;

    function CreateTexture(Width, Height: LongWord; Format: TTextureFormat): JEN_Header.ITexture; stdcall;
    function CreateGeomBuffer(GBufferType: TGBufferType; Count, Stride: LongInt; Data: Pointer): IGeomBuffer; stdcall;

    procedure RegisterLoader(Loader: TResLoader);
    function GetRef(const Name: UnicodeString): IResource;

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
  res : TResourceType;
begin
  for I := 0 to FLoaderList.Count - 1 do
    TResLoader(FLoaderList[i]).Free;

  for res := Low(TResourceType) to High(TResourceType) do
    FActiveRes[res] := nil;

  for I := 0 to FResList.Count - 1 do
    if FResList[i]._AddRef > 4 then
    begin
      Engine.Error('Do not all reference to resource' + IResource(FResList[i]).Name + ' released');
      while FResList[i]._Release > 4 do;
    end else
      FResList[i]._Release;

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
    Resource := nil;
   { if ResType = ResType then
    begin

     // Resource := DebuggerTexture;
    end;      }
    Engine.Warning('Error while loading file ' + FileName);
    Exit;
  end;

  FResList.Add(Resource);
  Engine.Log('Loading '+ (Resource as IResource).Name);
end;

function TResourceManager.Load(FilePath: PWideChar; ResType: TResourceType): JEN_Header.IResource;
var
  Resource : IResource;
begin
  case ResType of
    rtShader : Resource := TShaderResource.Create(FilePath);
    rtTexture: Resource := TTexture.Create(FilePath);
    rtFont   : Resource := TFont.Create(FilePath);
  end;

  Load(FilePath, Resource);
  Result := Resource;
end;

function TResourceManager.CreateTexture(Width, Height: LongWord; Format: TTextureFormat): JEN_Header.ITexture;
var
  Tex : ITexture;
begin
  Tex := TTexture.Create('');
  Tex.Init(Width, Height, Format);
  FResList.Add(Tex);
  Result := Tex;
end;

function TResourceManager.CreateGeomBuffer(GBufferType: TGBufferType; Count, Stride: LongInt; Data: Pointer): IGeomBuffer;
begin
  Result := TGeomBuffer.Create(GBufferType, Count, Stride, Data);
end;

procedure TResourceManager.RegisterLoader(Loader : TResLoader);
begin
  FLoaderList.Add(Loader);
  Engine.Log('Register '+ TResourceStringName[Loader.ResType] + ' loader. Ext UnicodeString: ' + Loader.ExtString);
end;

function TResourceManager.GetRef(const Name: UnicodeString): IResource;
begin

end;

end.
