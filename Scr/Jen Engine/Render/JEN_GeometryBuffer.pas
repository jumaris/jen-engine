unit JEN_GeometryBuffer;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  JEN_Header,
  JEN_OpenGLHeader;

type
  TGeomBuffer = class(TInterfacedObject, IGeomBuffer)
    constructor Create(GBufferType: TGBufferType; Count, Stride: LongInt; Data: Pointer);
   // class function Load(BufferType: TBufferType; Stream: TStream): TMeshBuffer;
    destructor Destroy; override;
  private
    FType  : GLenum;
    FID    : LongWord;
  public
    Count  : LongInt;
    Stride : LongInt;
    procedure SetData(Offset, Size: LongInt; Data: Pointer); stdcall;
    procedure Bind; stdcall;
    procedure Draw(mode: TGeomMode; count: LongInt; Indexed: Boolean; first: LongInt = 0); stdcall;
  end;

implementation

constructor TGeomBuffer.Create(GBufferType: TGBufferType; Count, Stride: LongInt; Data: Pointer);
begin
  inherited Create;
  Self.Count  := Count;
  Self.Stride := Stride;
  if GBufferType = gbIndex then
    FType := GL_ELEMENT_ARRAY_BUFFER
  else
    FType := GL_ARRAY_BUFFER;

  glGenBuffers(1, @FID);
  glBindBuffer(FType, FID);
  glBufferData(FType, Count * Stride, Data, GL_STREAM_DRAW );
end;

destructor TGeomBuffer.Destroy;
begin
  glDeleteBuffers(1, @FID);
  inherited;
end;

procedure TGeomBuffer.SetData(Offset, Size: LongInt; Data: Pointer);
type
  TByteArray = array[0..0] of Byte;
//var
//  p : ^TByteArray;
begin
 // Bind;
  //glBufferData(FType, size, nil, GL_STREAM_DRAW );
  {
  P := glMapBuffer(FType, GL_WRITE_ONLY);
  Move(Data^, P[Offset], Size);
  glUnmapBuffer(FType);
   }
  glBufferSubData(FType, offset, size, data);
end;

procedure TGeomBuffer.Bind;
begin
  glBindBuffer(FType, FID);
end;

procedure TGeomBuffer.Draw(mode: TGeomMode; count: LongInt; Indexed: Boolean; first: LongInt = 0); stdcall;
begin
  if Indexed then

  else
    glDrawArrays(GLenum(mode), first, count);
end;

end.
