unit Unit1;

interface

uses
  windows,
  JEN_Header,
  JEN_Math;

type
  TGame = class(TInterfacedObject, IGame)
  public
    procedure LoadContent; stdcall;
    procedure OnUpdate(dt: LongInt); stdcall;
    procedure OnRender; stdcall;
    procedure Close; stdcall;
  end;

var
  Engine : IJenEngine;
  Display : IDisplay;
  Render : IRender;
  Render2d : IRender2d;
  Utils : IUtils;
  Game : IGame;
  ResMan : IResourceManager;
  r : ITexture;
  s : IShaderProgram;


  procedure p;

implementation

procedure TGame.LoadContent;
var
  sr : IShaderResource;
begin
   ResMan.Load('Media\123.dds', r);
   ResMan.Load('Media\Shader2.xml', sr);
   s := sr.Compile;
end;

procedure TGame.OnUpdate(dt: LongInt);
begin
  Display.Caption := Utils.IntToStr(Render.LastDipCount);
end;

procedure TGame.OnRender;
const c =4;
var
  i : integer;
begin
  Render.Clear(True,False,False);

    for i := 0 to c do
    render2d.DrawSprite(r ,Frac(i / 50),i/1000,1/25,1/25, vec4f(1.0 - i/c,1,1,1), Utils.Time/10000*360,0.5,0.5);


    render2d.DrawSpriteAdv(s,nil,nil,nil,0.35,0.2,0.3,0.3, clWhite, clWhite, clWhite, clWhite, Utils.Time/10000*360,0.5,0.5);


        render2d.DrawSprite(r,0.25,0.6,0.5,0.3, vec4f(1,0,0,1),vec4f(0,1,0,1),vec4f(0,0,1,1),vec4f(1,1,1,1), Utils.Time/10000*360,0.5,0.5);

end;

procedure TGame.Close;
begin
  r        := nil;
  Display  := nil;
  Utils    := nil;
  Render   := nil;
  Render2d := nil;
  ResMan   := nil;
end;

procedure p;
begin
  ReportMemoryLeaksOnShutdown := True;
  GetJenEngine(Engine);

  Engine.GetSubSystem(ssDisplay, IJenSubSystem(Display));
  Engine.GetSubSystem(ssUtils, IJenSubSystem(Utils));
  Engine.GetSubSystem(ssRender, IJenSubSystem(Render));
  Engine.GetSubSystem(ssRender2d, IJenSubSystem(Render2d));
  Engine.GetSubSystem(ssResMan, IJenSubSystem(ResMan));
  Display.Init(1024,768,9,False);
  Render.Init();

  Render.SetVSync(False);
  Game := TGame.Create;
  Engine.Start(Game);

  Game := nil;
  Engine := nil;
end;

end.
