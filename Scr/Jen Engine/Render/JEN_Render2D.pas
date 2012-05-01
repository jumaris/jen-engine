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

  TQuad = array[1..4] of TVec2f;
  TTehniqueType = (ttNone, ttNormal, ttText, ttAdvanced, ttAdvanced1, ttAdvanced2, ttAdvanced3, ttAdvanced4);

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
    procedure Free; stdcall;
  private
    FRCWidth      : LongWord;
    FRCHeight     : LongWord;
    FRCScale      : Single;
    FRCRect       : TRecti;
    FEnableRC     : Boolean;
    FRCMatrix     : TMat4f;

    FRotCenter    : TVec2f;

    FBatch        : Boolean;
    FNormalShader : IShaderResource;
    FTextShader   : IShaderResource;
    FIdx          : LongWord;
    FVrtBuff      : IGeomBuffer;
    RenderTechnique : array[TTehniqueType] of TTehnique;

    Tehnique       : TTehniqueType;
    BatchTexture   : array[1..3] of ITexture;

    FDataBuff : array[1..Batch_Size*4] of TVec4f;
    FVertexBuff : array[1..Batch_Size*4] of TVec2f;
  public
    procedure Init;

    procedure ResolutionCorrect(Width, Height: LongWord); stdcall;
  //  procedure SetScaleMode(
    procedure UpdateRC;
    function  GetEnableRC: Boolean; stdcall;
    procedure SetEnableRC(Value: Boolean); stdcall;
    function  GetRCWidth: LongWord; stdcall;
    function  GetRCHeight: LongWord; stdcall;
    function  GetRCRect: TRecti; stdcall;
    function  GetRCScale: Single; stdcall;
    function  GetRCMatrix: TMat4f; stdcall;

    function  GetRotCenter: TVec2f; stdcall;
    procedure SetRotCenter(const Value: TVec2f); stdcall;

    class procedure FlushProc(Param: LongInt; Data: Pointer); static; stdcall;
    class procedure DisplayRestore(Param: LongInt; Data: Pointer); static; stdcall;

    procedure BatchBegin; stdcall;
    procedure BatchEnd; stdcall;
    procedure Flush;

    procedure RealDrawSprite(Tex: ITexture; const v: TQuad; const Data1, Data2, Data3, Data4: TVec4f; Effects: Cardinal);
    procedure DrawSprite(Tex: ITexture; x, y, w, h: Single; const Color1, Color2, Color3, Color4: TVec4f; Angle: Single; Effects: Cardinal); overload; stdcall;
    procedure DrawSprite(Tex: ITexture; x, y, w, h: Single; const Color: TVec4f; Angle: Single; Effects: Cardinal); overload; stdcall;

    procedure BeginDraw(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture); stdcall;
    procedure SetData(const Data1, Data2, Data3, Data4: TVec4f); stdcall;
    procedure DrawQuad(x, y, w, h, Angle: Single); overload; stdcall;
    procedure DrawQuad(const v1, v2, v3, v4: TVec2f; Angle: Single; const Center: TVec2f); overload; stdcall;
    procedure EndDraw; stdcall;
  end;

implementation

uses
  JEN_Main;

procedure TehniqueInit(var Tehnique: TTehnique; Shader: IShaderProgram);
var
  i: LongInt;
  Uniform : IShaderUniform;
begin
  if Assigned(Shader) then
    with Tehnique do
    begin
      LastUsed := Helpers.Time;
      ShaderProgram := Shader;
      ShaderProgram.Bind;

      VBUniform := ShaderProgram.Uniform('Position', utVec2, False);
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
  i : Integer;
  IdxBuff : array[1..Batch_Size*4] of Single;
  Shader : IShaderProgram;
begin
  FRCWidth := Render.Viewport.Width;
  FRCHeight := Render.Viewport.Height;
  for I := 1 to Batch_Size*4 do
    IdxBuff[i] := i-1;

  FRotCenter := Vec2f(0.5, 0.5);

  FVrtBuff := TGeomBuffer.Create(gbVertex, Batch_Size*4, 4, @IdxBuff[1]);

  ResMan.Load('|SpriteShader.xml', FNormalShader);
  FNormalShader.Compile(Shader);
  TehniqueInit(RenderTechnique[ttNormal], Shader);

  ResMan.Load('|TextShader.xml', FTextShader);
  FTextShader.Compile(Shader);
  TehniqueInit(RenderTechnique[ttText], Shader);

  Engine.AddEventListener(evRenderFlush, {$IFDEF FPC}Pointer(FlushProc){$ELSE}@FlushProc{$ENDIF});
  Engine.AddEventListener(evDisplayRestore, {$IFDEF FPC}Pointer(DisplayRestore){$ELSE}@DisplayRestore{$ENDIF});
