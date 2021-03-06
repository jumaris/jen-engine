unit JEN_Render2D;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_GeometryBuffer;

const
  Batch_Size = 15;

type
  IRender2D = interface(JEN_Header.IRender2D)
    procedure Init;
    procedure Flush;
    procedure UpdateRC;
  end;

  TVertex = record
    Pos : TVec2f;
    Tc  : TVec2f;
  end;

  TQuad = array[1..4] of TVertex;
  TTehniqueType = (ttNone, ttNormal, ttText, ttAdvanced, ttAdvanced1, ttAdvanced2, ttAdvanced3, ttAdvanced4);

  TTehnique = record
    VBUniform     : IShaderUniform;
    DBUniform     : IShaderUniform;
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
    FIdxBuff      : IGeomBuffer;
    RenderEntity  : IRenderEntity;
    RenderTechnique : array[TTehniqueType] of TTehnique;

    Tehnique       : TTehniqueType;
    BatchTexture   : array[1..3] of ITextureFrame;

    FDataBuff : array[1..Batch_Size*4] of TVec4f;
    FVertexBuff : array[1..Batch_Size*4] of TVertex;
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

    procedure TehniqueInit(var Tehnique: TTehnique; Shader: IShaderProgram);

    procedure RealDrawSprite(Tex: ITextureFrame; const v: TQuad; const Data1, Data2, Data3, Data4: TVec4f; Effects: Cardinal);
    procedure DrawSprite(Tex: ITextureFrame; x, y, w, h: Single; const Color1, Color2, Color3, Color4: TVec4f; Angle: Single; Effects: Cardinal); overload; stdcall;
    procedure DrawSprite(Tex: ITextureFrame; x, y, w, h: Single; const Color: TVec4f; Angle: Single; Effects: Cardinal); overload; stdcall;

    procedure BeginDraw(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITextureFrame); stdcall;
    procedure SetData(const Data1, Data2, Data3, Data4: TVec4f); stdcall;
    procedure DrawQuad(x, y, w, h, Angle: Single); overload; stdcall;
    procedure DrawQuad(const v1, v2, v3, v4: TVec2f; Angle: Single; const Center: TVec2f); overload; stdcall;
    procedure EndDraw; stdcall;
  end;

const
  TexCoord: array[0..3] of array[1..4] of TVec2f = (((x:1;y:1),(x:1;y:0),(x:0;y:1),(x:0;y:0)),
                                                    ((x:1;y:0),(x:0;y:0),(x:0;y:1),(x:1;y:1)),
                                                    ((x:0;y:1),(x:1;y:1),(x:1;y:0),(x:0;y:0)),
                                                    ((x:1;y:1),(x:0;y:1),(x:0;y:0),(x:1;y:0)));

  {
  TexCoord: array[0..3] of array[1..4] of TVec2f = (((x:0;y:0),(x:1;y:0),(x:1;y:1),(x:0;y:1)),
                                                    ((x:1;y:0),(x:0;y:0),(x:0;y:1),(x:1;y:1)),
                                                    ((x:0;y:1),(x:1;y:1),(x:1;y:0),(x:0;y:0)),
                                                    ((x:1;y:1),(x:0;y:1),(x:0;y:0),(x:1;y:0)));
                 }
implementation

uses
  JEN_Main;

procedure TRender2D.TehniqueInit(var Tehnique: TTehnique; Shader: IShaderProgram);
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

      VBUniform := ShaderProgram.Uniform('PosTC', utVec4, False);
      DBUniform := ShaderProgram.Uniform('QuadData', utVec4, False);

      i := 0;
      Uniform := ShaderProgram.Uniform('Map0', utInt, False);
      if Assigned(Uniform) then
        Uniform.Value(i);

      i := 1;
      Uniform := ShaderProgram.Uniform('Map1', utInt, False);
      if Assigned(Uniform) then
        Uniform.Value(i);
    end;
end;

procedure TRender2D.Init;
var
  i, k : Integer;
  SIdxBuff : array[0..Batch_Size * 4 - 1] of Single;
  IIdxBuff : array[0..Batch_Size * 6 - 3] of Byte;
  Shader : IShaderProgram;
