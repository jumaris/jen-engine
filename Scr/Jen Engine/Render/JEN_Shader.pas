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
    procedure Init(XML : IXML);
  end;

  IShaderProgram = interface(JEN_Header.IShaderProgram)
  ['{6A27461E-FA18-4B20-86AC-6BE9A830E3F5}']
    function Init(const VertexShader, FragmentShader: AnsiString): Boolean;
  end;

  IShaderUniform = interface(JEN_Header.IShaderUniform)
  ['{4AB4AE0B-7FBC-4838-87B0-4A9BEA508ED4}']
    procedure Init(ShaderID: GLEnum; const UName: string; UniformType: TShaderUniformType; Necessary: Boolean);
  end;

  IShaderAttrib = interface(JEN_Header.IShaderAttrib)
  ['{CB9EEB22-8256-46BB-B7B1-372E0D4CD624}']
    procedure Init(ShaderID: GLEnum; const AName: string; AttribType: TShaderAttribType; Necessary: Boolean);
  end;

  TShaderResource = class(TResource, IManagedInterface, IResource, IShaderResource)
    constructor Create(const Name, FilePath: string);
    destructor Destroy; override;
  private
    FShaderPrograms : TInterfaceList;
    FDefines        : TList;
    FXML            : IXML;
    function GetDefineId(const Name: string): LongInt;
    function GetDefine(const Name: string): LongInt; stdcall;
    procedure SetDefine(const Name: string; Value: LongInt); stdcall;
  public
    procedure Init(XML: IXML);
    procedure Reload; stdcall;
    procedure Compile(var Shader: IShaderProgram); overload;
    function Compile: JEN_Header.IShaderProgram; overload; stdcall;
  end;

  TShaderProgram = class(TManagedInterface, IShaderProgram)
    constructor Create;
    destructor Destroy; override;
  private
    FID           : GLhandle;
    FValid        : Boolean;
    FUniformList  : TInterfaceList;
    FAttribList   : TInterfaceList;
    FLock         : Boolean;
  public
    function Valid: Boolean; stdcall;
    function GetID: LongWord; stdcall;
    function Init(const VertexShader, FragmentShader: AnsiString): Boolean;
    function Uniform(const UName: String; UniformType: TShaderUniformType; Necessary: Boolean): JEN_Header.IShaderUniform; overload; stdcall;
    function Attrib(const AName: string; AttribType: TShaderAttribType; Necessary: Boolean): JEN_Header.IShaderAttrib; stdcall;
    procedure Lock(Value: Boolean); stdcall;
    procedure Update; stdcall;
    procedure Bind; stdcall;
  end;

  TShaderUniform = class(TManagedInterface, IShaderUniform)
    constructor Create;
  private
    FID             : GLint;
    FShaderId       : GLhandle;
    FType           : TShaderUniformType;
    FName           : string;
    FValue          : array [0..11] of Single;
    function GetName: string; stdcall;
    function GetType: TShaderUniformType; stdcall;
    //procedure SetType(Value: TShaderAttribType); stdcall;

    procedure Init(ShaderID: GLEnum; const UName: string; UniformType: TShaderUniformType; Necessary: Boolean);
  public
    function Valid: Boolean; stdcall;
    procedure Value(const Data; Count: LongInt); stdcall;
  end;

  TShaderAttrib = class(TManagedInterface, IShaderAttrib)
    constructor Create;
  private
    FID    : GLint;
    FType  : TShaderAttribType;
    FName  : string;
    function GetName: string; stdcall;
    function GetType: TShaderAttribType; stdcall;
    procedure Init(ShaderID: GLEnum; const AName: string; AttribType: TShaderAttribType; Necessary: Boolean);
  public
    function Valid: Boolean; stdcall;
    procedure Value(Stride, Offset: LongInt; Norm: Boolean); stdcall;
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
    function Load(Stream: IStream; var Resource: IResource): Boolean; override;
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

function TShaderProgram.Valid: Boolean;
begin
  Result := FValid;
end;

function TShaderProgram.GetID: LongWord;
begin
  Result := FID;
end;

function TShaderProgram.Init(const VertexShader, FragmentShader: AnsiString): Boolean;
var
  i           : LongInt;
  Status      : LongInt;
  LogBuf      : AnsiString;
  LogLen      : LongInt;
 // Count       : LongInt;
 // Info        : LongInt;
 // GLType      : LongInt;
