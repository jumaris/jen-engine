unit JEN_Shader;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils,
  JEN_OpenGLHeader,
  JEN_Header,
  JEN_Math,
  JEN_Resource,
  JEN_Helpers,
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
    procedure Init(ShaderID: GLEnum; const UName: AnsiString; UniformType: TShaderUniformType; Necessary: Boolean);
  end;

  IShaderAttrib = interface(JEN_Header.IShaderAttrib)
  ['{CB9EEB22-8256-46BB-B7B1-372E0D4CD624}']
    procedure Init(ShaderID: GLEnum; const AName: AnsiString; AttribType: TShaderAttribType; Necessary: Boolean);
    function GetLocation: GLhandle;
    property Location: GLhandle read GetLocation;
  end;

  TShaderResource = class(TResource, IResource, IShaderResource)
    constructor Create(const FilePath: UnicodeString);
    destructor Destroy; override;
  private
    FShaderPrograms : TInterfaceList;
    FDefines        : TList;
    FXML            : IXML;
    function GetDefineId(Name: PWideChar): LongInt;
    function GetDefine(Name: PWideChar): LongInt; stdcall;
    procedure SetDefine(Name: PWideChar; Value: LongInt); stdcall;
  public
    procedure Init(XML: IXML);
    procedure Reload; stdcall;
    procedure Compile(var Shader: JEN_Header.IShaderProgram); stdcall;
  end;

  TShaderProgram = class(TInterfacedObject, IShaderProgram)
    constructor Create;
    destructor Destroy; override;
  private
    FID           : GLhandle;
    FValid        : Boolean;
    FUniformList  : TInterfaceList;
    FAttribList   : TInterfaceList;
  class var
    ActiveShaderId: GLhandle;
    ActiveShader  : IShaderProgram;
  public
    function Valid: Boolean; stdcall;
    function GetID: LongWord; stdcall;
    function Init(const VertexShader, FragmentShader: AnsiString): Boolean;
    function Uniform(UName: PWideChar; UniformType: TShaderUniformType; Necessary: Boolean): JEN_Header.IShaderUniform; overload; stdcall;
    function Attrib(AName: PWideChar; AttribType: TShaderAttribType; Necessary: Boolean): JEN_Header.IShaderAttrib; stdcall;
    procedure Bind; stdcall;
  end;

  TShaderUniform = class(TInterfacedObject, IShaderUniform)
    constructor Create;
  private
    FID             : GLint;
    FShaderId       : GLhandle;
    FType           : TShaderUniformType;
    FName           : UnicodeString;
    FValue          : array [0..11] of Single;
    function GetName: PWideChar; stdcall;
    function GetType: TShaderUniformType; stdcall;
    //procedure SetType(Value: TShaderAttribType); stdcall;

    procedure Init(ShaderID: GLEnum; const UName: AnsiString; UniformType: TShaderUniformType; Necessary: Boolean);
  public
    function Valid: Boolean; stdcall;
    procedure Value(const Data; Count: LongInt); stdcall;
  end;

  TShaderAttrib = class(TInterfacedObject, IShaderAttrib)
    constructor Create;
  private
    FID    : GLint;
    FType  : TShaderAttribType;
    FName  : UnicodeString;
    function GetName: PWideChar; stdcall;
    function GetType: TShaderAttribType; stdcall;
    function GetLocation: GLhandle; 
    procedure Init(ShaderID: GLEnum; const AName: AnsiString; AttribType: TShaderAttribType; Necessary: Boolean);
  public
    function Valid: Boolean; stdcall;
    procedure Value(Stride, Offset: LongInt; Norm: Boolean); stdcall;
    procedure Enable; stdcall;
    procedure Disable; stdcall;
  end;

  TShaderDefine = record
    Name  : UnicodeString;
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
  Str         : string;
 // Count       : LongInt;
 // Info        : LongInt;
 // GLType      : LongInt;
