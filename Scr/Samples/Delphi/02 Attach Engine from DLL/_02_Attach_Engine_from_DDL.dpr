program _02_Attach_Engine_from_DDL;

uses
  JEN_Header in '..\..\..\Include\Delphi\JEN_Header.pas';

{$R *.res}
{$R ..\..\..\icon.RES}


type
  TGame = class(TInterfacedObject, IGame)
  public
    procedure LoadContent; stdcall;
    procedure OnUpdate(dt: double); stdcall;
    procedure OnRender; stdcall;
  end;

procedure TGame.LoadContent; stdcall;
begin

end;

procedure TGame.OnUpdate(dt: double); stdcall;
begin

end;

procedure TGame.OnRender; stdcall;
begin

end;

var Engine : IJenEngine;
var Display : IDisplay;
var Render : IRender;
var Game : TGame;
begin
  ReportMemoryLeaksOnShutdown := True;
  GetJenEngine(Engine);
  Engine.GetSubSystem(ssDisplay, IJenSubSystem(Display));
  Engine.GetSubSystem(ssRender, IJenSubSystem(Render));
  Display.Init();
  Render.Init();
  Game := TGame.Create;
  Engine.Start(Game);
end.
