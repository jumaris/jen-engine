unit JEN_Render;

interface

uses
  XSystem,
  JEN_Header,
  JEN_Math;

type
  TRender = class(TInterfacedObject, IJenSubSystem, IRender)
    procedure Init(DepthBits: Byte; StencilBits: Byte; FSAA: Byte); stdcall;
    constructor Create;
    destructor Destroy; override;
  private
    var
      FValid : Boolean;
      FGL_Context: HGLRC;
      FViewport: TRecti;
      FBlendType: TBlendType;
      FAlphaTest: Byte;
      FDepthTest: Boolean;
      FDepthWrite: Boolean;
      FCullFace: TCullFace;
    procedure SetViewport(Value: TRecti);
    procedure SetBlendType(Value: TBlendType); stdcall;
    procedure SetAlphaTest(Value: Byte); stdcall;
    procedure SetDepthTest(Value: Boolean); stdcall;
    procedure SetDepthWrite(Value: Boolean); stdcall;
    procedure SetCullFace(Value: TCullFace); stdcall;
  public
    var
      Matrix    : array [TMatrixType] of TMat4f;
      CameraPos : TVec3f;

    property Valid: Boolean read FValid;
    property BlendType: TBlendType write SetBlendType;
    property AlphaTest: Byte write SetAlphaTest;
    property DepthTest: Boolean write SetDepthTest;
    property DepthWrite: Boolean write SetDepthWrite;
    property CullFace: TCullFace write SetCullFace;
    property Viewport: TRecti read FViewport write SetViewport;
  end;

implementation

uses
  JEN_OpenGLHeader,
  JEN_Main;

procedure TRender.Init(DepthBits: Byte; StencilBits: Byte; FSAA: Byte);
var
  PFD: TPixelFormatDescriptor;
  PFAttrf: array [0 .. 1] of Single;
  PFAttri: array [0 .. 21] of Integer;

  PFIdx: LongInt;
  PFCount: LongWord;

  PHandle: HWND;
  TDC: HDC;
  RC: HGLRC;
  Result: Boolean;
