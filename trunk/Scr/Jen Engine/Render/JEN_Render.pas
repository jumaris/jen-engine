unit JEN_Render;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Windows,
  SysUtils,
  JEN_Header,
  JEN_OpenGLHeader,
  JEN_Helpers,
  JEN_Math;

const
  CompareFunc: array[TCompareMode] of GLenum = (GL_ZERO, GL_EQUAL, GL_GEQUAL, GL_LESS, GL_GREATER, GL_EQUAL, GL_NOTEQUAL, GL_ALWAYS, GL_NEVER);
  ScencilOp: array[TScencilOp] of GLenum = (GL_KEEP, GL_ZERO, GL_REPLACE, GL_INCR, GL_DECR, GL_INCR_WRAP, GL_DECR_WRAP, GL_INVERT);

  // (btNone, btNormal, btAdd, btMult, btOne, btNoOverride, btAddAlpha);
  BlendParams: array[TBlendType] of record
    Scr, Dest : GLenum;
  end = (
          (Scr: GL_ZERO; Dest: GL_ZERO),
          (Scr: GL_SRC_ALPHA; Dest: GL_ONE_MINUS_SRC_ALPHA),
          (Scr: GL_SRC_ALPHA; Dest: GL_ONE),
          (Scr: GL_ZERO; Dest: GL_SRC_COLOR),
          (Scr: GL_ONE;  Dest: GL_ZERO),
          (Scr: GL_ONE;  Dest: GL_ONE_MINUS_SRC_ALPHA)
        );
        {
      if Value <> btNone then
      glEnable(GL_BLEND);
    case Value of
      btNormal:
        glBlendFunc(, GL_ONE_MINUS_SRC_ALPHA);
      btAdd:
        glBlendFunc(, );
      btMult:
        glBlendFunc(GL_ZERO, GL_SRC_COLOR);
    else
      glDisable(GL_BLEND);
    end;   }
type
  IRender = interface(JEN_Header.IRender)
    function GetValid : Boolean;
    procedure Start;
    procedure Finish;
    procedure CheckGAPIErrors;
    property Valid : Boolean read GetValid;
  end;

  TRender = class(TInterfacedObject, IRender)
    procedure Init(DepthBits: Byte; StencilBits: Byte; FSAA: Byte); stdcall;
    procedure Free; stdcall;
  private
    FValid      : Boolean;
    FGL_Context : HGLRC;
    FViewport   : TRecti;
    FVSync      : Boolean;

    SBuffer     : array[TRenderSupport] of Boolean;

    FTarget     : IRenderTarget;
    FColorMask  : Byte;
    FBlendRGB   : TBlendType;
    FBlendA     : TBlendType;
    FAlphaTest  : Byte;
    FDepthTest  : Boolean;
    FStencilTest: Boolean;
    FDepthWrite : Boolean;
    FCullFace   : TCullFace;

    FFPS        : LongInt;
    FFPSTime    : LongInt;
    FFPSCount   : LongInt;
    FFrameTime  : LongInt;
    FFrameStart : LongInt;
    FDipCount   : LongWord;
    FLastDipCount : LongWord;

    FMatrix     : array [TMatrixType] of TMat4f;
    FCameraPos  : TVec3f;
    FCameraDir  : TVec3f;
    function GetValid: Boolean;
  public
    function CreateRenderTarget(Width, Height: LongWord; CFormat: TTextureFormat; Count: LongWord; Samples: LongWord; DepthBuffer: Boolean; DFormat: TTextureFormat): JEN_Header.IRenderTarget; stdcall;
    function GetTarget: IRenderTarget; stdcall;
    procedure SetTarget(Value: IRenderTarget); stdcall;

    procedure Clear(ColorBuff, DepthBuff, StensilBuff: Boolean); stdcall;
    function GetViewport: TRecti; stdcall;
    procedure SetViewport(const Value: TRecti); stdcall;
   // procedure SetArrayState(Vertex, TextureCoord, Normal, Color : Boolean); stdcall;
    function Support(RenderSupport: TRenderSupport): Boolean;

    function GetVSync: Boolean; stdcall;
    procedure SetVSync(Value: Boolean); stdcall;
    procedure SetClearColor(const Color: TVec4f); stdcall;
    function GetColorMask(Channel : TColorChannel): Boolean; overload; stdcall;
    procedure SetColorMask(Channel : TColorChannel; Value : Boolean); overload; stdcall;
    function GetColorMask: Byte; overload; stdcall;
    procedure SetColorMask(Red, Green, Blue, Alpha: Boolean); overload; stdcall;
    function GetBlendRGB: TBlendType; stdcall;
    function GetBlendA: TBlendType; stdcall;
    procedure SetBlend(Value: TBlendType); overload; stdcall;
    procedure SetBlend(ValueRGB, ValueA: TBlendType); overload; stdcall;
    function GetAlphaTest: Byte; stdcall;
    procedure SetAlphaTest(Value: Byte); stdcall;
    function GetDepthTest: Boolean; stdcall;
    procedure SetDepthTest(Value: Boolean); stdcall;
    function GetStencilTest: Boolean; stdcall;
    procedure SetStencilTest(Value: Boolean); stdcall;
    procedure SetStencilFunc(CompMode: TCompareMode; Value: LongInt; Mask: LongWord); stdcall;
    procedure SetStencilOp(Fail, ZFail, Pass: TScencilOp); stdcall;
    function GetDepthWrite: Boolean; stdcall;
    procedure SetDepthWrite(Value: Boolean); stdcall;
    procedure SetDepthOffset(Factor: Single; Units: Single); stdcall;
    function GetCullFace: TCullFace; stdcall;
    procedure SetCullFace(Value: TCullFace); stdcall;

    function GetFPS: LongWord; stdcall;
    function GetFrameTime: LongWord; stdcall;
    function GetFrameDipCount: LongWord; stdcall;
    function GetDipCount: LongWord; stdcall;
    procedure SetDipCount(Value : LongWord); stdcall;
    procedure IncDip; stdcall;

    function  GetMatrix(Idx: TMatrixType): TMat4f; stdcall;
    procedure SetMatrix(Idx: TMatrixType; const Value: TMat4f); stdcall;
    function  GetCameraPos: TVec3f; stdcall;
    procedure SetCameraPos(Value: TVec3f); stdcall;
    function  GetCameraDir: TVec3f; stdcall;
    procedure SetCameraDir(Value: TVec3f); stdcall;

    procedure CheckGAPIErrors;

    procedure Start;
    procedure Finish;
  end;

