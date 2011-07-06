unit JEN_Shader;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_Resource,
  JEN_OpenGlHeader,
  JEN_Utils,
  CoreX_XML;

type
  IShaderResource = interface(JEN_Header.IShaderResource)
  ['{CFF16358-641F-4312-A601-08CC9FC3BEA8}']
    function GetXML: IXML;
    procedure SetXML(Value: IXML);

    property XML: IXML read GetXML write SetXML;
  end;

  TShaderResource = class(TManagedInterface, IResource, IShaderResource)
    constructor Create(const Name: string);
    destructor Destroy; override;
  private
    FShaderPrograms : TInterfaceList;
    FDefines  : TList;
    XML       : IXML;
    FName     : string;
    function GetName: string; stdcall;
    function GetXML: IXML;
    procedure SetXML(Value: IXML);
    function GetDefineId(const Name: string): LongInt;
  public
    function GetDefine(const Name: string): LongInt; stdcall;
    procedure SetDefine(const Name: string; Value: LongInt); stdcall;
    function Compile: IShaderProgram; stdcall;
  end;

  TShaderProgram = class(TManagedInterface, IShaderProgram)
    constructor Create;
    destructor Destroy; override;
  public
    FID          : GLint;
    FUniformList : TInterfaceList;
    FAttribList  : TInterfaceList;
    function Uniform(const UName: string; UniformType: TShaderUniformType): IShaderUniform; stdcall;
    function Attrib(const AName: string; AttribType: TShaderAttribType; Norm: Boolean = False): IShaderAttrib; stdcall;
    procedure Bind; stdcall;
  end;

  TShaderUniform = class(TManagedInterface, IShaderUniform)
    constructor Create;
  private
    FID    : GLint;
    FType  : TShaderUniformType;
    FName  : string;
    FValue : array [0..11] of Single;
    function GetName: string; stdcall;
    function Init(ShaderID: GLEnum; const UName: string; UniformType: TShaderUniformType): Boolean;
  public
    procedure Value(const Data; Count: LongInt); stdcall;
  end;

  TShaderAttrib = class(TManagedInterface, IShaderAttrib)
    constructor Create;
  private
    FID    : GLint;
    FType  : TShaderAttribType;
    DType  : GLEnum;
    FNorm  : Boolean;
    Size   : LongInt;
    FName  : string;
    function GetName: string; stdcall;
    function Init(ShaderID: GLEnum; const AName: string; AttribType: TShaderAttribType; Norm: Boolean): Boolean;
  public
    procedure Value(Stride, Offset: LongInt); stdcall;
    property Name: string read FName;
    procedure Enable; stdcall;
    procedure Disable; stdcall;
  end;

  TShaderDefine = record
    Name  : String;
    Value : LongWord;
  end;

  TShaderLoader = class(TResLoader)
    constructor Create;
  public
    function Load(const Stream: TStream; var Resource: IResource): Boolean; override;
  end;

implementation

uses
  JEN_Main;

{$REGION 'TShaderProgram'}
constructor TShaderProgram.Create;
begin
  inherited;
  FID := glCreateProgram;
  FUniformList := TInterfaceList.Create;
  FAttribList := TInterfaceList.Create;
end;

destructor TShaderProgram.Destroy;
begin
  glDeleteShader(FID);
  FUniformList.Free;
  FAttribList.Free;
  inherited;
end;

function TShaderProgram.Uniform(const UName: string; UniformType: TShaderUniformType): IShaderUniform;
var
  i : LongInt;
  u : TShaderUniform;
begin
  for i := 0 to FUniformList.Count - 1 do
    if ((FUniformList[i] as IShaderUniform).Name = UName) then
    begin
      Result := IShaderUniform(FUniformList[i]);
      Exit;
    end;
  U := TShaderUniform.Create;
  if U.Init(FID, UName, UniformType) then
  FUniformList.Add(U);
  Result := U;
end;

function TShaderProgram.Attrib(const AName: string; AttribType: TShaderAttribType; Norm: Boolean = False): IShaderAttrib;
var
  i : LongInt;
  a : TShaderAttrib;