//  NameBuff    : array[0..255] of AnsiChar;
//  UniformType : TShaderUniformType;
//  Name        : String;
 // u           : IShaderUniform;
 // a           : IShaderAttrib;

  procedure Attach(ShaderType: GLenum; const Source: AnsiString);
  var
    Obj         : GLEnum;
    SourcePtr   : PAnsiChar;
    SourceSize  : LongInt;
    Str         : string;
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

  FValid := False;
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

  for i := 0 to FUniformList.Count - 1 do
  with (FUniformList[i] as IShaderUniform) do
    Init(FID, Name, UType, Valid);

  for i := 0 to FAttribList.Count - 1 do
  with (FAttribList[i] as IShaderAttrib) do
    Init(FID, Name, AType, Valid);
          {
  glGetProgramiv(FID, GL_ACTIVE_UNIFORMS, @Count);
  for i := 0 to Count-1 do
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

    u := nil;
    for j := 0 to FUniformList.Count -1 do
      if(FUniformList[j] as IShaderUniform).Name = Name then
        u := FUniformList[j] as IShaderUniform;

    if not (Assigned(u) and (u.Name = Name) and (u.UType = UniformType)) then
    begin
      u := TShaderUniform.Create;
      FUniformList.Add(u);
      u.Init(FID, Name, UniformType, True);
    end;

  end;   }

                     {
  glGetProgramiv(FID, GL_ACTIVE_ATTRIBUTES, @Count);
  for I := 0 to Count-1 do
  begin
    glGetActiveAttrib(FID, I, 255, @Info, @Info, @GLType, @NameBuff[0]);

    Name := String(NameBuff);
    a    := nil;

    for j := 0 to FAttribList.Count -1 do
      if(FAttribList[j] as IShaderAttrib).Name = Name then
        a := FAttribList[j] as IShaderAttrib;

    if not Assigned(a) then
    begin
      a := TShaderAttrib.Create;
      FAttribList.Add(IShaderAttrib(a));
    end;

    a.Init(FID, Name, True);
  end;   }

  Bind();
  glUseProgram(FID);
  Result := True;
  FValid := True;
end;

function TShaderProgram.Uniform(const UName: string; UniformType: TShaderUniformType; Necessary: Boolean): JEN_Header.IShaderUniform;
var
  i : LongInt;
  u : IShaderUniform;
begin
  for i := 0 to FUniformList.Count - 1 do
    if ((FUniformList[i] as IShaderUniform).Name = UName) then
      Exit(IShaderUniform(FUniformList[i]));

  u := TShaderUniform.Create;
  u.Init(FID, UName, UniformType, Necessary);
  FUniformList.Add(u);
  Result := u;
end;

function TShaderProgram.Attrib(const AName: string; AttribType: TShaderAttribType; Necessary: Boolean): JEN_Header.IShaderAttrib;
var
  i : LongInt;
  a : IShaderAttrib;
begin
  for i := 0 to FAttribList.Count - 1 do
    if ((FAttribList[i] as IShaderAttrib).Name = AName) then
      Exit(IShaderAttrib(FAttribList[i]));

  a := TShaderAttrib.Create;
  a.Init(FID, AName, AttribType, Necessary);
  FAttribList.Add(IShaderAttrib(a));
  Result := a;
end;

procedure TShaderProgram.Lock(Value: Boolean);
begin
  FLock := Value;
end;

procedure TShaderProgram.Update;
begin
  if FLock then
    Engine.CreateEvent(evRenderFlush);
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
  inherited;
  FID := -1;
end;

function TShaderUniform.Valid: Boolean;
begin
  Result := FID <> -1;
end;

function TShaderUniform.GetName: string;
begin
  Result := FName;
end;

function TShaderUniform.GetType: TShaderUniformType;
begin
  Result := FType;
end;

          {
procedure TShaderUniform.SetType(Value: TShaderUniformType);
begin
  FType := Value;
end;
                }
procedure TShaderUniform.Init(ShaderID: LongWord; const UName: string; UniformType: TShaderUniformType; Necessary: Boolean);
var
  i : LongInt;
begin
  FShaderId := ShaderID;
  FID   := glGetUniformLocation(ShaderID, PAnsiChar(AnsiString(UName)));
  FName := Copy(UName, 1, Length(UName));
  FType := UniformType;

  if (FID = -1) and Necessary then
    LogOut('Uncorrect uniform name ' + UName, lmWarning);

  for i := 0 to Length(FValue) - 1 do
    FValue[i] := NAN;
