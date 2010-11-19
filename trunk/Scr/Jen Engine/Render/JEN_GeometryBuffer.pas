unit JEN_GeometryBuffer;

interface

uses
  XSystem,
  JEN_OpenGLHeader;

type
  TGBufferType = (gbtIndex, gbtVertex);

  TGeomBuffer = class
    constructor Create(GBufferType: TGBufferType; Count, Stride: LongInt; Data: Pointer);
   // class function Load(BufferType: TBufferType; Stream: TStream): TMeshBuffer;
    destructor Destroy; override;
  private
    FType  : GLenum;
    FID    : LongWord;
  public
    Count  : LongInt;
    Stride : LongInt;
    procedure SetData(Offset, Size: LongInt; Data: Pointer);
    procedure Bind;
  end;

implementation

constructor TGeomBuffer.Create(GBufferType: TGBufferType; Count, Stride: LongInt; Data: Pointer);
begin
  Self.Count  := Count;
  Self.Stride := Stride;
  if GBufferType = gbtIndex then
    FType := GL_ELEMENT_ARRAY_BUFFER
  else
    FType := GL_ARRAY_BUFFER;

  glGenBuffersARB(1, @FID);
  glBindBufferARB(FType, FID);
  glBufferDataARB(FType, Count * Stride, Data, GL_STATIC_DRAW);
end;

destructor TGeomBuffer.Destroy;
begin
  glDeleteBuffersARB(1, @FID);
  inherited;
end;

procedure TGeomBuffer.SetData(Offset, Size: LongInt; Data: Pointer);
var
  p : PByteArray;
begin
  Bind;
  P := glMapBufferARB(FType, GL_WRITE_ONLY);
  Move(Data^, P[Offset], Size);
  glUnmapBufferARB(FType);
end;

procedure TGeomBuffer.Bind;
begin
  glBindBufferARB(FType, FID);
end;

end.