begin
  for i := 0 to FAttribList.Count - 1 do
    if ((FAttribList[i] as IShaderAttrib).Name = AName) then
    begin
      Result := IShaderAttrib(FAttribList[i]);
      Exit;
    end;
  A := TShaderAttrib.Create;
  if A.Init(FID, AName, AttribType, Norm) then
  FAttribList.Add(A);
  Result := A;
end;

procedure TShaderProgram.Bind;
begin
  if ResMan.Active[rtShader] <> IUnknown(Self) then
  begin
    glUseProgram(FID);
    ResMan.Active[rtShader] := Self;
  end;
end;
{$ENDREGION}

{$REGION 'TShaderUniform'}
constructor TShaderUniform.Create;
begin
  FID := -1;
  inherited;
end;

function TShaderUniform.GetName: string;
begin
  Result := FName;
end;

function TShaderUniform.Init(ShaderID: LongWord; const UName: string; UniformType: TShaderUniformType): Boolean;
var
  i : LongInt;
begin
  FID   := glGetUniformLocation(ShaderID, PAnsiChar(AnsiString(UName)));
  FName := UName;
  FType := UniformType;
  if FID = -1 then
    LogOut('Uncorrect uniform name ' + UName, lmWarning);
  for i := 0 to Length(FValue) - 1 do
    FValue[i] := NAN;

  Result := FID <> -1;
end;

procedure TShaderUniform.Value(const Data; Count: LongInt);
const
  USize : array [TShaderUniformType] of LongInt = (4, 4, 8, 12, 16, 36, 64);
begin
  if FID <> -1 then
  begin
    if Count * USize[FType] <= SizeOf(FValue) then
      if MemCmp(@FValue, @Data, Count * USize[FType]) <> 0 then
        Move(Data, FValue, Count * USize[FType])
      else
        Exit
    else
      Move(Data, FValue, SizeOf(FValue));

    case FType of
      utInt  : glUniform1iv(FID, Count, @Data);
      utVec1 : glUniform1fv(FID, Count, @Data);
      utVec2 : glUniform2fv(FID, Count, @Data);
      utVec3 : glUniform3fv(FID, Count, @Data);
      utVec4 : glUniform4fv(FID, Count, @Data);
      utMat3 : glUniformMatrix3fv(FID, Count, False, @Data);
      utMat4 : glUniformMatrix4fv(FID, Count, False, @Data);
    end;
  end else
    LogOut('Attempt to use uncorrect shader uniform', lmWarning);
end;
{$ENDREGION}

{$REGION 'TShaderArrtib'}
constructor TShaderAttrib.Create;
begin
  FID := -1;
  inherited;
end;

function TShaderAttrib.GetName: string;
begin
  Result := FName;
end;

function TShaderAttrib.Init(ShaderID: LongWord; const AName: string; AttribType: TShaderAttribType; Norm: Boolean): Boolean;
begin
  FID   := glGetAttribLocation(ShaderID, PAnsiChar(AnsiString(AName)));
  FName := AName;
  FType := AttribType;
  Size  := Byte(FType) mod 4 + 1;
  FNorm := Norm;
  if FID = -1 then
    LogOut('Uncorrect attrib name ' + AName, lmWarning);
  case FType of
    atVec1b..atVec4b : DType := GL_UNSIGNED_BYTE;
    atVec1s..atVec4s : DType := GL_SHORT;
    atVec1f..atVec4f : DType := GL_FLOAT;
  end;

  Result := FID <> -1;
end;

procedure TShaderAttrib.Value(Stride, Offset: LongInt);
begin
  if FID <> -1 then
    glVertexAttribPointer(FID, Size, DType, FNorm, Stride, Pointer(Offset))
  else
    LogOut('Attempt to use uncorrect shader attribute', lmWarning);
end;

procedure TShaderAttrib.Enable;
begin
  if FID <> -1 then
    glEnableVertexAttribArray(FID);
end;

procedure TShaderAttrib.Disable;
begin
  if FID <> -1 then
    glDisableVertexAttribArray(FID);
