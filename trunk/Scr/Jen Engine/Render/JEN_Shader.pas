unit JEN_Shader;

interface

uses
  JEN_Resource,
  JEN_OpenGlHeader,
  JEN_Utils,
  CoreX_XML;

type
  TShaderProgram = class
    constructor Create(blabla : String);
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

constructor TShaderProgram.Create(blabla : String);
begin

end;

destructor TShaderProgram.Destroy;
begin

end;

procedure TShaderProgram.Bind;
begin

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
begin

end;

constructor TShaderLoader.Create;
begin
  inherited;
  ExtString := 'xml';
  Resource := rtShader;
end;

function TShaderLoader.Load(const Stream : TStream; var Resource : TResource) : Boolean;
var
  Shader : TShader;
  N      : TXml;
begin
  Shader := Resource as TShader;

  with Shader do
  begin
    XML := TXML.Load(Stream);
    if not Assigned(XML) then Exit(false);

    N := XML.Node['Shader'];

    if Assigned(N) then
    begin
      XN_VS := N.Node['VertexShader'];
      XN_FS := N.Node['FragmentShader'];
    end;
  end;

end;

end.

