unit JEN_Log;
{$I Jen_config.INC}

interface

{$IFDEF LOG}
uses
  JEN_Utils,
  JEN_SystemInfo;

type
  TLogMsg = ( LM_HEADER_MSG, LM_INFO, LM_NOTIFY, LM_WARNING, LM_ERROR );

  TLogOutput = class
  constructor Create;
  public
    procedure BeginHeader; virtual; abstract;
    procedure EndHeader; virtual; abstract;
    procedure AddMsg( const Text : String; MType : TLogMsg ); virtual; abstract;
  end;

  TLog = class
  constructor Create;
  destructor Destroy; Override;
  protected
    fLogOutputs : TList;
  public
    property LogOutputs : TList read fLogOutputs; 
    procedure Init;
    procedure AddMsg( const Text : String; MType : TLogMsg );
  end;

  procedure LogOut( const Text : String; MType : TLogMsg ); inline;

var
  Log : TLog;
{$ENDIF}

implementation

{$IFDEF LOG}
uses
  JEN_DefConsoleLog, JEN_OpenGlHeader;

constructor TLogOutput.Create;
begin
  inherited;
  Log.LogOutputs.Add(self);
end;

constructor TLog.Create;
begin
  inherited;
  Log := self;
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
  SystemInfo.WindowsVersion(Major, Minor, Build);
  for i := 0 to fLogOutputs.Count - 1 do
  with TLogOutput(fLogOutputs[i]) do
    begin
      BeginHeader;
      AddMsg( 'JEngine', LM_HEADER_MSG );
      AddMsg( 'Windows version: '+Utils.IntToStr(Major)+'.'+Utils.IntToStr(Minor)+' (Buid '+Utils.IntToStr(Build)+')', LM_HEADER_MSG);
      AddMsg( 'CPU            : '+SystemInfo.CPUName+'(~'+Utils.IntToStr(SystemInfo.CPUSpeed)+')x'+Utils.IntToStr(SystemInfo.CPUCount), LM_HEADER_MSG);
      AddMsg( 'RAM Available  : '+Utils.IntToStr(SystemInfo.RAMFree)+'Mb', LM_HEADER_MSG);
      AddMsg( 'RAM Total      : '+Utils.IntToStr(SystemInfo.RAMTotal)+'Mb', LM_HEADER_MSG);
      EndHeader;
    end;       {

  for I := 0 to SystemInfo.ModesCount-1 do
    for J := 0 to SystemInfo.Modes[i].RefreshRates.Count-1 do
      LogOut( Utils.IntToStr(SystemInfo.Modes[i].Width) + 'x' + Utils.IntToStr(SystemInfo.Modes[i].Height) + 'x' + Utils.IntToStr(SystemInfo.Modes[i].RefreshRates.Refresh[j]), LM_INFO);
              }
end;


procedure TLog.AddMsg( const Text : String; MType : TLogMsg );
var
  i : Integer;
begin
  for i := 0 to fLogOutputs.Count - 1 do
    TLogOutput(fLogOutputs[i]).AddMsg( Text, MType );
end;

procedure LogOut( const Text : String; MType : TLogMsg );
begin
  Log.AddMsg( Text, MType );
end;
{$ENDIF}

end.
