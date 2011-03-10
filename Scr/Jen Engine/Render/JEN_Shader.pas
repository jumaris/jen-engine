unit JEN_Shader;

interface

uses
  JEN_Header,
  JEN_Resource,
  JEN_OpenGlHeader,
  JEN_Utils,

  CoreX_XML;

type
  TShaderProgram = class(TResource)
    constructor Create;
    destructor Destroy;
  private
  public
    FID : GLEnum;
    procedure Bind;
  end;

  TShader = class(TResource)
    constructor Create(const Name: string); override;
    destructor Destroy; override;
  private

  public
    XN_VS, XN_FS, XML : TXML;
    function Compile : TShaderProgram;
  end;

  TShaderLoader = class(TResLoader)
    constructor Create;
  public
    function Load(const Stream : TStream; var Resource : TResource) : Boolean; override;
  end;

implementation

uses
  JEN_Main;

constructor TShaderProgram.Create;
begin
  inherited Create('');
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

constructor TShader.Create(const Name: string);
begin
  inherited Create(Name);
end;

destructor TShader.Destroy;
begin
  if Assigned(XML) then
    XML.Free;
  inherited;
end;

function TShader.Compile : TShaderProgram;
var
  S: AnsiString;
  Shader : TShaderProgram;

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

  procedure InfoLog(Obj: LongWord; IsProgram: Boolean);
  var
    LogBuf : AnsiString;
    LogLen : LongInt;
  begin
    if IsProgram then
      glGetProgramiv(Obj, GL_INFO_LOG_LENGTH, @LogLen)
    else
      glGetShaderiv(Obj, GL_INFO_LOG_LENGTH, @LogLen);

    SetLength(LogBuf, LogLen);

    if IsProgram then
      glGetProgramInfoLog(Obj, LogLen, LogLen, PAnsiChar(LogBuf))
    else
      glGetShaderInfoLog(Obj, LogLen, LogLen, PAnsiChar(LogBuf));
    LogOut(Name + '\n' + string(LogBuf), lmWarning);
  end;

  function Attach(ShaderType: GLenum; const Source: AnsiString) : LongWord;
  var
    Obj : GLEnum;
    SourcePtr  : PAnsiChar;
    SourceSize : LongInt;
    Status : LongInt;
  begin
    Shader := TShaderProgram.Create;
    Obj := glCreateShader(ShaderType);

    SourcePtr  := PAnsiChar(Source);
    SourceSize := Length(Source);

    glShaderSource(Obj, 1, @SourcePtr, @SourceSize);
    glCompileShader(Obj);
    glGetShaderiv(Obj, GL_COMPILE_STATUS, @Status);
    if Status <> 1 then
      InfoLog(Obj, False);
    glAttachShader(Shader.FID, Obj);
    glDeleteShader(Obj);
  end;

begin
  if Assigned(XN_VS) and Assigned(XN_FS) then
  begin
   logout(MergeCode(XN_VS),lmNotify);
  logout(MergeCode(XN_FS),lmNotify);

  end;

end;

constructor TShaderLoader.Create;
begin
  inherited;
  ExtString := 'xml';
  ResType := rtShader;
end;

function TShaderLoader.Load(const Stream : TStream; var Resource : TResource) : Boolean;
var
  Shader : TShader;
begin
  Shader := Resource as TShader;

  with Shader do
  begin
    XML := TXML.Load(Stream);
    if not Assigned(XML) then Exit(false);

    XN_VS := XML.Node['VertexShader'];
    XN_FS := XML.Node['FragmentShader'];

  end;

end;

end.

