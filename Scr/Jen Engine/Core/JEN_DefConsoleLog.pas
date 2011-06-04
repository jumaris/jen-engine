unit JEN_DefConsoleLog;
{$I Jen_config.INC}

interface

{$IFDEF JEN_LOG}
uses
  JEN_Header,
  JEN_Utils,
  JEN_Log;
                   {
type TDefConsoleLog = class(TManagedInterface, ILogOutput)
  private
    LastUpdate : LongInt;
  public
    procedure Init; stdcall;
    procedure AddMsg(const Text: String; MType: TLogMsg); stdcall;
  end;      }
{$ENDIF}

implementation

{$IFDEF JEN_LOG}      {
uses
  JEN_MAIN;

procedure TDefConsoleLog.Init;
var
  S : AnsiString;
  Major : LongInt;
  Minor : LongInt;
  Build : LongInt;
begin
  SystemParams.WindowsVersion(Major, Minor, Build);
  SetLength(S,80);
  FillChar(S[1],80,ord('*'));
  Write(s);
  Writeln('JenEngine');
  Writeln('Windows version: '+Utils.IntToStr(Major)+'.'+Utils.IntToStr(Minor)+' (Buid '+Utils.IntToStr(Build)+')');
  Writeln('CPU            : '+SystemParams.CPUName+'(~'+Utils.IntToStr(SystemParams.CPUSpeed)+')x'+Utils.IntToStr(SystemParams.CPUCount));
  Writeln('RAM Available  : '+Utils.IntToStr(SystemParams.RAMFree)+'Mb');
  Writeln('RAM Total      : '+Utils.IntToStr(SystemParams.RAMTotal)+'Mb');
  Write(s);
  LastUpdate := Utils.Time;
end;

procedure TDefConsoleLog.AddMsg(const Text: String; MType: TLogMsg);
var
  str : String;
  tstr : String;
  h,m,s,start,i,j : LongInt;
begin
  if Pointer(Text) = nil then
    Exit;

  h := Trunc(Utils.Time/3600000);
  m := Trunc(Utils.Time/60000);
  s := Trunc(Utils.Time/1000) - m*60;
  m := m - h*60;

  Str := '';
  if h > 0 then
    Str := Utils.IntToStr(h) + ':';

  if m < 10 then
    Str := Str + '0';

  Str := Str + Utils.IntToStr(m) + ':';

  if s < 10 then
    Str := Str + '0';

  Str := Str + Utils.IntToStr(s) + ' 0000000';

  tstr := Utils.IntToStr(Utils.Time - LastUpdate);
  Move(tstr[1], str[length(Str)-length(tstr)], length(tstr)*2);

  case MType of
    lmHeaderMsg :
      Writeln(Text);

    lmNotify :
      begin       {
        Str := '00000';
        tstr := Utils.IntToStr(Round(Utils.Time/1000));
        Move(tstr[1], str[6-length(tstr)], length(tstr)*2);
                 }
      {
        Writeln('[' + str + 'ms] ' + Text);
      end;

    lmInfo :
      Writeln(Text);

    lmCode:
      begin
        i := 1;
        j := 1;
        str := '';

        Writeln('Source code:');
        while Text[i] <> #0 do
        begin
          start := i;
          while not (Text[i] in [#0, #09, #10, #13]) do Inc(i);

          if Text[i] = #0 then
            break;

          if Text[i] = #09 then
          begin
            str := str + Copy(Text, start, i-start) + '   ';
            Inc(i);
            Continue;
          end;

          Writeln(Utils.IntToStr(j), ':', str, Copy(Text, start, i-start));
          str := '';
          Inc(j);

          if Text[i] = #13 then Inc(i);
          if Text[i] = #10 then Inc(i);
        end;

      end;

    lmWarning :
      Writeln('[' + str + 'ms] WARNING: ' + Text);

    lmError :
      Writeln('[' + str + 'ms] ERROR: ' + Text);
  end;
  LastUpdate := Utils.Time;
end;    }
{$ENDIF}

end.

