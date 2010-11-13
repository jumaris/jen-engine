unit JEN_Render;
{$I Jen_config.INC}

interface

uses
  JEN_MATH;

type
  TBlendType = (btNone, btNormal, btAdd, btMult, btOne, btNoOverride, btAddAlpha);
  TCullFace = (cfNone, cfFront, cfBack);
  TMatrixType = (mtViewProj, mtModel, mtProj, mtView);

  TRender = class
  protected
    var
      FValid  : Boolean;
    procedure SetViewport(Value: TRecti); virtual; abstract;
    function  GetViewport: TRecti; virtual; abstract;
    procedure SetBlendType(Value: TBlendType); virtual; abstract;
    procedure SetAlphaTest(Value: Byte); virtual; abstract;
    procedure SetDepthTest(Value: Boolean); virtual; abstract;
    procedure SetDepthWrite(Value: Boolean); virtual; abstract;
    procedure SetCullFace(Value: TCullFace); virtual; abstract;
  public
    var
      Matrix    : array [TMatrixType] of TMat4f;
      CameraPos : TVec3f;
    property IsValid: Boolean read FValid;
    property BlendType: TBlendType write SetBlendType;
    property AlphaTest: Byte write SetAlphaTest;
    property DepthTest: Boolean write SetDepthTest;
    property DepthWrite: Boolean write SetDepthWrite;
    property CullFace: TCullFace write SetCullFace;
    property Viewport: TRecti read GetViewport write SetViewport;
  end;

implementation

end.
