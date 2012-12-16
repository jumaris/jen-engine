unit JEN_GeometryBuffer;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  JEN_OpenGLHeader,
  JEN_Header;

type
  TGeomBuffer = class(TInterfacedObject, IGeomBuffer)
    constructor Create(GBufferType: TGBufferType; Count, Stride: LongInt; Data: Pointer);
   // class function Load(BufferType: TBufferType; Stream: TStream): TMeshBuffer;
    destructor Destroy; override;
  private
    FType   : TGBufferType;
    FID     : GLhandle;
    FCount  : LongInt;
    FStride : LongInt;
    FPRIdx  : Int64;
    function GetType: TGBufferType; stdcall;
    function GetStride: LongInt; stdcall;
    function GetPrimitiveRestartIndex: Int64; stdcall;
  public
    procedure SetData(Offset, Size: LongInt; Data: Pointer); stdcall;
    procedure Bind; stdcall;
    procedure EnablePrimitiveRestart(Index: Int64); stdcall;
  end;

implementation

uses
  JEN_Main;

constructor TGeomBuffer.Create(GBufferType: TGBufferType; Count, Stride: LongInt; Data: Pointer);
begin
  inherited Create;
  FCount  := Count;
  FStride := Stride;
  FType   := GBufferType;
  FPRIdx  := -1;

  glGenBuffers(1, @FID);
  glBindBuffer(ord(FType), FID);
  SetData(0, Count * Stride, Data);
end;

destructor TGeomBuffer.Destroy;
begin
  glDeleteBuffers(1, @FID);
  inherited;
end;

function TGeomBuffer.GetType: TGBufferType;
begin
  Result := FType;
end;

function TGeomBuffer.GetStride: LongInt;
begin
  Result := FStride;
end;

function TGeomBuffer.GetPrimitiveRestartIndex: Int64;
begin
  Result := FPRIdx;
end;

procedure TGeomBuffer.SetData(Offset, Size: LongInt; Data: Pointer);
type
  TByteArray = array[0..0] of Byte;
var
  p : ^TByteArray;
begin
  Bind;

  if (Offset = 0) and (FCount * FStride = Size)  then
  begin
    glBufferData(ord(FType), size, nil, GL_STREAM_DRAW );
    P := glMapBuffer(ord(FType), GL_WRITE_ONLY);
    Move(Data^, P[Offset], Size);
    glUnmapBuffer(ord(FType));
  end else
    glBufferSubData(ord(FType), offset, size, data);
end;

procedure TGeomBuffer.Bind;
begin
  glBindBuffer(ord(FType), FID);
end;

procedure TGeomBuffer.EnablePrimitiveRestart(Index: Int64);
begin
  if (FType = gbIndex) and (not Render.Support(rsGLNVprimitiveRestart)) and (Render.GAPI <= gaOpenGl3_1) and (FPRIdx <> -1)  then
  begin
    FPRIdx := Index;
  end else
    Engine.Warning('Primitive restart is not supported!');
end;

end.