end;
{$ENDREGION}

constructor TShaderResource.Create;
begin
  inherited Create;
  FName := Name;
  FShaderPrograms := TInterfaceList.Create;
  FDefines := TList.Create;
end;

destructor TShaderResource.Destroy;
var
  i : LongInt;
begin
  XML := nil;

  FShaderPrograms.Free;
  for i := 0 to FDefines.Count - 1 do
  begin
    SetLength(TShaderDefine(FDefines[i]^).Name, 0);
    Dispose(FDefines[i]);
  end;

  FDefines.Free;
  LogOut('Shader resource ' + FName + ' destroyed',lmNotify);
  inherited;
end;

function TShaderResource.GetName: string;
begin
  Result := FName;
end;

function TShaderResource.GetXML: IXML;
begin
  Result := XML;
end;

procedure TShaderResource.SetXML(Value: IXML);
begin
  XML := Value;
end;

function TShaderResource.GetDefineId(const Name: String): LongInt;
var
  I : LongInt;
begin
  Result := -1;
  for I := 0 to FDefines.Count - 1 do
    if TShaderDefine(FDefines[i]^).Name = Name then
      Exit(I);
end;

function TShaderResource.GetDefine(const Name: String): LongInt;
var
  Id : LongInt;
begin
  Id := GetDefineId(Name);
  if Id = -1 then
    Exit(-1);

  Result := TShaderDefine(FDefines[id]^).Value;
end;

procedure TShaderResource.SetDefine(const Name: String; Value: LongInt);
var
  Define : ^TShaderDefine;
  Id : LongInt;
begin
  if Value < 0 then
  begin
    LogOut('Can not set the value to define less than zero', lmWarning);
    Exit;
  end;

  Id := GetDefineId(Name);

  if Id = -1 then
  begin
    New(Define);
    Define.Name := Name;
    Define.Value := Value;
    FDefines.Add(Define);
  end else
    TShaderDefine(FDefines[Id]^).Value := Value;
end;

function TShaderResource.Compile : IShaderProgram;
var
  Status : LongInt;
  LogBuf : AnsiString;
  LogLen : LongInt;
  Shader : TShaderProgram;
  XN_VS, XN_FS : IXML;
 // UniformCount : LongInt;
 // AttribCount : LongInt;
 // UniformInfo : LongInt;
 // Name : array[0..255] of AnsiChar;
 // Prefix : array[0..3] of AnsiChar;
 // K : LongInt;

  function IndexStr(const AText: string; const AValues: array of string): LongInt;
  var
    J : Integer;
  begin
  Result := -1;
  for J := Low(AValues) to High(AValues) do
    if LowerCase(AText) = AValues[J] then
    begin
      Result := J;
      Break;
    end;
  end;

  function MergeCode(const xNode: IXML): AnsiString;
  var
    i : LongInt;
    Param : TXMLParam;

    function GetParam(const Node: IXML; const Name: string): TXMLParam;
    begin
      Result := Node.Params[Name];
      if Result.Name = '' then
        LogOut('Not defined param def in token: ' + Node.Tag, lmWarning);
    end;

  begin
    Result:='';
    for i := 0 to xNode.Count - 1  do
    with xNode.NodeI[i] do
    begin
      case IndexStr(Tag,['code','define','ifdef','ifndef']) of
        0 ://code;
          Result := Result + AnsiString(Content);
        1 ://define
          begin
            Param := GetParam(xNode.NodeI[i],'def');
            if Param.Name = '' then
              Continue;

            SetDefine(Param.Value,1);
          end;
        2 ://ifdef
          begin
            Param := GetParam(xNode.NodeI[i],'def');
            if Param.Name = '' then
              Continue;

            case GetDefine(Param.Value) of
               1 : Result := Result + AnsiString(Content) + MergeCode(xNode.NodeI[i]);
              -1 : LogOut('Is not set definition: ' + Param.Value, lmWarning);
            end;

          end;
        3 ://ifndef
          begin
            Param := GetParam(xNode.NodeI[i],'def');
            if Param.Name = '' then
              Continue;

            if GetDefine(Param.Value)<= 0 then
               Result := Result + AnsiString(Content) + MergeCode(xNode.NodeI[i]);
          end;
        else
          LogOut('Uncorrect token: ' + Tag, lmWarning);
      end;

    end;
  end;

  procedure Attach(ShaderType: GLenum; const Source: AnsiString);
  var
    Obj : GLEnum;
    SourcePtr  : PAnsiChar;
    SourceSize : LongInt;
    Str : string;
    i : LongInt;
  begin
    Obj := glCreateShader(ShaderType);

    SourcePtr  := PAnsiChar(Source);
    SourceSize := Length(Source);

    glShaderSource(Obj, 1, @SourcePtr, @SourceSize);
    glCompileShader(Obj);
    glGetShaderiv(Obj, GL_COMPILE_STATUS, @Status);
    if Status <> 1 then
    begin
      LogOut('Error compiling shader', lmWarning);

      Str := 'Defines:';
      for I := 0 to FDefines.Count - 1 do
        with TShaderDefine(FDefines[i]^) do
          Str := Str + #10 + Name + ' - ' + Utils.IntToStr(Value);

      LogOut(Str, lmNotify);
      LogOut(string(Source), lmCode);

      glGetShaderiv(Obj, GL_INFO_LOG_LENGTH, @LogLen);
      SetLength(LogBuf, LogLen);
      glGetShaderInfoLog(Obj, LogLen, LogLen, PAnsiChar(LogBuf));
      LogOut(string(LogBuf), lmWarning);
    end;

    glAttachShader(Shader.FID, Obj);
    glDeleteShader(Obj);
  end;

