unit JEN_Game;

interface

uses
  JEN_OpenGlHeader,
  JEN_Utils;

type
  TGame = class
    constructor Create;
    destructor Destroy; override;
  private
    class var FisRunnig : Boolean;
    class var FQuit : Boolean;
  protected
    procedure LoadContent; virtual; abstract;
    procedure OnUpdate(dt: double); virtual; abstract;
    procedure OnRender; virtual; abstract;
  public
    class property Quit: Boolean read FQuit;
    class procedure Finish;

    procedure Run;
  end;

implementation

uses
  XSystem,
  JEN_Main;

constructor TGame.Create;
begin
  inherited;

  if(FisRunnig) then
  begin
    LogOut('Engine alredy running', lmError);
    Exit;
  end;

  FQuit  := False;
end;

destructor TGame.Destroy;
begin
  if Assigned(Render) then
    FreeAndNil(Render);

  if Assigned(Display) then
    FreeAndNil(Display);

  if Assigned(ResMan) then
    FreeAndNil(ResMan);

  FisRunnig := False;
  inherited;
end;

class procedure TGame.Finish;
begin
  FQuit := True;
 // FDisplay.HandleFree;
end;

procedure TGame.Run;
begin

  if(FisRunnig) then
  begin
    LogOut('Engine alredy running', lmError);
    Exit;
  end;

  if(not( Assigned(Display) and Display.Valid and
          Assigned(Render) and Render.Valid{ and
          Assigned(ResMan)} ) )then
  begin
    Logout('Error in some subsustem', lmError);
    Exit;
  end;

  Logout('Let''s rock!', lmNotify);
  FisRunnig := true;

  LoadContent;

  while not FQuit do
    begin
      Display.Update;
      OnUpdate(0);
      OnRender;
  //   glfinish;
      Display.Swap;
    end;
end;

initialization
begin
  Tgame.FisRunnig := false;
end;

end.
