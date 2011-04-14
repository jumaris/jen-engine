unit JEN_Shader;

interface

uses
  JEN_Header,
  JEN_Resource,
  JEN_OpenGlHeader,
  JEN_Utils,
  JEN_Math,
  CoreX_XML;

type
  TShaderProgram = class(TManagedInterfacedObj, IShaderProgram)
    constructor Create(Manager : TInterfaceList);
    destructor Destroy; override;
  private
  public
    FID : GLint;
    FUniformList : TInterfaceList;
    FAttribList : TInterfaceList;
    function Uniform(const UName: string; UniformType: TShaderUniformType): IShaderUniform; stdcall;
    function Attrib(const AName: string; AttribType: TShaderAttribType; Norm: Boolean = False): IShaderAttrib; stdcall;
    procedure Bind; stdcall;
  end;

  TShaderUniform = class(TManagedInterfacedObj, IShaderUniform)
    constructor Create(Manager : TInterfaceList);
  private
    FID    : GLint;
    FType  : TShaderUniformType;
    FName  : string;
    FValue : array [0..11] of Single;
    procedure Init(ShaderID: GLEnum; const UName: string; UniformType: TShaderUniformType);
  public
    procedure Value(const Data; Count: LongInt); stdcall;
    property Name: string read FName;
  end;

  TShaderAttrib = class(TManagedInterfacedObj, IShaderAttrib)
    constructor Create(Manager : TInterfaceList);
  private
    FID    : GLint;
    FType  : TShaderAttribType;
    DType  : GLEnum;
    FNorm : Boolean;
    Size   : LongInt;
    FName  : string;
    FValue : array [0..11] of Single;
    procedure Init(ShaderID: GLEnum; const AName: string; AttribType: TShaderAttribType; Norm: Boolean);
  public
    procedure Value(Stride, Offset: LongInt); stdcall;
    property Name: string read FName;
    procedure Enable; stdcall;
    procedure Disable; stdcall;
  end;

  TShaderResource = class(TManagedInterfacedObj, IResource, IShaderResource)
    constructor Create(const Name: string; Manager : TInterfaceList);
    destructor Destroy; override;
  private
    FShaderPrograms : TInterfaceList;
    function GetName: string; stdcall;
  public
    XN_VS, XN_FS, XML: TXML;
    FName: string;
    function Compile: IShaderProgram; stdcall;
  end;

  TShaderLoader = class(TResLoader)
    constructor Create;
  public
    function Load(const Stream: TStream; var Resource: IResource): Boolean; override;
  end;

implementation

uses
  JEN_Main;

//ShaderProgram
{$REGION 'TShaderProgram'}  
constructor TShaderProgram.Create(Manager: TInterfaceList);
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
    if TShaderUniform(FUniformList[i]).Name = UName then
    begin
      Result := IShaderUniform(FUniformList[i]);
      Exit;
    end;
  U := TShaderUniform.Create(FUniformList);
  U.Init(FID, UName, UniformType);
  Result := U;
end;

function TShaderProgram.Attrib(const AName: string; AttribType: TShaderAttribType; Norm: Boolean = False): IShaderAttrib;
var
  i : LongInt;
  a : TShaderAttrib;
begin
{
  for i := 0 to Length(FAttrib) - 1 do
    if FAttrib[i].Name = AName then
    begin
      Result := FAttrib[i];
      Exit;
    end;               }
  A := TShaderAttrib.Create(FAttribList);
  A.Init(FID, AName, AttribType, Norm);
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
constructor TShaderUniform.Create(Manager: TInterfaceList);
begin
  FID := -1;
  inherited;
end;

procedure TShaderUniform.Init(ShaderID: LongWord; const UName: string; UniformType: TShaderUniformType);
var
  i : LongInt;
begin
  FID   := glGetUniformLocation(ShaderID, PAnsiChar(AnsiString(UName)));
  FName := UName;
  FType := UniformType;
  for i := 0 to Length(FValue) - 1 do
    FValue[i] := NAN;
end;

procedure TShaderUniform.Value(const Data; Count: LongInt);
const
  USize : array [TShaderUniformType] of LongInt = (4, 4, 8, 12, 16, 36, 64);
begin                        {
 if Count * USize[FType] <= SizeOf(FValue) then
    if MemCmp(@FValue, @Data, Count * USize[FType]) <> 0 then
      Move(Data, FValue, Count * USize[FType])
    else
      Exit;            }

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
{$ENDREGION}

constructor TShaderAttrib.Create(Manager: TInterfaceList);
begin
  FID := -1;
  inherited;
end;

procedure TShaderAttrib.Init(ShaderID: LongWord; const AName: string; AttribType: TShaderAttribType; Norm: Boolean);
begin
  FID   := glGetAttribLocation(ShaderID, PAnsiChar(AnsiString(AName)));
  FName := AName;
  FType := AttribType;
  Size  := Byte(FType) mod 4 + 1;
  FNorm := Norm;
  case FType of
    atVec1b..atVec4b : DType := GL_UNSIGNED_BYTE;
    atVec1s..atVec4s : DType := GL_SHORT;
    atVec1f..atVec4f : DType := GL_FLOAT;
  end;  
end;

procedure TShaderAttrib.Value(Stride, Offset: LongInt);
begin
  if FID <> -1 then
    glVertexAttribPointer(FID, Size, DType, FNorm, Stride, Pointer(Offset));
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

constructor TShaderResource.Create(const Name: string; Manager: TInterfaceList);
begin
  inherited Create(Manager);
  FName := Name;
  FShaderPrograms := TInterfaceList.Create;
end;

destructor TShaderResource.Destroy;
begin
  if Assigned(XML) then
    XML.Free;
  FShaderPrograms.Free;
  inherited;
end;

function TShaderResource.GetName: string;
begin
  Result := FName;
end;

function TShaderResource.Compile : IShaderProgram;
var
  Shader : TShaderProgram;
  Status : LongInt;
  LogBuf : AnsiString;
  LogLen : LongInt;

  function IndexStr(const AText: string; const AValues: array of string): LongInt;
  var
    J : Integer;
  begin
  Result := -1;
  for J := Low(AValues) to High(AValues) do
    if AText = AValues[J] then
    begin
      Result := J;
      Break;
    end;
  end;

  function MergeCode(const Node:TXML): AnsiString;
  var
    i: LongInt;
  begin
    Result:='';
    for i:= 0 to Node.Count - 1  do
    with Node.NodeI[i] do
    begin
      case IndexStr(Tag,['Code']) of
        0 : begin
        Result := Result + AnsiString(Content);
        end;
      end;
    end;
  end;

  procedure Attach(ShaderType: GLenum; const Source: AnsiString);
  var
    Obj : GLEnum;
    SourcePtr  : PAnsiChar;
    SourceSize : LongInt;
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

  if Assigned(XN_VS) and Assigned(XN_FS) then
  begin
    Shader := TShaderProgram.Create(FShaderPrograms);
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
  Shader: TShaderResource;
begin
  Result := False;
  Shader := Resource as TShaderResource;

  with Shader do
  begin
    XML := TXML.Load(Stream);
    if not Assigned(XML) then Exit;

    XN_VS := XML.Node['VertexShader'];
    XN_FS := XML.Node['FragmentShader'];

    if not (Assigned(XN_VS) and Assigned(XN_FS)) then Exit;
  end;

  Result := True;
end;

end.

