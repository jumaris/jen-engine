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
    procedure AddMsg( const Text : String; MType : TLogMsg ); override;
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

procedure TDefConsoleLog.AddMsg( const Text : String; MType : TLogMsg );
var
  i    : Byte;
  str  : String;
  tstr : String;
begin
  case MType of
    LM_HEADER_MSG :
      Writeln(Text);

    LM_NOTIFY :
      begin
        Str := '00000';
        tstr := Utils.IntToStr(Round(Utils.Time/1000));
        Move(tstr[1], str[6-length(tstr)], length(tstr)*2);

        Str := Str + 's:0000000';
        tstr := Utils.IntToStr(Utils.Time - LastUpdate);
        Move(tstr[1], str[15-length(tstr)], length(tstr)*2);
        Writeln('[' + str + 'ms] ' + Text);
      end;

    LM_INFO :
      Writeln(Text);

    LM_WARNING :
      Writeln('WARNING: ' + Text);

    LM_ERROR :
      Writeln('ERROR: ' + Text);
  end;
  LastUpdate := Utils.Time;
end;
{$ENDIF}

end.

