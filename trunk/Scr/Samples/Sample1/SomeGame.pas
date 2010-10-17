unit SomeGame;
{$I Jen_config.INC}

interface

uses
  windows, JEN_MAIN;

type
  TSameGame = class ( TGame )
  private
    procedure LoadContent; override;
  public
    constructor Create;
  end;

var
  Game : TSameGame;

implementation

constructor TSameGame.Create;
begin
  inherited;
  SystemParams.Screen.SetMode( 1028, 768, 60 );
  Window  := TWindow.Create( True, 10, 90, 0 );
  Render  := TGLRender.Create( Window );
end;

procedure TSameGame.LoadContent;
begin

end;

end.
