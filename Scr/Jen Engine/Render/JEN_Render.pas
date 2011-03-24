unit JEN_Render;

interface

uses
  XSystem,
  JEN_Header,
  JEN_Math;

type
  IRender = interface(JEN_Header.IRender)
    function GetValid : Boolean;
    property Valid : Boolean read GetValid;
  end;

  TRender = class(TInterfacedObject, IRender)
    procedure Init(DepthBits: Byte; StencilBits: Byte; FSAA: Byte); stdcall;
    constructor Create;
    destructor Destroy; override;
  private
      FValid : Boolean;
      FGL_Context: HGLRC;
      FViewport: TRecti;
      FBlendType: TBlendType;
      FAlphaTest: Byte;
      FDepthTest: Boolean;
      FDepthWrite: Boolean;
      FCullFace: TCullFace;
      FMatrix: array [TMatrixType] of TMat4f;
      FCameraPos : TVec3f;
    procedure SetViewport(Value: TRecti);
    procedure SetBlendType(Value: TBlendType); stdcall;
    procedure SetAlphaTest(Value: Byte); stdcall;
    procedure SetDepthTest(Value: Boolean); stdcall;
    procedure SetDepthWrite(Value: Boolean); stdcall;
    procedure SetCullFace(Value: TCullFace); stdcall;
    procedure SetMatrix(Idx: TMatrixType; Value: TMat4f); stdcall;

    function GetValid: Boolean;
    function GetMatrix(Idx: TMatrixType): TMat4f; stdcall;
  public
    procedure Clear(ColorBuff, DepthBuff, StensilBuff: Boolean); stdcall;

 {   procedure Quad(const Rect, TexRect: TRecti; Color: TColor; Angle: Single); overload; stdcall;
    procedure Quad(x1, y1, x2, y2, x3, y3, x4, y4, cx, cy: Single; Color: TColor; PtIdx: Word; Angle: Single); overload; stdcall;
    }
    property Valid: Boolean read FValid;
  end;

implementation

uses
  JEN_OpenGLHeader,
  JEN_Main;

procedure TRender.Init(DepthBits: Byte; StencilBits: Byte; FSAA: Byte);
var
  PFD: TPixelFormatDescriptor;
  PFAttrf: array [0 .. 1] of Single;
  PFAttri: array [0 .. 21] of LongInt;

  PFIdx: LongInt;
  PFCount: LongWord;

  PHandle: HWND;
  TDC: HDC;
  RC: HGLRC;
  Result: Boolean;
begin

  if not(Assigned(Display){ and Display.Valid}) then
  begin
    LogOut('Cannot create OpenGL context, display is not correct', lmError);
    Exit;
  end;

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

  LogOut('OpenGL version : ' + glGetString(GL_VERSION) + ' (' + glGetString(GL_VENDOR) + ')', lmInfo);
  LogOut('Video device   : ' + glGetString(GL_RENDERER), lmInfo);

  SetBlendType(btNormal);
  SetAlphaTest(0);
  SetDepthTest(False);
  SetDepthWrite(False);
  SetCullFace(cfBack);

  glDepthFunc(GL_LEQUAL);
  glClearDepth(1.0);

 // Display.Restore;
  // glPixelStorei(GL_UNPACK_ALIGNMENT, 1);


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

procedure TRender.SetMatrix(Idx: TMatrixType; Value: TMat4f); stdcall;
begin
  FMatrix[Idx] := Value;
end;

function TRender.GetValid: Boolean;
begin
  Result := FValid;
end;

function TRender.GetMatrix(Idx: TMatrixType): TMat4f; stdcall;
begin
  Result := FMatrix[Idx];
end;

procedure TRender.Clear(ColorBuff, DepthBuff, StensilBuff: Boolean);
begin
  glClear( (GL_COLOR_BUFFER_BIT * Ord(ColorBuff)) or
           (GL_DEPTH_BUFFER_BIT * Ord(DepthBuff)) or
           (GL_STENCIL_BUFFER_BIT * Ord(StensilBuff)) );
