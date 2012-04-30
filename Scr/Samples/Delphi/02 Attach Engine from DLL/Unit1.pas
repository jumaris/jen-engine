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
  Game : IGame;
  Input : IInput;
  ResMan : IResourceManager;
  r : ITexture;
  s : IShaderProgram;
  tsss : TTSBoard;
  Font  : IFont;
  Cam   :  ICamera2d;
  procedure p;

implementation

function IntToStr(Value: LongInt): string;
var
  Res : string[32];
begin
  Str(Value, Res);
  Result := string(Res);
end;


procedure TGame.LoadContent;
var
sp  : IShaderResource;
begin
//  ResMan.Load('Media\ArialFont.jfi', Font); //OOOOO◊≈Õ‹ Œœ¿—Õ¿!
  ResMan.Load('Media\123.dds', r);
 ResMan.Load('media\123.xml', sp);
 sp.Compile(s);
  //tsss := TTSBoard.Create;
  //tsss.Init('Test', '1.0');
  //tsss.Sumbit('ÈˆÛ',5123);
 { Cam := Helpers.CreateCamera2D;
  Cam.Enable := True;   }
end;

procedure TGame.OnUpdate(dt: LongInt);
var
  i   : Integer;
begin
 // Display.Caption := '321';//PWideChar(IntToStr(Render.FPS)+'['+IntToStr(Render.FrameTime)+']'+IntToStr(Render.LastDipCount));
{  for I := 1 to Input.Mouse.WheelDelta do
    Cam.Scale := Cam.Scale*2;

  for I := -1 downto Input.Mouse.WheelDelta do
    Cam.Scale := Cam.Scale/2;    }
//  Engine.log(IntToStr(Render.FPS)+'['+IntToStr(Render.FrameTime)+']'+IntToStr(Render.LastDipCount));

end;

procedure TGame.OnRender;
var i : integer;
begin
  //Cam.SetCam;
  Render.Clear(True,False,False);

//  Render2d.DrawSprite(r,300,100,512,512,clwhite);
  Render2d.DrawSprite(s,r,nil,nil,300,200,512,512,clBlack,clWhite,clBlack,clWhite,45,0);
     {
  Font.OutlineSize := 1;
 // Font.Scale := Cam.Scale;
 Font.SetGradColors(clwhite, Vec4f(1,0,0,1));
  Font.OutlineColor := Vec3f(1,0,0);
  Font.Print('asd',0,0);         }
{
  for i := 0 to 20 do

  Render2d.DrawSprite(r,0,0,1024,768,clwhite);  }
end;

procedure TGame.Close;
begin
  Cam      := nil;
  r        := nil;
   Font    := nil;
  RT       := nil;
  Display  := nil;
  Input    := nil;
  Render   := nil;
  Render2d := nil;
  ResMan   := nil;
  Helpers  := nil;
end;

procedure p;
var
sp  : IShaderResource;
begin
//  ReportMemoryLeaksOnShutdown := True;
  Engine := GetJenEngine(False);

  Engine.GetSubSystem(ssDisplay, IJenSubSystem(Display));
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

 // tsss.Free;

  Game := nil;
  Engine := nil;
end;

end.
