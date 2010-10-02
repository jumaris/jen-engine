unit SomeGame;
{$I Jen_config.INC}

interface

uses
  JEN_Game,
  JEN_Window,
  JEN_Render,
  JEN_OpenGL;

type
  TSameGame = class ( TGame )
  private
    procedure LoadContent; override;
  public
    constructor Create;
  end;

var Game : TSameGame;

implementation

constructor TSameGame.Create;
begin
  inherited;
  Window  := TWindow.Create( True, 10, 90, 0 );
  Render  := TGLRender.Create( Window );
end;

procedure TSameGame.LoadContent;
begin

end;

end.
