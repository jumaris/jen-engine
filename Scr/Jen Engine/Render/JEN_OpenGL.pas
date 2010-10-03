unit JEN_OpenGL;
{$I Jen_config.INC}

interface

uses
  XSystem,
  JEN_Render,
  JEN_Window;

type
  TGLRender = class( TRender )
    private
      FOGL_Context  : HGLRC;
    public
      constructor Create( Window : TWindow; DepthBits : Byte = 24; StencilBits : Byte = 8 );
      destructor  Destroy;  override;
  end;

implementation

uses
  JEN_OpenGLHeader,
  JEN_Main;

constructor TGLRender.Create(Window: TWindow; DepthBits : Byte; StencilBits : Byte );
var
  PFD      : TPixelFormatDescriptor;
begin
  inherited Create;

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

  SetPixelFormat( Window.DC, ChoosePixelFormat( Window.DC, @PFD), @PFD);

  FOGL_Context := wglCreateContext( Window.DC );
  if ( FOGL_Context = 0 ) Then
    begin
      LogOut( 'Cannot create OpenGL context.', LM_ERROR );
      exit;
    end else
      LogOut( 'Create OpenGL context.', LM_NOTIFY );

  if not wglMakeCurrent( Window.DC, FOGL_Context ) Then
    begin
      LogOut( 'Cannot set current OpenGL context.', LM_ERROR );
      exit;
    end else
    LogOut( 'Make current OpenGL context.', LM_NOTIFY );
    {$IFDEF LOG}LogOut( 'OpenGL version : ' + glGetString( GL_VERSION )+ ' (' + glGetString( GL_VENDOR ) +')', LM_INFO ){$ENDIF};
    {$IFDEF LOG}LogOut( 'Video device   : ' + glGetString( GL_RENDERER ), LM_INFO ){$ENDIF};
end;

destructor  TGLRender.Destroy;
begin
  if not wglDeleteContext( FOGL_Context ) Then
    LogOut( 'Cannot delete OpenGL context.', LM_ERROR )
  else
    LogOut( 'Delete OpenGL context.', LM_NOTIFY );

  inherited;
end;

end.