implementation

uses
  JEN_Main,
  JEN_RenderTarget;

procedure TRender.Free;
begin
  Engine.Log('Delete OpenGL context.');
  if not wglDeleteContext(FGL_Context) Then
    Engine.Error('Cannot delete OpenGL context.')
end;

procedure TRender.Init(DepthBits: Byte; StencilBits: Byte; FSAA: Byte);
var
  PFD     : TPixelFormatDescriptor;
  PFAttrf : array [0 .. 1] of Single;
  PFAttri : array [0 .. 21] of LongInt;

  PFIdx   : LongInt;
  PFCount : LongWord;

  Par     : Integer;
  PHandle : HWND;
  TDC     : HDC;
  RC      : HGLRC;
  Result  : Boolean;

//  FID     : LongWord;
begin
  FValid := False;
  Result := False;
  Set8087CW($133F);

  if not (Assigned(Display) and Display.Valid) then
  begin
    Engine.Error('Cannot create OpenGL context, display is not correct');
    Exit;
  end;

  FillChar(PFD, SizeOf(TPixelFormatDescriptor), 0);
  with PFD do
  begin
    nSize := SizeOf(TPixelFormatDescriptor);
    nVersion := 1;
    dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
    cColorBits := 24;
    cAlphaBits := 8;
    cDepthBits := DepthBits;
    cStencilBits := StencilBits;
  end;

  if FSAA > 0 then
  begin
    PHandle := CreateWindowEx(0, 'Edit', nil, 0, 0, 0, 0, 0, 0, 0, 0, nil);
    TDC := GetDC(PHandle);
    Result := (PHandle <> 0) and SetPixelFormat
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
    Result := Result and (ReleaseDC(PHandle, TDC)=0);
    Result := Result and DestroyWindow(PHandle);

    if Result = False then
      Engine.Warning('Cannot set FSAA');
  end;

  Engine.Log('Set pixel format.');

  if Result then
    Result := SetPixelFormat(Display.DC, PFIdx, @PFD)
  else
    Result := SetPixelFormat(Display.DC, ChoosePixelFormat(Display.DC, @PFD), @PFD);

  if not Result then
  begin
    Engine.Error('Cannot set pixel format.');
    Exit;
  end;

  Engine.Log('Create OpenGL context.');
  FGL_Context := wglCreateContext(Display.DC);
  if (FGL_Context = 0) Then
  begin
    Engine.Error('Cannot create OpenGL context.');
    Exit;
  end;

  Engine.Log('Make current OpenGL context.');
  if not wglMakeCurrent(Display.DC, FGL_Context) Then
  begin
    Engine.Error('Cannot set current OpenGL context.');
    Exit;
  end;

  ReadGlExt;
  glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS ,@Par);

  SBuffer[rsWGLEXTswapcontrol] := glIsSupported('WGL_EXT_swap_control');
  if not LoadGLLibraly Then
  begin
    Engine.Error('Error when load extensions.');
    Exit;
  end;

  Engine.Log('OpenGL version : ' + glGetString(GL_VERSION) + ' (' + glGetString(GL_VENDOR) + ')');
  Engine.Log('Video device   : ' + glGetString(GL_RENDERER));
  Engine.Log('Texture units  : ' + IntToStr(Par));

  FMatrix[mt2DMat].Ortho(0, Display.Width, Display.Height, 0, -1, 1);
  FMatrix[mtViewProj].Identity;
  FMatrix[mtModel].Identity;
  FMatrix[mtProj].Identity;
  FMatrix[mtView].Identity;

  SetColorMask(True, True, True, True);
  SetBlend(btNormal);
  SetAlphaTest(0);
  SetDepthTest(False);
  SetDepthWrite(False);
  SetCullFace(cfBack);

  glDepthFunc(GL_LEQUAL);
  glClearDepth(1);
  SetClearColor(Vec4f(0, 0, 0, 0));
  SetVSync(false);
  SetViewport(Recti(0, 0, Display.Width, Display.Height));

  //glTexEnvf(GL_TEXTURE_FILTER_CONTROL, GL_TEXTURE_LOD_BIAS,-2.0);
   // Display.Restore;
  // glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  // glShadeModel(GL_SMOOTH);

  // glHint(GL_SHADE_MODEL,GL_NICEST);

  // glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  // glEnable(GL_TEXTURE_2D);
  // glEnable(GL_NORMALIZE);
  // glEnable(GL_COLOR_MATERIAL);
  CheckGAPIErrors;
  Render2d.Init;
  Render2d.UpdateRC;
  CheckGAPIErrors;
  FValid := True;