begin
  FRCWidth := Render.Viewport.Width;
  FRCHeight := Render.Viewport.Height;
  for I := 0 to Batch_Size * 4 - 1 do
    SIdxBuff[i] := i;
  FVrtBuff := TGeomBuffer.Create(gbVertex, Batch_Size * 4, 4, @SIdxBuff[0]);

  i := 0; k := 0;
  while i < (Batch_Size * 6) - 3 do
  begin

    if (I > 3) then
    begin
      IIdxBuff[i] := k-1;
      IIdxBuff[i+1] := k;

      inc(i, 2);
    end;

    for i := i to i + 3 do
    begin
      IIdxBuff[i] := k;
      inc(k);
    end;

  end;
  FIdxBuff := TGeomBuffer.Create(gbIndex, (Batch_Size * 6) - 2, 1, @IIdxBuff[0]);

  RenderEntity := Render.CreateRenderEntity;
  RenderEntity.AttachAndBind(FIdxBuff);
  RenderEntity.AttachAndBind(FVrtBuff);
  RenderEntity.BindAttrib(0, atVec1f, 4, 0);

  FRotCenter := Vec2f(0.5, 0.5);


  ResMan.Load('|SpriteShader.xml', FNormalShader);
  FNormalShader.GetShader(Shader);
  TehniqueInit(RenderTechnique[ttNormal], Shader);

  ResMan.Load('|TextShader.xml', FTextShader);
  FTextShader.GetShader(Shader);
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
  Engine.RemoveEventListener(evRenderFlush, {$IFDEF FPC}Pointer(FlushProc){$ELSE}@FlushProc{$ENDIF});
  Engine.RemoveEventListener(evDisplayRestore, {$IFDEF FPC}Pointer(DisplayRestore){$ELSE}@DisplayRestore{$ENDIF});
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
    FRCMatrix.Ortho(0, FRCWidth + BorderV * 2, FRCHeight + BorderH * 2, 0, -1, 1);
   // Render.Viewport := FRCRect;
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

  with RenderTechnique[Tehnique] do
  begin
    VBUniform.Value(FVertexBuff[1], FIdx*4);
    if Assigned(DBUniform) then
      DBUniform.Value(FDataBuff[1], FIdx*4);
    RenderEntity.Draw(gmTriangleStrip, FIdx * 6 - 2);
  end;
  //FVrtBuff.Draw(gmQuads, FIdx*4, False);

  FIdx := 0;
  Render.IncDip;
end;

procedure PrepareVertex(var v: TQuad; const Pos, Size: TVec2f; Rect: TRectf; TcId: Integer); overload; inline;
begin
  v[1].Pos := Pos + Vec2f(0, Size.y);
  v[2].Pos := Pos + Size;
  v[3].Pos := Pos + Vec2f(Size.x, 0);
  v[4].Pos := Pos;

  v[1].TC := TexCoord[TcId][1] * Rect.Size + Rect.Location;
  v[2].TC := TexCoord[TcId][2] * Rect.Size + Rect.Location;
  v[3].TC := TexCoord[TcId][3] * Rect.Size + Rect.Location;
  v[4].TC := TexCoord[TcId][4] * Rect.Size + Rect.Location;
end;

procedure PrepareVertex(var v: TQuad; const v1, v2, v3, v4, Rect: TVec2f); overload; inline;
begin

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
    v[1].Pos := v[1].Pos - Center;
    v[2].Pos := v[2].Pos - Center;
    v[3].Pos := v[3].Pos - Center;
    v[4].Pos := v[4].Pos - Center;
	  v[1].Pos := Vec2f(v[1].Pos.x*tcos - v[1].Pos.y*tsin, v[1].Pos.x*tsin + v[1].Pos.y*tcos);
    v[2].Pos := Vec2f(v[2].Pos.x*tcos - v[2].Pos.y*tsin, v[2].Pos.x*tsin + v[2].Pos.y*tcos);
    v[3].Pos := Vec2f(v[3].Pos.x*tcos - v[3].Pos.y*tsin, v[3].Pos.x*tsin + v[3].Pos.y*tcos);
    v[4].Pos := Vec2f(v[4].Pos.x*tcos - v[4].Pos.y*tsin, v[4].Pos.x*tsin + v[4].Pos.y*tcos);
    v[1].Pos := Render.Matrix[mt2DMat]*(v[1].Pos + Center);
    v[2].Pos := Render.Matrix[mt2DMat]*(v[2].Pos + Center);
    v[3].Pos := Render.Matrix[mt2DMat]*(v[3].Pos + Center);
    v[4].Pos := Render.Matrix[mt2DMat]*(v[4].Pos + Center);
  end else
  begin
    v[1].Pos := Render.Matrix[mt2DMat]*v[1].Pos;
    v[2].Pos := Render.Matrix[mt2DMat]*v[2].Pos;
    v[3].Pos := Render.Matrix[mt2DMat]*v[3].Pos;
    v[4].Pos := Render.Matrix[mt2DMat]*v[4].Pos;
  end;

  MinX := Min(Min(Min(v[1].Pos.x, v[2].Pos.x), v[3].Pos.x), v[4].Pos.x);
  MinY := Min(Min(Min(v[1].Pos.y, v[2].Pos.y), v[3].Pos.y), v[4].Pos.y);
  MaxX := Max(Max(Max(v[1].Pos.x, v[2].Pos.x), v[3].Pos.x), v[4].Pos.x);
  MaxY := Max(Max(Max(v[1].Pos.y, v[2].Pos.y), v[3].Pos.y), v[4].Pos.y);
  Result := ((((MaxX >= -1) and (MinX <= 1)) and (MaxY >= -1)) and (MinY <= 1));
