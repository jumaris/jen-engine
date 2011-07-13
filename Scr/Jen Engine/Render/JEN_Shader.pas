unit JEN_Shader;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_Resource,
  JEN_OpenGlHeader,
  JEN_Utils,
  sysutils,
  CoreX_XML;

type
  IShaderResource = interface(JEN_Header.IShaderResource)
  ['{CFF16358-641F-4312-A601-08CC9FC3BEA8}']
    function GetXML: IXML;
    procedure SetXML(Value: IXML);

    property XML: IXML read GetXML write SetXML;
  end;

  TShaderResource = class(TManagedInterface, IManagedInterface, IResource, IShaderResource)
    constructor Create(const Name: string);
    destructor Destroy; override;
  private
    FShaderPrograms : TInterfaceList;
    FDefines        : TList;
    XML             : IXML;
    FName           : string;
    function GetName: string; stdcall;
    function GetXML: IXML;
    procedure SetXML(Value: IXML);
    function GetDefineId(const Name: string): LongInt;
  public
    function GetDefine(const Name: string): LongInt; stdcall;
    procedure SetDefine(const Name: string; Value: LongInt); stdcall;
    function Compile: JEN_Header.IShaderProgram; stdcall;
  end;

  IShaderProgram = interface(JEN_Header.IShaderProgram)
    function Init(const VertexShader, FragmentShader: AnsiString): Boolean;
  end;

  TShaderProgram = class(TManagedInterface, IShaderProgram)
    constructor Create;
    destructor Destroy; override;
  private
    FID              : GLint;
    FUniformsVersion : LongWord;
    FUniformList     : TInterfaceList;
    FAttribList      : TInterfaceList;
  public
    function Init(const VertexShader, FragmentShader: AnsiString): Boolean;
    function Uniform(const UName: String; CreateDebug: Boolean): IShaderUniform; overload; stdcall;
    function Attrib(const AName: string; CreateDebug: Boolean): IShaderAttrib; stdcall;
    function GetUniformsVersion: LongWord; stdcall;

    procedure Bind; stdcall;
  end;

  TShaderUniform = class(TManagedInterface, IShaderUniform)
    constructor Create;
  private
    FID             : GLint;
    FType           : TShaderUniformType;
    FName           : string;
    FValue          : array [0..11] of Single;
    FVersion        : Word;
    function GetName: string; stdcall;
    function GetVersion: Word; stdcall;

    procedure SetType(Value: TShaderUniformType);
    procedure Init(ShaderID: GLEnum; const UName: string; UniformType: TShaderUniformType);
  public
    procedure Value(const Data; Count: LongInt); stdcall;
  end;

  TShaderAttrib = class(TManagedInterface, IShaderAttrib)
    constructor Create;
  private
    FID    : GLint;
    FName  : string;
    function GetName: string; stdcall;
    function Init(ShaderID: GLEnum; const AName: string): Boolean;
  public
    procedure Value(Stride, Offset: LongInt; AttribType: TShaderAttribType; Norm: Boolean); stdcall;
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

