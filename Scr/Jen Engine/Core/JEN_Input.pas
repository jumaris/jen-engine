unit JEN_Input;

interface

uses
  Windows,
  JEN_Header;

type
  IInput = interface(JEN_Header.IInput)
    procedure SetState(InputKey: TInputKey; Value: Boolean);
    procedure Init;
    procedure Reset;
  end;

  TInput = class(TInterfacedObject, IInput)
  constructor Create;
  procedure Free; stdcall;
  private
    FCapture    : Boolean;
    FMouse      : TMouse;
    FDown, FHit : array [TInputKey] of Boolean;
    FLastKey    : TInputKey;
    procedure SetState(InputKey: TInputKey; Value: Boolean);

    function GetLastKey: TInputKey; stdcall;
    function IsKeyDown(Value: TInputKey): Boolean; stdcall;
    function IsKeyHit(Value: TInputKey): Boolean; stdcall;

    function GetMouse: TMouse; stdcall;
    procedure SetCapture(Value: Boolean); stdcall;

    class procedure onKeyUp(Param: LongInt); stdcall; static;
    class procedure onKeyDown(Param: LongInt); stdcall; static;
    class procedure onActivate(Param: LongInt); stdcall; static;
  public
    procedure Update; stdcall;
    procedure Init;
    procedure Reset;
  end;

implementation

uses
  JEN_Main;

constructor TInput.Create;
begin
  inherited;
end;

procedure TInput.Free;
begin
end;

procedure TInput.Init;
begin
  Engine.AddEventProc(evKeyUp, @TInput.OnKeyUp);
  Engine.AddEventProc(evKeyDown, @TInput.OnKeyDown);
  Engine.AddEventProc(evActivate, @TInput.OnActivate);
end;

procedure TInput.Reset;
begin
  FillChar(FDown, SizeOf(FDown), False);
  Update;
  FMouse.Delta.x := 0;
  FMouse.Delta.y := 0;
end;

class procedure TInput.OnKeyUp(Param: LongInt); stdcall;
begin
  Input.SetState(TInputKey(Param), False);
end;

class procedure TInput.OnKeyDown(Param: LongInt); stdcall;
begin
  Input.SetState(TInputKey(Param), True);
end;

class procedure TInput.onActivate(Param: LongInt); stdcall;
begin
  if Param <> 0 then
    Input.Reset;
end;

procedure TInput.SetState(InputKey: TInputKey; Value: Boolean);
begin
  if FDown[InputKey] and (not Value) then
  begin
    FHit[InputKey] := True;
    FLastKey := InputKey;
  end;
  FDown[InputKey] := Value;
end;

function TInput.GetLastKey: TInputKey;
begin
  Result := FLastKey;
end;

function TInput.IsKeyDown(Value: TInputKey): Boolean;
begin
  Result := FDown[Value];
end;

function TInput.IsKeyHit(Value: TInputKey): Boolean;
begin
  Result := FHit[Value];
end;

function TInput.GetMouse: TMouse;
begin
  Result := FMouse;
end;

procedure TInput.SetCapture(Value: Boolean);
begin
  FCapture := Value;
end;

procedure TInput.Update;
var
  Rect : TRect;
  Pos  : TPoint;
  CPos : TPoint;
begin
  FillChar(FHit, SizeOf(FHit), False);
  GetWindowRect(Display.Handle, Rect);
  GetCursorPos(Pos);

  if not FCapture then
  begin
    ScreenToClient(Display.Handle, Pos);
    FMouse.Delta.X := Pos.X - FMouse.Pos.X;
    FMouse.Delta.Y := Pos.Y - FMouse.Pos.Y;
    FMouse.Pos.X := Pos.X;
    FMouse.Pos.Y := Pos.Y;
  end else
    if Display.Active then
    begin
      CPos.X := (Rect.Right + Rect.Left) div 2;
      CPos.Y := (Rect.Bottom + Rect.Top) div 2;

      FMouse.Delta.X := Pos.X - CPos.X;
      FMouse.Delta.Y := Pos.Y - CPos.Y;

      if (FMouse.Delta.X <> 0) or (FMouse.Delta.Y <> 0) then
        SetCursorPos(CPos.X, CPos.Y);

      Inc(FMouse.Pos.X, FMouse.Delta.X);
      Inc(FMouse.Pos.Y, FMouse.Delta.Y);
    end else
    begin
      FMouse.Delta.X := 0;
      FMouse.Delta.Y := 0;
    end;
end;



end.