end;

procedure TRender2D.RealDrawSprite(Tex: ITextureFrame; const v: TQuad; const Data1, Data2, Data3, Data4: TVec4f; Effects: Cardinal);
var
  TCParams    : TVec4f;
begin
  if( (FIdx = 0) or (FBatch = False) or (not Assigned(BatchTexture[1])) or (BatchTexture[1].Texture.ID <> Tex.Texture.ID) or (Tehnique <> ttNormal)) then
  begin
    if FIdx > 0 then
      Flush;

    Tehnique := ttNormal;
    RenderTechnique[ttNormal].ShaderProgram.Bind;

    Tex.Texture.Bind;
  end;
  BatchTexture[1] := Tex;

  Move(v[1], FVertexBuff[FIdx*4+1], sizeof(TVertex)*4);
  FDataBuff[FIdx*4+1] := Data1;
  FDataBuff[FIdx*4+2] := Data2;
  FDataBuff[FIdx*4+3] := Data3;
  FDataBuff[FIdx*4+4] := Data4;

  inc(FIdx);
  if (FIdx = Batch_Size) or (FBatch = False) then
    Flush;
end;

procedure TRender2D.DrawSprite(Tex: ITextureFrame; x, y, w, h: Single; const Color1, Color2, Color3, Color4: TVec4f; Angle: Single; Effects: Cardinal);
var
  v     : TQuad;
  maxTC : TVec2f;
  TexRect: TRectf;
  TcId  : LongInt;
begin
  if not (Assigned(Tex)) then Exit;

  v[1].Pos := Vec2f(x+w, y+h);
  v[2].Pos := Vec2f(x+w, y  );
  v[3].Pos := Vec2f(x,   y+h);
  v[4].Pos := Vec2f(x,   y  );
                 {
  v[1].Pos := Vec2f(x  , y+h);
  v[2].Pos := Vec2f(x+w, y+h);
  v[3].Pos := Vec2f(x+w, y  );
  v[4].Pos := Vec2f(x  , y  ); }

  TexRect := Tex.TextureRect;
  maxTC := Vec2f(TexRect.Width, TexRect.Height);
  TcId := (Effects and FX_FLIPX + Effects and FX_FLIPY);
  v[1].TC := TexCoord[TcId][1] * maxTC + TexRect.Location;
  v[2].TC := TexCoord[TcId][2] * maxTC + TexRect.Location;
  v[3].TC := TexCoord[TcId][3] * maxTC + TexRect.Location;
  v[4].TC := TexCoord[TcId][4] * maxTC + TexRect.Location;


  if not ComputeVertex(v, Angle, Vec2f(x, y) + Vec2f(w, h) * FRotCenter) then
    exit;
  RealDrawSprite(Tex, v, Color1, Color2, Color3, Color4, Effects);
end;

procedure TRender2D.DrawSprite(Tex: ITextureFrame; x, y, w, h: Single; const Color: TVec4f; Angle: Single; Effects: Cardinal);
var
  v : TQuad;
  maxTC : TVec2f;
  TexRect: TRectf;
  TcId: LongInt;
begin
  if not (Assigned(Tex)) then Exit;

  v[1].Pos := Vec2f(x+w, y+h);
  v[2].Pos := Vec2f(x+w, y  );
  v[3].Pos := Vec2f(x,   y+h);
  v[4].Pos := Vec2f(x,   y  );
                 {
  v[1].Pos := Vec2f(x  , y+h);
  v[2].Pos := Vec2f(x+w, y+h);
  v[3].Pos := Vec2f(x+w, y  );
  v[4].Pos := Vec2f(x  , y  ); }

  TexRect := Tex.TextureRect;
  maxTC := Vec2f(TexRect.Width, TexRect.Height);
  TcId := (Effects and FX_FLIPX + Effects and FX_FLIPY);
  v[1].TC := TexCoord[TcId][1] * maxTC + TexRect.Location;
  v[2].TC := TexCoord[TcId][2] * maxTC + TexRect.Location;
  v[3].TC := TexCoord[TcId][3] * maxTC + TexRect.Location;
  v[4].TC := TexCoord[TcId][4] * maxTC + TexRect.Location;

  if not ComputeVertex(v, Angle, Vec2f(x, y) + Vec2f(w, h) * FRotCenter) then
    exit;
  RealDrawSprite(Tex, v, Color, Color, Color, Color, Effects);