end;

                 {
procedure TRender.DrawQuad(const Texture: N4Header.TTexture; v1, v2, v3, v4: N4Header.TTexVec; cx, cy: Single; Color: N4Header.TColor; Angle, Scale: Single);
var
  s, c : Single;
  tx, ty : Single;
  qColor   : N4.TVec4f;
  qTexture : N4.TTexture;
begin
  with TRGBA(Color) do
    qColor := Math.Vec4f(B, G, R, A) * (1 / 255);

  if Texture.Texture <> nil then
    qTexture := TTexture(Texture.Texture)
  else
    qTexture := Render.WhiteTex;

  Render.CheckBatch(qTexture, qColor);
  Render.SimpleMat.ColorParam.Diffuse := qColor;
  Render.SimpleMat.DiffuseMap := qTexture;
  if Render.SimpleMat.Blending = 3 then
    Render.SimpleMat.ColorParam.Ambient.x := 0
  else
    Render.SimpleMat.ColorParam.Ambient.x := 1;

  Render.SimpleMat.Enable;
  Math.SinCos(Angle * Math.deg2rad, s, c);

  tx := 0.5 / Texture.Width;
  ty := 0.5 / Texture.Height;

  v1.x := v1.x - cx;
  v1.y := v1.y - cy;
  v2.x := v2.x - cx;
  v2.y := v2.y - cy;
  v3.x := v3.x - cx;
  v3.y := v3.y - cy;
  v4.x := v4.x - cx;
  v4.y := v4.y - cy;

  with Math do
    Render.Quad(Vec4f(cx + (v1.x * c - v1.y * s) * Scale, cy + (v1.x * s + v1.y * c) * Scale, v1.s + tx, v1.t + ty),
                Vec4f(cx + (v2.x * c - v2.y * s) * Scale, cy + (v2.x * s + v2.y * c) * Scale, v2.s + tx, v2.t + ty),
                Vec4f(cx + (v3.x * c - v3.y * s) * Scale, cy + (v3.x * s + v3.y * c) * Scale, v3.s + tx, v3.t + ty),
                Vec4f(cx + (v4.x * c - v4.y * s) * Scale, cy + (v4.x * s + v4.y * c) * Scale, v4.s + tx, v4.t + ty));
//  Render.FlushBatch;
end;             }
                 {
procedure TRender.DrawQuad(v1, v2, v3, v4: N4Header.TTexVec; cx, cy: Single; Color: N4Header.TColor; Angle, Scale: Single);
var
  s, c : Single;
  tx, ty : Single;
  qColor   : N4.TVec4f;
  qTexture : N4.TTexture;
begin
  with TRGBA(Color) do
    qColor := Math.Vec4f(B, G, R, A) * (1 / 255);

  Math.SinCos(Angle * Math.deg2rad, s, c);

  tx := 0.5 / Texture.Width;
  ty := 0.5 / Texture.Height;

  v1.x := v1.x - cx;
  v1.y := v1.y - cy;
  v2.x := v2.x - cx;
  v2.y := v2.y - cy;
  v3.x := v3.x - cx;
  v3.y := v3.y - cy;
  v4.x := v4.x - cx;
  v4.y := v4.y - cy;

  with Math do
    Render.Quad(Vec4f(cx + (v1.x * c - v1.y * s) * Scale, cy + (v1.x * s + v1.y * c) * Scale, v1.s + tx, v1.t + ty),
                Vec4f(cx + (v2.x * c - v2.y * s) * Scale, cy + (v2.x * s + v2.y * c) * Scale, v2.s + tx, v2.t + ty),
                Vec4f(cx + (v3.x * c - v3.y * s) * Scale, cy + (v3.x * s + v3.y * c) * Scale, v3.s + tx, v3.t + ty),
                Vec4f(cx + (v4.x * c - v4.y * s) * Scale, cy + (v4.x * s + v4.y * c) * Scale, v4.s + tx, v4.t + ty));

end;


procedure TRender.Quad(const v1, v2, v3, v4: TTexVec; Color: TColor; Angle: Single);
begin
  DrawQuad(v1, v2, v3, v4, 0, 0, Color, Angle);
end;

procedure TRender.Quad(const Rect, TexRect: TRecti; Color: TColor; Angle: Single);
begin
  Quad(TexVec(Rect.Left, Rect.Top, TexRect.Left, TexRect.Top),
       TexVec(Rect.Right, Rect.Top, TexRect.Right, TexRect.Top),
       TexVec(Rect.Right, Rect.Bottom, TexRect.Right, TexRect.Bottom),
       TexVec(Rect.Left, Rect.Bottom, TexRect.Left, TexRect.Bottom), Color, Angle);
end;

procedure TRender.Quad(x1, y1, x2, y2, x3, y3, x4, y4, cx, cy: Single; Color: TColor; PtIdx: Word; Angle: Single);
var
  s, t, ss, ts : Single;
begin
  ss := Texture.PatternWidth / Texture.Width;
  ts := Texture.PatternHeight / Texture.Height;
  s := PtIdx mod (Texture.Width div Texture.PatternWidth) * ss;
  t := PtIdx div (Texture.Height div Texture.PatternHeight) * ts;
  ss := ss + s;
  ts := ts + t;

  DrawQuad(Texture,
           TexVec(x1, y1, s, t),
           TexVec(x2, y2, ss, t),
           TexVec(x3, y3, ss, ts),
           TexVec(x4, y4, s, ts), cx, cy, Color, Angle, Scale);
end;
                                                                     }

end.
