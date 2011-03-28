unit JEN_Render2D;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_OpenGlHeader;

const Batch_Size = 16;

type
  IRender2D = interface(JEN_Header.IRender2D)

  end;

  TRender2D = class(TInterfacedObject, IRender2D)
    constructor Create;
  private
    class var FBuff : array[1..Batch_Size] of
      record
        V : array[1..4] of TVec4f;
        C : array[1..4] of TVec4f;
      end;
    class var FIdx : Byte;
  public
    class procedure Flush;
    procedure DrawQuad(const v1, v2, v3, v4: TVec4f; const C: TVec2f; Angle: Single); overload; stdcall;
    procedure DrawSprite(Tex : ITexture; X, Y, W, H, Angle: Single); stdcall;
  end;

implementation

uses
  JEN_Main;

constructor TRender2D.Create;
begin
  inherited;
  FIdx := 1;
end;

class procedure TRender2D.Flush;
var
  I : Byte;
begin
  for I := 1 to FIdx do
  with FBuff[I] do
  begin
    glbegin(GL_QUADS);

    glvertex4fv(@V[1]);
    glvertex4fv(@V[2]);
    glvertex4fv(@V[3]);
    glvertex4fv(@V[4]);

    glend;
  end;

  FIdx := 1;
  Render.IncDip;
end;

procedure TRender2D.DrawQuad(const v1, v2, v3, v4: TVec4f; const C: TVec2f; Angle: Single);
begin
  with FBuff[FIdx] do
  begin
    V[1]:=v1;
    V[2]:=v2;
    V[3]:=v3;
    V[4]:=v4;
  end;

  if FIdx = Batch_Size then
    Flush
  else
    inc(FIdx);
end;

procedure TRender2D.DrawSprite(Tex: ITexture; X, Y, W, H, Angle: Single);
var
  v : array[1..4] of TVec4f;
begin
  if not Assigned(Tex) then Exit;
  ResMan.ResChangeCallBack := @TRender2D.Flush;

  Tex.Bind;

  v[1] := Vec4f(X  , Y  , 0, 1);
  v[2] := Vec4f(X+W, Y  , 1, 1);
  v[3] := Vec4f(X+W, Y+H, 1, 0);
  v[4] := Vec4f(X  , Y+H, 0, 0);

  DrawQuad(v[1], v[2], v[3], v[4], Vec2f(X + W/2, Y + H/2), Angle);
end;

end.