end;

procedure TRender2D.Free; stdcall;
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

procedure TRender2D.ResolutionCorrect(Width, Height: LongWord); stdcall;
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
    FRCScale := Max(FRCWidth/Render.Viewport.Width, FRCHeight/Render.Viewport.Height);
    BorderV  := Round((Render.Viewport.Width - FRCWidth/FRCScale)/2);
    BorderH  := Round((Render.Viewport.Height - FRCHeight/FRCScale)/2);
    FRCRect  := Recti(BorderV, BorderH, Render.Viewport.Width - BorderV*2, Render.Viewport.Height - BorderH*2);
    FRCMatrix.Ortho(0, FRCWidth, FRCHeight, 0, -1, 1);
    Render.Viewport := FRCRect;
  end else
  begin
    FRCScale  := 1;
    FRCRect   := Render.Viewport;//Recti(0, 0, Display.Width, Display.Height);
    FRCMatrix.Ortho(0, Render.Viewport.Width, Render.Viewport.Height, 0, -1, 1);
  end;

  Render.Matrix[mt2DMat] := FRCMatrix;
end;

function TRender2D.GetEnableRC: Boolean; stdcall;
begin
  Result := FEnableRC;
end;

procedure TRender2D.SetEnableRC(Value: Boolean); stdcall;
begin
  if Value <> FEnableRC then
  begin
    FEnableRC := Value;
    UpdateRC;
  end;
end;

function TRender2D.GetRCWidth: LongWord; stdcall;
begin
  Result := FRCWidth;
end;

function TRender2D.GetRCHeight: LongWord; stdcall;
begin
  Result := FRCHeight;
end;

function TRender2D.GetRCRect: TRecti; stdcall;
begin
  Result := FRCRect
end;

function TRender2D.GetRCScale: Single; stdcall;
begin
  Result := FRCScale
end;

function TRender2D.GetRCMatrix: TMat4f; stdcall;
begin
  Result := FRCMatrix;
end;

function TRender2D.GetRotCenter: TVec2f; stdcall;
begin
  Result := FRotCenter;
end;

procedure TRender2D.SetRotCenter(const Value: TVec2f); stdcall;
begin
  FRotCenter := Value;
end;

class procedure TRender2D.FlushProc(Param: LongInt; Data: Pointer); stdcall;
begin
  Render2d.Flush;
end;

class procedure TRender2D.DisplayRestore(Param: LongInt; Data: Pointer); stdcall;
begin
  Render2d.UpdateRC;
end;

procedure TRender2D.BatchBegin; stdcall;
begin
  Flush;
  FBatch := True;
end;

procedure TRender2D.BatchEnd; stdcall;
begin
  Flush;
  FBatch := False;
end;

procedure TRender2D.Flush;
begin
  if FIdx = 0 then Exit;

  FVrtBuff.Bind;
  with RenderTechnique[Tehnique] do
  begin
    IndxAttrib.Value(4, 0);
    IndxAttrib.Enable;

    VBUniform.Value(FVertexBuff[1], FIdx*4);
    if Assigned(DBUniform) then
      DBUniform.Value(FDataBuff[1], FIdx*4);
  end;
  FVrtBuff.Draw(gmQuads, FIdx*4, False);

  FIdx := 0;
  Render.IncDip;
end;

function ComputeVertex(var v: TQuad; Angle: Single; const Center: TVec2f): Boolean; inline;
var
  tsin, tcos  : Single;
  MinX, MinY, MaxX, MaxY: Single;
