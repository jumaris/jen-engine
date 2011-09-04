unit JEN_Render2D;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_GeometryBuffer;

const Batch_Size = 15;

type
  IRender2D = interface(JEN_Header.IRender2D)
    procedure Init;
    procedure Flush;
    function  GetTextShader: IShaderProgram;
    procedure BatchQuad(const v1, v2, v3, v4, Data1, Data2, Data3, Data4: TVec4f); stdcall;
  end;
  TByteArray = array [0..1] of Byte;

  TTehniqueType = (ttNormal, ttText, ttAdvanced, ttAdvanced1, ttAdvanced2, ttAdvanced3, ttAdvancedLast);

  TTehnique = record
    IndxAttrib    : IShaderAttrib;
    VBUniform     : IShaderUniform;
    DBUniform     : IShaderUniform;
    TCParUniform1 : IShaderUniform;
		TCParUniform2 : IShaderUniform;
		TCParUniform3 : IShaderUniform;
    ShaderProgram : IShaderProgram;
    LastUsed      : LongInt;
  end;

  TRender2D = class(TInterfacedObject, IRender2D)
    constructor Create;
    procedure Free; stdcall;
  private
    FNormalShader : IShaderResource;
    FTextShader   : IShaderResource;
    FIdx          : LongWord;
    FVrtBuff      : IGeomBuffer;
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
    FVertexBuff : array[1..Batch_Size*4] of TVec4f;
  public
    procedure Init;
    procedure Flush;
    function GetTextShader: IShaderProgram;

    class procedure FlushProc(Param: LongInt); stdcall; static;

    procedure BatchQuad(const v1, v2, v3, v4, Data1, Data2, Data3, Data4: TVec4f); stdcall;
    procedure DrawSpriteAdv(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture; const v1, v2, v3, v4, Data1, Data2, Data3, Data4: TVec4f; const Center: TVec2f; Angle: Single); stdcall;

    procedure DrawSprite(Tex: ITexture; x, y, w, h: Single; const Color: TVec4f; Angle, cx, cy: Single); overload; stdcall;
    procedure DrawSprite(Tex: ITexture; x, y, w, h: Single; const c1, c2, c3, c4: TVec4f; Angle, cx, cy: Single); overload;  stdcall;
  end;

implementation

uses
  JEN_Main;

function TehniqueInit(Shader: IShaderProgram): TTehnique;
var
  i: LongInt;
  Uniform : IShaderUniform;
begin
  if Assigned(Shader) then
    with Result do
    begin
      LastUsed := Utils.Time;
      ShaderProgram := Shader;
      ShaderProgram.Bind;
      VBUniform := ShaderProgram.Uniform('PosTexCoord');
      DBUniform := ShaderProgram.Uniform('QuadData', False);
      TCParUniform1 := ShaderProgram.Uniform('TexCoordParams1', False);
		  TCParUniform2 := ShaderProgram.Uniform('TexCoordParams2', False);
		  TCParUniform3 := ShaderProgram.Uniform('TexCoordParams3', False);

      i := 0;
      Uniform := ShaderProgram.Uniform('Map0', False);
      if Assigned(Uniform) then
        Uniform.Value(i);

      i := 1;
      Uniform := ShaderProgram.Uniform('Map1', False);
      if Assigned(Uniform) then
        Uniform.Value(i);

      IndxAttrib := ShaderProgram.Attrib('IndxAttrib');
      IndxAttrib.Value(4, 0, atVec1f);
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
  for I := 1 to Batch_Size*4 do
    IdxBuff[i] := i-1;

  FVrtBuff := TGeomBuffer.Create(gbVertex, Batch_Size*4, 4, @IdxBuff[1]);//Render.CreateGeomBuffer(gbVertex, Batch_Size*4, 4, @IdxBuff[1]);
  ResMan.Load('Media\Shader.xml', FNormalShader);
  ResMan.Load('Media\Text.xml', FTextShader);
  RenderTechnique[ttNormal] := TehniqueInit(FNormalShader.Compile);
  RenderTechnique[ttText] := TehniqueInit(FTextShader.Compile);

  Engine.AddEventProc(evRenderFlush, @TRender2D.FlushProc);
end;

procedure TRender2D.Free;
begin
end;

function TRender2D.GetTextShader: IShaderProgram;
begin
  Result := RenderTechnique[ttText].ShaderProgram;
end;

class procedure TRender2D.FlushProc;
begin
  Render2d.Flush;
end;

procedure TRender2D.Flush;
var
  TCParams  : TVec4f;
  Blend     : TBlendType;
  AlphaTest : Byte;
