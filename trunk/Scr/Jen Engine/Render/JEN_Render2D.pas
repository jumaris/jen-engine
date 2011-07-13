unit JEN_Render2D;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_GeometryBuffer;

const Batch_Size = 8;

type
  IRender2D = interface(JEN_Header.IRender2D)
    procedure Init;
    procedure BatchQuad(const v1, v2, v3, v4, Data1, Data2, Data3, Data4: TVec4f); stdcall;
  end;
  TByteArray = array [0..1] of Byte;

  TTehniqueType = (ttNormal, ttAdvanced, ttAdvanced1, ttAdvanced2, ttAdvanced3, ttAdvancedLast);

  TTehnique = record
    IndxAttrib    : IShaderAttrib;
    VBUniform     : IShaderUniform;
    DBUniform     : IShaderUniform;
    ShaderProgram : IShaderProgram;
    LastUsed      : LongInt;
  end;

  TRender2D = class(TInterfacedObject, IRender2D)
    constructor Create;
    destructor Destroy; override;
  private
    FShader : IShaderResource;
  class var
    FIdx     : LongWord;
    FVrtBuff : IGeomBuffer;
    RenderTechnique : array[TTehniqueType] of TTehnique;

    FBatchParams : record
      Tehnique        : TTehniqueType;
      BatchShader     : IShaderProgram;
      UniformsVersion : LongWord;
      BatchTexture1   : ITexture;
      BatchTexture2   : ITexture;
      BatchTexture3   : ITexture;
      Blend           : TBlendType;
      ColorMask       : Byte;
      AlphaTest       : Byte;
    end;

    FDataBuff : array[1..Batch_Size*4] of TVec4f;
    FVertexBuff : array[1..Batch_Size] of record
      v : array[1..4] of TVec4f;
    end;

  public
    class procedure Flush(Param: LongInt = 0); stdcall; static;
    procedure Init;
    procedure BatchQuad(const v1, v2, v3, v4, Data1, Data2, Data3, Data4: TVec4f); stdcall;
    procedure DrawSpriteAdv(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture; x, y, w, h: Single; const Data1, Data2, Data3, Data4: TVec4f; Angle, cx, cy: Single); stdcall;

    procedure DrawSprite(Tex : ITexture; x, y, w, h: Single; const Color: TVec4f; Angle, cx, cy: Single); overload; stdcall;
    procedure DrawSprite(Tex : ITexture; x, y, w, h: Single; const c1, c2, c3, c4: TVec4f; Angle, cx, cy: Single); overload;  stdcall;
  end;

implementation

uses
  JEN_Main;

function TehniqueInit(Shader: IShaderProgram): TTehnique;
var
  i : LongInt;
  Uniform : IShaderUniform;
begin
  if Assigned(Shader) then
    with Result do
    begin
      LastUsed := Utils.Time;
      ShaderProgram := Shader;
      VBUniform := ShaderProgram.Uniform('PosTexCoord');
      DBUniform := ShaderProgram.Uniform('QuadData', False);

      for I := 0 to 3 do
      begin
        Uniform := ShaderProgram.Uniform('QuadData', False);
        if Assigned(Uniform) then
          Uniform.Value(i);
      end;

      IndxAttrib := ShaderProgram.Attrib('IndxAttrib');
      IndxAttrib.Value(4,0, atVec1f);
    end;
end;

constructor TRender2D.Create;
begin
  inherited;
end;

procedure TRender2D.Init;
var
  i : ShortInt;
  IdxBuff : array[1..Batch_Size*4] of Single;
begin
  for I:=1  to Batch_Size*4 do
    IdxBuff[i] := i-1;

  FVrtBuff := Render.CreateGeomBuffer(gbVertex, Batch_Size*4, 4, @IdxBuff[1]);

  ResMan.Load('Media\Shader.xml', FShader);
  RenderTechnique[ttNormal] := TehniqueInit(FShader.Compile);

  Engine.AddEventProc(evFrameEnd, @TRender2D.Flush);
end;

destructor TRender2D.Destroy;
begin
  inherited;
end;

class procedure TRender2D.Flush;
var
  Blend     : TBlendType;
  AlphaTest : Byte;
begin
  if FIdx = 0 then Exit;

  with FBatchParams do
  begin
    if Assigned(BatchTexture1) then
      BatchTexture1.Bind(0);
    if Assigned(BatchTexture2) then
      BatchTexture1.Bind(1);
    if Assigned(BatchTexture3) then
      BatchTexture1.Bind(2);
  end;

  Blend     := Render.BlendType;
  AlphaTest := Render.AlphaTest;

  Render.BlendType := FBatchParams.Blend;
  Render.AlphaTest := FBatchParams.AlphaTest;

  FVrtBuff.Bind;

  with RenderTechnique[FBatchParams.Tehnique] do
  begin
    IndxAttrib.Enable;
    ShaderProgram.Bind;

    VBUniform.Value(FVertexBuff[1], FIdx*4);
    if Assigned(DBUniform) then
      DBUniform.Value(FDataBuff[1], FIdx*4);
  end;
  FVrtBuff.Draw(gmQuads, FIdx*4, false);

  Render.BlendType := Blend;
  Render.AlphaTest := AlphaTest;

  FIdx := 0;
  Render.IncDip;