begin
                           {
  if not(Assigned(Display) and Display.Valid) then
  begin
    LogOut('Cannot create OpenGL context, display is not correct', lmError);
    Exit;
  end;
                           }
  FillChar(PFD, SizeOf(PFD), 0);
  with PFD do
  begin
    nSize := SizeOf(PFD);
    nVersion := 1;
    dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
    cColorBits := 24;
    cAlphaBits := 8;
    cDepthBits := DepthBits;
    cStencilBits := StencilBits;
  end;

   Result := False;
  if FSAA > 0 then
  begin
    PHandle := CreateWindowExW(0, 'Edit', nil, 0, 0, 0, 0, 0, 0, 0, 0, nil);
    Result := PHandle <> 0;
    TDC := GetDC(PHandle);
    Result := Result and SetPixelFormat
      (TDC, ChoosePixelFormat(TDC, @PFD), @PFD);
    RC := wglCreateContext(TDC);
    Result := Result and wglMakeCurrent(TDC, RC);
    wglChoosePixelFormatARB := glGetProc('wglChoosePixelFormatARB', Result);
    if @wglChoosePixelFormatARB <> nil then
    begin
      FillChar(PFAttrf[0], length(PFAttrf) * SizeOf(Single), 0);
      PFAttri[0] := WGL_ACCELERATION_ARB;
      PFAttri[1] := WGL_FULL_ACCELERATION_ARB;
      PFAttri[2] := WGL_DRAW_TO_WINDOW_ARB;
      PFAttri[3] := GL_TRUE;
      PFAttri[4] := WGL_SUPPORT_OPENGL_ARB;
      PFAttri[5] := GL_TRUE;
      PFAttri[6] := WGL_DOUBLE_BUFFER_ARB;
      PFAttri[7] := GL_TRUE;
      PFAttri[8] := WGL_COLOR_BITS_ARB;
      PFAttri[9] := 24;
      PFAttri[10] := WGL_ALPHA_BITS_ARB;
      PFAttri[11] := 8;
      PFAttri[12] := WGL_DEPTH_BITS_ARB;
      PFAttri[13] := DepthBits;
      PFAttri[14] := WGL_STENCIL_BITS_ARB;
      PFAttri[15] := StencilBits;
      PFAttri[16] := WGL_SAMPLE_BUFFERS_ARB;
      PFAttri[17] := GL_TRUE;
      PFAttri[18] := WGL_SAMPLES_ARB;
      PFAttri[19] := FSAA;
      PFAttri[20] := 0;
      PFAttri[21] := 0;
      Result := Result and wglChoosePixelFormatARB
        (TDC, @PFAttri, @PFAttrf, 1, @PFIdx, @PFCount);
      Result := Result and (PFCount <> 0);
    end
    else
      Result := False;
    Result := Result and wglMakeCurrent(0, 0);
    Result := Result and wglDeleteContext(RC);
    Result := Result and ReleaseDC(PHandle, TDC);
    Result := Result and DestroyWindow(PHandle);

    if Result = False then
      LogOut('Cannot set FSAA', lmWarning);
  end;

  if Result then
    Result := SetPixelFormat(Display.DC, PFIdx, @PFD)
  else
    Result := SetPixelFormat(Display.DC, ChoosePixelFormat(Display.DC, @PFD),
      @PFD);

  if not Result then
  begin
    LogOut('Cannot set pixel format.', lmError);
    Exit;
  end;

  FGL_Context := wglCreateContext(Display.DC);
  if (FGL_Context = 0) Then
  begin
    LogOut('Cannot create OpenGL context.', lmError);
    Exit;
  end
  else
    LogOut('Create OpenGL context.', lmNotify);

  if not wglMakeCurrent(Display.DC, FGL_Context) Then
  begin
    LogOut('Cannot set current OpenGL context.', lmError);
    Exit;
  end
  else
    LogOut('Make current OpenGL context.', lmNotify);

  FValid := LoadGLLibraly;
  if not FValid Then
  begin
    LogOut('Error when load extensions.', lmError);
    Exit;
  end;

  LogOut('OpenGL version : ' + glGetString(GL_VERSION) + ' (' + glGetString
      (GL_VENDOR) + ')', lmInfo);
  LogOut('Video device   : ' + glGetString(GL_RENDERER), lmInfo);

  BlendType := btNormal;
  AlphaTest := 0;
  DepthTest := False;
  DepthWrite := False;
  CullFace := cfBack;

  glDepthFunc(GL_LEQUAL);
  glClearDepth(1.0);

 // Display.Restore;
  // glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glDisable(GL_TEXTURE_2D);

  glClearColor(1.0, 0.0, 0.0, 0.0);
  // glShadeModel(GL_SMOOTH);
  // glHint(GL_SHADE_MODEL,GL_NICEST);

  // glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  // glEnable(GL_TEXTURE_2D);
  // glEnable(GL_NORMALIZE);
  // glEnable(GL_COLOR_MATERIAL);
end;

constructor TRender.Create;
begin
  inherited;
  FValid := False;
end;

destructor TRender.Destroy;
begin
  if not wglDeleteContext(FGL_Context) Then
    LogOut('Cannot delete OpenGL context.', lmError)
  else
    LogOut('Delete OpenGL context.', lmNotify);
  inherited;
end;

procedure TRender.SetViewport(Value: TRecti);
begin
  FViewport := Value;
  glViewport(Value.Left, Value.Top, Value.Width, Value.Height);
end;

procedure TRender.SetBlendType(Value: TBlendType);
begin
  if FBlendType <> Value then
  begin
    if FBlendType = btNone then
      glEnable(GL_BLEND);
    FBlendType := Value;
    case Value of
      btNormal:
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      btAdd:
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);
      btMult:
        glBlendFunc(GL_ZERO, GL_SRC_COLOR);
    else
      glDisable(GL_BLEND);
    end;
  end;
end;

procedure TRender.SetAlphaTest(Value: Byte);
begin
  if FAlphaTest <> Value then
  begin
    FAlphaTest := Value;
    if Value > 0 then
    begin
      glEnable(GL_ALPHA_TEST);
      glAlphaFunc(GL_GREATER, Value / 255);
    end
    else
      glDisable(GL_ALPHA_TEST);
  end;
end;

procedure TRender.SetDepthTest(Value: Boolean);
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

procedure TRender.SetDepthWrite(Value: Boolean);
begin
  if FDepthWrite <> Value then
  begin
    FDepthWrite := Value;
    glDepthMask(Value);
  end;
end;

procedure TRender.SetCullFace(Value: TCullFace);
begin
  if FCullFace <> Value then
  begin
    if FCullFace = cfNone then
      glEnable(GL_CULL_FACE);
    FCullFace := Value;
    case Value of
      cfFront:
        glCullFace(GL_FRONT);
      cfBack:
        glCullFace(GL_BACK);
    else
      glDisable(GL_CULL_FACE);
    end;
  end;
end;

end.
