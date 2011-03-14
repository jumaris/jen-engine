unit JEN_Header;
{$I Jen_config.INC}

interface

type
  HWND  = LongWord;
  HDC   = LongWord;

  TLogMsg = (lmHeaderMsg, lmInfo, lmNotify, lmWarning, lmError);

  TJenSubSystemType = (ssUtils, ssSystemParams, ssLog, ssDisplay, ssRender, ssResMan);
  TBlendType = (btNone, btNormal, btAdd, btMult, btOne, btNoOverride, btAddAlpha);
  TCullFace = (cfNone, cfFront, cfBack);
  TMatrixType = (mtViewProj, mtModel, mtProj, mtView);
  TResourceType = (rtShader, rtTexture);
  TTextureFilter =  (tfNone, tfBilinear, tfTrilinear, tfAniso);
  TSetModeResult = (SM_Successful, SM_SetDefault, SM_Error);


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
    function IntToStr(Value: Integer): string; stdcall;
    function StrToInt(const Str: string; Def: Integer = 0): Integer; stdcall;
    function FloatToStr(Value: Single; Digits: Integer = 8): string; stdcall;
    function StrToFloat(const Str: string; Def: Single = 0): Single; stdcall;
    function ExtractFileDir(const FileName: string): string; stdcall;
    function ExtractFileName(const FileName: string): string; stdcall;
    function ExtractFileExt(const FileName: string): string; stdcall;
    function ExtractFileNameNoExt(const FileName: string): string; stdcall;
    property Time : LongInt read GetTime;
  end;

  IScreen = interface
    function GetWidth  : Integer; stdcall;
    function GetHeight : Integer; stdcall;
    function GetBPS    : Byte; stdcall;
    function GetRefresh: Byte; stdcall;

    function SetMode(W, H, R: integer): TSetModeResult; stdcall;

    property Width  : Integer read GetWidth;
    property Height : Integer read GetHeight;
    property BPS    : Byte read GetBPS;
    property Refresh: Byte read GetRefresh;
  end;

  ISystemParams = interface(IJenSubSystem)
    function GetRAMTotal: Cardinal; stdcall;
    function GetRAMFree: Cardinal; stdcall;
    function GetCPUCount: Integer; stdcall;
    function GetCPUName: String; stdcall;
    function GetCPUSpeed: LongWord; stdcall;

    property CPUCount: Integer read GetCPUCount;
    property CPUName: String read GetCPUName;
    property CPUSpeed: LongWord read GetCPUSpeed;
    property RAMTotal: Cardinal read GetRAMTotal;
    property RAMFree: Cardinal read GetRAMFree;
  end;

  ILog = interface(IJenSubSystem)
    procedure Print(const Text: String; MType: TLogMsg); stdcall;
  end;

  IDisplay = interface(IJenSubSystem)
    function Init(Width: Cardinal = 800; Height: Cardinal = 600; Refresh: Byte = 0; FullScreen: Boolean = False): Boolean; stdcall;

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

    procedure Swap; stdcall;
    procedure ShowCursor(Value: Boolean); stdcall;
                {
    procedure Resize(W, H: Cardinal);
    property VSync: Boolean read FVSync write SetVSync;
                                                }
    property Active: Boolean read GetActive write SetActive;
    property Cursor: Boolean read GetCursorState write ShowCursor;
    property FullScreen: Boolean read GetFullScreen write SetFullScreen;

    property Handle: HWND  read GetHandle;
    property DC: HDC read GetHDC;
    property Width: Cardinal read GetWidth;
    property Height: Cardinal read GetHeight;
    property Caption: String write SetCaption;

   // property FPS: LongInt read FFPS;
  end;

  IRender = interface(IJenSubSystem)
    procedure Init(DepthBits: Byte = 24; StencilBits: Byte = 8; FSAA: Byte = 0); stdcall;

    procedure SetBlendType(Value: TBlendType); stdcall;
    procedure SetAlphaTest(Value: Byte); stdcall;
    procedure SetDepthTest(Value: Boolean); stdcall;
    procedure SetDepthWrite(Value: Boolean); stdcall;
    procedure SetCullFace(Value: TCullFace); stdcall;

    property BlendType: TBlendType write SetBlendType;
    property AlphaTest: Byte write SetAlphaTest;
    property DepthTest: Boolean write SetDepthTest;
    property DepthWrite: Boolean write SetDepthWrite;
    property CullFace: TCullFace write SetCullFace;
  end;

  IResource = interface

  end;

  IShader = interface(IResource)

  end;

  ITexture = interface(IResource)
    procedure Bind(Channel: Byte = 0); stdcall;
  end;

  IResourceManager = interface(IJenSubSystem)
    function Load(const FileName: string; Resource : TResourceType) : IResource; overload; stdcall;
    procedure Load(const FileName: string; out Resource : IShader); overload; stdcall;
    procedure Load(const FileName: string; out Resource : ITexture); overload; stdcall;

    function LoadShader(const FileName: string): IShader; stdcall;
    function LoadTexture(const FileName: string): ITexture; stdcall;
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
