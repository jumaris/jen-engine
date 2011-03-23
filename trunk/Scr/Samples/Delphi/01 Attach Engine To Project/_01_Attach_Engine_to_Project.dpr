 program _01_Attach_Engine_to_Project;

uses
  JEN_Main in '..\..\..\Jen Engine\JEN_Main.pas',
  JEN_Render in '..\..\..\Jen Engine\Render\JEN_Render.pas',
  JEN_Math in '..\..\..\Include\Delphi\JEN_Math.pas',
  JEN_OpenGLHeader in '..\..\..\Jen Engine\Utils\JEN_OpenGLHeader.pas',
  JEN_SystemInfo in '..\..\..\Jen Engine\Utils\JEN_SystemInfo.pas',
  JEN_Utils in '..\..\..\Jen Engine\Utils\JEN_Utils.pas',
  XSystem in '..\..\..\Jen Engine\Utils\XSystem.pas',
  JEN_Camera3D in '..\..\..\Jen Engine\Core\JEN_Camera3D.pas',
  JEN_GeometryBuffer in '..\..\..\Jen Engine\Render\JEN_GeometryBuffer.pas',
  JEN_DefConsoleLog in '..\..\..\Jen Engine\Core\JEN_DefConsoleLog.pas',
  JEN_Display in '..\..\..\Jen Engine\Core\JEN_Display.pas',
  JEN_Display_Window in '..\..\..\Jen Engine\Core\JEN_Display_Window.pas',
  JEN_Log in '..\..\..\Jen Engine\Core\JEN_Log.pas',
  JEN_ResourceManager in '..\..\..\Jen Engine\Core\JEN_ResourceManager.pas',
  JEN_DDSTexture in '..\..\..\Jen Engine\Core\JEN_DDSTexture.pas',
  JEN_Shader in '..\..\..\Jen Engine\Render\JEN_Shader.pas',
  CoreX_XML in '..\..\..\Jen Engine\Utils\CoreX_XML.pas',
  JEN_Resource in '..\..\..\Jen Engine\Core\JEN_Resource.pas',
  JEN_Header in '..\..\..\Include\Delphi\JEN_Header.pas',
  SomeGame in 'SomeGame.pas',
  JEN_Render2D in '..\..\..\Jen Engine\Render\JEN_Render2D.pas';

{$R ..\..\..\dll\jen.res}
{$R ..\..\..\icon.RES}

type
  TGame = class(TInterfacedObject, IGame)
  var
  r : ITexture;
  s : IShaderResource;
  sp : IShaderProgram;
  public
    procedure LoadContent; stdcall;
    procedure OnUpdate(dt: double); stdcall;
    procedure OnRender; stdcall;
  end;

procedure TGame.LoadContent; stdcall;
begin
  ResMan.Load('Media\asd.dds', r);
  ResMan.Load('Media\Shader.xml', s);
  sp := s.Compile;

end;

procedure TGame.OnUpdate(dt: double); stdcall;
begin

end;

procedure TGame.OnRender; stdcall;
begin

  Render.Clear(True,False,False);
  Render.CullFace := cfNone;

//   glviewport (0,0,1024,768);
  {
  Render.Matrix[mtProj].Ortho( 0, 800, 000, 600, -1, 1 );
  Render.Matrix[mtModel].Identity;

 // Render.Matrix[mtProj].Ortho(0,800,600,00,-1,1);
 // Render.Matrix[mtModel].Identity;


  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
//  glLoadMatrixf(@Render.Matrix[mtProj]);
  //glOrtho(0,1,0,1,0,1);// (0,800,
 // glOrtho(0, 800, 0, 100, -1, 1);
  glOrtho( 0, 800, 000, 600, -1, 1 );
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
                      }
  sp.Bind;
  r.Bind;
  render2d.Quad(Vec4f(0,1,0,0),
                Vec4f(1,0,1,1),
                Vec4f(0,0,0,1),
                Vec4f(1,1,1,0),vec2f(0,0));
end;

procedure pp;
var
  Engine : IJenEngine;
  Display : IDisplay;
  Render : IRender;
  Utils : IUtils;
  Game : TGame;
  ResMan : IResourceManager;
begin
  ReportMemoryLeaksOnShutdown := True;
  GetJenEngine(Engine);
  Engine.GetSubSystem(ssDisplay, IJenSubSystem(Display));
  Engine.GetSubSystem(ssRender, IJenSubSystem(Render));
  Engine.GetSubSystem(ssResMan, IJenSubSystem(ResMan));
  Engine.GetSubSystem(ssUtils, IJenSubSystem(Utils));
  Display.Init(1024, 768, 60, false);
  Render.Init();
  Game := TGame.Create;
  Engine.Start(Game);

  Game := nil;
  Engine := nil;
end;

begin
 // Engine := nil;
 // Game := TSomeGame.Create;
  pp;

end.