end;

procedure TRender2D.BatchQuad(const v1, v2, v3, v4, Data1, Data2, Data3, Data4: TVec4f);
begin
  inc(FIdx);

  with FVertexBuff[FIdx] do
  begin
    V[1]:=v1;
    V[2]:=v2;
    V[3]:=v3;
    V[4]:=v4;
  end;

  FDataBuff[(FIdx-1)*4+1] := Data1;
  FDataBuff[(FIdx-1)*4+2] := Data2;
  FDataBuff[(FIdx-1)*4+3] := Data3;
  FDataBuff[(FIdx-1)*4+4] := Data4;

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

  if Abs(Angle)<=EPS then
  begin
     v4 := Vec2f(X  , Y  );
     v3 := Vec2f(X+W, Y  );
     v2 := Vec2f(X+W, Y+H);
     v1 := Vec2f(X  , Y+H);
     Exit;
  end;

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
  tx1 := -cx*w;
	ty1 := -cy*h;
	tx2 := (1.0-cx)*w;
	ty2 := (1.0-cy)*h;

	v4 := Vec2f(tx1*tcos - ty1*tsin, tx1*tsin + ty1*tcos) + p;
  v3 := Vec2f(tx2*tcos - ty1*tsin, tx2*tsin + ty1*tcos) + p;
  v2 := Vec2f(tx2*tcos - ty2*tsin, tx2*tsin + ty2*tcos) + p;
  v1 := Vec2f(tx1*tcos - ty2*tsin, tx1*tsin + ty2*tcos) + p;
end;

procedure TRender2D.DrawSpriteAdv(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture; x, y, w, h: Single; const Data1, Data2, Data3, Data4: TVec4f; Angle, cx, cy: Single);
var
  v : array[1..4] of TVec2f;

  procedure UpdateBathParams;
  var
    Teh : TTehniqueType;
    OlderTime : LongInt;
    OlderTeh : TTehniqueType;
  begin
    with FBatchParams do
    begin
      BatchShader     := Shader;
      UniformsVersion := Shader.UniformsVersion;
      BatchTexture1   := Tex1;
      BatchTexture2   := Tex2;
      BatchTexture3   := Tex3;
      Blend           := Render.BlendType;
      ColorMask       := Render.GetColorMask;
      AlphaTest       := Render.AlphaTest;

      OlderTeh        := ttAdvanced;
      OlderTime       := RenderTechnique[ttAdvanced].LastUsed;

      for Teh := ttNormal to ttAdvancedLast do
        with RenderTechnique[Teh] do
        if ShaderProgram = Shader then
        begin
          LastUsed := Utils.Time;
          Tehnique := Teh;
          Exit;
        end else
          if (OlderTime>LastUsed) and (Teh >= ttAdvanced) then
          begin
            OlderTime := LastUsed;
            OlderTeh  := Teh;
          end;

      RenderTechnique[OlderTeh] := TehniqueInit(Shader);
      Tehnique := OlderTeh;
    end;
  end;

begin
  if not Assigned(Shader) then Exit;

  with FBatchParams do
  begin

    if FIdx = 0 then
      UpdateBathParams
    else if(BatchShader <> Shader) or
           (BatchTexture1 <> Tex1) or (BatchTexture2 <> Tex2) or (BatchTexture3 <> Tex3) or
           (Blend <> Render.BlendType) or (ColorMask <> Render.GetColorMask) or (AlphaTest <> Render.AlphaTest) or
           (UniformsVersion <> Shader.UniformsVersion) then
    begin
      Flush;
      UpdateBathParams;
    end;

    Rotate2D(v[1], v[2], v[3], v[4], x, y, w, h, Angle, cx, cy);

    BatchQuad( Vec4f(v[1].x, v[1].y, 0, 1),
               Vec4f(v[2].x, v[2].y, 1, 1),
               Vec4f(v[3].x, v[3].y, 1, 0),
               Vec4f(v[4].x, v[4].y, 0, 0), Data1, Data2, Data3, Data4);
  end;

end;

procedure TRender2D.DrawSprite(Tex : ITexture; x, y, w, h: Single; const Color: TVec4f; Angle, cx, cy: Single);
begin
  DrawSpriteAdv(RenderTechnique[ttNormal].ShaderProgram, Tex, nil, nil, x, y, w, h, Color, Color, Color, Color, Angle, cx, cy);
end;

procedure TRender2D.DrawSprite(Tex: ITexture; X, Y, W, H: Single; const c1, c2, c3, c4: TVec4f; Angle, Cx, Cy: Single);
begin
  DrawSpriteAdv(RenderTechnique[ttNormal].ShaderProgram, Tex, nil, nil, x, y, w, h, c1, c2, c3, c4, Angle, cx, cy);
end;

end.