begin
  if Abs(Angle) > EPS then
  begin
    {Mat := Mat4f(Deg2Rad*Angle, Vec3f(0, 0, 1));
    Mat.Pos := Vec3f(Center.x, Center.y, 0);
    Mat.Translate(Vec3f(-Center.x, -Center.y, 0));

    v[1] := Render.Matrix[mt2DMat]*(Mat*v1);
    v[2] := Render.Matrix[mt2DMat]*(Mat*v2);
    v[3] := Render.Matrix[mt2DMat]*(Mat*v3);
    v[4] := Render.Matrix[mt2DMat]*(Mat*v4); }

    sincos(Deg2Rad*Angle, tsin, tcos);
    v[1] := v[1] - Center;
    v[2] := v[2] - Center;
    v[3] := v[3] - Center;
    v[4] := v[4] - Center;
	  v[1] := Vec2f(v[1].x*tcos - v[1].y*tsin, v[1].x*tsin + v[1].y*tcos);
    v[2] := Vec2f(v[2].x*tcos - v[2].y*tsin, v[2].x*tsin + v[2].y*tcos);
    v[3] := Vec2f(v[3].x*tcos - v[3].y*tsin, v[3].x*tsin + v[3].y*tcos);
    v[4] := Vec2f(v[4].x*tcos - v[4].y*tsin, v[4].x*tsin + v[4].y*tcos);
    v[1] := Render.Matrix[mt2DMat]*(v[1] + Center);
    v[2] := Render.Matrix[mt2DMat]*(v[2] + Center);
    v[3] := Render.Matrix[mt2DMat]*(v[3] + Center);
    v[4] := Render.Matrix[mt2DMat]*(v[4] + Center);
  end else
  begin
    v[1] := Render.Matrix[mt2DMat]*v[1];
    v[2] := Render.Matrix[mt2DMat]*v[2];
    v[3] := Render.Matrix[mt2DMat]*v[3];
    v[4] := Render.Matrix[mt2DMat]*v[4];
  end;

  MinX := Min(Min(Min(v[1].x, v[2].x), v[3].x), v[4].x);
  MinY := Min(Min(Min(v[1].y, v[2].y), v[3].y), v[4].y);
  MaxX := Max(Max(Max(v[1].x, v[2].x), v[3].x), v[4].x);
  MaxY := Max(Max(Max(v[1].y, v[2].y), v[3].y), v[4].y);
  Result := ((((MaxX >= -1) and (MinX <= 1)) and (MaxY >= -1)) and (MinY <= 1));
end;

procedure TRender2D.RealDrawSprite(Tex: ITexture; const v: TQuad; const Data1, Data2, Data3, Data4: TVec4f; Effects: Cardinal);
var
  TCParams    : TVec4f;
begin
  if( (FIdx = 0) or (FBatch = False) or (BatchTexture[1] <> Tex) or (Tehnique <> ttNormal)) then
  begin
    if FIdx > 0 then
      Flush;

    Tehnique := ttNormal;
    RenderTechnique[ttNormal].ShaderProgram.Bind;

    Tex.Bind(0);
    TCParams := Tex.CoordParams;
    RenderTechnique[Tehnique].TCParUniform1.Value(TCParams);
    BatchTexture[1] := Tex;
  end;

  Move(v[1], FVertexBuff[FIdx*4+1], sizeof(TVec2f)*4);
  FDataBuff[FIdx*4+1] := Data1;
  FDataBuff[FIdx*4+2] := Data2;
  FDataBuff[FIdx*4+3] := Data3;
  FDataBuff[FIdx*4+4] := Data4;

  inc(FIdx);
  if (FIdx = Batch_Size) or (FBatch = False) then
    Flush;
end;

procedure TRender2D.DrawSprite(Tex: ITexture; x, y, w, h: Single; const Color1, Color2, Color3, Color4: TVec4f; Angle: Single; Effects: Cardinal);
var
  v : TQuad;
begin
  if not (Assigned(Tex)) then Exit;
  v[1] := Vec2f(x, y+h);
  v[2] := Vec2f(x+w, y+h);
  v[3] := Vec2f(x+w, y);
  v[4] := Vec2f(x, y);
  if not ComputeVertex(v, Angle, Vec2f(x, y) + Vec2f(w, h) * FRotCenter) then
    exit;
  RealDrawSprite(Tex, v, Color1, Color2, Color3, Color4, Effects);
end;

