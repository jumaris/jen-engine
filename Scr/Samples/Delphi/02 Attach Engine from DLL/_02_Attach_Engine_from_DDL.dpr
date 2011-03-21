program _02_Attach_Engine_from_DDL;

uses
  JEN_Header in '..\..\..\Include\Delphi\JEN_Header.pas',
  JEN_Math in '..\..\..\Include\Delphi\JEN_Math.pas';

{$R *.res}
{$R ..\..\..\icon.RES}


type
  TGame = class(TInterfacedObject, IGame)
  public
    procedure LoadContent; stdcall;
    procedure OnUpdate(dt: double); stdcall;
    procedure OnRender; stdcall;
  end;

var
  Engine : IJenEngine;
  Display : IDisplay;
  Render : IRender;
  Game : TGame;
  ResMan : IResourceManager;


procedure TGame.LoadContent;
begin
  ResMan.LoadTexture('Media\asd.dds');
end;

procedure TGame.OnUpdate(dt: double);
begin

end;

procedure TGame.OnRender;
begin
  Render.Clear(True,False,False);
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  GetJenEngine(Engine);
  Engine.GetSubSystem(ssDisplay, IJenSubSystem(Display));
  Engine.GetSubSystem(ssRender, IJenSubSystem(Render));
  Engine.GetSubSystem(ssResMan, IJenSubSystem(ResMan));
  Display.Init(1024,768,9,false);
  Render.Init();
  Game := TGame.Create;
  Engine.Start(Game);
end.
