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
  end;
   TByteArray = array [0..1] of Byte;

  TRender2D = class(TInterfacedObject, IRender2D)
    constructor Create;
    destructor Destroy; override;
  private
    FShader : IShaderResource;
    FBatchParams : record
      BatchTexture : ITexture;
      Blend : TBlendType;
      AlphaTest : Byte;
      VertexColor : Boolean;
    end;
  class var
    FVertexBuff : array[1..Batch_Size] of
    record
      v: array[1..4] of TVec4f;
    end;

    FColorBuff : array[1..Batch_Size] of
    record
      c: array[1..4] of TVec4f;
    end;
    FIdx: LongWord;
    FIndxAttrib : IShaderAttrib;
    FVBUniform : IShaderUniform;
    FCBUniform : IShaderUniform;
    FShaderProgram : IShaderProgram;
    FVrtBuff : TGeomBuffer;
  public
    class procedure Flush;
    procedure Init;
    procedure DrawQuad(const v1, v2, v3, v4: TVec4f; const C: TVec2f; Angle: Single); overload; stdcall;
    procedure DrawSprite(Tex : ITexture; X, Y, W, H, Angle: Single); stdcall;
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
begin
  for I:=1  to Batch_Size*4 do
    IdxBuff[i]:=i-1;

  FVrtBuff := TGeomBuffer.Create(gbtVertex, Batch_Size*4, 4, @IdxBuff[1]);

  ResMan.Load('Media\Shader.xml', FShader);
  FShaderProgram := FShader.Compile;
  FVBUniform := FShaderProgram.Uniform('bb',utVec4);
  FCBUniform := FShaderProgram.Uniform('bb2',utVec4);
  FIndxAttrib := FShaderProgram.Attrib('indx',atVec1f);
  FIndxAttrib.Value(0,0);
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
  FShaderProgram.Bind;

  FVBUniform.Value(FVertexBuff[1],FIdx*4);
  FCBUniform.Value(FColorBuff[1],FIdx*4);

  FVrtBuff.Bind;
  FIndxAttrib.Enable;

  glDrawArrays(GL_QUADS, 0, FIdx*4);

  FIdx := 1;
  Render.IncDip;
end;

procedure TRender2D.DrawQuad(const v1, v2, v3, v4: TVec4f; const C: TVec2f; Angle: Single);
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
    end else
      DrawQuad(v[1], v[2], v[3], v[4], Vec2f(X + W/2, Y + H/2), Angle);
  end;


end;

end.
