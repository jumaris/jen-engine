unit JEN_Game;
{$I JeN_config.INC}

interface

uses
  JEN_OpenGlHeader,
  JEN_Display,
  JEN_Render;

type
  TGame = class
    constructor Create;
    destructor Destroy; override;
  private
    var FRender : TRender;
    var FDisplay : TDisplay;
    class var FisRunnig : Boolean;
    class var FQuit : Boolean;
  protected
    procedure LoadContent; virtual; abstract;
  public
    class property Quit: Boolean read FQuit;
    class procedure Finish;

    property Display: TDisplay read FDisplay write FDisplay;
    property Render: TRender read FRender write FRender;

    procedure Run;
    procedure OnUpdate(dt: double); virtual; abstract;
    procedure OnRender; virtual; abstract;
  end;

implementation

uses
  XSystem,
  JEN_Main;

constructor TGame.Create;
begin
  inherited;
  if( FisRunnig ) then
    LogOut('Engine alredy running', lmWarning);

  if Assigned(FDisplay) then
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

class procedure TGame.Finish;
begin
  FQuit := True;
 // FDisplay.HandleFree;
end;

procedure TGame.Run;
begin
  if FisRunnig or (Assigned(FDisplay)= False) or (FDisplay.Valid = False) then Exit;
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
