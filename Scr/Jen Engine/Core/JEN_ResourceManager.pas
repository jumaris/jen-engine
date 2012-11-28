{$A8,B-,C+,D+,E-,F-,G+,H+,I+,J-,K-,L+,M-,N-,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$MINSTACKSIZE $00004000}
{$MAXSTACKSIZE $00100000}
{$IMAGEBASE $00400000}
{$APPTYPE GUI}
{$WARN SYMBOL_DEPRECATED ON}
{$WARN SYMBOL_LIBRARY ON}
{$WARN SYMBOL_PLATFORM ON}
{$WARN SYMBOL_EXPERIMENTAL ON}
{$WARN UNIT_LIBRARY ON}
{$WARN UNIT_PLATFORM ON}
{$WARN UNIT_DEPRECATED ON}
{$WARN UNIT_EXPERIMENTAL ON}
{$WARN HRESULT_COMPAT ON}
{$WARN HIDING_MEMBER ON}
{$WARN HIDDEN_VIRTUAL ON}
{$WARN GARBAGE ON}
{$WARN BOUNDS_ERROR ON}
{$WARN ZERO_NIL_COMPAT ON}
{$WARN STRING_CONST_TRUNCED ON}
{$WARN FOR_LOOP_VAR_VARPAR ON}
{$WARN TYPED_CONST_VARPAR ON}
{$WARN ASG_TO_TYPED_CONST ON}
{$WARN CASE_LABEL_RANGE ON}
{$WARN FOR_VARIABLE ON}
{$WARN CONSTRUCTING_ABSTRACT ON}
{$WARN COMPARISON_FALSE ON}
{$WARN COMPARISON_TRUE ON}
{$WARN COMPARING_SIGNED_UNSIGNED ON}
{$WARN COMBINING_SIGNED_UNSIGNED ON}
{$WARN UNSUPPORTED_CONSTRUCT ON}
{$WARN FILE_OPEN ON}
{$WARN FILE_OPEN_UNITSRC ON}
{$WARN BAD_GLOBAL_SYMBOL ON}
{$WARN DUPLICATE_CTOR_DTOR ON}
{$WARN INVALID_DIRECTIVE ON}
{$WARN PACKAGE_NO_LINK ON}
{$WARN PACKAGED_THREADVAR ON}
{$WARN IMPLICIT_IMPORT ON}
{$WARN HPPEMIT_IGNORED ON}
{$WARN NO_RETVAL ON}
{$WARN USE_BEFORE_DEF ON}
{$WARN FOR_LOOP_VAR_UNDEF ON}
{$WARN UNIT_NAME_MISMATCH ON}
{$WARN NO_CFG_FILE_FOUND ON}
{$WARN IMPLICIT_VARIANTS ON}
{$WARN UNICODE_TO_LOCALE ON}
{$WARN LOCALE_TO_UNICODE ON}
{$WARN IMAGEBASE_MULTIPLE ON}
{$WARN SUSPICIOUS_TYPECAST ON}
{$WARN PRIVATE_PROPACCESSOR ON}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN OPTION_TRUNCATED ON}
{$WARN WIDECHAR_REDUCED ON}
{$WARN DUPLICATES_IGNORED ON}
{$WARN UNIT_INIT_SEQ ON}
{$WARN LOCAL_PINVOKE ON}
{$WARN MESSAGE_DIRECTIVE ON}
{$WARN TYPEINFO_IMPLICITLY_ADDED ON}
{$WARN RLINK_WARNING ON}
{$WARN IMPLICIT_STRING_CAST ON}
{$WARN IMPLICIT_STRING_CAST_LOSS ON}
{$WARN EXPLICIT_STRING_CAST OFF}
{$WARN EXPLICIT_STRING_CAST_LOSS OFF}
{$WARN CVT_WCHAR_TO_ACHAR ON}
{$WARN CVT_NARROWING_STRING_LOST ON}
{$WARN CVT_ACHAR_TO_WCHAR ON}
{$WARN CVT_WIDENING_STRING_LOST ON}
{$WARN NON_PORTABLE_TYPECAST ON}
{$WARN XML_WHITESPACE_NOT_ALLOWED ON}
{$WARN XML_UNKNOWN_ENTITY ON}
{$WARN XML_INVALID_NAME_START ON}
{$WARN XML_INVALID_NAME ON}
{$WARN XML_EXPECTED_CHARACTER ON}
{$WARN XML_CREF_NO_RESOLVE ON}
{$WARN XML_NO_PARM ON}
{$WARN XML_NO_MATCHING_PARM ON}
{$WARN IMMUTABLE_STRINGS OFF}
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
    FResChangeCallBack  : Pointer;
    FResourceCache      : array [TResourceType] of TInterfaceList;
    FActiveRes          : array [TResourceType] of IUnknown;
    FActiveResID        : array [TResourceType] of LongWord;
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
    procedure AddResource(Resource: IResource);

    function CreateTexture(Width, Height: LongWord; Format: TTextureFormat): JEN_Header.ITexture; stdcall;
    function CreateGeomBuffer(GBufferType: TGBufferType; Count, Stride: LongInt; Data: Pointer): IGeomBuffer; stdcall;

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

function TResourceManager.CreateGeomBuffer(GBufferType: TGBufferType; Count, Stride: LongInt; Data: Pointer): IGeomBuffer;
begin
  Result := TGeomBuffer.Create(GBufferType, Count, Stride, Data);
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
