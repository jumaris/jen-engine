unit JEN_Game;
{$I JeN_config.INC}

interface

uses
  JEN_Display,
  JEN_Render;

type
  TGame = class
    constructor Create;
    destructor  Destroy; override;
  private
    var FRender         : TRender;
    procedure SetRender(Render : TRender);

    class var FisRunnig : Boolean;
    class var FQuit     : Boolean;
    class var FDisplay  : TDisplay;
    class procedure SetDisplay(Display : TDisplay); static;
  protected
    procedure   LoadContent; virtual; abstract;
  public
    class procedure Exit;

    procedure Run;

    class property Quit   : Boolean read FQuit;
    class property Display: TDisplay read FDisplay write SetDisplay;
    property       Render : TRender read FRender write SetRender;
  end;

implementation

uses
  XSystem,
  JEN_Main;

constructor TGame.Create;
begin
  inherited;
  if( FisRunnig ) then
    LogOut( 'Engine alredy running', LM_WARNING );

  if Assigned( FDisplay ) then
    FDisplay.Free;

  FDisplay:= nil;
  FRender := nil;
  FQuit   := False;
end;

destructor TGame.Destroy;
begin

  if Assigned( FRender ) then
    begin
      FRender.Free;
      FRender := nil;
    end;

  if Assigned( FDisplay ) then
    begin
      FDisplay.Free;
      FDisplay := nil;
    end;

  FisRunnig := False;
  inherited;
end;

class procedure TGame.Exit;
begin
  FQuit := True;
 // FDisplay.HandleFree;
end;

class procedure TGame.SetDisplay(Display : TDisplay);
begin
  if Assigned( FDisplay ) then
    begin
      FDisplay.Free;
      LogOut( 'Display alrady exist', LM_WARNING );
    end;

  FDisplay := Display;
end;

procedure TGame.SetRender( Render : TRender );
begin
  if Assigned( FRender ) then
    begin
      FRender.Free;
      LogOut( 'Render alrady exist', LM_WARNING );
    end;

  FRender := Render;
end;

procedure TGame.Run;
begin
  if FisRunnig or (not Assigned(FDisplay)) then Exit;
  FisRunnig := true;

  LoadContent;

  while not FQuit do
    begin
      Display.Update;
    end;
end;

initialization
begin
  Tgame.FisRunnig := false;
end;

end.
