unit JEN_Display;

interface

uses
  XSystem,
  JEN_Render,
  JEN_OpenGLHeader;

type
  TDisplay = class
  protected
    var
      FValid    : Boolean;
      FVSync    : Boolean;
      FFPS      : LongInt;
      FFPSTime  : LongInt;
      FFPSCount : LongInt;
    procedure SetFullScreen(Value: Boolean); virtual; abstract;
    procedure SetActive(Value: Boolean); virtual; abstract;
    procedure SetCaption(Value: string); virtual; abstract;
    procedure SetVSync(Value: Boolean);

    function  GetFullScreen: Boolean; virtual; abstract;
    function  GetActive: Boolean; virtual; abstract;
    function  GetDC: HDC; virtual; abstract;
    function  GetHandle: HWND; virtual; abstract;
    function  GetWidth: Cardinal; virtual; abstract;
    function  GetHeight: Cardinal; virtual; abstract;
  public
    Render : TRender;

    procedure Swap;
    procedure Resize(W, H: Cardinal); virtual; abstract;
    procedure ShowCursor(Value: Boolean); virtual; abstract;

    property Valid: Boolean read FValid;
    property FullScreen: Boolean read GetFullScreen write SetFullScreen;
    property VSync: Boolean read FVSync write SetVSync;
    property Active: Boolean read GetActive write SetActive;
    property Handle: HWND  read GetHandle;
    property DC: HDC read GetDC;
    property Width: Cardinal read GetWidth;
    property Height: Cardinal read GetHeight;
    property Caption: String write SetCaption;
    property FPS: LongInt read FFPS;

    procedure Restore; virtual;
    procedure Update; virtual; abstract;
  end;

implementation

uses
  JEN_MAIN;

procedure TDisplay.Swap;
begin
  SwapBuffers(DC);

  Inc(FFPSCount);
  if Utils.Time - FFPSTime >= 1000 then
  begin
    FFPS      := FFPSCount;
    FFPSCount := 0;
    FFPSTime  := Utils.Time;
  end;
end;

procedure TDisplay.Restore;
begin
  FFPSTime  := Utils.Time;
  FFPSCount := 0;
end;

procedure TDisplay.SetVSync(Value: Boolean);
begin
  FVSync := Value;
  if FullScreen then
    wglSwapIntervalEXT(Ord(FVSync))
  else
    wglSwapIntervalEXT(0);
end;

end.