end;

function TRender.CreateRenderTarget(Width, Height: LongWord; CFormat: TTextureFormat; Count: LongWord; Samples: LongWord; DepthBuffer: Boolean; DFormat: TTextureFormat): JEN_Header.IRenderTarget;
begin
  Result := TRenderTarget.Create(Width, Height, CFormat, Count, Samples, DepthBuffer, DFormat);
end;

function TRender.GetTarget: IRenderTarget;
begin
  Result := FTarget;
end;

procedure TRender.SetTarget(Value: IRenderTarget);
const
  ChannelList  : array [0..Ord(High(TRenderChannel)) - 1] of GLenum = (GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT0 + 1, GL_COLOR_ATTACHMENT0 + 2, GL_COLOR_ATTACHMENT0 + 3, GL_COLOR_ATTACHMENT0 + 4, GL_COLOR_ATTACHMENT0 + 5, GL_COLOR_ATTACHMENT0 + 6, GL_COLOR_ATTACHMENT0 + 7);
begin
  if FTarget = Value then
    Exit;
  Engine.DispatchEvent(evRenderFlush);

  FTarget := Value;
  if Value <> nil then
  begin
    glBindFramebuffer(GL_FRAMEBUFFER, Value.ID);
    if Value.ColChanCount = 0 then
    begin
      glDrawBuffer(GL_NONE);
      glReadBuffer(GL_NONE);
    end else
    begin
      glDrawBuffer(GL_BACK);
      glReadBuffer(GL_BACK);
    end;
    glDrawBuffers(Value.ColChanCount, @ChannelList[0]);
  end else
  begin
    SetViewport(Recti(0, 0, Display.Width, Display.Height));
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
  end;
end;

function TRender.GetValid: Boolean;
begin
  Result := FValid;
