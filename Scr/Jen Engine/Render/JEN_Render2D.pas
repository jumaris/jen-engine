unit JEN_Render2D;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_GeometryBuffer,
  JEN_OpenGlHeader;

const Batch_Size = 4;

type
  IRender2D = interface(JEN_Header.IRender2D)
    procedure Init;
    procedure BatchQuad(const v1, v2, v3, v4, c1, c2, c3, c4: TVec4f; const C: TVec2f; Angle: Single = 0); overload; stdcall;
    procedure BatchQuad(const v1, v2, v3, v4: TVec4f; const C: TVec2f; Angle: Single); overload; stdcall;
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
      AlphaTest : Byte;
      VertexColor : Boolean;
    end;

    FVertexBuff : array[1..Batch_Size] of
    record
      v: array[1..4] of TVec4f;
    end;

    FColorBuff : array[1..Batch_Size] of
    record
      c: array[1..4] of TVec4f;
    end;
    FIdx: LongWord;

    RenderTechnique : array[boolean] of record
      FIndxAttrib : IShaderAttrib;
      FVBUniform : IShaderUniform;
      FCBUniform : IShaderUniform;
      FShaderProgram : IShaderProgram;
    end;

    FVrtBuff : TGeomBuffer;
  public
    class procedure Flush; stdcall; static;
    procedure Init;
    procedure BatchQuad(const v1, v2, v3, v4, c1, c2, c3, c4: TVec4f; const C: TVec2f; Angle: Single); overload; stdcall;
    procedure BatchQuad(const v1, v2, v3, v4: TVec4f; const C: TVec2f; Angle: Single); overload; stdcall;
    procedure DrawSprite(Tex : ITexture; X, Y, W, H, Angle: Single); overload; stdcall;
    procedure DrawSprite(Tex : ITexture; const c1, c2, c3, c4: TVec4f; X, Y, W, H, Angle: Single); overload; stdcall;
  end;

implementation

uses
  JEN_Main;

constructor TRender2D.Create;
begin
  inherited;
  FIdx := 1;
  FVrtBuff := nil;
end;

procedure TRender2D.Init;
var
  i : ShortInt;
  IdxBuff : array[1..Batch_Size*4] of Single;

  procedure SetupTechnique(Value : Boolean);
  begin
    with RenderTechnique[Value] do
    begin
      FShader['VertexColor']:=Ord(Value);
      FShaderProgram := FShader.Compile;
      FVBUniform := FShaderProgram.Uniform('PosTexCoord',utVec4);
      FCBUniform := FShaderProgram.Uniform('QuadColor',utVec4);
      FIndxAttrib := FShaderProgram.Attrib('Indx',atVec1f);
      FIndxAttrib.Value(0,0);
    end;
  end;

begin
  for I:=1  to Batch_Size*4 do
    IdxBuff[i]:=i-1;

  FVrtBuff := TGeomBuffer.Create(gbtVertex, Batch_Size*4, 4, @IdxBuff[1]);

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

  with RenderTechnique[FBatchParams.VertexColor] do
  begin
    FShaderProgram.Bind;

    FVBUniform.Value(FVertexBuff[1],FIdx*4);
    if FBatchParams.VertexColor then
      FCBUniform.Value(FColorBuff[1],FIdx*4);
    FIndxAttrib.Enable;
  end;

  FVrtBuff.Bind;

  glDrawArrays(GL_QUADS, 0, FIdx*4);

  FIdx := 1;
  Render.IncDip;
end;

procedure TRender2D.BatchQuad(const v1, v2, v3, v4, c1, c2, c3, c4: TVec4f; const C: TVec2f; Angle: Single);
begin
  with FVertexBuff[FIdx],FColorBuff[FIdx] do
  begin
    V[1]:=v1;
    C[1]:=Vec4f(1  , 0  , 0 ,1);
    V[2]:=v2;
    C[2]:=Vec4f(0  , 1  , 0 ,1);
    V[3]:=v3;
    C[3]:=Vec4f(0  , 0  , 1 ,1);
    V[4]:=v4;
    C[4]:=Vec4f(1 , 1  , 1 ,1);
  end;

  if FIdx = Batch_Size then
    Flush
  else
    inc(FIdx);
end;

procedure TRender2D.BatchQuad(const v1, v2, v3, v4: TVec4f; const C: TVec2f; Angle: Single);
begin
  with FVertexBuff[FIdx],FColorBuff[FIdx] do
  begin
    V[1]:=v1;
    V[2]:=v2;
    V[3]:=v3;
    V[4]:=v4;
  end;

  if FIdx = Batch_Size then
    Flush
  else
    inc(FIdx);
end;

procedure TRender2D.DrawSprite(Tex: ITexture; X, Y, W, H, Angle: Single);
var
  v : array[1..4] of TVec4f;
  c : array[1..4] of TVec4f;

  procedure UpdateBathParams;
  begin
    with FBatchParams do
    begin
      BatchTexture := Tex;
      Blend := Render.BlendType;
      AlphaTest := Render.AlphaTest;
      VertexColor := false;
    end;
  end;

begin
  if not Assigned(Tex) then Exit;

  with FBatchParams do
  begin
    if FIdx = 1 then
      UpdateBathParams
    else if(BatchTexture <> Tex) or (Blend <> Render.BlendType) or (AlphaTest <> Render.AlphaTest) then
    begin
      Tex.Bind;
      Flush;
      UpdateBathParams;
    end;

    v[1] := Vec4f(X  , Y  , 0, 1);
    v[2] := Vec4f(X+W, Y  , 1, 1);
    v[3] := Vec4f(X+W, Y+H, 1, 0);
    v[4] := Vec4f(X  , Y+H, 0, 0);

    if VertexColor then
    begin
      c[1]:=Vec4f(1, 1, 1, 1);
      c[2]:=Vec4f(1, 1, 1, 1);
      c[3]:=Vec4f(1, 1, 1, 1);
      c[4]:=Vec4f(1, 1, 1, 1);
      BatchQuad(v[1], v[2], v[3], v[4], c[1], c[2], c[3], c[4], Vec2f(X + W/2, Y + H/2), Angle);
    end else
      BatchQuad(v[1], v[2], v[3], v[4], Vec2f(X + W/2, Y + H/2), Angle);
  end;

end;

procedure TRender2D.DrawSprite(Tex: ITexture; const c1, c2, c3, c4: TVec4f; X, Y, W, H, Angle: Single);
var
  v : array[1..4] of TVec4f;
  c : array[1..4] of TVec4f;

  procedure UpdateBathParams;
  begin
    with FBatchParams do
    begin
      BatchTexture := Tex;
      Blend := Render.BlendType;
      AlphaTest := Render.AlphaTest;
      VertexColor := True;
    end;
  end;

begin
  if not Assigned(Tex) then Exit;

  with FBatchParams do
  begin

    if FIdx = 1 then
      UpdateBathParams
    else if(BatchTexture <> Tex) or (Blend <> Render.BlendType) or (AlphaTest <> Render.AlphaTest) or (VertexColor <> True) then
    begin
      Tex.Bind;
      Flush;
      UpdateBathParams;
    end;

    v[1] := Vec4f(X  , Y  , 0, 1);
    v[2] := Vec4f(X+W, Y  , 1, 1);
    v[3] := Vec4f(X+W, Y+H, 1, 0);
    v[4] := Vec4f(X  , Y+H, 0, 0);

    BatchQuad(v[1], v[2], v[3], v[4], c1, c2, c3, c4, Vec2f(X + W/2, Y + H/2), Angle);
  end;

end;

end.
