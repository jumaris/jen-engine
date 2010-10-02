unit JEN_Game;
{$I JeN_config.INC}

interface

uses
  JEN_Window, JEN_Render;

type
  TGame = class
  private
    class var   FisRunnig : Boolean;
    class var   FQuit     : Boolean;
    class var   FWindow   : TWindow;
    var FRender           : TRender;
    procedure   SetWindow( Window : TWindow );
    function    GetWindow : TWindow; inline;
    procedure   SetRender( Render : TRender );
  protected
    procedure   LoadContent; virtual; abstract;
  public
    constructor Create;
    destructor  Destroy; override;

    class procedure Exit;

    procedure   Run;

    class property    Quit  : Boolean read FQuit;
    property    Window: TWindow read GetWindow write SetWindow;
    property    Render: TRender read FRender write SetRender;
  end;

implementation

uses
  XSystem, JEN_Log;

constructor TGame.Create;
begin
  inherited;
  if( FisRunnig ) then
    LogOut( 'Engine alredy running', LM_WARNING );

  if Assigned( FWindow ) then
    FWindow.Free;

  FWindow := nil;
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

  if Assigned( FWindow ) then
    begin
      FWindow.Free;
      FWindow := nil;
    end;

  FisRunnig := False;
  inherited;
end;

class procedure TGame.Exit;
begin
  FQuit := True;
  FWindow.HandleFree;
end;

procedure TGame.SetWindow( Window : TWindow );
begin
  if Assigned( FWindow ) then
    begin
      FWindow.Free;
      LogOut( 'Window alrady exist', LM_WARNING );
    end;

  FWindow := Window;
end;

function TGame.GetWindow;
begin
  result := FWindow;
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
  if FisRunnig or (not Assigned( FWindow )) then Exit;
  FisRunnig := true;

  LoadContent;

  while not FQuit do
    begin
      Window.Update;
    end;
end;

initialization
begin
  Tgame.FisRunnig := false;
end;

end.