end;

procedure TRender2D.BeginDraw(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITextureFrame);
var
  Teh         : TTehniqueType;
  OlderTime   : LongInt;
  OlderTeh    : TTehniqueType;
  TCParams    : TVec4f;
  TexBath     : Boolean;
begin
  if not Assigned(Shader) then
    Exit;

  TexBath := ((BatchTexture[1] = Tex1) or (Assigned(Tex1) and Assigned(BatchTexture[1]) and (Tex1.Texture.ID = BatchTexture[1].Texture.ID))) and
             ((BatchTexture[2] = Tex2) or (Assigned(Tex2) and Assigned(BatchTexture[2]) and (Tex2.Texture.ID = BatchTexture[2].Texture.ID))) and
             ((BatchTexture[3] = Tex3) or (Assigned(Tex3) and Assigned(BatchTexture[3]) and (Tex3.Texture.ID = BatchTexture[3].Texture.ID)));

  if( (FIdx = 0) or (FBatch = False) or (TexBath = False) or (RenderTechnique[Tehnique].ShaderProgram <> Shader)) then
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
      Tex1.Texture.Bind(TC_Texture0);

    if Assigned(Tex2) then
      Tex2.Texture.Bind(TC_Texture1);

    if Assigned(Tex3) then
      Tex3.Texture.Bind(TC_Texture2);
  end;

  BatchTexture[1] := Tex1;
  BatchTexture[2] := Tex2;
  BatchTexture[3] := Tex3;
end;

procedure TRender2D.DrawQuad(x, y, w, h, Angle: Single);
var
   v      : TQuad;
   maxTC  : TVec2f;
   TexRect: TRectf;
begin
  v[1].Pos := Vec2f(x+w, y+h);
  v[2].Pos := Vec2f(x+w, y  );
  v[3].Pos := Vec2f(x,   y+h);
  v[4].Pos := Vec2f(x,   y  );

  if Assigned(BatchTexture[1]) then
    TexRect := BatchTexture[1].TextureRect
  else
    TexRect := Rectf(0, 0, 1, 1);


  maxTC := Vec2f(TexRect.Width, TexRect.Height);
  v[1].TC := TexCoord[0][1] * maxTC + TexRect.Location;
  v[2].TC := TexCoord[0][2] * maxTC + TexRect.Location;
  v[3].TC := TexCoord[0][3] * maxTC + TexRect.Location;
  v[4].TC := TexCoord[0][4] * maxTC + TexRect.Location;

  if not ComputeVertex(v, Angle, Vec2f(x, y) + Vec2f(w, h) * FRotCenter) then
    exit;

  Move(v[1], FVertexBuff[FIdx*4+1], sizeof(TVertex)*4);

  inc(FIdx);
  if (FIdx = Batch_Size) then
    Flush;
end;

procedure TRender2D.DrawQuad(const v1, v2, v3, v4: TVec2f; Angle: Single; const Center: TVec2f);
var
   v   : TQuad;
   maxTC  : TVec2f;
   TexRect: TRectf;
begin
  v[1].Pos := v1;
  v[2].Pos := v2;
  v[3].Pos := v3;
  v[4].Pos := v4;

  if Assigned(BatchTexture[1]) then
    maxTC := BatchTexture[1].Texture.MaxTC
  else
    maxTC := Vec2f(1, 1);

  if Assigned(BatchTexture[1]) then
    TexRect := BatchTexture[1].TextureRect
  else
    TexRect := Rectf(0, 0, 1, 1);

  maxTC := Vec2f(TexRect.Width, TexRect.Height);
  v[1].TC := TexCoord[0][1] * maxTC + TexRect.Location;
  v[2].TC := TexCoord[0][2] * maxTC + TexRect.Location;
  v[3].TC := TexCoord[0][3] * maxTC + TexRect.Location;
  v[4].TC := TexCoord[0][4] * maxTC + TexRect.Location;

  if not ComputeVertex(v, Angle, Center) then
    exit;

  Move(v[1], FVertexBuff[FIdx*4+1], sizeof(TVertex)*4);

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
