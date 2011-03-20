unit JEN_Shader;

interface

uses
  JEN_Header,
  JEN_Resource,
  JEN_OpenGlHeader,
  JEN_Utils,

  CoreX_XML;

type
  TShaderProgram = class(TInterfacedObject, IShaderProgram)
    constructor Create;
    destructor Destroy;
  private
  public
    FID : GLEnum;
    procedure Bind; stdcall;
  end;

  TShaderResource = class(TInterfacedObject, IResource, IShaderResource)
    constructor Create(const Name: string);
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

constructor TShaderProgram.Create;
begin
  inherited;
  FID := glCreateProgram;
end;

destructor TShaderProgram.Destroy;
begin
  glDeleteShader(FID);
  inherited;
end;

procedure TShaderProgram.Bind;
begin
//glValidateProgramARB(0);
//     glDeleteObjectARB(8);
end;

constructor TShaderResource.Create(const Name: string);
begin
  inherited Create;
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
  S: AnsiString;
  Shader : TShaderProgram;
  Status : LongInt;
  LogBuf : AnsiString;
  LogLen : LongInt;

  function IndexStr(const AText: string; const AValues: array of string): Integer;
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

  function MergeCode(const Node:TXML) : AnsiString;
  var
    i: integer;
  begin
    Result:='';
    for i:= 0 to Node.Count - 1  do
    with Node.NodeI[i] do
    begin
      case IndexStr(Tag,['Code']) of
        0 : begin
        Result := Result + Content;
        end;
      end;
    end;
  end;

  function Attach(ShaderType: GLenum; const Source: AnsiString) : LongWord;
  var
    Obj : GLEnum;
    SourcePtr  : PAnsiChar;
    SourceSize : LongInt;
    P,Start : PAnsiChar;
    L, S : AnsiString;
    I,Tab,Len : integer;
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

      LogOut(Source, lmCode);

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

      Result := IShaderProgram(FShaderPrograms.Add(Shader));
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
  Shader := Resource as TShaderResource;

  with Shader do
  begin
    XML := TXML.Load(Stream);
    if not Assigned(XML) then Exit(false);

    XN_VS := XML.Node['VertexShader'];
    XN_FS := XML.Node['FragmentShader'];
  end;

end;

end.

