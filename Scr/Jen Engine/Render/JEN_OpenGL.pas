unit JEN_OpenGL;
{$I Jen_config.INC}

interface

uses
  XSystem,
  JEN_Render,
  JEN_Display;

type
  TGLRender = class( TRender )
      constructor  Create(Display : TDisplay; DepthBits : Byte = 24; StencilBits : Byte = 8 );
      destructor  Destroy;  override;
    private
      FOGL_Context  : HGLRC;
      FDisplay      : TDisplay;
      FValid        : Boolean;
      function GetValid : Boolean; override;
  end;

implementation

uses
  JEN_OpenGLHeader,
  JEN_Main;

constructor TGLRender.Create(Display : TDisplay; DepthBits : Byte; StencilBits : Byte );
var
  PFD      : TPixelFormatDescriptor;
begin
  inherited Create;
  FDisplay := Display;
  FValid := False;

  if not Assigned(Display) then
  begin
    LogOut('Cannot create OpenGL context, display is not correct', LM_ERROR);
    Exit;
  end;

  FillChar(PFD, SizeOf(PFD), 0);
  with PFD do
  begin
    nSize        := SizeOf(PFD);
    nVersion     := 1;
    dwFlags      := $25;
    cColorBits   := 32;
    cDepthBits   := DepthBits;
    cStencilBits := StencilBits;
  end;

  SetPixelFormat(Display.DC, ChoosePixelFormat(Display.DC, @PFD), @PFD);

  FOGL_Context := wglCreateContext(Display.DC);
  if (FOGL_Context = 0) Then
  begin
    LogOut('Cannot create OpenGL context.', LM_ERROR);
    exit;
  end else
    LogOut('Create OpenGL context.', LM_NOTIFY);

  if not wglMakeCurrent(Display.DC, FOGL_Context) Then
  begin
    LogOut('Cannot set current OpenGL context.', LM_ERROR);
    exit;
  end else
    LogOut('Make current OpenGL context.', LM_NOTIFY);
  FValid := True;
  LogOut('OpenGL version : ' + glGetString(GL_VERSION )+ ' (' + glGetString(GL_VENDOR) +')', LM_INFO);
  LogOut('Video device   : ' + glGetString(GL_RENDERER), LM_INFO);
end;

destructor TGLRender.Destroy;
begin
  if not wglDeleteContext( FOGL_Context ) Then
    LogOut( 'Cannot delete OpenGL context.', LM_ERROR )
  else
    LogOut( 'Delete OpenGL context.', LM_NOTIFY );
  inherited;
end;

function TGLRender.GetValid : Boolean;
begin
  result := FValid;
end;

end.
