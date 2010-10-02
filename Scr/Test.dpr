program Test;

uses
  JEN_Main in 'JEN_Main.pas',
  JEN_SystemInfo in 'Utils\JEN_SystemInfo.pas',
  JEN_Utils in 'Utils\JEN_Utils.pas',
  JEN_Window in 'Windows\JEN_Window.pas',
  XSystem in 'Utils\XSystem.pas',
  JEN_Game in 'JEN_Game.pas',
  SomeGame in 'SomeGame.pas',
  JEN_Log in 'Log\JEN_Log.pas',
  JEN_DefConsoleLog in 'Log\JEN_DefConsoleLog.pas',
  JEN_OpenGLHeader in 'Utils\JEN_OpenGLHeader.pas',
  JEN_OpenGL in 'Render\JEN_OpenGL.pas',
  JEN_Render in 'Render\JEN_Render.pas',
  JEN_Math in 'Utils\JEN_Math.pas',
  Engine in 'Engine.pas';

{$IFDEF DEBUG}
  {$APPTYPE CONSOLE}
{$EndIf}

{$R *.res}
{$R icon.RES}

var x : String;
begin
  Game := TSameGame.Create;
  Game.Run;
  Game.Free;
  readln(x);
end.