function TShaderProgram.Init(const VertexShader, FragmentShader: AnsiString): Boolean;
var
  Status      : LongInt;
  LogBuf      : AnsiString;
  LogLen      : LongInt;
  I           : LongInt;
  Count       : LongInt;
  Info        : LongInt;
  GLType      : LongInt;
  NameBuff    : array[0..255] of AnsiChar;
  UniformType : TShaderUniformType;
  Name        : String;
  U           : TShaderUniform;
  A           : TShaderAttrib;

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

      LogOut(Str, lmNotify);
      LogOut(string(Source)+#0, lmCode);

      glGetShaderiv(Obj, GL_INFO_LOG_LENGTH, @LogLen);
      SetLength(LogBuf, LogLen);
      glGetShaderInfoLog(Obj, LogLen, LogLen, PAnsiChar(LogBuf));
      LogOut(string(LogBuf), lmWarning);
    end;

    glAttachShader(FID, Obj);
    glDeleteShader(Obj);
  end;

begin
  if glIsProgram(FID) then
    glDeleteProgram(FID);

  FID := glCreateProgram;
  Result := False;

  if (VertexShader = '') or (FragmentShader = '') then
    Exit;

  Attach(GL_VERTEX_SHADER, VertexShader);
  Attach(GL_FRAGMENT_SHADER, FragmentShader);

  glLinkProgram(FID);
  glGetProgramiv(FID, GL_LINK_STATUS, @Status);
  if Status <> 1 then
  begin
    LogOut('Error linking shader', lmWarning);
    glGetProgramiv(FID, GL_INFO_LOG_LENGTH, @LogLen);
    SetLength(LogBuf, LogLen);
    glGetProgramInfoLog(FID, LogLen, LogLen, PAnsiChar(LogBuf));
    LogOut(string(LogBuf), lmWarning);
    Exit;
  end;

  glGetProgramiv(FID, GL_ACTIVE_UNIFORMS, @Count);
  for I := 0 to Count-1 do
  begin
    glGetActiveUniform(FID, I, 255, @Info, @Info, @GLType, @NameBuff[0]);
    case GLType of
      GL_INT, GL_SAMPLER_1D..GL_SAMPLER_2D_SHADOW: UniformType := utInt;
      GL_FLOAT: UniformType := utVec1;
      GL_FLOAT_VEC2: UniformType := utVec2;
      GL_FLOAT_VEC3: UniformType := utVec3;
      GL_FLOAT_VEC4: UniformType := utVec4;
      GL_FLOAT_MAT3: UniformType := utMat3;
      GL_FLOAT_MAT4: UniformType := utMat4;
      else UniformType := utNone;
    end;

    Name := String(NameBuff);
    Delete(Name, Pos('[', Name), 3);

    U:= TShaderUniform.Create;
    U.Init(FID,  Name, UniformType);
    FUniformList.Add(IShaderUniform(U));
  end;

  glGetProgramiv(FID, GL_ACTIVE_ATTRIBUTES, @Count);
  for I := 0 to Count-1 do
  begin
    glGetActiveAttrib(FID, I, 255, @Info, @Info, @GLType, @NameBuff[0]);

    Name := String(NameBuff);
    A:= TShaderAttrib.Create;
    A.Init(FID, Name);
    FAttribList.Add(IShaderAttrib(A));
  end;

  Result := True;
end;

function TShaderProgram.Uniform(const UName: string; CreateDebug: Boolean): IShaderUniform;
var
  i : LongInt;
  u : TShaderUniform;
begin
  for i := 0 to FUniformList.Count - 1 do
    if ((FUniformList[i] as IShaderUniform).Name = UName) then
      Exit(IShaderUniform(FUniformList[i]));

  if CreateDebug then
  begin
    U := TShaderUniform.Create;
    U.Init(FID, UName, utNone);
    Result := U;
  end else
    Result := nil;
end;

function TShaderProgram.Attrib(const AName: string; CreateDebug: Boolean): IShaderAttrib;
var
  i : LongInt;
  a : TShaderAttrib;
begin
  for i := 0 to FAttribList.Count - 1 do
    if ((FAttribList[i] as IShaderAttrib).Name = AName) then
      Exit(IShaderAttrib(FAttribList[i]));

  if CreateDebug then
  begin
    A := TShaderAttrib.Create;
    A.Init(FID, AName);
    Result := A;
  end else
    Result := nil;
end;

function TShaderProgram.GetUniformsVersion: LongWord;
var
  i : LongInt;
begin
  Result := 0;
  for i := 0 to FUniformList.Count - 1 do
    inc(Result, (FUniformList[i] as IShaderUniform).Version);
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

function TShaderUniform.GetVersion: Word;
begin
  Result := FVersion;
end;

procedure TShaderUniform.SetType(Value: TShaderUniformType);
begin
  FType := Value;
end;

procedure TShaderUniform.Init(ShaderID: LongWord; const UName: string; UniformType: TShaderUniformType);
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
end;

procedure TShaderUniform.Value(const Data; Count: LongInt);
const
  USize : array [TShaderUniformType] of LongInt = (0, 4, 4, 8, 12, 16, 36, 64);
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

    inc(FVersion);
    if FVersion = 65535 then
    FVersion := 0;

    case FType of
      utInt  : glUniform1iv(FID, Count, @Data);
      utVec1 : glUniform1fv(FID, Count, @Data);
      utVec2 : glUniform2fv(FID, Count, @Data);
      utVec3 : glUniform3fv(FID, Count, @Data);
      utVec4 : glUniform4fv(FID, Count, @Data);
      utMat3 : glUniformMatrix3fv(FID, Count, False, @Data);
      utMat4 : glUniformMatrix4fv(FID, Count, False, @Data);
    end;
  end;
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

function TShaderAttrib.Init(ShaderID: LongWord; const AName: string): Boolean;
begin
  FID   := glGetAttribLocation(ShaderID, PAnsiChar(AnsiString(AName)));
  FName := AName;

  if FID = -1 then
    LogOut('Uncorrect attrib name ' + AName, lmWarning);
  Result := FID <> -1;
end;

procedure TShaderAttrib.Value(Stride, Offset: LongInt; AttribType: TShaderAttribType; Norm: Boolean);
var
  DType : GLEnum;
  Size  : LongInt;
begin
  if FID <> -1 then
  begin
    case AttribType of
      atVec1b..atVec4b: DType := GL_UNSIGNED_BYTE;
      atVec1s..atVec4s: DType := GL_SHORT;
      atVec1f..atVec4f: DType := GL_FLOAT;
      else DType := 0;
    end;
    Size := Byte(AttribType) mod 4 + 1;
    glVertexAttribPointer(FID, Size, DType, Norm, Stride, Pointer(Offset));
  end;
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

function TShaderResource.Compile: JEN_Header.IShaderProgram;
var
  XN_VS   : IXML;
  XN_FS   : IXML;
  i       : LongInt;
  Str     : string;
  Shader  : IShaderProgram;

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

begin
  XN_VS := XML.Node['VertexShader'];
  XN_FS := XML.Node['FragmentShader'];

  Shader := TShaderProgram.Create;
  Result := Shader;

  if not (Assigned(XN_VS) and Assigned(XN_FS)) then Exit;

  if not Shader.Init(MergeCode(XN_VS), MergeCode(XN_FS)) then
  begin
    Str := 'Defines:';
    for I := 0 to FDefines.Count - 1 do
      with TShaderDefine(FDefines[i]^) do
        Str := Str + #10 + Name + ' - ' + Utils.IntToStr(Value);

    LogOut(Str, lmNotify);
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

