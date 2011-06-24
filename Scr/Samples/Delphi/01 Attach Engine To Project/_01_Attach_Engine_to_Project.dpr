program _01_Attach_Engine_to_Project;

uses
  JEN_Main in '..\..\..\Jen Engine\JEN_Main.pas',
  JEN_Render in '..\..\..\Jen Engine\Render\JEN_Render.pas',
  JEN_Math in '..\..\..\Include\Delphi\JEN_Math.pas',
  JEN_OpenGLHeader in '..\..\..\Jen Engine\Utils\JEN_OpenGLHeader.pas',
  JEN_SystemInfo in '..\..\..\Jen Engine\Helpers\JEN_SystemInfo.pas',
  JEN_Utils in '..\..\..\Jen Engine\Utils\JEN_Utils.pas',
  JEN_GeometryBuffer in '..\..\..\Jen Engine\Render\JEN_GeometryBuffer.pas',
  JEN_Display in '..\..\..\Jen Engine\Core\JEN_Display.pas',
  JEN_Log in '..\..\..\Jen Engine\Core\JEN_Log.pas',
  JEN_ResourceManager in '..\..\..\Jen Engine\Core\JEN_ResourceManager.pas',
  JEN_DDSTexture in '..\..\..\Jen Engine\Core\JEN_DDSTexture.pas',
  JEN_Shader in '..\..\..\Jen Engine\Render\JEN_Shader.pas',
  CoreX_XML in '..\..\..\Jen Engine\Utils\CoreX_XML.pas',
  JEN_Resource in '..\..\..\Jen Engine\Core\JEN_Resource.pas',
  JEN_Header in '..\..\..\Include\Delphi\JEN_Header.pas',
  SomeGame in 'SomeGame.pas',
  JEN_Render2D in '..\..\..\Jen Engine\Render\JEN_Render2D.pas',
  JEN_Console in '..\..\..\Jen Engine\Core\JEN_Console.pas',
  JEN_Camera3D in '..\..\..\Jen Engine\Helpers\JEN_Camera3D.pas',
  JEN_Helpers in '..\..\..\Jen Engine\Helpers\JEN_Helpers.pas',
  JEN_Input in '..\..\..\Jen Engine\Core\JEN_Input.pas';

{$R ..\..\..\dll\jen.res}
{$R ..\..\..\icon.RES}

type
  TGame = class(TInterfacedObject, IGame)
  public
    var
    r,r2 : ITexture;
    Shader : IShaderProgram;
    procedure LoadContent; stdcall;
    procedure OnUpdate(dt: LongInt); stdcall;
    procedure OnRender; stdcall;
    procedure Close; stdcall;
  end;

var
  Engine : IJenEngine = nil;
  Input  : IInput = nil;
  Display : IDisplay = nil;
  Render : IRender = nil;
  Utils : IUtils = nil;
  Game : IGame = nil;
  ResMan : IResourceManager = nil;
  Helpers : IHelpers = nil;
  Camera : ICamera3d = nil;

procedure TGame.LoadContent;
begin
  ResMan.Load('Media\123.dds', r2);
  ResMan.Load('Media\123.dds', r);
  r2 := nil;

  Camera := Helpers.CreateCamera3D;
end;

procedure TGame.OnUpdate(dt: LongInt);
begin
  Display.Caption := Utils.IntToStr(Display.FPs);
  Camera.onUpdate(dt);
end;

procedure TGame.OnRender;
var
  i : LongInt;
  M : TMat4f;
const c = 20000;
begin
  Render.Clear(True,False,False);

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