end;

procedure TShaderUniform.Value(const Data; Count: LongInt);
const
  USize : array [TShaderUniformType] of LongInt = (0, 4, 4, 8, 12, 16, 16, 36, 64);
begin
  if (FID = -1) or ((ResMan.Active[rtShader] as IShaderProgram).GetID <> FShaderId) then
    Exit;

  if Count * USize[FType] <= SizeOf(FValue) then
  begin
    if MemCmp(@FValue, @Data, Count * USize[FType]) <> 0 then
      Move(Data, FValue, Count * USize[FType])
    else
      Exit;
  end else
    Move(Data, FValue, SizeOf(FValue));

  (ResMan.Active[rtShader] as IShaderProgram).Update;

  case FType of
    utInt  : glUniform1iv(FID, Count, @Data);
    utVec1 : glUniform1fv(FID, Count, @Data);
    utVec2 : glUniform2fv(FID, Count, @Data);
    utVec3 : glUniform3fv(FID, Count, @Data);
    utVec4 : glUniform4fv(FID, Count, @Data);
    utMat2 : glUniformMatrix2fv(FID, Count, False, @Data);
    utMat3 : glUniformMatrix3fv(FID, Count, False, @Data);
    utMat4 : glUniformMatrix4fv(FID, Count, False, @Data);
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

function TShaderAttrib.GetType: TShaderAttribType;
begin
  Result := FType;
end;

procedure TShaderAttrib.Init(ShaderID: LongWord; const AName: string; AttribType: TShaderAttribType; Necessary: Boolean);
begin
  FID   := glGetAttribLocation(ShaderID, PAnsiChar(AnsiString(AName)));
  FName := Copy(AName, 1, Length(AName));
  FType := AttribType;

  if (FID = -1) and Necessary then
    LogOut('Uncorrect attrib name ' + AName, lmWarning);
end;

function TShaderAttrib.Valid: Boolean;
begin
  Result := FID <> -1;
end;

procedure TShaderAttrib.Value(Stride, Offset: LongInt; Norm: Boolean);
var
  DType : GLEnum;
  Size  : LongInt;
begin
  if FID <> -1 then
  begin
    case FType of
      atVec1b..atVec4b: DType := GL_UNSIGNED_BYTE;
      atVec1s..atVec4s: DType := GL_SHORT;
      atVec1f..atVec4f: DType := GL_FLOAT;
      else Exit;
    end;
    Size := (Byte(FType) - 1) mod 4 + 1;
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
  inherited Create(Name, FilePath, rtShader);
  FShaderPrograms := TInterfaceList.Create;
  FDefines := TList.Create;
end;

destructor TShaderResource.Destroy;
var
  i : LongInt;
begin
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

procedure TShaderResource.Init(XML: IXML);
var
  I       : LongInt;
  Shader  : IShaderProgram;
begin
  FXML := XML;
  for I := 0 to FShaderPrograms.Count - 1 do
  begin
    Shader := FShaderPrograms[i] as IShaderProgram;
    Compile(Shader);
  end;
end;

procedure TShaderResource.Reload; stdcall;
var
  i : IResource;
begin
  i := self;
  ResMan.Load(FFilePath+FName, i);
end;

procedure TShaderResource.Compile(var Shader : IShaderProgram);
var
  XN_VS   : IXML;
  XN_FS   : IXML;
  i       : LongInt;
  Str     : string;

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
  if not (Assigned(FXML) and Assigned(Shader)) then Exit;

  XN_VS := FXML.Node['VertexShader'];
  XN_FS := FXML.Node['FragmentShader'];

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

function TShaderResource.Compile : JEN_Header.IShaderProgram;
var
  Shader : IShaderProgram;
begin
  Shader := IShaderProgram(TShaderProgram.Create);
  Compile(Shader);
  FShaderPrograms.Add(Shader);
  Result := Shader;
end;

constructor TShaderLoader.Create;
begin
  inherited;
  ExtString := 'xml';
  ResType := rtShader;
end;

function TShaderLoader.Load(Stream : IStream; var Resource : IResource) : Boolean;
var
  Shader: IShaderResource;
begin
  Result := False;
  if not Assigned(Resource) then Exit;
  Shader := Resource as IShaderResource;
  Shader.Init(TXML.Load(Stream));
  Result := True;
end;

end.

