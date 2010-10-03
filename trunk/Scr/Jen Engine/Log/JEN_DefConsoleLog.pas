unit JEN_DefConsoleLog;
{$I Jen_config.INC}

interface

{$IFDEF LOG}
uses
  JEN_Log;

type TDefConsoleLog = class(TLogOutput)
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
end;

procedure TDefConsoleLog.EndHeader;
begin
  BeginHeader;
end;

procedure TDefConsoleLog.AddMsg( const Text : String; MType : TLogMsg );
var
  i   : Byte;
  str : String;
begin
  case MType of
    LM_HEADER_MSG :
      Writeln( Text );

    LM_NOTIFY :
      begin
        str  := Utils.IntToStr( Utils.Time );
        for i := 0 to 6 - Length(str) do
          str := '0' + str;
        Writeln(  '[' + str + 'ms] ' + Text );
      end;

    LM_INFO :
      Writeln( Text );

    LM_WARNING :
      Writeln( 'WARNING: ' + Text );

    LM_ERROR :
      Writeln( 'ERROR: ' + Text );
  end;
end;
{$ENDIF}

end.