//  NameBuff    : array[0..255] of AnsiChar;
//  UniformType : TShaderUniformType;
//  Name        : UnicodeString;
 // u           : IShaderUniform;
 // a           : IShaderAttrib;

  procedure Attach(ShaderType: GLenum; const Source: AnsiString);
  var
    Obj         : GLEnum;
    SourcePtr   : PAnsiChar;
    SourceSize  : LongInt;
  begin
    Obj := glCreateShader(ShaderType);

    SourcePtr  := PAnsiChar(Source);
    SourceSize := Length(Source);

    glShaderSource(Obj, 1, @SourcePtr, @SourceSize);
    glCompileShader(Obj);
    glGetShaderiv(Obj, GL_COMPILE_STATUS, @Status);
    if Status <> 1 then
    begin
      Engine.Warning('Error compiling shader');
      Engine.CodeBlock(Source);

      glGetShaderiv(Obj, GL_INFO_LOG_LENGTH, @LogLen);
      SetLength(LogBuf, LogLen);
      glGetShaderInfoLog(Obj, LogLen, LogLen, PAnsiChar(LogBuf));
      Engine.Warning(LogBuf);
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

  //TODO
  //хак, но не спасёт при глобальных изменнениях шейдеров и особенно типов аттрибутов
  //надо писать свою систему выделения локейшина для аттрибута

  for i := 0 to FAttribList.Count - 1 do
  begin
    Str := (FAttribList[i] as IShaderAttrib).Name;
    glBindAttribLocation(FID, (FAttribList[i] as IShaderAttrib).Location, PAnsiChar(Str)); 
  end;

  glLinkProgram(FID);
  glGetProgramiv(FID, GL_LINK_STATUS, @Status);
  if Status <> 1 then
  begin
    Engine.Warning('Error linking shader');
    glGetProgramiv(FID, GL_INFO_LOG_LENGTH, @LogLen);
    SetLength(LogBuf, LogLen);
    glGetProgramInfoLog(FID, LogLen, LogLen, PAnsiChar(LogBuf));
    Engine.Warning(LogBuf);
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

    Name := UnicodeString(NameBuff);
    Delete(Name, Pos('[', Name), 3);

    u := nil;
    for j := 0 to FUniformList.Count -1 do
      if(FUniformList[j] as IShaderUniform).Name = Name then
        u := FUniformList[j] as IShaderUniform;
           //COMPARE
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

    Name := UnicodeString(NameBuff);
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

function TShaderProgram.Uniform(UName: PWideChar; UniformType: TShaderUniformType; Necessary: Boolean): JEN_Header.IShaderUniform;
var
  i : LongInt;
  u : IShaderUniform;
begin
  for i := 0 to FUniformList.Count - 1 do
    if WideSameStr((FUniformList[i] as IShaderUniform).Name, UName) then
      Exit(IShaderUniform(FUniformList[i]));

  u := TShaderUniform.Create;
  u.Init(FID, UName, UniformType, Necessary);
  FUniformList.Add(u);
  Result := u;
end;

function TShaderProgram.Attrib(AName: PWideChar; AttribType: TShaderAttribType; Necessary: Boolean): JEN_Header.IShaderAttrib;
var
  i : LongInt;
  a : IShaderAttrib;
begin
  for i := 0 to FAttribList.Count - 1 do
    if WideSameStr((FAttribList[i] as IShaderAttrib).Name, AName) then
      Exit(IShaderAttrib(FAttribList[i]));

  a := TShaderAttrib.Create;
  a.Init(FID, AName, AttribType, Necessary);
  FAttribList.Add(IShaderAttrib(a));
  Result := a;
end;

procedure TShaderProgram.Bind;
begin
  if (ActiveShaderId <> FID) then
  begin
    glUseProgram(FID);
    ActiveShaderId := FID;
    ActiveShader := Self;
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

function TShaderUniform.GetName: PWideChar;
begin
  Result := PWideChar(FName);
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
procedure TShaderUniform.Init(ShaderID: LongWord; const UName: AnsiString; UniformType: TShaderUniformType; Necessary: Boolean);
var
  i : LongInt;
begin
  FShaderId := ShaderID;
  FID   := glGetUniformLocation(ShaderID, PAnsiChar(UName));
  FName := Copy(UName, 1, Length(UName));
  FType := UniformType;

  if (FID = -1) and Necessary then
    Engine.Warning('Uncorrect uniform name ' + UName);

  for i := 0 to Length(FValue) - 1 do
    FValue[i] := NAN;
end;

procedure TShaderUniform.Value(const Data; Count: LongInt);
const
  USize : array [TShaderUniformType] of LongInt = (0, 4, 4, 8, 12, 16, 16, 36, 64);
