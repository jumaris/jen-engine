unit SomeGame;

interface
    {
uses
  JEN_Header;//,
 { xsystem;
                  }   {
type
  TSomeGame = class(TInterfacedObject, IGame)
    constructor Create;
  private
    procedure LoadContent; stdcall;
    procedure OnUpdate(Dt: Double); stdcall;
    procedure OnRender; stdcall;
  end;

var
  Game : TSomeGame;     }

implementation
      {
var
  r : ITexture;
  s : IShader;
         }      {
constructor TSomeGame.Create;
begin
  inherited;       {
  Display := TDisplayWindow.Create(1024, 768, 60, False);
  Render := TGLRender.Create(24, 8, 8);
  ResMan := TResourceManager.Create;

                  }
 // Display.VSync := False;
{ Display.FullScreen := True;
  Display.FullScreen := False;
  Display.resize(800, 600);
  Display.ShowCursor(False);
  Display.ShowCursor(True);
  Display.Caption := 'lol бардак'; }

 // glClearColor(1,1,0,1);
{end;

procedure TSomeGame.LoadContent;
begin              {
  ResMan.Load('Media\asd.dds', r);
  ResMan.Load('Media\Shader.xml', s);
  s.Compile;  }
{end;

procedure TSomeGame.OnUpdate(Dt: Double);
begin
 // Display.Caption := 'FPS:' + Utils.IntToStr(Display.FPS);
end;

procedure TSomeGame.OnRender;
begin         {
  glClear( GL_COLOR_BUFFER_BIT);

   glviewport(0,0,1024,768);
//  Render.Matrix[mtProj].Identity;
 // Render.Matrix[mtProj].Ortho(0,800,600,00,-1,1);
 // Render.Matrix[mtModel].Identity;


  glMatrixMode(GL_PROJECTION);
 // glLoadIdentity;
//  glLoadMatrixf(@Render.Matrix[mtProj]);
  //glOrtho(0,1,0,1,0,1);// (0,800,
 // glOrtho(0, 800, 0, 100, -1, 1);
 // glOrtho( 0, 800, 0, 600, -1, 1 );
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  glenable(GL_TEXTURE_2D);
//  r.Bind;
  glbegin(GL_TRIANGLES);

      gltexcoord2f(0,1);
  glvertex3f(0,100,0);

    gltexcoord2f(1,0);
  glvertex3f(150,0,0);


  gltexcoord2f(0,0);
  glvertex3f(0,0,0);








  glend;
           }
{end;       }

end.
