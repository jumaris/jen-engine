unit JEN_Header;
{$I Jen_config.INC}

interface

type
  TSubSystemType = (ssUtils, ssSystemParams, ssLog, ssDisplay, ssRender, ssResMan);

type
  HWND  = LongWord;
  HDC   = LongWord;

  IGame = interface
  ['{90D553BB-F6AF-4DD1-960E-649678FC909E}']
    procedure LoadContent; stdcall;
    procedure OnUpdate(dt: double); stdcall;
    procedure OnRender; stdcall;
  end;

  IEngineSubSystem = interface(IUnknown)
	['{76E1647A-63ED-4E9A-86CA-D9E3BEE296D6}']

	end;

  IJenEngine = interface
  ['{0BBFAF93-B133-4708-B4CC-6B815268C591}']
    function GetSubSystem(SubSustemType: TSubSystemType; out SubSystem: IEngineSubSystem) : HResult; stdcall;
    function Start(Game : IGame) : HResult; stdcall;
   { Utils        : TUtils;
    SystemParams : TSystem;
    Log          : TLog;
    Display      : TDisplay;
    Render       : TRender;
    ResMan       : TResourceManager;
    Valid        : Boolean;     }
  end;

  IDisplay = interface(IEngineSubSystem)
  ['{FE4E8245-F1DA-43D4-8E42-3B308660E613}']
    function Init(Width: Cardinal = 800; Height: Cardinal = 600; Refresh: Byte = 0; FullScreen: Boolean = False): HRESULT; stdcall;

    function SetFullScreen(Value: Boolean): HRESULT; stdcall;
    function SetActive(Value: Boolean): HRESULT; stdcall;
    function SetCaption(const Value: string): HRESULT; stdcall;
    function SetVSync(Value: Boolean): HRESULT; stdcall;

    function GetFullScreen: LongBool; stdcall;
    function GetActive: LongBool; stdcall;
    function GetCursorState: LongBool; stdcall;
    function GetHDC(out Value : HDC) : HRESULT; stdcall;
    function GetHandle(out Value : HWND): HRESULT; stdcall;
    function GetWidth(out Value : LongWord): HRESULT; stdcall;
    function GetHeight(out Value : LongWord): HRESULT; stdcall;
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

{$IFNDEF JEN_CTD}
  {$IFDEF JEN_ATTACH_DLL}
    procedure GetEngine(out Engine: IJenEngine); stdcall; external 'JEN.dll';
  {$ELSE}
    var GetEngine : procedure(out Engine: IJenEngine); stdcall;
  {$ENDIF}
{$ENDIF}

implementation


end.
