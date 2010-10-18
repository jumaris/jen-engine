unit JEN_Display;

interface

uses
  XSystem;

type
  TDisplay = class
  protected
    function  GetFullScreen : Boolean; virtual; abstract;
    procedure SetActive(Value : Boolean); virtual; abstract;
    function  GetActive : Boolean; virtual; abstract;
    function  GetHandle : HWND; virtual; abstract;
    function  GetDC : HDC; virtual; abstract;
  public
    property FullScreen : Boolean read GetFullScreen;
    property Active : Boolean read GetActive write SetActive;
    property Handle : HWND  read GetHandle;
    property DC : HDC read GetDC;
    procedure Update; virtual; abstract;
  end;

implementation

uses
  JEN_MAIN;

end.
