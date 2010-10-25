unit SomeGame;
{$I Jen_config.INC}

interface

uses
  JEN_MAIN,
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
 // SystemParams.Screen.SetMode( 1028, 768, 60 );
  Display := TDisplayWindow.Create(1028, 768, 60, false);
  Render := TGLRender.Create(Display);

  if not (Display.isValid and Render.isValid) then
    Exit;
        glClearColor(1,1,0,1);
  Logout('Let''s rock!', LM_NOTIFY);
  Run;
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
