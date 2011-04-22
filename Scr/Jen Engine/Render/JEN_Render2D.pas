unit JEN_Render2D;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_GeometryBuffer,
  JEN_OpenGlHeader;

const Batch_Size = 8;

type
  IRender2D = interface(JEN_Header.IRender2D)
    procedure Init;
    procedure BatchQuad(const v1, v2, v3, v4, c1, c2, c3, c4: TVec4f); overload; stdcall;
    procedure BatchQuad(const v1, v2, v3, v4, Color: TVec4f); overload; stdcall;
  end;
  TByteArray = array [0..1] of Byte;

  TRender2D = class(TInterfacedObject, IRender2D)
    constructor Create;
    destructor Destroy; override;
  private
    FShader : IShaderResource;
  class var
    FBatchParams : record
      BatchTexture : ITexture;
      Blend : TBlendType;
      ColorMask : Byte;
      AlphaTest : Byte;
      VertexColor : Boolean;
    end;

    FVertexBuff : array[1..Batch_Size] of
    record
      v: array[1..4] of TVec4f;
    end;

    FColorBuff : array[1..Batch_Size*4] of TVec4f;
    FIdx: LongWord;

    RenderTechnique : array[boolean] of record
      //FIndxAttrib : IShaderAttrib;
      FVBUniform : IShaderUniform;
      FCBUniform : IShaderUniform;
      FShaderProgram : IShaderProgram;
    end;

    FVrtBuff : TGeomBuffer;
  public
    class procedure Flush; stdcall; static;
    procedure Init;
    procedure BatchQuad(const v1, v2, v3, v4, c1, c2, c3, c4: TVec4f); overload; stdcall;
    procedure BatchQuad(const v1, v2, v3, v4, Color: TVec4f); overload; stdcall;
    procedure DrawSprite(Tex: ITexture; x, y, w, h: Single; const Color: TVec4f; Angle, cx, cy: Single); overload; stdcall;
    procedure DrawSprite(Tex: ITexture; x, y, w, h: Single; const c1, c2, c3, c4: TVec4f; Angle, cx, cy: Single); overload;  stdcall;
  end;

implementation

uses
  JEN_Main;

constructor TRender2D.Create;
begin
  inherited;
end;

procedure TRender2D.Init;
var
  i : ShortInt;
  IdxBuff : array[1..Batch_Size*4] of Word;

  procedure SetupTechnique(Value : Boolean);
  begin
    with RenderTechnique[Value] do
    begin
      FShader['VertexColor']:=Ord(Value);
      FShaderProgram := FShader.Compile;
      FVBUniform := FShaderProgram.Uniform('PosTexCoord',utVec4);
      FCBUniform := FShaderProgram.Uniform('QuadColor',utVec4);
    //  FIndxAttrib := FShaderProgram.Attrib('Indx',atVec1f);
    //  FIndxAttrib.Value(0,0);
    end;
  end;

begin
  for I:=1  to Batch_Size*4 do
    IdxBuff[i] := i-1;

  FVrtBuff := TGeomBuffer.Create(gbtVertex, Batch_Size*4, 2, @IdxBuff[1]);

  ResMan.Load('Media\Shader.xml', FShader);
  SetupTechnique(True);
  SetupTechnique(False);

  Engine.AddEventProc(evFrameEnd, @TRender2D.Flush);
end;

destructor TRender2D.Destroy;
begin
  if Assigned(FVrtBuff) then
    FVrtBuff.Free;
  inherited;
end;

class procedure TRender2D.Flush;
var
  I : Byte;
  vc : PSingle;
begin
  if FIdx = 0 then Exit;
  Render.SetArrayState(false, true, false, false);

  with RenderTechnique[FBatchParams.VertexColor] do
  begin
    FShaderProgram.Bind;

    FVBUniform.Value(FVertexBuff[1],FIdx*4);
    if FBatchParams.VertexColor then
      FCBUniform.Value(FColorBuff[1],FIdx*4)
    else
      FCBUniform.Value(FColorBuff[1],FIdx);
  end;

  FVrtBuff.Bind;
  glTexCoordPointer(1, GL_SHORT, 0, 0);
  glDrawArrays(GL_QUADS, 0, FIdx*4);

  FIdx := 0;
  Render.IncDip;
end;

procedure TRender2D.BatchQuad(const v1, v2, v3, v4, c1, c2, c3, c4: TVec4f);
begin
  inc(FIdx);

  with FVertexBuff[FIdx] do
  begin
    V[1]:=v1; FColorBuff[(FIdx-1)*4+1] := c1;
    V[2]:=v2; FColorBuff[(FIdx-1)*4+2] := c2;
    V[3]:=v3; FColorBuff[(FIdx-1)*4+3] := c3;
    V[4]:=v4; FColorBuff[(FIdx-1)*4+4] := c4;
  end;

  if FIdx = Batch_Size then
    Flush;
end;

procedure TRender2D.BatchQuad(const v1, v2, v3, v4, Color: TVec4f);
begin
  inc(FIdx);

  with FVertexBuff[FIdx] do
  begin
    V[1]:=v1;
    V[2]:=v2;
    V[3]:=v3;
    V[4]:=v4;
  end;
  FColorBuff[FIdx] := Color;

  if FIdx = Batch_Size then
    Flush;
