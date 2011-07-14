unit JEN_Log;
{$I Jen_config.INC}

interface

uses
  JEN_Header,
  JEN_Utils;

type
  TLog = class(TInterfacedObject, ILog)
  constructor Create;
  destructor Destroy; Override;
  protected
    class var FLogOutputs : TInterfaceList;
  public
    procedure RegisterOutput(Value : ILogOutput); stdcall;
    procedure Print(const Text: String; MType: TLogMsg); stdcall;
    class property LogOutputs : TInterfaceList read fLogOutputs;
  end;

  TFileLog = class(TInterfacedObject, ILogOutput)
  constructor Create(FileName : String);
  destructor Destroy; override;
  private
    Stream : TFileStream;
    LastUpdate : LongInt;
  public
    procedure Init; stdcall;
    procedure AddMsg(const Text: String; MType: TLogMsg); stdcall;
  end;

implementation

uses
  JEN_MAIN;

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

procedure TLog.RegisterOutput(Value : ILogOutput); stdcall;
begin
  if not Assigned(Value) then
  begin
    Print('Output is not assigned', lmWarning);
    Exit;
  end;

  FLogOutputs.Add(Value, False);
  Value.Init;
end;

procedure TLog.Print(const Text: String; MType: TLogMsg);
var
  i : LongInt;
begin
  for i := 0 to fLogOutputs.Count - 1 do
    ILogOutput(fLogOutputs[i]).AddMsg(Text, MType);
end;

constructor TFileLog.Create(FileName : String);
begin
  Stream := TFileStream.Open(FileName, True);
end;

destructor TFileLog.Destroy;
begin
  if Assigned(Stream) then
    Stream.Free;
end;

procedure TFileLog.Init;
var
  S : AnsiString;
  Major : LongInt;
  Minor : LongInt;
  Build : LongInt;
begin
  Helpers.SystemInfo.WindowsVersion(Major, Minor, Build);
  SetLength(S,80);
  FillChar(S[1],80,ord('*'));
  AddMsg(String(s),lmHeaderMsg);
  AddMsg('JenEngine',lmHeaderMsg);
  AddMsg('Windows version: '+Utils.IntToStr(Major)+'.'+Utils.IntToStr(Minor)+' (Buid '+Utils.IntToStr(Build)+')'+Utils.IntToStr(Helpers.SystemInfo.CPUCount),lmHeaderMsg);
  AddMsg('CPU            : '+Helpers.SystemInfo.CPUName+'(~'+Utils.IntToStr(Helpers.SystemInfo.CPUSpeed)+')x',lmHeaderMsg);
  AddMsg('RAM Available  : '+Utils.IntToStr(Helpers.SystemInfo.RAMFree)+'Mb',lmHeaderMsg);
  AddMsg('RAM Total      : '+Utils.IntToStr(Helpers.SystemInfo.RAMTotal)+'Mb',lmHeaderMsg);
  AddMsg(String(s),lmHeaderMsg);
  LastUpdate := Utils.Time;
end;

procedure TFileLog.AddMsg(const Text: String; MType: TLogMsg);
var
  str,line : String;
  tstr : String;
  TimeStr : String;
  h,m,s,start,i,j : LongInt;
begin
  if Pointer(Text) = nil then
    Exit;

  h := Trunc(Utils.Time/3600000);
  m := Trunc(Utils.Time/60000);
  s := Trunc(Utils.Time/1000) - m*60;
  m := m - h*60;

  TimeStr := '';
  if h > 0 then
    TimeStr := Utils.IntToStr(h) + ':';

  tstr := '0' + Utils.IntToStr(m);
  TimeStr := TimeStr + Copy(tstr, Length(tstr)-1, 2) + ':';

  tstr := '0' + Utils.IntToStr(s);
  TimeStr := TimeStr + Copy(tstr, Length(tstr)-1, 2) + ' ';

  if (Utils.Time - LastUpdate > 9999) then
    tstr := '9999'
  else
    tstr := '0000' + Utils.IntToStr(Utils.Time - LastUpdate);

  TimeStr := TimeStr + Copy(tstr, Length(tstr)-3, 4);

  case MType of
    lmHeaderMsg,lmInfo:
      str := Text+#13#10;

    lmNotify :
      str := '[' + TimeStr + 'ms] ' + Text+#13#10;

    lmCode:
      begin
        i := 1;
        j := 1;
        str := 'Source code:'+#13#10;

        while Text[i] <> #0 do
        begin
          start := i;
          while not (AnsiChar(Text[i]) in [#0, #09, #10, #13]) do Inc(i);

          if Text[i] = #0 then
            break;

          if Text[i] = #09 then
          begin
            line := line + Copy(Text, start, i-start) + '   ';
            Inc(i);
            Continue;
          end;

          tstr := '000'+ Utils.IntToStr(j);
          str := str + Copy(tstr, Length(tstr)-2, 3) + ':' + Line + Copy(Text, start, i-start) + #13#10;
          Line := '';
          Inc(j);

          if Text[i] = #13 then Inc(i);
          if Text[i] = #10 then Inc(i);
        end;

      end;

    lmWarning :
      str := '[' + TimeStr + 'ms] WARNING: ' + Text+#13#10;

    lmError :
      str := '[' + TimeStr + 'ms] ERROR: ' + Text+#13#10;
  end;
  LastUpdate := Utils.Time;

  Stream.Write(str[1], Length(str)*2);
end;

end.
