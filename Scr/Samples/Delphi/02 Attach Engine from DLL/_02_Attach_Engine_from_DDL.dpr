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
  Render2d : IRender2d;
  Utils : IUtils;
  Game : TGame;
  ResMan : IResourceManager;
  r : ITexture;


procedure TGame.LoadContent;
begin
  r := ResMan.LoadTexture('Media\123.dds');
end;

procedure TGame.OnUpdate(dt: double);
begin
  Display.Caption := Utils.IntToStr(Display.FPs);
end;

procedure TGame.OnRender;
const c =4;
var
  i : integer;
begin
  Render.Clear(True,False,False);

    for i := 0 to c do
    render2d.DrawSprite(r ,Frac(i / 50),i/1000,1/25,1/25, vec4f(1.0 - i/c,1,1,1), Utils.Time/10000*360,0.5,0.5);


    render2d.DrawSprite(r,0.5,0.5,0.5,0.5, vec4f(1,2,1,1), Utils.Time/10000*360,0.5,0.5);

    render2d.DrawSprite(r,0.0,0.5,0.5,0.5, vec4f(1,0,0,1),vec4f(0,1,0,1),vec4f(0,0,1,1),vec4f(1,1,1,1), Utils.Time/10000*360,0.5,0.5);

end;

begin
  ReportMemoryLeaksOnShutdown := True;
  GetJenEngine(Engine);
  Engine.GetSubSystem(ssDisplay, IJenSubSystem(Display));
  Engine.GetSubSystem(ssUtils, IJenSubSystem(Utils));
  Engine.GetSubSystem(ssRender, IJenSubSystem(Render));
  Engine.GetSubSystem(ssRender2d, IJenSubSystem(Render2d));
  Engine.GetSubSystem(ssResMan, IJenSubSystem(ResMan));
  Display.Init(1024,768,9,false);
  Render.Init();
  Game := TGame.Create;
  Engine.Start(Game);
end.
