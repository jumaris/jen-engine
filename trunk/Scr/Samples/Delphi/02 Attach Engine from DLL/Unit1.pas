unit Unit1;

interface

uses

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
  RT : IRenderTarget;
  Utils : IUtils;
  Game : IGame;
  Input : IInput;
  ResMan : IResourceManager;
  r : ITexture;
  s : IShaderProgram;
  sr : IShaderResource;
  c : Boolean;
  procedure p;

implementation

procedure TGame.LoadContent;

begin
   ResMan.Load('Media\123.dds', r);
   RT := Render.CreateRenderTarget(512,512, tfoBGRA8, 1, 0, false);
 //  ResMan.Load('Media\Text.xml', sr);
 //  s := sr.Compile;
  // r.Filter := tfNone;
end;

procedure TGame.OnUpdate(dt: LongInt);
begin
//Input.Update;
  Display.Caption := Utils.IntToStr(Display.FPS);
  if Input.Hit[ikSpace] then
   c := not c;
end;

procedure TGame.OnRender;
const m =2500;
var
  i : integer;
begin

  //Render.CullFace := cfNone;

 //   Render.Clear(True,False,False);

  if c then Render.SetRenderTarget(Rt);
  //Render.Clear(True,False,False);

                      //render.AlphaTest:=64;
 // render2d.DrawSprite(r,0,0,0.5,0.5, clWhite);
  //render2d.DrawSpriteAdv(s,r,nil,nil,0,0,1,1.33333333, clWhite,clWhite,clWhite,clWhite);


  for i := 0 to m do
  render2d.DrawSprite(r ,Frac(i / 300)*1000,(i div 300)*100,100,100, vec4f(1.0 - i/m,1,1,1), 0*Utils.Time/10000*360,0.5,0.5);
    //ssprite2d_Draw(r,Frac(i / 300)*1000,(i div 300)*100,100,100,0);


    //render2d.DrawSpriteAdv(s,nil,nil,nil,0.35,0.2,0.3,0.3, clWhite, clWhite, clWhite, clWhite, Utils.Time/10000*360,0.5,0.5);


       // render2d.DrawSprite(r,256,400,400,400, vec4f(1,0,0,1),vec4f(0,1,0,1),vec4f(0,0,1,1),vec4f(1,1,1,1),0* Utils.Time/10000*360,0.5,0.5);
  if c then
  begin
  Render.SetRenderTarget(nil);

  render2d.DrawSprite(Rt.Texture[rcColor0],0,0,1024,768, clWhite, clWhite, clWhite, clWhite);
  end;

 // render2d.DrawSprite(Rt.Texture[rcColor0],256,400,400,400, vec4f(1,0,0,1),vec4f(0,1,0,1),vec4f(0,0,1,1),vec4f(1,1,1,1), Utils.Time/10000*360,0.5,0.5);
end;

procedure TGame.Close;
begin
  r        := nil;
  RT       := nil;
  s        := nil;
  sr       := nil;
  Display  := nil;
  Utils    := nil;
  Input    := nil;
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
  Engine.GetSubSystem(ssInput, IJenSubSystem(Input));
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
