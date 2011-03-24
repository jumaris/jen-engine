unit JEN_Render2D;

interface

uses
  JEN_Header,
  JEN_Math,
  JEN_OpenGlHeader;

type
  IRender2D = interface(JEN_Header.IRender2D)

  end;

  TRender2D = class(TInterfacedObject, IRender2D)
    procedure Quad(const v1, v2, v3, v4: TVec4f; const C: TVec2f; Angle: Single; Color: TColor); overload; stdcall;
  end;

implementation

procedure TRender2D.Quad(const v1, v2, v3, v4: TVec4f; const C: TVec2f; Angle: Single; Color: TColor);
begin
  glbegin(GL_QUADS);

  glvertex4fv(@v1);
  glvertex4fv(@v2);
  glvertex4fv(@v3);
  glvertex4fv(@v4);

  glend;
end;

end.
