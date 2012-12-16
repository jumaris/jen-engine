unit JEN_RenderEntity;

interface


uses
  JEN_OpenGLHeader,
  JEN_Helpers,
  JEN_Header;

type           {
  IRenderEntity= interface(JEN_Header.IRenderEntity)
    function Init stdcall;
  end;
                       }
  TRenderEntity = class(TInterfacedObject, IRenderEntity)
    constructor Create(Shader: IShaderProgram);
    destructor Destroy; override;
  class var
    CurrentVAO    : GLhandle;
  private
    FValid        : Boolean;
    FID           : GLhandle;
    FShader       : IShaderProgram;
    FIdxBuffer    : IGeomBuffer;
    FBufferList   : TInterfaceList;
  public
    function Valid: Boolean; stdcall;
    function GetID: LongWord; stdcall;
 //   function Init(Shader: IShaderProgram); stdcall;
    procedure AttachAndBind(Buffer: IGeomBuffer); stdcall;
    procedure Attrib(AName: PWideChar; AttribType: TShaderAttribType; Stride, Offset: LongInt; Norm, Necessary: Boolean); stdcall;
    procedure Draw(mode: TGeomMode; count: LongInt; Indexed: Boolean; first: LongInt); stdcall;
    procedure Bind;
  end;

implementation

uses
  JEN_Main;

constructor TRenderEntity.Create(Shader: IShaderProgram);
begin
  glGenVertexArrays(1, @FID);
  FBufferList := TInterfaceList.Create;

  if not Assigned(Shader) then
  begin
    Engine.Warning('Shader programm must be not null');
    FValid := False;
    Exit;
  end;

  FValid  := True;
  FShader := Shader;
end;

destructor TRenderEntity.Destroy;
begin
  glDeleteVertexArrays(1, @FID);
  FBufferList.Free;
end;

function TRenderEntity.Valid: Boolean;
begin
  Result := FValid;
end;

function TRenderEntity.GetID: LongWord;
begin
  Result := FID;
end;
         {
function TRenderEntity.Init(Shader: IShaderProgram);
begin
  if not Assigned(Shader) then
  begin
    Engine.Warning('Shader programm must be not null');
    FValid := False;
    glDeleteVertexArrays(1, @FID);
    Exit;
  end;
  FValid  := True;
  FShader := Shader;
end;
                  }
procedure TRenderEntity.AttachAndBind(Buffer: IGeomBuffer);
begin
  if not (Assigned(Buffer) and FValid) then
    Exit;

  Bind;

  if Buffer.GType = gbIndex then
    FIdxBuffer := Buffer
  else
    FBufferList.Add(Buffer);

  Buffer.Bind;
end;

procedure TRenderEntity.Attrib(AName: PWideChar; AttribType: TShaderAttribType; Stride, Offset: LongInt; Norm, Necessary: Boolean);
var
  Attrib: IShaderAttrib;
begin
  if not FValid then
    Exit;

  Bind;
  Attrib := FShader.Attrib(AName, AttribType, Necessary);
  Attrib.Enable;
  Attrib.Value(Stride, Offset, Norm);
end;

procedure TRenderEntity.Bind;
begin
  if (not FValid) or (CurrentVAO = FID) then
    Exit;

  glBindVertexArray(FID);
  CurrentVAO := FID;
end;

procedure TRenderEntity.Draw(mode: TGeomMode; count: LongInt; Indexed: Boolean; first: LongInt);
const
  IndexType  : array [1..4] of GLenum = (GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT, GL_FALSE, GL_UNSIGNED_INT);
var
  Index: Int64;
begin
  Bind;
  if Assigned(FIdxBuffer) then
  begin
    Index := FIdxBuffer.PrimitiveRestartIndex;
    if Index <> -1 then
    begin
      glEnable(JEN_PRIMITIVE_RESTART);
      glPrimitiveRestartIndex(Index);
    end;

    glDrawElements(GLenum(mode), count, IndexType[FIdxBuffer.Stride], nil);

    if Index <> -1 then
      glDisable(JEN_PRIMITIVE_RESTART);

  end else
    glDrawArrays(GLenum(mode), first, count);
end;

initialization
  TRenderEntity.CurrentVAO := High(GLHandle);

end.
