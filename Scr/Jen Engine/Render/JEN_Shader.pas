unit JEN_Shader;

interface

uses
  JEN_ResourceManager,
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
    FProgram : TShaderProgram;
    procedure Bind;
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
  inherited;
end;

procedure TShader.Bind;
begin
  if Assigned(FProgram) then
    FProgram.Bind;
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
  XML : TXml;
begin
  Shader := Resource as TShader;

  XML := TXML.Load(Stream);



end;

end.

