unit JEN_Log;
{$I Jen_config.INC}

interface

uses
  JEN_Header,
  JEN_Utils,
  JEN_SystemInfo;

type
  TLogOutput = class
  constructor Create;
  public
    procedure BeginHeader; virtual; abstract;
    procedure EndHeader; virtual; abstract;
    procedure AddMsg(const Text: String; MType: TLogMsg); virtual; abstract;
  end;

  ILog = interface(JEN_Header.ILog)
    procedure Init;
  end;

  TLog = class(TInterfacedObject,  ILog)
  constructor Create;
  destructor Destroy; Override;
  protected
    class var {$IFDEF JEN_LOG}fLogOutputs : TList;{$ENDIF}
  public
    procedure Init;
    procedure Print(const Text: String; MType: TLogMsg); stdcall;
    class property LogOutputs : TList read fLogOutputs;
  end;

implementation

{$IFDEF JEN_LOG}
uses
  JEN_Main;

constructor TLogOutput.Create;
begin
  inherited;
  TLog.LogOutputs.Add(self);
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
  i,j   : Integer;
  Major : LongInt;
  Minor : LongInt;
  Build : LongInt;
begin
  SystemParams.WindowsVersion(Major, Minor, Build);
  for i := 0 to fLogOutputs.Count - 1 do
  with TLogOutput(fLogOutputs[i]) do
    begin
      BeginHeader;
      AddMsg('JEngine', lmHeaderMsg);
      AddMsg('Windows version: '+Utils.IntToStr(Major)+'.'+Utils.IntToStr(Minor)+' (Buid '+Utils.IntToStr(Build)+')', lmHeaderMsg);
      AddMsg('CPU            : '+SystemParams.CPUName+'(~'+Utils.IntToStr(SystemParams.CPUSpeed)+')x'+Utils.IntToStr(SystemParams.CPUCount), lmHeaderMsg);
      AddMsg('RAM Available  : '+Utils.IntToStr(SystemParams.RAMFree)+'Mb', lmHeaderMsg);
      AddMsg('RAM Total      : '+Utils.IntToStr(SystemParams.RAMTotal)+'Mb', lmHeaderMsg);
      EndHeader;
    end;
                         {
  with SystemParams.Screen do
  for I := 0 to GetModesCount -1 do
    for J := 0 to Modes[i].RefreshRates.Count-1 do
      LogOut( Utils.Conv(Modes[i].Width) + 'x' + Utils.Conv(Modes[i].Height) + 'x' + Utils.Conv(Modes[i].RefreshRates.Refresh[j]), lmInfo);
              }
end;


procedure TLog.Print(const Text: String; MType: TLogMsg);
var
  i : Integer;
begin
  for i := 0 to fLogOutputs.Count - 1 do
    TLogOutput(fLogOutputs[i]).AddMsg(Text, MType);
end;
{$ELSE}

{$ENDIF}

end.