end;

procedure Rotate2D(out v1, v2, v3, v4 : TVec2f; x, y, w, h, Angle, Cx, Cy: Single); inline;
var
  tsin, tcos : Single;
  p :TVec2f;
  //tx1,tx2,ty1,ty2, vx, vy : TVec2f;
  tx1,tx2,ty1,ty2: single;
begin
  sincos(Deg2Rad*Angle,tsin,tcos);
  p  := Vec2f(x + w*Cx, y + h*Cy);
          {
  vx := Vec2f(tcos,tsin);
  vy := Vec2f(-tsin,tcos);

  tx1 := vx*-(w*Cx); tx2 := vx*(w*(1.0-Cx));
  ty1 := vy*-(h*Cy); ty2 := vy*(h*(1.0-Cy));

  v4 := tx1 + ty1 + p;
  v3 := tx2 + ty1 + p;
  v2 := tx2 + ty2 + p;
  v1 := tx1 + ty2 + p;
     }
  tx1 := -cx*h;
	ty1 := -cy*w;
	tx2 := (1.0-cx)*h;
	ty2 := (1.0-cy)*w;

	v4 := Vec2f(tx1*tcos - ty1*tsin, tx1*tsin + ty1*tcos) + p;
  v3 := Vec2f(tx2*tcos - ty1*tsin, tx2*tsin + ty1*tcos) + p;
  v2 := Vec2f(tx2*tcos - ty2*tsin, tx2*tsin + ty2*tcos) + p;
  v1 := Vec2f(tx1*tcos - ty2*tsin, tx1*tsin + ty2*tcos) + p;
end;

procedure TRender2D.DrawSprite(Tex: ITexture; X, Y, W, H: Single; const Color: TVec4f; Angle, Cx, Cy: Single);
var
  v : array[1..4] of TVec2f;

  procedure UpdateBathParams;
  begin
    with FBatchParams do
    begin
      BatchTexture := Tex;
      Blend := Render.BlendType;
      ColorMask := Render.GetColorMask;
      AlphaTest := Render.AlphaTest;
      VertexColor := false;
    end;
  end;

begin
  if not Assigned(Tex) then Exit;

  with FBatchParams do
  begin
    Tex.Bind;

    if FIdx = 0 then
      UpdateBathParams
    else if(BatchTexture <> Tex) or (Blend <> Render.BlendType) or (ColorMask <> Render.GetColorMask) or (AlphaTest <> Render.AlphaTest) then
    begin
      Flush;
      UpdateBathParams;
    end;

    if Abs(Angle)<=EPS then
    begin
      v[4] := Vec2f(X  , Y  );
      v[3] := Vec2f(X+W, Y  );
      v[2] := Vec2f(X+W, Y+H);
      v[1] := Vec2f(X  , Y+H);
    end else
      Rotate2D(v[1], v[2], v[3], v[4], x, y, w, h, Angle, cx, cy);

    if VertexColor then
      BatchQuad( Vec4f(v[1].x, v[1].y, 0, 0),
                 Vec4f(v[2].x, v[2].y, 1, 0),
                 Vec4f(v[3].x, v[3].y, 1, 1),
                 Vec4f(v[4].x, v[4].y, 0, 1), Color, Color, Color, Color)
    else
      BatchQuad( Vec4f(v[1].x, v[1].y, 0, 0),
                 Vec4f(v[2].x, v[2].y, 1, 0),
                 Vec4f(v[3].x, v[3].y, 1, 1),
                 Vec4f(v[4].x, v[4].y, 0, 1), Color);
  end;

end;

procedure TRender2D.DrawSprite(Tex: ITexture; X, Y, W, H: Single; const c1, c2, c3, c4: TVec4f; Angle, Cx, Cy: Single);
var
  v : array[1..4] of TVec2f;
  c : array[1..4] of TVec4f;

  procedure UpdateBathParams;
  begin
    with FBatchParams do
    begin
      BatchTexture := Tex;
      Blend := Render.BlendType;
      ColorMask := Render.GetColorMask;
      AlphaTest := Render.AlphaTest;
      VertexColor := True;
    end;
  end;

begin
  if not Assigned(Tex) then Exit;

  with FBatchParams do
  begin
    Tex.Bind;

    if FIdx = 0 then
      UpdateBathParams
    else if(BatchTexture <> Tex) or (Blend <> Render.BlendType) or (ColorMask <> Render.GetColorMask) or (AlphaTest <> Render.AlphaTest) or (VertexColor <> True) then
    begin
      Flush;
      UpdateBathParams;
    end;

    if Abs(Angle)<=EPS then
    begin
      v[4] := Vec2f(X  , Y  );
      v[3] := Vec2f(X+W, Y  );
      v[2] := Vec2f(X+W, Y+H);
      v[1] := Vec2f(X  , Y+H);
    end else
      Rotate2D(v[1], v[2], v[3], v[4], x, y, w, h, Angle, cx, cy);

    BatchQuad( Vec4f(v[1].x, v[1].y, 0, 0),
               Vec4f(v[2].x, v[2].y, 1, 0),
               Vec4f(v[3].x, v[3].y, 1, 1),
               Vec4f(v[4].x, v[4].y, 0, 1), c1, c2, c3, c4);
  end;

end;

end.
