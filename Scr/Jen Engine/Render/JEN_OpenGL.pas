unit JEN_OpenGL;
{$I Jen_config.INC}

interface

uses
  XSystem,
  JEN_Render,
  JEN_Display,
  JEN_Math;

type
  TGLRender = class(TRender)
      constructor Create(Display: TDisplay; DepthBits: Byte = 24; StencilBits: Byte = 8; FSAA : Byte = 0);
      destructor Destroy;  override;
    private
      FGL_Context : HGLRC;
      FDisplay    : TDisplay;
      FViewport   : TRecti;

      FBlendType  : TBlendType;
      FAlphaTest  : Byte;
      FDepthTest  : Boolean;
      FDepthWrite : Boolean;
      FCullFace   : TCullFace;
      procedure SetViewport(Value: TRecti); override;
      function  GetViewport: TRecti; override;
      procedure SetBlendType(Value: TBlendType); override;
      procedure SetAlphaTest(Value: Byte); override;
      procedure SetDepthTest(Value: Boolean); override;
      procedure SetDepthWrite(Value: Boolean); override;
      procedure SetCullFace(Value: TCullFace); override;
    public

  end;

implementation

uses
  JEN_OpenGLHeader,
  JEN_Main;

constructor TGLRender.Create(Display: TDisplay; DepthBits: Byte; StencilBits: Byte; FSAA : Byte);
var
  PFD : TPixelFormatDescriptor;
  PFAttrf : array[0..1] of Single;
  PFAttri : array[0..19] of Integer;

  PFIdx    : LongInt;
  PFCount  : LongWord;

  PHandle : HWND;
  TDC : HDC;
  RC : HGLRC;
  Result : Boolean;
begin
  inherited Create;
  FDisplay := Display;
  FValid := False;

  if not (Assigned(Display) and Display.Valid) then
  begin
    LogOut('Cannot create OpenGL context, display is not correct', lmError);
    Exit;
  end;

  FillChar(PFD, SizeOf(PFD), 0);
  with PFD do
  begin
    nSize        := SizeOf(PFD);
    nVersion     := 1;
    dwFlags      := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
    cColorBits   := 32;
    cDepthBits   := DepthBits;
    cStencilBits := StencilBits;
  end;

  Result := False;
  if FSAA > 0 then
  begin
    PHandle := CreateWindowExW(0, 'Edit', nil, 0, 0, 0, 0, 0, 0, 0, 0, nil);
    Result := PHandle <> 0;
    TDC := GetDC(PHandle);
    Result := Result and SetPixelFormat(TDC, ChoosePixelFormat(TDC, @PFD), @PFD);
    RC := wglCreateContext(TDC);
    Result := Result and wglMakeCurrent(TDC, RC);
    wglChoosePixelFormatARB := glGetProc('wglChoosePixelFormatARB', Result);
    if @wglChoosePixelFormatARB <> nil then
    begin
      FillChar(PFAttrf[0], length(PFAttrf)*sizeof(Single), 0);
      PFAttri[0] := WGL_ACCELERATION_ARB;
      PFAttri[1] := WGL_FULL_ACCELERATION_ARB;
      PFAttri[2] := WGL_DRAW_TO_WINDOW_ARB;
      PFAttri[3] := GL_TRUE;
      PFAttri[4] := WGL_SUPPORT_OPENGL_ARB;
      PFAttri[5] := GL_TRUE;
      PFAttri[6] := WGL_DOUBLE_BUFFER_ARB;
      PFAttri[7] := GL_TRUE;
      PFAttri[8] := WGL_COLOR_BITS_ARB;
      PFAttri[9] := 32;
      PFAttri[10] := WGL_DEPTH_BITS_ARB;
      PFAttri[11] := DepthBits;
      PFAttri[12] := WGL_STENCIL_BITS_ARB;
      PFAttri[13] := StencilBits;
      PFAttri[14] := WGL_SAMPLE_BUFFERS_ARB;
      PFAttri[15] := GL_TRUE;
      PFAttri[16] := WGL_SAMPLES_ARB;
      PFAttri[17] := FSAA;
      PFAttri[18] := 0;
      PFAttri[19] := 0;
      Result := Result and wglChoosePixelFormatARB(TDC, @PFAttri, @PFAttrf, 1, @PFIdx, @PFCount);
      Result := Result and (PFCount<>0);
    end else
      Result := false;
    Result := Result and wglMakeCurrent(0, 0);
    Result := Result and wglDeleteContext(RC);
    Result := Result and ReleaseDC(PHandle, TDC);
    Result := Result and DestroyWindow(PHandle);

    if Result = false then
      LogOut('Cannot set FSAA', lmWarning);
  end;

  if Result then
    Result := SetPixelFormat(Display.DC, PFIdx, @PFD)
  else
    Result := SetPixelFormat(Display.DC, ChoosePixelFormat(Display.DC, @PFD), @PFD);

  if not Result then
  begin
    LogOut('Cannot set pixel format.', lmError);
    exit;
  end;

  FGL_Context := wglCreateContext(Display.DC);
  if(FGL_Context = 0)Then
  begin
    LogOut('Cannot create OpenGL context.', lmError);
    exit;
  end else
    LogOut('Create OpenGL context.', lmNotify);

  if not wglMakeCurrent(Display.DC, FGL_Context) Then
  begin
    LogOut('Cannot set current OpenGL context.', lmError);
    exit;
  end else
    LogOut('Make current OpenGL context.', lmNotify);

  FValid := LoadGLLibraly;

  LogOut('OpenGL version : ' + glGetString(GL_VERSION )+ ' (' + glGetString(GL_VENDOR) +')', lmInfo);
  LogOut('Video device   : ' + glGetString(GL_RENDERER), lmInfo);

  BlendType   := btNormal;
  AlphaTest   := 0;
  DepthTest   := true;
  DepthWrite  := true;
  CullFace    := cfBack;

  glDepthFunc ( GL_LEQUAL );
  glClearDepth( 1.0 );

  Display.Render := Self;
  Display.Restore;
  //glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glDisable(GL_TEXTURE_2D);

  glClearColor(0.0, 0.0, 0.0, 0.0);
  //glShadeModel(GL_SMOOTH);
  //glHint(GL_SHADE_MODEL,GL_NICEST);
  glDepthFunc(GL_LEQUAL);
  glClearDepth(1.0);

  //glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  glEnable(GL_TEXTURE_2D);