end;

procedure TRender.Clear(ColorBuff, DepthBuff, StensilBuff: Boolean);
begin
  glClear( (GL_COLOR_BUFFER_BIT * Ord(ColorBuff)) or
           (GL_DEPTH_BUFFER_BIT * Ord(DepthBuff)) or
           (GL_STENCIL_BUFFER_BIT * Ord(StensilBuff)) );
end;

function TRender.GetViewport: TRecti;
begin
  Result := FViewport;
end;

procedure TRender.SetViewport(const Value: TRecti);
begin
  if not (FViewport = Value) then
  begin
    FViewport := Value;
    glViewport(Value.Left, Value.Top, Value.Width, Value.Height);
  end;
end;
             {
procedure TRender.SetArrayState(Vertex, TextureCoord, Normal, Color : Boolean);

  procedure SetState(State : GLenum; Value : Boolean);
  begin
    if Value then
      glEnableClientState(State)
    else
      glDisableClientState(State);
  end;

begin
  if(FArrayState.Vertex <> Vertex) then
    SetState(GL_VERTEX_ARRAY, Vertex);

  if(FArrayState.TextureCoord <> TextureCoord) then
    SetState(GL_TEXTURE_COORD_ARRAY, TextureCoord);

  if(FArrayState.Normal <> Normal) then
    SetState(GL_NORMAL_ARRAY, Normal);

  if(FArrayState.Color <> Color) then
    SetState(GL_COLOR_ARRAY, Color);

  FArrayState.Vertex := Vertex;
  FArrayState.TextureCoord := TextureCoord;
  FArrayState.Normal := Normal;
  FArrayState.Color := Color;
end;        }

function TRender.Support(RenderSupport: TRenderSupport): Boolean;
begin
  Result := SBuffer[RenderSupport];
end;

function TRender.GetVSync: Boolean;
begin
  Result := FVSync;
end;

procedure TRender.SetVSync(Value: Boolean);
begin
  FVSync := Value;
  if Support(rsWGLEXTswapcontrol) then
  if Display.FullScreen then
    wglSwapIntervalEXT(Ord(FVSync))
  else
    wglSwapIntervalEXT(0);
end;

procedure TRender.SetClearColor(const Color: TVec4f);
begin
  glClearColor(Color.x, Color.y, Color.z, Color.w);
end;

function TRender.GetColorMask(Channel : TColorChannel): Boolean;
begin
  Result := FColorMask and (1 shl (ord(Channel)+1))<> 0;
end;

procedure TRender.SetColorMask(Channel : TColorChannel; Value : Boolean);
var
  Mask: Byte;
begin
  Mask := FColorMask or 1 shl (ord(Channel)+1);
  if not Value then
    Mask := Mask xor 1 shl (ord(Channel)+1);

  if Mask <> FColorMask then
  begin
    FColorMask := Mask;
    glColorMask(FColorMask and $01 <> 0, FColorMask and $02 <> 0, FColorMask and $04 <> 0, FColorMask and $08 <> 0);
  end;
end;

function TRender.GetColorMask: Byte;
begin
  Result := FColorMask;
end;

procedure TRender.SetColorMask(Red, Green, Blue, Alpha: Boolean);
var
  Mask: Byte;
begin
  Mask := Byte(Red) + Byte(Green) shl 1 + Byte(Blue) shl 2 + Byte(Alpha) shl 3;

  if Mask <> FColorMask then
  begin
    FColorMask := Mask;
    glColorMask(Red, Green, Blue, Alpha);
  end;
end;

function TRender.GetBlendRGB: TBlendType;
begin
  Result := FBlendRGB;
end;

function TRender.GetBlendA: TBlendType;
begin
  Result := FBlendA;
end;

procedure TRender.SetBlend(Value: TBlendType);
begin
  if (FBlendRGB <> Value) or (FBlendA <> Value) then
  begin
    FBlendRGB := Value;
    FBlendA   := Value;

    if Value <> btNone then
    begin
      glEnable(GL_BLEND);
      glBlendFunc(BlendParams[Value].Scr, BlendParams[Value].Dest);
    end else
      glDisable(GL_BLEND);
  end;
end;