begin
  XN_VS := XML.Node['VertexShader'];
  XN_FS := XML.Node['FragmentShader'];

  if not (Assigned(XN_VS) and Assigned(XN_FS)) then Exit;

  if Assigned(XN_VS) and Assigned(XN_FS) then
  begin

    Shader := TShaderProgram.Create;
    with Shader do
    begin
      Attach(GL_VERTEX_SHADER, MergeCode(XN_VS));
      Attach(GL_FRAGMENT_SHADER, MergeCode(XN_FS));
      glLinkProgram(FID);
      glGetProgramiv(FID, GL_LINK_STATUS, @Status);
      if Status <> 1 then
      begin
        LogOut('Error linking shader', lmWarning);
        glGetProgramiv(FID, GL_INFO_LOG_LENGTH, @LogLen);
        SetLength(LogBuf, LogLen);
        glGetProgramInfoLog(FID, LogLen, LogLen, PAnsiChar(LogBuf));
        LogOut(string(LogBuf), lmWarning);
      end;
         {
      glGetProgramiv(FID, GL_ACTIVE_ATTRIBUTES , @AttribCount);
      glGetProgramiv(FID, GL_ACTIVE_UNIFORMS, @UniformCount);

      Prefix := 'JEN_';
      for K := 0 to UniformCount-1 do
      begin
        glGetActiveUniform (FID, K, 256, @UniformInfo, @UniformInfo, @UniformInfo, @Name[0]);
        if MemCmp(@Name[0], @Prefix[0], 4) = 0 then

        logout(Name, lmNotify);
      end;
               }
      (Shader as IManagedInterface).SetManager(FUniformList);
      FShaderPrograms.Add(Shader);
      Result := Shader;
     end;

  end;

end;

constructor TShaderLoader.Create;
begin
  inherited;
  ExtString := 'xml';
  ResType := rtShader;
end;

function TShaderLoader.Load(const Stream : TStream; var Resource : IResource) : Boolean;
var
  Shader: IShaderResource;

  ss: IXML;
begin
  Result := False;
  if not Assigned(Resource) then Exit;
  Shader := Resource as IShaderResource;

  with Shader do
  begin
    ss:= GetXML;
    XML := TXML.Load(Stream);
    if not Assigned(XML) then Exit;

    if not (Assigned(XML.Node['VertexShader']) and Assigned(XML.Node['FragmentShader'])) then Exit;
  end;

  Result := True;
end;

end.

