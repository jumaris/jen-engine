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
    constructor Create;
    destructor Destroy; override;
  class var
    CurrentVAO    : GLhandle;
  private
    FValid        : Boolean;
    FID           : GLhandle;
    FIdxBuffer    : IGeomBuffer;
    FBufferList   : TInterfaceList;
  public
    function Valid: Boolean; stdcall;
    function GetID: LongWord; stdcall;
    procedure AttachAndBind(Buffer: IGeomBuffer); stdcall;
    procedure BindAttrib(Attrib: IShaderAttrib; Stride, Offset: LongInt; Norm: Boolean); overload; stdcall;
    procedure BindAttrib(Location: LongInt; AType: TShaderAttribType; Stride, Offset: LongInt; Norm: Boolean); overload; stdcall;
    procedure Draw(mode: TGeomMode; count: LongInt; first: LongInt); stdcall;
    procedure Bind;
  end;

implementation

uses
  JEN_Shader,
  JEN_Main;

constructor TRenderEntity.Create;
begin
  glGenVertexArrays(1, @FID);
  FBufferList := TInterfaceList.Create;
  FValid  := True;
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
  if not FValid then
    Exit;

  if not Assigned(Buffer) then
  begin
    Engine.Warning('Buffer must be assigned');
    Exit;
  end;

  Bind;

  if Buffer.GType = gbIndex then
    FIdxBuffer := Buffer
  else
    FBufferList.Add(Buffer);

  Buffer.Bind;
end;

procedure TRenderEntity.BindAttrib(Attrib: JEN_Header.IShaderAttrib; Stride, Offset: LongInt; Norm: Boolean);
begin
  if not Assigned(Attrib) then
  begin
    Engine.Warning('Attribute must be assigned');
    Exit;
  end;

  BindAttrib(IShaderAttrib(Attrib).Location, Attrib.AType, Stride, Offset, Norm);
end;

procedure TRenderEntity.BindAttrib(Location: LongInt; AType: TShaderAttribType; Stride, Offset: LongInt; Norm: Boolean);
var
  DType : GLEnum;
  Size  : LongInt;
begin
  if not FValid then
    Exit;

  if Location <> -1 then
  begin
    Bind;
    glEnableVertexAttribArray(Location);
    case AType of
      atVec1b..atVec4b: DType := GL_UNSIGNED_BYTE;
      atVec1s..atVec4s: DType := GL_SHORT;
      atVec1f..atVec4f: DType := GL_FLOAT;
      else Exit;
    end;
    Size := (Byte(AType) - 1) mod 4 + 1;
    glVertexAttribPointer(Location, Size, DType, Norm, Stride, Pointer(Offset));
  end;
end;

procedure TRenderEntity.Bind;
begin
  if (not FValid) or (CurrentVAO = FID) then
    Exit;

  glBindVertexArray(FID);
  CurrentVAO := FID;
end;

procedure TRenderEntity.Draw(mode: TGeomMode; count: LongInt; first: LongInt);
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
