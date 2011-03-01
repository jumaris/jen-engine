unit JEN_Display_Window;

interface

uses
  XSystem,
  JEN_SystemInfo,
  JEN_Display;

      {
type
  TDisplayWindow = class(TDisplay)
    constructor Create(Width: Cardinal = 800; Height: Cardinal = 600; Refresh: Byte = 0; FullScreen: Boolean = False);
    destructor Destroy; override;
  private
   
    procedure SetFullScreen(Value: Boolean);
    procedure SetActive(Value: Boolean);
    procedure SetCaption(const Value: string);

    function GetFullScreen: Boolean; override;
    function GetActive: Boolean; override;
    function GetCursorState: Boolean; override;
    function GetHandle: HWND; override;
    function GetHDC: HDC; override;
    function GetWidth: Cardinal; override;
    function GetHeight: Cardinal; override;
  public
    procedure Restore; override;
    procedure Update; override;
    procedure Resize(W, H: Cardinal); override;
    procedure ShowCursor(Value: Boolean); override;

    class function WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall; static;
  end;   }

implementation

uses
  JEN_MAIN,
  JEN_MATH;


end.
