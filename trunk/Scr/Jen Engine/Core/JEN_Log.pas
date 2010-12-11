unit JEN_Log;
{$I Jen_config.INC}

interface

uses
  JEN_Utils,
  JEN_SystemInfo;

type
  TLogMsg = (lmHeaderMsg, lmInfo, lmNotify, lmWarning, lmError);

  TLogOutput = class
  constructor Create;
  public
    procedure BeginHeader; virtual; abstract;
    procedure EndHeader; virtual; abstract;
    procedure AddMsg(const Text: String; MType: TLogMsg); virtual; abstract;
  end;

  TLog = class
  constructor Create;
  destructor Destroy; Override;
  protected
    {$IFDEF LOG}fLogOutputs : TList;{$ENDIF}
  public
    property LogOutputs : TList read fLogOutputs; 
    procedure Init;
    procedure AddMsg(const Text: String; MType: TLogMsg);
  end;

implementation

{$IFDEF LOG}
uses
  JEN_Main,
  JEN_DefConsoleLog,
  JEN_OpenGlHeader;

constructor TLogOutput.Create;
begin
  inherited;
  Log.LogOutputs.Add(self);
end;

constructor TLog.Create;
begin
  inherited;
  fLogOutputs := TList.Create;
end;

destructor TLog.Destroy;
var  
  i : integer;
begin
  for I := 0 to fLogOutputs.Count - 1 do
     TObject(fLogOutputs[i]).Free;    
  fLogOutputs.Free;
  inherited;
end;

procedure TLog.Init;
var
  i,j       : Integer;
  Major     : LongInt;
  Minor     : LongInt;
  Build     : LongInt;
begin
  SystemParams.WindowsVersion(Major, Minor, Build);
  for i := 0 to fLogOutputs.Count - 1 do
  with TLogOutput(fLogOutputs[i]) do
    begin
      BeginHeader;
      AddMsg('JEngine', lmHeaderMsg);
      AddMsg('Windows version: '+Utils.Conv(Major)+'.'+Utils.Conv(Minor)+' (Buid '+Utils.Conv(Build)+')', lmHeaderMsg);
      AddMsg('CPU            : '+SystemParams.CPUName+'(~'+Utils.Conv(SystemParams.CPUSpeed)+')x'+Utils.Conv(SystemParams.CPUCount), lmHeaderMsg);
      AddMsg('RAM Available  : '+Utils.Conv(SystemParams.RAMFree)+'Mb', lmHeaderMsg);
      AddMsg('RAM Total      : '+Utils.Conv(SystemParams.RAMTotal)+'Mb', lmHeaderMsg);
      EndHeader;
    end;
                         {
  with SystemParams.Screen do
  for I := 0 to GetModesCount -1 do
    for J := 0 to Modes[i].RefreshRates.Count-1 do
      LogOut( Utils.Conv(Modes[i].Width) + 'x' + Utils.Conv(Modes[i].Height) + 'x' + Utils.Conv(Modes[i].RefreshRates.Refresh[j]), lmInfo);
              }
end;


procedure TLog.AddMsg(const Text: String; MType: TLogMsg);
var
  i : Integer;
begin
  for i := 0 to fLogOutputs.Count - 1 do
    TLogOutput(fLogOutputs[i]).AddMsg(Text, MType);
end;
{$ELSE}

{$ENDIF}

end.