procedure TRender.SetBlend(ValueRGB, ValueA: TBlendType);
begin
  if (FBlendRGB <> ValueRGB) or (FBlendA <> ValueA) then
  begin
    FBlendRGB := ValueRGB;
    FBlendA   := ValueA;

    if ValueRGB <> btNone then
    begin
      glEnable(GL_BLEND);
      glBlendFuncSeparate(BlendParams[ValueRGB].Scr, BlendParams[ValueRGB].Dest, BlendParams[ValueA].Scr, BlendParams[ValueA].Dest);
    end else
      glDisable(GL_BLEND);
  end;
end;

function TRender.GetAlphaTest: Byte;
begin
  Result := FAlphaTest;
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

function TRender.GetDepthTest: Boolean;
begin
  Result := FDepthTest;
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

function TRender.GetStencilTest: Boolean; stdcall;
begin
  Result := FStencilTest;
end;

procedure TRender.SetStencilTest(Value: Boolean); stdcall;
begin
  if FStencilTest <> Value then
  begin
    FStencilTest := Value;
    if Value then
      glEnable(GL_STENCIL_TEST)
    else
      glDisable(GL_STENCIL_TEST);
  end;
end;

procedure TRender.SetStencilFunc(CompMode: TCompareMode; Value: LongInt; Mask: LongWord); stdcall;
begin
  glStencilFunc(CompareFunc[CompMode], Value, Mask);
end;

procedure TRender.SetStencilOp(Fail, ZFail, Pass: TScencilOp); stdcall;
begin
  glStencilOp(ScencilOp[Fail], ScencilOp[ZFail], ScencilOp[Pass]);
end;

function TRender.GetDepthWrite: Boolean;
begin
  Result := FDepthWrite;
end;

procedure TRender.SetDepthWrite(Value: Boolean);
begin
  if FDepthWrite <> Value then
  begin
    FDepthWrite := Value;
    glDepthMask(Value);
  end;
end;

procedure TRender.SetDepthOffset(Factor: Single; Units: Single); stdcall;
begin
  glPolygonOffset(Factor, Units);
  if (Abs(Factor) <= EPS) and (Abs(Units) <= EPS) then
    glDisable(GL_POLYGON_OFFSET_FILL)
  else
    glEnable(GL_POLYGON_OFFSET_FILL);
end;

function TRender.GetCullFace: TCullFace;
begin
  Result := FCullFace;
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

function TRender.GetMatrix(Idx: TMatrixType): TMat4f;
begin
  Result := FMatrix[Idx];
end;

procedure TRender.SetMatrix(Idx: TMatrixType; const Value: TMat4f);
begin
  FMatrix[Idx] := Value;
end;

function TRender.GetCameraPos: TVec3f;
begin
  Result := FCameraPos;
end;

procedure TRender.SetCameraPos(Value: TVec3f);
begin
  FCameraPos := Value;
end;

function TRender.GetCameraDir: TVec3f;
begin
  Result := FCameraDir;
end;

procedure TRender.SetCameraDir(Value: TVec3f);
begin
  FCameraDir := Value;
end;

function TRender.GetFPS: LongWord;
begin
  Result := FFps;
end;

function TRender.GetFrameTime: LongWord;
begin
  Result := FFrameTime;
end;

function TRender.GetDipCount: LongWord;
begin
  Result := FDipCount;
end;

procedure TRender.SetDipCount(Value: LongWord);
begin
  FDipCount := Value;
end;

function TRender.GetFrameDipCount: LongWord;
begin
  Result := FLastDipCount;
end;

procedure TRender.IncDip;
begin
  Inc(FDipCount);
end;

procedure TRender.CheckGAPIErrors;
var
  error: GLenum;
begin
  error := glGetError;
  if(error <> 0) then
    Engine.Warning('OpenGL error 0x' + IntToHex(error, 4));
end;

procedure TRender.Start;
begin
  FFrameStart := Helpers.RealTime;
end;

procedure TRender.Finish;
begin
  CheckGAPIErrors;
  Engine.DispatchEvent(evRenderFlush);

  Inc(FFPSCount);
  if Helpers.RealTime - FFPSTime >= 1000 then
  begin
    FFPS      := FFPSCount;
    FFPSCount := 0;
    FFPSTime  := FFPSTime + 1000;
  end;
  FFrameTime := Helpers.RealTime - FFrameStart;

  FLastDipCount := FDipCount;
  FDipCount := 0;
end;

end.
