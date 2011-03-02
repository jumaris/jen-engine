unit JEN_Display_Window;

interface

uses
  XSystem,
  JEN_SystemInfo,
  JEN_Display;

{
type
  TDisplayWindow = class
    constructor Create(Width: Cardinal = 800; Height: Cardinal = 600; Refresh: Byte = 0; FullScreen: Boolean = False);
    destructor Destroy; override;
  private
    FCaption    : String;
    FHandle     : HWND;
    FDC         : HDC;
    FWidth      : Cardinal;
    FHeight     : Cardinal;
    FRefresh    : Byte;
    FFullScreen : Boolean;
    FActive     : Boolean;
    FCursor     : Boolean;
    procedure SetFullScreen(Value: Boolean);
    procedure SetActive(Value: Boolean);
    procedure SetCaption(const Value: string);

    function GetFullScreen: Boolean;
    function GetActive: Boolean;
    function GetCursorState: Boolean;
    function GetHandle: HWND;
    function GetHDC: HDC;
    function GetWidth: Cardinal;
    function GetHeight: Cardinal;
  public
    procedure Restore;
    procedure Update;
    procedure Resize(W, H: Cardinal);
    procedure ShowCursor(Value: Boolean);

    class function WndProc(hWnd: HWND; Msg: LongWord; wParam: LongInt; lParam: LongInt): LongInt; stdcall; static;
  end;
      }
implementation

uses
  JEN_MAIN,
  JEN_MATH;


end.
