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
    procedure UpdateRC;
  end;
  TByteArray = array [0..1] of Byte;

  TTehniqueType = (ttNormal, ttText, ttAdvanced, ttAdvanced1, ttAdvanced2, ttAdvanced3, ttAdvancedLast);

  TTehnique = record
    IndxAttrib    : IShaderAttrib;
    MatUniform    : IShaderUniform;
    VBUniform     : IShaderUniform;
    DBUniform     : IShaderUniform;
    TCParUniform1 : IShaderUniform;
		TCParUniform2 : IShaderUniform;
		TCParUniform3 : IShaderUniform;
    ShaderProgram : IShaderProgram;
    LastUsed      : LongInt;
  end;

  TRender2D = class(TInterfacedObject, IRender2D)
    procedure Free; stdcall;
  private
    FRCWidth      : LongWord;
    FRCHeight     : LongWord;
    FRCScale      : Single;
    FRCRect       : TRecti;
    FEnableRC     : Boolean;
    FRCMatrix     : TMat4f;

    FBatch        : Boolean;
    FNormalShader : IShaderResource;
    FTextShader   : IShaderResource;
    FIdx          : LongWord;
    FVrtBuff      : IGeomBuffer;
    RenderTechnique : array[TTehniqueType] of TTehnique;

    Tehnique        : TTehniqueType;
    BatchTexture1   : ITexture;
    BatchTexture2   : ITexture;
    BatchTexture3   : ITexture;

    FDataBuff : array[1..Batch_Size*4] of TVec4f;
    FVertexBuff : array[1..Batch_Size*4] of TVec4f;
  public
    procedure Init;

    procedure ResolutionCorrect(Width, Height: LongWord); stdcall;
    procedure UpdateRC;
    function  GetEnableRC: Boolean; stdcall;
    procedure SetEnableRC(Value: Boolean); stdcall;
    function  GetRCWidth: LongWord; stdcall;
    function  GetRCHeight: LongWord; stdcall;
    function  GetRCRect: TRecti; stdcall;
    function  GetRCScale: Single; stdcall;
    function  GetRCMatrix: TMat4f; stdcall;

    class procedure FlushProc(Param: LongInt; Data: Pointer); stdcall; static;
    class procedure DisplayRestore(Param: LongInt; Data: Pointer); stdcall; static;

    procedure BatchBegin; stdcall;
    procedure BatchEnd; stdcall;
    procedure Flush;

    procedure DrawSprite(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture; const v1, v2, v3, v4, Data1, Data2, Data3, Data4: TVec4f; Angle: Single; const Center: TVec2f; Effects: Cardinal); overload; stdcall;
    procedure DrawSprite(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture; x, y, w, h: Single; const Data1, Data2, Data3, Data4: TVec4f; Angle: Single; const Center: TVec2f; Effects: Cardinal); overload; stdcall;
    procedure DrawSprite(Tex: ITexture; x, y, w, h: Single; const Color: TVec4f; Angle, cx, cy: Single; Effects: Cardinal); overload; stdcall;
    procedure DrawSprite(Tex: ITexture; x, y, w, h: Single; const c1, c2, c3, c4: TVec4f; Angle, cx, cy: Single; Effects: Cardinal); overload; stdcall;
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
      MatUniform := ShaderProgram.Uniform('Matrix2D', utMat4);
      VBUniform := ShaderProgram.Uniform('PosTexCoord', utVec4, False);
      DBUniform := ShaderProgram.Uniform('QuadData', utVec4, False);
      TCParUniform1 := ShaderProgram.Uniform('TexCoordParams1', utVec4, False);
		  TCParUniform2 := ShaderProgram.Uniform('TexCoordParams2', utVec4, False);
		  TCParUniform3 := ShaderProgram.Uniform('TexCoordParams3', utVec4, False);

      i := 0;
      Uniform := ShaderProgram.Uniform('Map0', utInt, False);
      if Assigned(Uniform) then
        Uniform.Value(i);

      i := 1;
      Uniform := ShaderProgram.Uniform('Map1', utInt, False);
      if Assigned(Uniform) then
        Uniform.Value(i);

      IndxAttrib := ShaderProgram.Attrib('IndxAttrib', atVec1f);
      IndxAttrib.Value(4, 0);
    end;
end;

procedure TRender2D.Init;
var
  i : ShortInt;
  IdxBuff : array[1..Batch_Size*4] of Single;