procedure TRender2D.DrawSprite(Tex: ITexture; x, y, w, h: Single; const Color: TVec4f; Angle: Single; Effects: Cardinal);
var
  v : TQuad;
begin
  if not (Assigned(Tex)) then Exit;
  v[1] := Vec2f(x, y+h);
  v[2] := Vec2f(x+w, y+h);
  v[3] := Vec2f(x+w, y);
  v[4] := Vec2f(x, y);
  if not ComputeVertex(v, Angle, Vec2f(x, y) + Vec2f(w, h) * FRotCenter) then
    exit;
  RealDrawSprite(Tex, v, Color, Color, Color, Color, Effects);
end;

procedure TRender2D.BeginDraw(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture);
var
  Teh         : TTehniqueType;
  OlderTime   : LongInt;
  OlderTeh    : TTehniqueType;
  TCParams    : TVec4f;
begin
  if not Assigned(Shader) then
    Exit;

  if( (FIdx = 0) or (FBatch = False) or (RenderTechnique[Tehnique].ShaderProgram <> Shader) or
      (BatchTexture[1] <> Tex1) or (BatchTexture[2] <> Tex2) or (BatchTexture[3] <> Tex3) ) then
  begin
    if FIdx > 0 then
      Flush;

    OlderTeh   := ttAdvanced;
    OlderTime  := RenderTechnique[ttAdvanced].LastUsed;
    Tehnique   := ttNone;

    for Teh := ttNormal to High(TTehniqueType) do
    with RenderTechnique[Teh] do
    if ShaderProgram = Shader then
    begin
      LastUsed := Helpers.Time;
      Tehnique := Teh;
      Break;
    end else
      if (OlderTime>LastUsed) and (Teh >= ttAdvanced) then
      begin
        OlderTime := LastUsed;
        OlderTeh  := Teh;
      end;

    if Tehnique = ttNone then
    begin
      TehniqueInit(RenderTechnique[OlderTeh], Shader);
      Tehnique := OlderTeh;
    end;

    RenderTechnique[Tehnique].ShaderProgram.Bind;

    if Assigned(Tex1) then
    begin
      Tex1.Bind(0);
      TCParams := Tex1.CoordParams;
      RenderTechnique[Tehnique].TCParUniform1.Value(TCParams);
    end;

    if Assigned(Tex2) then
    begin
      Tex2.Bind(1);
      TCParams := Tex2.CoordParams;
      RenderTechnique[Tehnique].TCParUniform2.Value(TCParams);
    end;

   if Assigned(Tex3) then
    begin
      Tex3.Bind(2);
      TCParams := Tex3.CoordParams;
      RenderTechnique[Tehnique].TCParUniform3.Value(TCParams);
    end;
  end;
end;

procedure TRender2D.DrawQuad(x, y, w, h, Angle: Single);
var
   v : TQuad;
begin
  v[1] := Vec2f(x, y+h);
  v[2] := Vec2f(x+w, y+h);
  v[3] := Vec2f(x+w, y);
  v[4] := Vec2f(x, y);
  if not ComputeVertex(v, Angle, Vec2f(x, y) + Vec2f(w, h) * FRotCenter) then
    exit;

  Move(v[1], FVertexBuff[FIdx*4+1], sizeof(TVec2f)*4);

  inc(FIdx);
  if (FIdx = Batch_Size) then
    Flush;
end;

procedure TRender2D.DrawQuad(const v1, v2, v3, v4: TVec2f; Angle: Single; const Center: TVec2f);
var
   v : TQuad;
begin
  v[1] := v1;
  v[2] := v2;
  v[3] := v3;
  v[4] := v4;
  if not ComputeVertex(v, Angle, Center) then
    exit;

  Move(v[1], FVertexBuff[FIdx*4+1], sizeof(TVec2f)*4);

  inc(FIdx);
  if (FIdx = Batch_Size) then
    Flush;
end;

procedure TRender2D.SetData(const Data1, Data2, Data3, Data4: TVec4f);
begin
  FDataBuff[FIdx*4+1] := Data1;
  FDataBuff[FIdx*4+2] := Data2;
  FDataBuff[FIdx*4+3] := Data3;
  FDataBuff[FIdx*4+4] := Data4;
end;

procedure TRender2D.EndDraw;
begin
  if not FBatch then
    Flush;
end;


end.
