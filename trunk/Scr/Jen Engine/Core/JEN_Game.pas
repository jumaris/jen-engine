unit JEN_Game;

interface

uses
  JEN_OpenGlHeader,
  JEN_Display,
  JEN_Render,
  JEN_ResourceManager,
  JEN_DDSTexture,
  JEN_Texture;

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
    Display : TDisplay;
    Render : TRender;
    ResMan : TResourceManager;
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
    LogOut('Engine alredy running', lmWarning);

  if Assigned(Display) then
    Display.Free;

  FQuit  := False;
  ResMan := TResourceManager.Create;
  ResMan.AddResLoader(TDDSLoader.Create);
end;

destructor TGame.Destroy;
begin
  if Assigned(Render) then
    begin
      Render.Free;
      Render := nil;
    end;

  if Assigned(Display) then
    begin
      Display.Free;
      Display := nil;
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
  if( FisRunnig or not(Assigned(Display) and Display.Valid and Assigned(Render) and Render.Valid) )then Exit;
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