begin
  for I := 1 to Batch_Size*4 do
    IdxBuff[i] := i-1;

  FVrtBuff := TGeomBuffer.Create(gbVertex, Batch_Size*4, 4, @IdxBuff[1]);//Render.CreateGeomBuffer(gbVertex, Batch_Size*4, 4, @IdxBuff[1]);
  ResMan.Load('|SpriteShader.xml', FNormalShader);
  ResMan.Load('|TextShader.xml', FTextShader);
  RenderTechnique[ttNormal] := TehniqueInit(FNormalShader.Compile);
  RenderTechnique[ttText] := TehniqueInit(FTextShader.Compile);

  Engine.AddEventProc(evRenderFlush, @TRender2D.FlushProc);
  Engine.AddEventProc(evDisplayRestore, @TRender2D.DisplayRestore);
end;

procedure TRender2D.Free;
///var
//Teh :TTehniqueType;
begin
 { FVrtBuff := nil;
  FNormalShader := nil;
  FTextShader := nil;
  for Teh := ttNormal to ttAdvancedLast do
  with RenderTechnique[ TTehniqueType(Teh)] do
  begin
    ShaderProgram := nil;
    VBUniform :=  nil;
      DBUniform :=  nil;
      TCParUniform1 :=  nil;
		  TCParUniform2 := nil;
		  TCParUniform3 :=  nil;

      IndxAttrib :=  nil;
  end;


  FBatchParams.BatchShader     := nil;
  FBatchParams.BatchTexture1   := nil;
  FBatchParams.BatchTexture2   := nil;
  FBatchParams.BatchTexture3   := nil;
       }
end;

procedure TRender2D.ResolutionCorrect(Width, Height: LongWord);
begin
  FRCWidth := Width;
  FRCHeight := Height;
  FEnableRC := True;
  UpdateRC;
end;

procedure TRender2D.UpdateRC;
var
  BorderV : LongInt;
  BorderH : LongInt;
begin
  if FEnableRC then
  begin
    FRCScale := Max(FRCWidth/Display.Width, FRCHeight/Display.Height);
    BorderV  := Round((Display.Width - FRCWidth/FRCScale)/2);
    BorderH  := Round((Display.Height - FRCHeight/FRCScale)/2);
    FRCRect  := Recti(BorderV, BorderH, Display.Width - BorderV*2, Display.Height- BorderH*2);
  end else
  begin
    FRCScale := 1;
    FRCRect  := Recti(0, 0, Display.Width, Display.Height);
  end;

  FRCMatrix.Ortho(0, FRCWidth, FRCHeight, 0, -1, 1);
  Render.Viewport := FRCRect;
  Render.Matrix[mt2DMat] := FRCMatrix;
end;

function TRender2D.GetEnableRC: Boolean;
begin
  Result := FEnableRC;
end;

procedure TRender2D.SetEnableRC(Value: Boolean);
begin
  if Value <> FEnableRC then
  begin
    FEnableRC := Value;
    UpdateRC;
  end;
end;

function TRender2D.GetRCWidth: LongWord;
begin
  Result := FRCWidth;
end;

function TRender2D.GetRCHeight: LongWord;
begin
  Result := FRCHeight;
end;

function TRender2D.GetRCRect: TRecti;
begin
  Result := FRCRect
end;

function TRender2D.GetRCScale: Single;
begin
  Result := FRCScale
end;

function TRender2D.GetRCMatrix: TMat4f;
begin
  Result := FRCMatrix;
end;

class procedure TRender2D.FlushProc;
begin
  Render2d.Flush;
end;

class procedure TRender2D.DisplayRestore;
begin
  Render2d.UpdateRC;
end;

procedure TRender2D.BatchBegin;
begin
  Flush;
  FBatch := True;
end;

procedure TRender2D.BatchEnd;
begin
  Flush;
  FBatch := False;
end;

procedure TRender2D.Flush;
var
  TCParams  : TVec4f;
  mat       : TMat4f;
begin
  if FIdx = 0 then Exit;

  if Assigned(BatchTexture1) then
    BatchTexture1.Bind(0);
  if Assigned(BatchTexture2) then
    BatchTexture2.Bind(1);
  if Assigned(BatchTexture3) then
    BatchTexture3.Bind(2);

  FVrtBuff.Bind;

  with RenderTechnique[Tehnique] do
  begin
    ShaderProgram.Bind;
    IndxAttrib.Value(4, 0);
    IndxAttrib.Enable;

  //  TCParams := vec4f(Render.Matrix[mt2DMat].e00, Render.Matrix[mt2DMat].e10, Render.Matrix[mt2DMat].e01, Render.Matrix[mt2DMat].e11);
    mat := Render.Matrix[mt2DMat];
    MatUniform.Value(mat);

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
  FVrtBuff.Draw(gmQuads, FIdx*4, False);

  FIdx := 0;
  Render.IncDip;
end;

procedure Rotate2D(out v1, v2, v3, v4: TVec4f; Angle: Single); inline;
var
  tsin, tcos : Single;
