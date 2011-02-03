unit SomeGame;

interface

uses
  JEN_MAIN,
  xsystem,
  JEN_OPENGLHEADER;

type
  TSameGame = class(TGame)
  private
    procedure LoadContent; override;
    procedure OnUpdate( Dt : Double ); override;
    procedure OnRender; override;
  public
    constructor Create;
  end;

implementation

var r : TTexture;

constructor TSameGame.Create;
begin
  inherited;
  Display := TDisplayWindow.Create(1024, 768, 60, true);
  TGLRender.Create(24, 8, 0);
  TResourceManager.Create;
  r := ResMan.Load('Media\asd.dds');
 // Display.VSync := false;
{ Display.FullScreen := true;
  Display.FullScreen := false;
  Display.resize(800, 600);
  Display.ShowCursor(False);
  Display.ShowCursor(True);
  Display.Caption := 'lol бардак'; }

  glClearColor(1,1,0,1);
end;

procedure TSameGame.LoadContent;
begin

end;

procedure TSameGame.OnUpdate(Dt: Double);
begin
 // Display.Caption := 'FPS:' + Utils.IntToStr(Display.FPS);
end;

procedure TSameGame.OnRender;
begin
  glClear( GL_COLOR_BUFFER_BIT);

//  Render.Matrix[mtProj].Identity;
  Render.Matrix[mtProj].Ortho(0,800,0,600,-1,1);
 // Render.Matrix[mtModel].Identity;


  glMatrixMode(GL_PROJECTION);
 // glLoadIdentity;
  glLoadMatrixf(@Render.Matrix[mtProj]);
 // glOrtho(0, 800, 0, 100, -1, 1);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  glenable(GL_TEXTURE_2D);
  glenable(GL_TEXTURE0);
//  glbindtexture(GL_TEXTURE_2D,r.FID);
  glbegin(GL_TRIANGLES);

  gltexcoord2f(0,0);
  glvertex3f(0,0,0);
  gltexcoord2f(1,0);
  glvertex3f(150,0,0);
  gltexcoord2f(0,1);
  glvertex3f(0,100,0);
  glend;

end;

end.
