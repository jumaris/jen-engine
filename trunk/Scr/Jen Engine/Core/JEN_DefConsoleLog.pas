unit JEN_DefConsoleLog;
{$I Jen_config.INC}

interface

{$IFDEF LOG}
uses
  JEN_Log;

type TDefConsoleLog = class(TLogOutput)
  private
    LastUpdate : LongInt;
  public
    procedure BeginHeader; override;
    procedure EndHeader; override;
    procedure AddMsg(const Text: String; MType: TLogMsg); override;
  end;
{$ENDIF}

implementation

{$IFDEF LOG}
uses
  JEN_MAIN;

procedure TDefConsoleLog.BeginHeader;
begin
  Writeln('*******************************************************************************');
  LastUpdate := Utils.Time;
end;

procedure TDefConsoleLog.EndHeader;
begin
  BeginHeader;
end;

procedure TDefConsoleLog.AddMsg(const Text: String; MType: TLogMsg);
var
  str  : String;
  tstr : String;
  h,m,s : LongInt;
begin
  case MType of
    lmHeaderMsg :
      Writeln(Text);

    lmNotify :
      begin       {
        Str := '00000';
        tstr := Utils.IntToStr(Round(Utils.Time/1000));
        Move(tstr[1], str[6-length(tstr)], length(tstr)*2);
                 }
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
        Writeln('[' + str + 'ms] ' + Text);
      end;

    lmInfo :
      Writeln(Text);

    lmWarning :
      Writeln('WARNING: ' + Text);

    lmError :
      Writeln('ERROR: ' + Text);
  end;
  LastUpdate := Utils.Time;
end;
{$ENDIF}

end.

