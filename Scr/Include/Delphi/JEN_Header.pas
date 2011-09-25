unit JEN_Header;

interface

uses
  Windows,
  JEN_Math;

type
  TJenSubSystemType = (ssUtils, ssHelpers, ssInput, ssDisplay, ssResMan, ssRender, ssRender2d);
  TEvent = (evLogMsg, evActivate, evKeyUp, evKeyDown, evDisplayRestore, evRenderFlush);

  TLogMsg = (lmHeaderMsg, lmInfo, lmNotify, lmCode, lmWarning, lmError);

  TInputKey = (
  // Keyboard
    ikNone = $00, ikPlus = $BB, ikMinus = $BD, ikTilde = $C0,
    ik0 = $30, ik1, ik2, ik3, ik4, ik5, ik6, ik7, ik8, ik9,
    ikA = $41, ikB, ikC, ikD, ikE, ikF, ikG, ikH, ikI, ikJ, ikK, ikL, ikM,
    ikN, ikO, ikP, ikQ, ikR, ikS, ikT, ikU, ikV, ikW, ikX, ikY, ikZ,
    ikF1 = $70, ikF2, ikF3, ikF4, ikF5, ikF6, ikF7, ikF8, ikF9, ikF10, ikF11, ikF12,
    ikEsc = $1B, ikEnter = $0D, ikBack = $08, ikTab, ikShift = $10, ikCtrl, ikAlt, ikSpace = $20,
    ikPgUp, ikPgDown, ikEnd, ikHome, ikLeft, ikUp, ikRight, ikDown, ikIns = $2D, ikDel,
  // Mouse
    ikMouseL = $01, ikMouseR, ikMouseM = $04, ikMouseWheelUp, ikMouseWheelDown
  );

  TResourceType = (rtShader, rtFont, rtTexture, rtTexture1, rtTexture2, rtTexture3, rtTexture4, rtTexture5, rtTexture6,
                  rtTexture7, rtTexture8, rtTexture9, rtTexture10, rtTexture11, rtTexture12,
	                rtTexture13, rtTexture14, rtTexture15);

  // TVertexAttrib = (vaPosition, vaNormal, vaColor, vaTexCoord);
  TGBufferType = (gbIndex, gbVertex);
  TGeomMode = (gmTrianles = $0004, gmTriangleStrip, gmTriangleFan, gmQuads, gmQuadStrip, gmPolygon);
  TBlendType = (btNone, btNormal, btAdd, btMult, btOne, btNoOverride, btAddAlpha);
  TCullFace = (cfNone, cfFront, cfBack);
  TColorChannel = (ccRed, ccGreen, ccBlue, ccAlpha);
  TRenderChannel = (rcDepth, rcColor0, rcColor1, rcColor2, rcColor3, rcColor4, rcColor5, rcColor6, rcColor7);
  TMatrixType = (mt2DMat, mtViewProj, mtModel, mtProj, mtView);

  TShaderUniformType = (utNone, utInt, utVec1, utVec2, utVec3, utVec4, utMat2, utMat3, utMat4);
  TShaderAttribType  = (atNone, atVec1b, atVec2b, atVec3b, atVec4b,
                        atVec1s, atVec2s, atVec3s, atVec4s,
                        atVec1f, atVec2f, atVec3f, atVec4f);

  TTextureFormat = (tfoNone, tfoDXT1c, tfoDXT1a, tfoDXT3, tfoDXT5, tfoDepth8, tfoDepth16, tfoDepth24, tfoDepth32, tfoA8, tfoL8, tfoAL8, tfoBGRA8, tfoBGR8, tfoBGR5A1, tfoBGR565, tfoBGRA4, tfoR16F, tfoR32F, tfoGR16F, tfoGR32F, tfoBGRA16F, tfoBGRA32F);
  TTextureFilter = (tfiNone, tfiBilinear, tfiTrilinear, tfiAniso);
  TTextureCompareMode = (tcmNone, tcmLEqual, tcmGEqual, tcmLess, tcmGreater, tcmEqual, tcmNotEqual, tcmAlways, tcmNewer);

  TEventProc = procedure(Param: LongInt; Data: Pointer); stdcall;

  TCompareFunc = function (Item1, Item2: Pointer): LongInt;
  IList = interface
    function GetCount: LongInt; stdcall;
    function GetItem(idx: LongInt): Pointer; stdcall;
    procedure SetItem(idx: LongInt; Value: Pointer); stdcall;
    function IndexOf(p: Pointer): LongInt; stdcall;
    function Add(p: Pointer): Pointer; stdcall;
    procedure Del(idx: LongInt); stdcall;
    procedure Clear; stdcall;
    procedure Sort(CompareFunc: TCompareFunc); stdcall;

    property Count: LongInt read GetCount;
    property Items[Idx: LongInt]: Pointer read GetItem write SetItem; default;
  end;

  IGame = interface
    procedure LoadContent; stdcall;
    procedure OnUpdate(dt: LongInt); stdcall;
    procedure OnRender; stdcall;
    procedure Close; stdcall;
  end;

  IJenSubSystem = interface(IUnknown)
    procedure Free; stdcall;
  end;

  IJenEngine = interface
    procedure Start(Game : IGame); stdcall;
    procedure Finish; stdcall;

    procedure GetSubSystem(SubSustemType: TJenSubSystemType; out SubSystem: IJenSubSystem); stdcall;

    procedure AddEventProc(Event: TEvent; Proc: TEventProc); stdcall;
    procedure DelEventProc(Event: TEvent; Proc: TEventProc); stdcall;
    procedure CreateEvent(Event: TEvent; Param: LongInt = 0; Data: Pointer = nil); stdcall;

    procedure LogOut(const Text: string; MType: TLogMsg); stdcall;
  end;

  IStream = interface
    function Valid: Boolean; stdcall;
    function GetName: string; stdcall;
    function GetSize: LongInt; stdcall;
    function GetPos: LongInt; stdcall;
    procedure SetPos(Value: LongInt); stdcall;
    function Read(out Buf; BufSize: LongInt): LongWord; stdcall;
    function Write(const Buf; BufSize: LongInt): LongWord; stdcall;
    function ReadAnsi: AnsiString; stdcall;
    procedure WriteAnsi(const Value: AnsiString); stdcall;
    function ReadUnicode: WideString; stdcall;
    procedure WriteUnicode(const Value: WideString); stdcall;

    property Size: LongInt read GetSize;
    property Pos: LongInt read GetPos write SetPos;
    property Name: String read GetName;
  end;

  TXMLParam = record
    Name  : string;
    Value : string;
  end;

  IXMLParams = interface
    function GetParam(const Name: string): TXMLParam; stdcall;
    function GetParamI(Idx: LongInt): TXMLParam; stdcall;
    function GetCount: LongInt; stdcall;

    property Count: LongInt read GetCount;
    property Param[const Name: string]: TXMLParam read GetParam; default;
    property ParamI[Idx: LongInt]: TXMLParam read GetParamI;
  end;

  IXML = interface
    function GetCount: LongInt; stdcall;
    function GetTag: string; stdcall;
    function GetContent: string; stdcall;
    function GetDataLen: LongInt; stdcall;
    function GetParams: IXMLParams; stdcall;
    function GetNode(const TagName: string): IXML; stdcall;
    function GetNodeI(Idx: LongInt): IXML; stdcall;

    property Count: LongInt read GetCount;
    property Tag: string read GetTag;
    property Content: string read GetContent;
    property DataLen: LongInt read GetDataLen;
    property Params: IXMLParams read GetParams;
    property Node[const TagName: string]: IXML read GetNode; default;
    property NodeI[Idx: LongInt]: IXML read GetNodeI;
  end;

  IUtils = interface(IJenSubSystem)
    function GetTime : LongInt; stdcall;
    procedure Sleep(Value: LongWord); stdcall;
    function IntToStr(Value: LongInt): string; stdcall;
    function StrToInt(const Str: string; Def: LongInt = 0): LongInt; stdcall;
    function FloatToStr(Value: Single; Digits: LongInt = 8): string; stdcall;
    function StrToFloat(const Str: string; Def: Single = 0): Single; stdcall;
    function ExtractFileDir(const FileName: string): string; stdcall;
    function ExtractFileName(const FileName: string; NoExt: Boolean = False): string; stdcall;
    function ExtractFileExt(const FileName: string): string; stdcall;
    property Time : LongInt read GetTime;
  end;

  IScreen = interface
    function GetWidth  : LongInt; stdcall;
    function GetHeight : LongInt; stdcall;
    function GetBPS    : Byte; stdcall;
    function GetRefresh: Byte; stdcall;
    function GetDesktopRect : TRecti; stdcall;

    function SetMode(W, H, R: LongInt): Boolean; stdcall;
    procedure ResetMode; stdcall; //do not use!!!

    property DesktopRect : TRecti read GetDesktopRect;
    property Width  : LongInt read GetWidth;
    property Height : LongInt read GetHeight;
    property BPS    : Byte read GetBPS;
    property Refresh: Byte read GetRefresh;
  end;

  TMouse = object
    Pos   : TPoint2i;
    Delta : TPoint2i;
  end;

  IInput = interface(IJenSubSystem)
    procedure Update; stdcall;

    function GetLastKey: TInputKey; stdcall;
    function IsKeyDown(Value: TInputKey): Boolean; stdcall;
    function IsKeyHit(Value: TInputKey): Boolean; stdcall;

    function GetMouse: TMouse; stdcall;
    procedure SetCapture(Value: Boolean); stdcall;

    property Mouse: TMouse read GetMouse;
    property Down[Value: TInputKey]: Boolean read IsKeyDown;
    property Hit[Value: TInputKey]: Boolean read IsKeyHit;
  end;

  IDisplay = interface(IJenSubSystem)
    function Init(Width: LongWord = 800; Height: LongWord = 600; Refresh: Byte = 0; FullScreen: Boolean = False): Boolean; stdcall;
    procedure Resize(Width, Height: LongWord); stdcall;

    procedure SetActive(Value: Boolean); stdcall;
    procedure SetCaption(const Value: String); stdcall;
    procedure SetFullScreen(Value: Boolean); stdcall;

    function GetFullScreen: Boolean; stdcall;
    function GetActive: Boolean; stdcall;
    function GetCursorState: Boolean; stdcall;
    function GetWndDC: HDC; stdcall;
    function GetWndHandle: HWND; stdcall;
    function GetWidth: LongWord; stdcall;
    function GetHeight: LongWord; stdcall;

    procedure Swap; stdcall;
    procedure ShowCursor(Value: Boolean); stdcall;
                {
    procedure Resize(W, H: LongWord);
    property VSync: Boolean read FVSync write SetVSync;
                                                }
    property Active: Boolean read GetActive write SetActive;
    property Cursor: Boolean read GetCursorState write ShowCursor;
    property FullScreen: Boolean read GetFullScreen write SetFullScreen;

    property Handle: HWND  read GetWndHandle;
    property DC: HDC read GetWndDC;
    property Width: LongWord read GetWidth;
    property Height: LongWord read GetHeight;
    property Caption: String write SetCaption;
  end;

  IResource = interface
  ['{85CA9B42-E24A-4FA8-BFFA-083B73CCA057}']
    procedure Reload; stdcall;
    function GetName: string; stdcall;
    function GetFilePath: string; stdcall;
    function GetResType: TResourceType; stdcall;

    property Name: string read GetName;
    property FilePath: string read GetFilePath;
    property ResType: TResourceType read GetResType;
  end;

  IShaderUniform = interface
  ['{A587E658-8ADD-4928-A985-771AB9E5D562}']
    function GetName: string; stdcall;
    function GetType: TShaderUniformType; stdcall;
 //   procedure SetType(Value: TShaderUniformType); stdcall;

    function Valid: Boolean; stdcall;
    procedure Value(const Data; Count: LongInt = 1); stdcall;

    property Name: string read GetName;
    property UType: TShaderUniformType read GetType;
  end;

  IShaderAttrib = interface
  ['{3BF51C3F-3063-4CAE-9993-12F7A5E11DED}']
    function GetName: string; stdcall;
    function GetType: TShaderAttribType; stdcall;
  //  procedure SetType(Value: TShaderAttribType); stdcall;

    function Valid: Boolean; stdcall;
    procedure Value(Stride, Offset: LongInt; Norm: Boolean = False); stdcall;

    procedure Enable; stdcall;
    procedure Disable; stdcall;

    property Name: string read GetName;
    property AType: TShaderAttribType read GetType;
  end;

  IShaderProgram = interface
  ['{1F79BB95-C0B0-45AF-AA8D-AF9999CC85C8}']
    function Valid: Boolean; stdcall;
    function GetID: LongWord; stdcall;
    function Uniform(const UName: String; UniformType: TShaderUniformType; Necessary: Boolean = True): IShaderUniform; overload; stdcall;
    function Attrib(const AName: string; AttribType: TShaderAttribType; Necessary: Boolean = True): IShaderAttrib; stdcall;
    procedure Bind; stdcall;
  end;

  IShaderResource = interface(IResource)
  ['{313C3497-C065-4A29-A970-07B9750D5914}']
    function GetDefine(const Name: String): LongInt; stdcall;
    procedure SetDefine(const Name: String; Value: LongInt); stdcall;

    function Compile: IShaderProgram; stdcall;

    property Define[const Name: String]: LongInt read GetDefine write SetDefine; default;
  end;

  ITexture = interface(IResource)
  ['{E9EEFA65-F004-4668-9BAD-2FE92D19F050}']
    procedure Bind(Channel: Byte = 0); stdcall;

    function GetID: LongWord; stdcall;
    function GetCoordParams: TVec4f; stdcall;
    function GetFormat: TTextureFormat; stdcall;
    procedure SetFormat(Value: TTextureFormat); stdcall;
    function GetSampler: LongWord; stdcall;
    procedure SetSampler(Value: LongWord); stdcall;
    function GetFilter: TTextureFilter; stdcall;
    procedure SetFilter(Value: TTextureFilter); stdcall;
    function GetClamp: Boolean; stdcall;
    procedure SetClamp(Value: Boolean); stdcall;
    procedure SetCompare(Value: TTextureCompareMode); stdcall;

    procedure DataSet(Width, Height, Size: LongInt; Data: Pointer; Level: LongInt); stdcall;
    procedure Flip(Vertical, Horizontal: Boolean); stdcall;

    property ID: LongWord read GetID;
        //property Width: LongInt read FWidth;
   // property Height: LongInt read FHeight;
    property CoordParams: TVec4f read GetCoordParams;
    property Format: TTextureFormat read GetFormat write SetFormat;
    property Sampler: LongWord read GetSampler write SetSampler;
    property Filter: TTextureFilter read GetFilter write SetFilter;
    property Clamp: Boolean read GetClamp write SetClamp;
  end;

  IGeomBuffer = Interface
    procedure SetData(Offset, Size: LongInt; Data: Pointer); stdcall;
    procedure Bind; stdcall;
    procedure Draw(mode: TGeomMode; count: LongInt; Indexed: Boolean; first: LongInt = 0); stdcall;
  end;

  IFont = interface(IResource)
  ['{9057EA67-509A-4D17-AFC8-8B96481A6BCF}']
    function GetTextWidth(const Text: String): Single; stdcall;
    procedure Print(const Text: String; X, Y: Single);stdcall;

    function GetScale: Single; stdcall;
    procedure SetScale(Value: Single); stdcall;
    function GetColor: TVec4f; stdcall;
    procedure SetColor(const Value: TVec4f); stdcall;
    procedure SetGradColors(const Value1, Value2: TVec4f); stdcall;
    function GetOutlineColor: TVec3f; stdcall;
    procedure SetOutlineColor(Value: TVec3f); stdcall;
    function GetOutlineSize: Single; stdcall;
    procedure SetOutlineSize(const Value: Single); stdcall;
    function GetEdgeSmooth: Single; stdcall;
    procedure SetEdgeSmooth(Value: Single); stdcall;

    property Scale: Single read GetScale write SetScale;
    property Color: TVec4f read GetColor write SetColor;
    property OutlineColor: TVec3f read GetOutlineColor write SetOutlineColor;
    property OutlineSize: Single read GetOutlineSize write SetOutlineSize;
    property EdgeSmooth: Single read GetEdgeSmooth write SetEdgeSmooth;
  end;

  IResourceManager = interface(IJenSubSystem)
    function Load(const FilePath: string; Resource: TResourceType): IResource; overload; stdcall;
    procedure Load(const FilePath: string; out Resource: JEN_Header.IShaderResource); overload; stdcall;
    procedure Load(const FilePath: string; out Resource: JEN_Header.ITexture); overload; stdcall;
    procedure Load(const FilePath: string; out Resource: JEN_Header.IFont); overload; stdcall;
    {
    function LoadShader(const FileName: string): IShaderResource; stdcall;
    function LoadTexture(const FileName: string): ITexture; stdcall;    }

    function CreateTexture(Width, Height: LongWord; Format: TTextureFormat): ITexture; stdcall;
    function CreateGeomBuffer(GBufferType: TGBufferType; Count, Stride: LongInt; Data: Pointer): IGeomBuffer; stdcall;
  end;

  TRenderSupport = (rsWGLEXTswapcontrol);

  IRenderTarget = interface
    function GetID: LongWord; stdcall;
    function GetWidth: LongWord; stdcall;
    function GetHeight: LongWord; stdcall;
    function GetColChanCount: LongInt; stdcall;
    function GetTexture(Channel: TRenderChannel): ITexture; stdcall;

    property ID: LongWord read GetID;
    property Width: LongWord read GetWidth;
    property Height: LongWord read GetHeight;
    property ColChanCount: LongInt read GetColChanCount;
    property Texture[Channel: TRenderChannel]: ITexture read GetTexture;
  end;

  IRender = interface(IJenSubSystem)
    procedure Init(DepthBits: Byte = 24; StencilBits: Byte = 8; FSAA: Byte = 0); stdcall;
    function Support(RenderSupport: TRenderSupport): Boolean;

    function CreateRenderTarget(Width, Height: LongWord; CFormat: TTextureFormat; Count: LongWord; Samples: LongWord = 0; DepthBuffer: Boolean = False; DFormat: TTextureFormat = tfoDepth24): JEN_Header.IRenderTarget; stdcall;
    function GetTarget: IRenderTarget; stdcall;
    procedure SetTarget(Value: IRenderTarget); stdcall;

    function GetViewport: TRecti; stdcall;
    procedure SetViewport(const Value: TRecti); stdcall;
    function GetVSync: Boolean; stdcall;
    procedure SetVSync(Value: Boolean); stdcall;

    procedure Clear(ColorBuff, DepthBuff, StensilBuff: Boolean); stdcall;

    procedure SetClearColor(const Color: TVec4f); stdcall;
    function GetColorMask(Channel: TColorChannel): Boolean; overload; stdcall;
    procedure SetColorMask(Channel: TColorChannel; Value: Boolean); overload; stdcall;
    function GetColorMask: Byte; overload; stdcall;
    procedure SetColorMask(Red, Green, Blue, Alpha: Boolean); overload; stdcall;
    function GetBlendType: TBlendType; stdcall;
    procedure SetBlendType(Value: TBlendType); stdcall;
    function GetAlphaTest: Byte; stdcall;
    procedure SetAlphaTest(Value: Byte); stdcall;
    function GetDepthTest: Boolean; stdcall;
    procedure SetDepthTest(Value: Boolean); stdcall;
    function GetDepthWrite: Boolean; stdcall;
    procedure SetDepthWrite(Value: Boolean); stdcall;
    function GetCullFace: TCullFace; stdcall;
    procedure SetCullFace(Value: TCullFace); stdcall;

    function  GetMatrix(Idx: TMatrixType): TMat4f; stdcall;
    procedure SetMatrix(Idx: TMatrixType;const Value: TMat4f); stdcall;
    function  GetCameraPos: TVec3f; stdcall;
    procedure SetCameraPos(Value: TVec3f); stdcall;
    function  GetCameraDir: TVec3f; stdcall;
    procedure SetCameraDir(Value: TVec3f); stdcall;

    function GetFPS: LongWord; stdcall;
    function GetFrameTime: LongWord; stdcall;
    function GetLastDipCount: LongWord; stdcall;
    function GetDIPCount: LongWord; stdcall;
    procedure SetDIPCount(Value: LongWord); stdcall;
    procedure IncDIP; stdcall;

    property Target: IRenderTarget read GetTarget write SetTarget;
    property Viewport: TRecti read GetViewport write SetViewPort;
    property VSync: Boolean read GetVSync write SetVSync;
    property ClearColor: TVec4f write SetClearColor;
    property ColorMask[Channel: TColorChannel]: Boolean read GetColorMask write SetColorMask;
    property BlendType: TBlendType read GetBlendType write SetBlendType;
    property AlphaTest: Byte read GetAlphaTest write SetAlphaTest;
    property DepthTest: Boolean read GetDepthTest write SetDepthTest;
    property DepthWrite: Boolean read GetDepthWrite write SetDepthWrite;
    property CullFace: TCullFace read GetCullFace write SetCullFace;
    property Matrix[Idx: TMatrixType]: TMat4f read GetMatrix write SetMatrix;
    property CameraPos: TVec3f read GetCameraPos write SetCameraPos;
    property CameraDir: TVec3f read GetCameraDir write SetCameraDir;
    property FPS: LongWord read GetFPS;
    property FrameTime: LongWord read GetFrameTime;
    property DipCount: LongWord read GetDipCount write SetDipCount;
    property LastDipCount: LongWord read GetLastDipCount;
  end;

  IRender2D = interface(IJenSubSystem)
    procedure ResolutionCorrect(Width, Height: LongWord); stdcall;
    function  GetEnableRC: Boolean; stdcall;
    procedure SetEnableRC(Value: Boolean); stdcall;
    function  GetRCWidth: LongWord; stdcall;
    function  GetRCHeight: LongWord; stdcall;
    function  GetRCRect: TRecti; stdcall;
    function  GetRCScale: Single; stdcall;
    function  GetRCMatrix: TMat4f; stdcall;

    procedure BatchBegin; stdcall;
    procedure BatchEnd; stdcall;

    procedure DrawSprite(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture; const v1, v2, v3, v4, Data1, Data2, Data3, Data4: TVec4f; Angle: Single; const Center: TVec2f; Effects: Cardinal); overload; stdcall;
    procedure DrawSprite(Shader: IShaderProgram; Tex1, Tex2, Tex3: ITexture; x, y, w, h: Single; const Data1, Data2, Data3, Data4: TVec4f; Angle: Single; const Center: TVec2f; Effects: Cardinal); overload; stdcall;
    procedure DrawSprite(Tex : ITexture; x, y, w, h: Single; const Color: TVec4f; Angle: Single = 0.0; cx: Single = 0.5; cy: Single = 0.5; Effects: Cardinal = 0); overload; stdcall;
    procedure DrawSprite(Tex : ITexture; x, y, w, h: Single; const c1, c2, c3, c4: TVec4f; Angle: Single = 0.0; cx: Single = 0.5; cy: Single = 0.5; Effects: Cardinal = 0); overload;  stdcall;

    property EnableRCt: Boolean read GetEnableRC write SetEnableRC;
    property RCRect: TRecti read GetRCRect;
    property RCWidth: LongWord read GetRCWidth;
    property RCHeight: LongWord read GetRCHeight;
    property RCScale: Single read GetRCScale;
    property RCMatrix: TMat4f read GetRCMatrix;
  end;

  ICamera2d = interface
    function GetEnable: Boolean; stdcall;
    procedure SetEnable(Value: Boolean); stdcall;
    function GetPos: TVec2f; stdcall;
    procedure SetPos(const Value: TVec2f); stdcall;
    function GetAngle: Single; stdcall;
    procedure SetAngle(Value: Single); stdcall;
    function GetScale: Single; stdcall;
    procedure SetScale(Value: Single); stdcall;

    procedure SetCam; stdcall;

    property Enable: Boolean read GetEnable write SetEnable;
    property Pos: TVec2f read GetPos write SetPos;
    property Angle: Single read GetAngle write SetAngle;
    property Scale: Single read GetScale write SetScale;
  end;

  ICamera3d = interface
    function GetFOV: Single; stdcall;
    procedure SetFOV(Value: Single); stdcall;
    function GetPos: TVec3f; stdcall;
    procedure SetPos(const Value: TVec3f); stdcall;
    function GetAngle: TVec3f; stdcall;
    procedure SetAngle(const Value: TVec3f); stdcall;
    function GetDir: TVec3f; stdcall;
    function GetMaxSpeed: Single; stdcall;
    procedure SetMaxSpeed(Value: Single); stdcall;
    function GetZNear: Single; stdcall;
    procedure SetZNear(Value: Single); stdcall;
    function GetZFar: Single; stdcall;
    procedure SetZFar(Value: Single); stdcall;

    procedure onUpdate(DeltaTime: Single); stdcall;

    property FOV: Single read GetFOV write SetFOV;
    property Pos: TVec3f read GetPos write SetPos;
    property Angle: TVec3f read GetAngle write SetAngle;
    property Dir: TVec3f read GetDir;
    property MaxSpeed: Single read GetMaxSpeed write SetMaxSpeed;

    property ZNear: Single read GetZNear write SetZNear;
    property ZFar: Single read GetZFar write SetZFar;
  end;

  TGPUInfo = record
    Description   : PWideChar;
    ChipType      : PWideChar;
    MemorySize    : LongWord;
    DriverVersion : PWideChar;
    DriverDate    : PWideChar;
  end;
  PGPUInfo = ^TGPUInfo;

  ISystemInfo = interface
    function GetScreen: IScreen; stdcall;
    function GetGpuList: IList; stdcall;

    function GetRAMTotal: LongWord; stdcall;
    function GetRAMFree: LongWord; stdcall;
    function GetCPUCount: LongInt; stdcall;
    function GetCPUName: String; stdcall;
    function GetCPUSpeed: LongWord; stdcall;

    property GPUList: IList read GetGpuList;
    property CPUCount: LongInt read GetCPUCount;
    property CPUName: String read GetCPUName;
    property CPUSpeed: LongWord read GetCPUSpeed;
    property RAMTotal: LongWord read GetRAMTotal;
    property RAMFree: LongWord read GetRAMFree;

    procedure WindowsVersion(out Major: LongInt;out Minor: LongInt;out Build: LongInt); stdcall;
    property Screen: IScreen read GetScreen;
  end;

  IHelpers = interface(IJenSubSystem)
    function CreateStream(FileName: string; RW: Boolean = True): IStream; stdcall;
    function CreateCamera3D: ICamera3d; stdcall;
    function CreateCamera2D: ICamera2d; stdcall;

    function GetSystemInfo: ISystemInfo; stdcall;
    property SystemInfo: ISystemInfo read GetSystemInfo;
  end;

  function GetJenEngine(FileLog, Debug: Boolean): JEN_Header.IJenEngine; stdcall; external 'JEN.dll';

implementation


end.