begin
  if FIdx = 0 then Exit;

  with FBatchParams do
  begin
    if Assigned(BatchTexture1) then
      BatchTexture1.Bind(0);
    if Assigned(BatchTexture2) then
      BatchTexture2.Bind(1);
    if Assigned(BatchTexture3) then
      BatchTexture3.Bind(2);
  end;

  Blend     := Render.BlendType;
  AlphaTest := Render.AlphaTest;

  Render.BlendType := FBatchParams.Blend;
  Render.AlphaTest := FBatchParams.AlphaTest;

  FVrtBuff.Bind;

  with FBatchParams, RenderTechnique[FBatchParams.Tehnique] do
  begin
    IndxAttrib.Value(4, 0, atVec1f);
    IndxAttrib.Enable;
    ShaderProgram.Bind;

    if Assigned(TCParUniform1) and Assigned(BatchTexture1) then
    begin
      TCParams := BatchTexture1.CoordParams;
      TCParUniform1.Value(TCParams);
    end;

    if Assigned(TCParUniform2) and Assigned(BatchTexture2) then
    begin
      TCParams := BatchTexture2.CoordParams;
      TCParUniform2.Value(TCParams);
    end;

    if Assigned(TCParUniform3) and Assigned(BatchTexture3) then
    begin
      TCParams := BatchTexture3.CoordParams;
      TCParUniform3.Value(TCParams);
    end;

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

  FVertexBuff[(FIdx-1)*4+1] := v1;
  FVertexBuff[(FIdx-1)*4+2] := v2;
  FVertexBuff[(FIdx-1)*4+3] := v3;
  FVertexBuff[(FIdx-1)*4+4] := v4;

  FDataBuff[(FIdx-1)*4+1] := Data1;
  FDataBuff[(FIdx-1)*4+2] := Data2;
  FDataBuff[(FIdx-1)*4+3] := Data3;
  FDataBuff[(FIdx-1)*4+4] := Data4;

  if FIdx = Batch_Size then
    Flush;
end;

procedure Rotate2D(out v1, v2, v3, v4: TVec4f; Angle: Single); inline;
var
  tsin, tcos : Single;
  tx1,tx2,ty1,ty2: single;
begin
  sincos(Deg2Rad*Angle,tsin,tcos);

	v4 := Vec4f(v4.x*tcos - v4.y*tsin, v4.x*tsin + v4.y*tcos, v4.z, v4.w);
  v3 := Vec4f(v3.x*tcos - v3.y*tsin, v3.x*tsin + v3.y*tcos, v3.z, v3.w);
  v2 := Vec4f(v2.x*tcos - v2.y*tsin, v2.x*tsin + v2.y*tcos, v2.z, v2.w);
  v1 := Vec4f(v1.x*tcos - v1.y*tsin, v1.x*tsin + v1.y*tcos, v1.z, v1.w);
end;

procedure TRender2D.DrawSpriteAdv(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture; const v1, v2, v3, v4, Data1, Data2, Data3, Data4: TVec4f; const Center: TVec2f; Angle: Single); stdcall;
var
  v : array[1..4] of TVec4f;
  c,p : TVec4f;

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
          if (OlderTime<LastUsed) and (Teh >= ttAdvanced) then
          begin
            OlderTime := LastUsed;
            OlderTeh  := Teh;
          end;

      RenderTechnique[OlderTeh] := TehniqueInit(Shader);
      Tehnique := OlderTeh;
    end;
  end;

  function InScreen(const Pos: TVec4f): Boolean; inline;
  begin
    Result := (Pos.x>=0) and (Pos.y>=0) and (Pos.x<=Display.Width) and (Pos.y<=Display.Height);
  end;

begin
  if not (Assigned(Shader) and Shader.Valid) then Exit;

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

    c := Vec4f(2/Display.Width, 2/Display.Height, 1, 1);
    if Abs(Angle) > EPS then
    begin
      p := Vec4f(Center.X, Center.Y, 0, 0);
      v[1] := v1 - p;
      v[2] := v2 - p;
      v[3] := v3 - p;
      v[4] := v4 - p;
      Rotate2D(v[1], v[2], v[3], v[4], Angle);
      v[1] := (v[1] + p) * c;
      v[2] := (v[2] + p) * c;
      v[3] := (v[3] + p) * c;
      v[4] := (v[4] + p) * c;
    end else
    begin
      v[1] := v1 * c;
      v[2] := v2 * c;
      v[3] := v3 * c;
      v[4] := v4 * c;
    end;

    if not (InScreen(v[4]) or InScreen(v[3]) or InScreen(v[2]) or InScreen(v[1])) then Exit;
    BatchQuad(v[1], v[2], v[3], v[4], Data1, Data2, Data3, Data4);
  end;

end;

procedure TRender2D.DrawSprite(Tex : ITexture; x, y, w, h: Single; const Color: TVec4f; Angle, cx, cy: Single);
begin
  if not Assigned(Tex) then Exit;
  DrawSpriteAdv(RenderTechnique[ttNormal].ShaderProgram, Tex, nil, nil, Vec4f(x, y+h, 0, 0),Vec4f(x+w, y+h , 1, 0), Vec4f(x+w, y, 1, 1), Vec4f(x, y, 0, 1), Color, Color, Color, Color, Vec2f(x + w*cx,y + h*cy), Angle);
end;

procedure TRender2D.DrawSprite(Tex: ITexture; X, Y, W, H: Single; const c1, c2, c3, c4: TVec4f; Angle, Cx, Cy: Single);
begin
  if not Assigned(Tex) then Exit;
  DrawSpriteAdv(RenderTechnique[ttNormal].ShaderProgram, Tex, nil, nil, Vec4f(x, y+h, 0, 0),Vec4f(x+w, y+h , 1, 0), Vec4f(x+w, y, 1, 1), Vec4f(x, y, 0, 1), c1, c2, c3, c4, Vec2f(x + w*cx,y + h*cy), Angle);
end;

end.
