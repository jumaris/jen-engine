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

implementation


initialization
begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$EndIf}
  TUtils.Create;
  TSystem.Create;
  TLog.Create;
{$IFDEF DEBUG}
  TDefConsoleLog.Create;
{$EndIf}
  Log.Init;
end;

finalization
begin
  Utils.Free;
  SystemInfo.Free;
  Log.Free;
end;



end.
