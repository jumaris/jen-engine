unit JEN_Log;
{$I Jen_config.INC}

interface

uses
  JEN_Header,
  JEN_Utils;

type
  ILog = interface(JEN_Header.ILog)
    procedure Init;
  end;

  TLog = class(TInterfacedObject, ILog)
  constructor Create;
  destructor Destroy; Override;
  protected
    class var {$IFDEF JEN_LOG}fLogOutputs : TInterfaceList;{$ENDIF}
  public
    procedure Init;
    procedure RegisterOutput(Value : ILogOutput); stdcall;
    procedure Print(const Text: String; MType: TLogMsg); stdcall;
    class property LogOutputs : TInterfaceList read fLogOutputs;
  end;

implementation

{$IFDEF JEN_LOG}
constructor TLog.Create;
begin
  inherited;
  fLogOutputs := TInterfaceList.Create;
end;

destructor TLog.Destroy;
begin
  fLogOutputs.Free;
  inherited;
end;

procedure TLog.Init;        
var
  i : LongInt;
begin
  for i := 0 to fLogOutputs.Count - 1 do
    with ILogOutput(fLogOutputs[i]) do
      Init;
end;

procedure TLog.RegisterOutput(Value : ILogOutput); stdcall;
begin
  if not Assigned(Value) then
  begin
    Print('Output is not assigned', lmWarning);
    Exit;
  end;

  fLogOutputs.Add(Value);
  Value.Init;
end;

procedure TLog.Print(const Text: String; MType: TLogMsg);
var
  i : LongInt;
begin
  for i := 0 to fLogOutputs.Count - 1 do
    ILogOutput(fLogOutputs[i]).AddMsg(Text, MType);
end;
{$ELSE}

{$ENDIF}

end.
