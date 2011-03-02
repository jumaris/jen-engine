unit JEN_Header;
{$I Jen_config.INC}

interface

type
  TJenSubSystemType = (ssUtils, ssSystemParams, ssLog, ssDisplay, ssRender, ssResMan);

type
  HWND  = LongWord;
  HDC   = LongWord;

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
   { Utils        : TUtils;
    SystemParams : TSystem;
    Log          : TLog;
    Display      : TDisplay;
    Render       : TRender;
    ResMan       : TResourceManager;
    Valid        : Boolean;     }
  end;

  IUtils = interface(IJenSubSystem)

  end;

  ILog = interface(IJenSubSystem)

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
                {
    procedure Swap;
    procedure Resize(W, H: Cardinal);
    procedure ShowCursor(Value: Boolean);

 //   property Cursor: LongBool read GetCursorState write ShowCursor;
   { property FullScreen: Boolean read GetFullScreen write SetFullScreen;
    property VSync: Boolean read FVSync write SetVSync;

    property Handle: HWND  read GetHandle;
    property DC: HDC read GetHDC;
    property Width: Cardinal read GetWidth;
    property Height: Cardinal read GetHeight;
    property Caption: String write SetCaption;
    property FPS: LongInt read FFPS;       }
  end;

  IRender = interface(IJenSubSystem)
    procedure Init(DepthBits: Byte = 24; StencilBits: Byte = 8; FSAA: Byte = 0); stdcall;
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
