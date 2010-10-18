unit SomeGame;
{$I Jen_config.INC}

interface

uses
  JEN_MAIN,
  JEN_Display_Window;

type
  TSameGame = class(TGame)
  private
    procedure LoadContent; override;
  public
    constructor Create;
  end;

implementation

constructor TSameGame.Create;
begin
  inherited;
 // SystemParams.Screen.SetMode( 1028, 768, 60 );
  Display := TDisplayWindow.Create(1028, 768, 60, false);
  Render  := TGLRender.Create;
end;

procedure TSameGame.LoadContent;
begin

end;

end.