begin
  sincos(Deg2Rad*Angle,tsin,tcos);

	v4 := Vec4f(v4.x*tcos - v4.y*tsin, v4.x*tsin + v4.y*tcos, v4.z, v4.w);
  v3 := Vec4f(v3.x*tcos - v3.y*tsin, v3.x*tsin + v3.y*tcos, v3.z, v3.w);
  v2 := Vec4f(v2.x*tcos - v2.y*tsin, v2.x*tsin + v2.y*tcos, v2.z, v2.w);
  v1 := Vec4f(v1.x*tcos - v1.y*tsin, v1.x*tsin + v1.y*tcos, v1.z, v1.w);
end;

procedure TRender2D.DrawSprite(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture; const v1, v2, v3, v4, Data1, Data2, Data3, Data4: TVec4f; Angle: Single; const Center: TVec2f; Effects: Cardinal); stdcall;
var
  v : array[1..4] of TVec4f;
  p : TVec4f;

  procedure UpdateBathParams;
  var
    Teh : TTehniqueType;
    OlderTime : LongInt;
    OlderTeh : TTehniqueType;
  begin
    BatchTexture1   := Tex1;
    BatchTexture2   := Tex2;
    BatchTexture3   := Tex3;
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

  function InScreen(const Pos: TVec4f): Boolean; inline;
  begin
    Result := (Pos.x>=0) and (Pos.y>=0) and (Pos.x<=Display.Width) and (Pos.y<=Display.Height);
  end;

begin
  if not (Assigned(Shader) and Shader.Valid) then Exit;

  if FIdx = 0 then
    UpdateBathParams
  else
    if((FBatch = False) or (RenderTechnique[Tehnique].ShaderProgram <> Shader) or
      (BatchTexture1 <> Tex1) or (BatchTexture2 <> Tex2) or (BatchTexture3 <> Tex3)) then
    begin
      Flush;
      UpdateBathParams;
    end;

  if Abs(Angle) > EPS then
  begin
    p := Vec4f(Center.X, Center.Y, 0, 0);
    v[1] := v1 - p;
    v[2] := v2 - p;
    v[3] := v3 - p;
    v[4] := v4 - p;
    Rotate2D(v[1], v[2], v[3], v[4], Angle);
    FVertexBuff[FIdx*4+1] := v[1] + p;
    FVertexBuff[FIdx*4+2] := v[2] + p;
    FVertexBuff[FIdx*4+3] := v[3] + p;
    FVertexBuff[FIdx*4+4] := v[4] + p;
  end else
  begin
    FVertexBuff[FIdx*4+1] := v1;
    FVertexBuff[FIdx*4+2] := v2;
    FVertexBuff[FIdx*4+3] := v3;
    FVertexBuff[FIdx*4+4] := v4;
  end;

  FDataBuff[FIdx*4+1] := Data1;
  FDataBuff[FIdx*4+2] := Data2;
  FDataBuff[FIdx*4+3] := Data3;
  FDataBuff[FIdx*4+4] := Data4;

  inc(FIdx);
  if FIdx = Batch_Size then
    Flush;
end;

procedure TRender2D.DrawSprite(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture; x, y, w, h: Single; const Data1, Data2, Data3, Data4: TVec4f; Angle: Single; const Center: TVec2f; Effects: Cardinal);
begin
  DrawSprite(Shader, Tex1, Tex2, Tex3, Vec4f(x, y+h, 0, 0),Vec4f(x+w, y+h, 1, 0), Vec4f(x+w, y, 1, 1), Vec4f(x, y, 0, 1), Data1, Data2, Data3, Data4, Angle, Center, Effects);
end;

procedure TRender2D.DrawSprite(Tex : ITexture; x, y, w, h: Single; const Color: TVec4f; Angle, cx, cy: Single; Effects: Cardinal);
begin
  if not Assigned(Tex) then Exit;
  DrawSprite(RenderTechnique[ttNormal].ShaderProgram, Tex, nil, nil, Vec4f(x, y+h, 0, 0),Vec4f(x+w, y+h , 1, 0), Vec4f(x+w, y, 1, 1), Vec4f(x, y, 0, 1), Color, Color, Color, Color, Angle, Vec2f(x + w*cx,y + h*cy), Effects);
end;

procedure TRender2D.DrawSprite(Tex: ITexture; X, Y, W, H: Single; const c1, c2, c3, c4: TVec4f; Angle, Cx, Cy: Single; Effects: Cardinal);
begin
  if not Assigned(Tex) then Exit;
  DrawSprite(RenderTechnique[ttNormal].ShaderProgram, Tex, nil, nil, Vec4f(x, y+h, 0, 0),Vec4f(x+w, y+h , 1, 0), Vec4f(x+w, y, 1, 1), Vec4f(x, y, 0, 1), c1, c2, c3, c4, Angle, Vec2f(x + w*cx,y + h*cy), Effects);
end;

end.
