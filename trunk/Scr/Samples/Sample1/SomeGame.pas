unit SomeGame;

interface

uses
  JEN_MAIN,
  xsystem,
  JEN_OPENGLHEADER;

type
  TSameGame = class(TGame)
  private
    procedure LoadContent; override;
    procedure OnUpdate( Dt : Double ); override;
    procedure OnRender; override;
  public
    constructor Create;
  end;

implementation

constructor TSameGame.Create;
begin
  inherited;
  Display := TDisplayWindow.Create(1024, 768, 60, false);
  Render := TGLRender.Create(Display,24,8,2);

 // Display.FullScreen := true;
  Display.FullScreen := false;

  if not (Display.isValid and Render.isValid) then
    Exit;
  glClearColor(1,1,0,1);
end;

procedure TSameGame.LoadContent;
begin

end;

procedure TSameGame.OnUpdate( Dt : Double );
begin

end;

procedure TSameGame.OnRender;
begin
  glClear( GL_COLOR_BUFFER_BIT);
end;

end.