//  r.Bind;

   // Render.BlendType := btNormal;

   //   glEnableClientState( GL_COLOR_ARRAY);

  // glBindBuffer(GL_ARRAY_BUFFER, 0);
                  {
  Render.BlendType := btNone;


 //for i := 0 to 25000 do
 // render2d.DrawSprite(r ,Frac(i / 500),i/10000,1/25,1/25, vec4f(2,1,1,1), Utils.Time/10000*360,0.5,0.5);

                                         }

  for i := 0 to 10 do
    render2d.DrawSprite(r ,Frac(i / 50),i/4000,1/25,1/25, vec4f(1.0 - i/c,1,1,1), Utils.Time/10000*360,0.5,0.5);
                      {

    render2d.DrawSprite(r,0.5,0.5,0.5,0.2, vec4f(1,2,1,1), Utils.Time/10000*360,0.5,0.5);

    render2d.DrawSprite(r,0.0,0.5,0.5,0.2, vec4f(1,0,0,1),vec4f(0,1,0,1),vec4f(0,0,1,1),vec4f(1,1,1,1), Utils.Time/10000*360,0.5,0.5);
                        }
  //log.Print(Utils.IntToStr(Render.LastDipCount), lmNotify);

             {
  glMatrixMode(GL_PROJECTION);
  M := Render.Matrix[mtProj];
  glLoadMatrixf(@M);

  glMatrixMode(GL_MODELVIEW);
  M := Render.Matrix[mtView];
  glLoadMatrixf(@M);


 // glMatrixMode(GL_MODELVIEW);
//  M := Render.Matrix[mtModel];
 // glLoadMatrixf(@M);
      {
  glLoadIdentity;
//  glLoadMatrixf(@Render.Matrix[mtProj]);
  //glOrtho(0,1,0,1,0,1);// (0,800,
 // glOrtho(0, 800, 0, 100, -1, 1);
  glOrtho( 0, 800, 000, 600, -1, 1 );

  glLoadIdentity;   }
                {
  Shader.Bind;
  glBegin( GL_QUADS );
  // bottom
  glNormal3f( 0, -1, 0 );
  glTexCoord2f( 1, 1 ); glVertex3f( -1 , -1 , -1  );
  glTexCoord2f( 0, 1 ); glVertex3f(  1 , -1 , -1  );
  glTexCoord2f( 0, 0 ); glVertex3f(  1 , -1 ,  1  );
  glTexCoord2f( 1, 0 ); glVertex3f( -1 , -1 ,  1  );

  // top
  glNormal3f( 0, 1, 0 );
  glTexCoord2f( 0, 1 ); glVertex3f( -1 ,  1 , -1  );
  glTexCoord2f( 0, 0 ); glVertex3f( -1 ,  1 ,  1  );
  glTexCoord2f( 1, 0 ); glVertex3f(  1 ,  1 ,  1  );
  glTexCoord2f( 1, 1 ); glVertex3f(  1 ,  1 , -1  );

  // back
  glNormal3f( 0, 0, -1 );
  glTexCoord2f( 1, 0 ); glVertex3f( -1 , -1 , -1);
  glTexCoord2f( 1, 1 ); glVertex3f( -1 ,  1 , -1 );
  glTexCoord2f( 0, 1 ); glVertex3f(  1 ,  1 , -1 );
  glTexCoord2f( 0, 0 ); glVertex3f(  1 , -1 , -1 );

  // front
  glNormal3f( 0, 0, 1 );
  glTexCoord2f( 0, 0 ); glVertex3f( -1 , -1 ,  1  );
  glTexCoord2f( 1, 0 ); glVertex3f(  1 , -1 ,  1  );
  glTexCoord2f( 1, 1 ); glVertex3f(  1 ,  1 ,  1  );
  glTexCoord2f( 0, 1 ); glVertex3f( -1 ,  1 ,  1  );

  // left
  glNormal3f( -1, 0, 0 );
  glTexCoord2f( 0, 0 ); glVertex3f( -1 , -1 , -1  );
  glTexCoord2f( 1, 0 ); glVertex3f( -1 , -1 ,  1  );
  glTexCoord2f( 1, 1 ); glVertex3f( -1 ,  1 ,  1  );
  glTexCoord2f( 0, 1 ); glVertex3f( -1 ,  1 , -1  );
                // right
  glNormal3f( 1, 0, 0 );
  glTexCoord2f( 1, 0 ); glVertex3f( 1 , -1 , -1  );
  glTexCoord2f( 1, 1 ); glVertex3f( 1 ,  1 , -1  );
  glTexCoord2f( 0, 1 ); glVertex3f( 1 ,  1 ,  1  );
  glTexCoord2f( 0, 0 ); glVertex3f( 1 , -1 ,  1  );
glEnd;
                       }
end;

procedure TGame.Close;
begin
  r        := nil;
  Display  := nil;
  Utils    := nil;
  Render   := nil;
  Render2d := nil;
  ResMan   := nil;
  Helpers  := nil;
end;

procedure pp;
begin
  ReportMemoryLeaksOnShutdown := True;
  GetJenEngine(Engine);
  Engine.GetSubSystem(ssDisplay, IJenSubSystem(Display));
  Engine.GetSubSystem(ssRender, IJenSubSystem(Render));
  Engine.GetSubSystem(ssResMan, IJenSubSystem(ResMan));
  Engine.GetSubSystem(ssUtils, IJenSubSystem(Utils));
  Engine.GetSubSystem(ssInput, IJenSubSystem(Input));
  Engine.GetSubSystem(ssHelpers, IJenSubSystem(Helpers));

  Display.Init(1024, 768, 60, false);
  Render.Init();


//  Display.SetVSync(False);
  Display.FullScreen := false;
  //Display.SetVSync(false);
  Game := TGame.Create;
  Engine.Start(Game);

  Game := nil;
  Engine := nil;
end;

begin
  pp;
end.