begin
  if (FID = -1) then
    Exit;

  if (TShaderProgram.ActiveShaderId <> FShaderId) then
  begin
    Engine.Warning('Before set uniform value bind the shader');
    Exit;
  end;

  if Count * USize[FType] <= SizeOf(FValue) then
  begin
    if MemCmp(@FValue, @Data, Count * USize[FType]) <> 0 then
      Move(Data, FValue, Count * USize[FType])
    else
      Exit;
  end else
    Move(Data, FValue, SizeOf(FValue));

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

function TShaderAttrib.GetName: PWideChar;
begin
  Result := PWideChar(FName)
end;

function TShaderAttrib.GetType: TShaderAttribType;
begin
  Result := FType;
end;

function TShaderAttrib.GetLocation: GLhandle; 
begin
  Result := FID;
end;

procedure TShaderAttrib.Init(ShaderID: LongWord; const AName: AnsiString; AttribType: TShaderAttribType; Necessary: Boolean);
begin
  FID   := glGetAttribLocation(ShaderID, PAnsiChar(AName));
  FName := Copy(AName, 1, Length(AName));
  FType := AttribType;

  if (FID = -1) and Necessary then
    Engine.Warning('Uncorrect attrib name ' + AName);
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
  inherited Create(FilePath, rtShader);
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
  Engine.Log('Shader resource ' + FName + ' destroyed');
  inherited;
end;

function TShaderResource.GetDefineId(Name: PWideChar): LongInt;
var
  I : LongInt;
begin
  Result := -1;
  for I := 0 to FDefines.Count - 1 do
    if TShaderDefine(FDefines[i]^).Name = Name then
      Exit(I);
end;

function TShaderResource.GetDefine(Name: PWideChar): LongInt;
var
  Id : LongInt;
begin
  Id := GetDefineId(Name);
  if Id = -1 then
    Exit(-1);

  Result := TShaderDefine(FDefines[id]^).Value;
end;

procedure TShaderResource.SetDefine(Name: PWideChar; Value: LongInt);
var
  Define : ^TShaderDefine;
  Id : LongInt;
begin
  if Value < 0 then
  begin
    Engine.Warning('Can not set the value to define less than zero');
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
  Shader  : JEN_Header.IShaderProgram;
begin
  FXML := XML;
  for I := 0 to FShaderPrograms.Count - 1 do
  begin
    Shader := FShaderPrograms[i] as JEN_Header.IShaderProgram;
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

procedure TShaderResource.Compile(var Shader: JEN_Header.IShaderProgram);
var
  XN_VS   : IXML;
  XN_FS   : IXML;
  i       : LongInt;
  Str     : UnicodeString;

  function IndexStr(const AText: UnicodeString; const AValues: array of UnicodeString): LongInt;
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

    function GetParam(const Node: IXML; const Name: UnicodeString): TXMLParam;
    begin
      Result := Node.Params[PWideChar(Name)];
      if Result.Name = '' then
        Engine.Warning('Not defined param def in token: ' + Node.Tag);
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
              -1 : Engine.Warning('Is not set definition: ' + Param.Value);
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
          Engine.Warning('Uncorrect token: ' + Tag);
      end;

    end;
  end;

begin
  Shader := IShaderProgram(TShaderProgram.Create);

  if (Assigned(FXML)) then
  begin
    XN_VS := FXML.Node['VertexShader'];
    XN_FS := FXML.Node['FragmentShader'];
  end;

  if not (Assigned(XN_VS) and Assigned(XN_FS)) then
  begin
    Engine.Warning('Uncorrect shader xml file');
    Exit;
  end;

  if not (Shader as IShaderProgram).Init(MergeCode(XN_VS), MergeCode(XN_FS)) then
  begin
    Str := 'Defines:';
    for I := 0 to FDefines.Count - 1 do
      with TShaderDefine(FDefines[i]^) do
        Str := Str + #10 + Name + ' - ' + IntToStr(Value);

    Engine.Log(Str);
  end;
  FShaderPrograms.Add(Shader);
end;

constructor TShaderLoader.Create;
begin
  inherited;
  ExtString := '.xml';
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

procedure ClearResources(Param: LongInt; Data: Pointer); stdcall;
begin
  TShaderProgram.ActiveShaderId := 0;
  TShaderProgram.ActiveShader := nil;
end;

initialization
begin
  CreateEngine;
  Engine.AddEventListener(evFinish, @ClearResources);
end;

end.

