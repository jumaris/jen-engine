unit JEN_Main;

interface

uses
  JEN_Utils,
  JEN_SystemInfo,
  JEN_Window,
  JEN_Game,
  JEN_Log,
  JEN_DefConsoleLog,
  JEN_OpenGLHeader,
  JEN_OpenGL,
  JEN_Render,
  JEN_Math;

const
  LM_INFO       = TLogMsg.LM_INFO;
  LM_NOTIFY     = TLogMsg.LM_NOTIFY;
  LM_WARNING    = TLogMsg.LM_WARNING;
  LM_ERROR      = TLogMsg.LM_ERROR;

var
  Utils        : TUtils;
  SystemParams : TSystem;
  Log          : TLog;

procedure LogOut( const Text : String; MType : TLogMsg );

implementation

procedure LogOut( const Text : String; MType : TLogMsg );
begin
  Log.AddMsg( Text, MType );
end;

initialization
begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$EndIf}
  Utils := TUtils.Create;
  SystemParams := TSystem.Create;
  Log := TLog.Create;
{$IFDEF DEBUG}
  TDefConsoleLog.Create;
{$EndIf}
  Log.Init;
end;

finalization
begin
  Utils.Free;
  SystemParams.Free;
  Log.Free;
end;



end.
