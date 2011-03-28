unit JEN_Header;
{$I Jen_config.INC}

interface

uses
  JEN_Math;

type
  HWND  = LongWord;
  HDC   = LongWord;

  TLogMsg = (lmHeaderMsg, lmInfo, lmNotify, lmCode, lmWarning, lmError);

  TJenSubSystemType = (ssUtils, ssSystemParams, ssLog, ssDisplay, ssResMan, ssRender, ssRender2d);
  TBlendType = (btNone, btNormal, btAdd, btMult, btOne, btNoOverride, btAddAlpha);
  TCullFace = (cfNone, cfFront, cfBack);
  TMatrixType = (mtViewProj, mtModel, mtProj, mtView);
  TResourceType = (rtShader, rtTexture, rtTexture1, rtTexture2, rtTexture3, rtTexture4, rtTexture5, rtTexture6,
                  rtTexture7, rtTexture8, rtTexture9, rtTexture10, rtTexture11, rtTexture12,
	                rtTexture13, rtTexture14, rtTexture15);
  TShaderUniformType = (utInt, utVec1, utVec2, utVec3, utVec4, utMat3, utMat4);
  TTextureFilter = (tfNone, tfBilinear, tfTrilinear, tfAniso);
  TSetModeResult = (SM_Successful, SM_SetDefault, SM_Error);

  TColor = LongWord;

  IGame = interface
    procedure LoadContent; stdcall;
    procedure OnUpdate(dt: double); stdcall;
    procedure OnRender; stdcall;
  end;

  IJenSubSystem = interface(IUnknown)

  end;

  IJenEngine = interface
    procedure GetSubSystem(SubSustemType: TJenSubSystemType; out SubSystem: IJenSubSystem); stdcall;
    procedure Start(Game : IGame); stdcall;
  end;

  IUtils = interface(IJenSubSystem)
    function GetTime : LongInt; stdcall;
    procedure Sleep(Value: LongWord); stdcall;
    function IntToStr(Value: LongInt): string; stdcall;
    function StrToInt(const Str: string; Def: LongInt = 0): LongInt; stdcall;
    function FloatToStr(Value: Single; Digits: LongInt = 8): string; stdcall;
    function StrToFloat(const Str: string; Def: Single = 0): Single; stdcall;
    function ExtractFileDir(const FileName: string): string; stdcall;
    function ExtractFileName(const FileName: string): string; stdcall;
    function ExtractFileExt(const FileName: string): string; stdcall;
    function ExtractFileNameNoExt(const FileName: string): string; stdcall;
    property Time : LongInt read GetTime;
  end;

  IScreen = interface
    function GetWidth  : LongInt; stdcall;
    function GetHeight : LongInt; stdcall;
    function GetBPS    : Byte; stdcall;
    function GetRefresh: Byte; stdcall;

    function SetMode(W, H, R: LongInt): TSetModeResult; stdcall;

    property Width  : LongInt read GetWidth;
    property Height : LongInt read GetHeight;
    property BPS    : Byte read GetBPS;
    property Refresh: Byte read GetRefresh;
  end;

  ISystemParams = interface(IJenSubSystem)
    function GetRAMTotal: LongWord; stdcall;
    function GetRAMFree: LongWord; stdcall;
    function GetCPUCount: LongInt; stdcall;
    function GetCPUName: String; stdcall;
    function GetCPUSpeed: LongWord; stdcall;

    property CPUCount: LongInt read GetCPUCount;
    property CPUName: String read GetCPUName;
    property CPUSpeed: LongWord read GetCPUSpeed;
    property RAMTotal: LongWord read GetRAMTotal;
    property RAMFree: LongWord read GetRAMFree;
  end;

  ILogOutput = interface
    procedure Init; stdcall;
    procedure AddMsg(const Text: String; MType: TLogMsg); stdcall;
  end;

  ILog = interface(IJenSubSystem)
    procedure RegisterOutput(Value : ILogOutput); stdcall;
    procedure Print(const Text: String; MType: TLogMsg); stdcall;
  end;

  IDisplay = interface(IJenSubSystem)
    function Init(Width: LongWord = 800; Height: LongWord = 600; Refresh: Byte = 0; FullScreen: Boolean = False): Boolean; stdcall;

    procedure SetActive(Value: Boolean); stdcall;
    procedure SetCaption(const Value: string); stdcall;
    procedure SetVSync(Value: Boolean); stdcall;
    procedure SetFullScreen(Value: Boolean); stdcall;

    function GetFullScreen: Boolean; stdcall;
    function GetActive: Boolean; stdcall;
    function GetCursorState: Boolean; stdcall;
    function GetHDC: HDC; stdcall;
    function GetHandle: HWND; stdcall;
    function GetWidth: LongWord; stdcall;
    function GetHeight: LongWord; stdcall;
    function GetFPS: LongWord; stdcall;

    procedure Swap; stdcall;
    procedure ShowCursor(Value: Boolean); stdcall;
                {
    procedure Resize(W, H: LongWord);
    property VSync: Boolean read FVSync write SetVSync;
                                                }
    property Active: Boolean read GetActive write SetActive;
    property Cursor: Boolean read GetCursorState write ShowCursor;
    property FullScreen: Boolean read GetFullScreen write SetFullScreen;

    property Handle: HWND  read GetHandle;
    property DC: HDC read GetHDC;
    property Width: LongWord read GetWidth;
    property Height: LongWord read GetHeight;
    property Caption: String write SetCaption;
    property FPS: LongWord read GetFPS;
  end;

  IResource = interface
    function GetName: string; stdcall;
    property Name: string read GetName;
  end;

  IShaderUniform = interface
    procedure Value(const Data; Count: LongInt = 1); stdcall;
  end;

  IShaderProgram = interface
    function Uniform(const UName: string; UniformType: TShaderUniformType): IShaderUniform; stdcall;
    //function Attrib(const AName: string; AttribType: TShaderAttribType; Norm: Boolean = False): TShaderAttrib; stdcall;
    procedure Bind; stdcall;
  end;

  IShaderResource = interface(IResource)
    function Compile: IShaderProgram; stdcall;
  end;

  ITexture = interface(IResource)
    procedure Bind(Channel: Byte = 0); stdcall;
  end;

  IResourceManager = interface(IJenSubSystem)
    function Load(const FileName: string; Resource: TResourceType): IResource; overload; stdcall;
    procedure Load(const FileName: string; out Resource: IShaderResource); overload; stdcall;
    procedure Load(const FileName: string; out Resource: ITexture); overload; stdcall;

    function LoadShader(const FileName: string): IShaderResource; stdcall;
    function LoadTexture(const FileName: string): ITexture; stdcall;
  end;

  IRender = interface(IJenSubSystem)
    procedure Init(DepthBits: Byte = 24; StencilBits: Byte = 8; FSAA: Byte = 0); stdcall;

    procedure SetBlendType(Value: TBlendType); stdcall;
    procedure SetAlphaTest(Value: Byte); stdcall;
    procedure SetDepthTest(Value: Boolean); stdcall;
    procedure SetDepthWrite(Value: Boolean); stdcall;
    procedure SetCullFace(Value: TCullFace); stdcall;

    procedure SetMatrix(Idx: TMatrixType; Value: TMat4f); stdcall;
    function  GetMatrix(Idx: TMatrixType): TMat4f; stdcall;

    function GetDipCount : LongWord;
    procedure SetDipCount(Value : LongWord);
    procedure IncDip;

    procedure Clear(ColorBuff, DepthBuff, StensilBuff: Boolean); stdcall;

    property BlendType: TBlendType write SetBlendType;
    property AlphaTest: Byte write SetAlphaTest;
    property DepthTest: Boolean write SetDepthTest;
    property DepthWrite: Boolean write SetDepthWrite;
    property CullFace: TCullFace write SetCullFace;
    property Matrix[Idx: TMatrixType]: TMat4f read GetMatrix write SetMatrix;
    property DipCount: LongWord read GetDipCount write SetDipCount;
  end;

  IRender2D = interface(IJenSubSystem)
    procedure DrawQuad(const v1, v2, v3, v4: TVec4f; const C: TVec2f; Angle: Single = 0); overload; stdcall;
    procedure DrawSprite(Tex : ITexture; X, Y, W, H: Single; Angle: Single = 0); stdcall;
 ///  procedure Quad(const Rect, TexRect: TRecti; Color: TColor; Angle: Single = 0); overload; stdcall;
  //  procedure Quad(x1, y1, x2, y2, x3, y3, x4, y4, cx, cy: Single; Color: TColor; PtIdx: Word = 0; Angle: Single = 0); overload; stdcall;
  end;

{$IFNDEF JEN_CTD}
  {$IFDEF JEN_ATTACH_DLL}
    procedure GetJenEngine(out Engine: IJenEngine); stdcall; external 'JEN.dll';
  {$ELSE}
    var GetJenEngine : procedure(out Engine: IJenEngine); stdcall;
  {$ENDIF}
{$ENDIF}

implementation


end.
