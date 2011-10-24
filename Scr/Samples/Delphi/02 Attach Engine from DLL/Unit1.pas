unit Unit1;

interface

uses
  TopScores,
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
  Helpers : IHelpers;
  RT : IRenderTarget;
  Utils : IUtils;
  Game : IGame;
  Input : IInput;
  ResMan : IResourceManager;
  r : ITexture;
  tsss : TTSBoard;
  Font  : IFont;
  Cam   :  ICamera2d;
  procedure p;


implementation

procedure TGame.LoadContent;

begin
  ResMan.Load('Media\ArialFont.jfi', Font);
  ResMan.Load('Media\123.dds', r);
  //tsss := TTSBoard.Create;
  //tsss.Init('Test', '1.0');
  //tsss.Sumbit('éöó',5123);
  Cam := Helpers.CreateCamera2D;
  Cam.Enable := True;
end;

procedure TGame.OnUpdate(dt: LongInt);
var
  i : Integer;
begin
  Display.Caption := Utils.IntToStr(Render.FPS)+'['+Utils.IntToStr(Render.FrameTime)+']'+Utils.IntToStr(Render.LastDipCount);
  for I := 1 to Input.Mouse.WheelDelta do
    Cam.Scale := Cam.Scale*2;

  for I := -1 downto Input.Mouse.WheelDelta do
    Cam.Scale := Cam.Scale/2;

end;

procedure TGame.OnRender;
begin
  Cam.SetCam;
  Render.Clear(True,False,False);
  Font.OutlineSize := 1;
 // Font.Scale := Cam.Scale;
 Font.SetGradColors(clwhite, Vec4f(1,0,0,1));
  Font.OutlineColor := Vec3f(1,0,0);
  Font.Print('asd',0,0);
  Render2d.DrawSprite(r,0,0,50,60,clwhite);
end;

procedure TGame.Close;
begin
  r        := nil;
  RT       := nil;
  Display  := nil;
  Utils    := nil;
  Input    := nil;
  Render   := nil;
  Render2d := nil;
  ResMan   := nil;
  Helpers  := nil;
end;

procedure p;
begin
  ReportMemoryLeaksOnShutdown := True;
  Engine := GetJenEngine(True, False);

  Engine.GetSubSystem(ssDisplay, IJenSubSystem(Display));
  Engine.GetSubSystem(ssUtils, IJenSubSystem(Utils));
  Engine.GetSubSystem(ssRender, IJenSubSystem(Render));
  Engine.GetSubSystem(ssHelpers, IJenSubSystem(Helpers));
  Engine.GetSubSystem(ssInput, IJenSubSystem(Input));
  Engine.GetSubSystem(ssRender2d, IJenSubSystem(Render2d));
  Engine.GetSubSystem(ssResMan, IJenSubSystem(ResMan));
  Display.Init(1024,768,9,false);
  Render.Init();
 // Render2d.ResolutionCorrect(800,600);

  Render.SetVSync(False);
  Game := TGame.Create;
  Engine.Start(Game);

  tsss.Free;

  Game := nil;
  Engine := nil;
end;

end.