//  glEnable(GL_NORMALIZE);
// glEnable(GL_COLOR_MATERIAL);
end;

destructor TGLRender.Destroy;
begin
  if not wglDeleteContext(FGL_Context) Then
    LogOut('Cannot delete OpenGL context.', lmError)
  else
    LogOut('Delete OpenGL context.', lmNotify);
  inherited;
end;

procedure TGLRender.SetViewport(Value: TRecti);
begin
  FViewport := Value;
  glViewport(Value.Left, Value.Top, Value.Width, Value.Height);
end;

function TGLRender.GetViewport: TRecti;
begin
  Result := FViewport;
end;

procedure TGLRender.SetBlendType(Value: TBlendType);
begin
  if FBlendType <> Value then
  begin
    if FBlendType = btNone then
      glEnable(GL_BLEND);
    FBlendType := Value;
    case Value of
      btNormal : glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      btAdd    : glBlendFunc(GL_SRC_ALPHA, GL_ONE);
      btMult   : glBlendFunc(GL_ZERO, GL_SRC_COLOR);
    else
      glDisable(GL_BLEND);
    end;
  end;
end;

procedure TGLRender.SetAlphaTest(Value: Byte);
begin
  if FAlphaTest <> Value then
  begin
    FAlphaTest := Value;
    if Value > 0 then
    begin
      glEnable(GL_ALPHA_TEST);
      glAlphaFunc(GL_GREATER, Value / 255);
    end else
      glDisable(GL_ALPHA_TEST);
  end;
end;

procedure TGLRender.SetDepthTest(Value: Boolean);
begin
  if FDepthTest <> Value then
  begin
    FDepthTest := Value;
    if Value then
      glEnable(GL_DEPTH_TEST)
    else
      glDisable(GL_DEPTH_TEST);
  end;
end;

procedure TGLRender.SetDepthWrite(Value: Boolean);
begin
  if FDepthWrite <> Value then
  begin
    FDepthWrite := Value;
    glDepthMask(Value);
  end;
end;

procedure TGLRender.SetCullFace(Value: TCullFace);
begin
  if FCullFace <> Value then
  begin
    if FCullFace = cfNone then
      glEnable(GL_CULL_FACE);
    FCullFace := Value;
    case Value of
      cfFront : glCullFace(GL_FRONT);
      cfBack  : glCullFace(GL_BACK);
    else
      glDisable(GL_CULL_FACE);
    end;
  end;
end;


end.
