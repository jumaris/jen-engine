program Test;

uses
  SomeGame in 'SomeGame.pas',
  JEN_Main in '..\..\Jen Engine\JEN_Main.pas',
  JEN_Display in '..\..\Jen Engine\Core\JEN_Display.pas',
  JEN_Display_Window in '..\..\Jen Engine\Core\JEN_Display_Window.pas',
  JEN_Game in '..\..\Jen Engine\Core\JEN_Game.pas',
  JEN_DefConsoleLog in '..\..\Jen Engine\Log\JEN_DefConsoleLog.pas',
  JEN_Log in '..\..\Jen Engine\Log\JEN_Log.pas',
  JEN_OpenGL in '..\..\Jen Engine\Render\JEN_OpenGL.pas',
  JEN_Render in '..\..\Jen Engine\Render\JEN_Render.pas',
  JEN_Window in '..\..\Jen Engine\Windows\JEN_Window.pas',
  JEN_Math in '..\..\Jen Engine\Utils\JEN_Math.pas',
  JEN_OpenGLHeader in '..\..\Jen Engine\Utils\JEN_OpenGLHeader.pas',
  JEN_SystemInfo in '..\..\Jen Engine\Utils\JEN_SystemInfo.pas',
  JEN_Utils in '..\..\Jen Engine\Utils\JEN_Utils.pas',
  XSystem in '..\..\Jen Engine\Utils\XSystem.pas',
  JEN_Camera3D in '..\..\Jen Engine\Core\JEN_Camera3D.pas';

{$IFDEF DEBUG}
  {$APPTYPE CONSOLE}
{$EndIf}

{$R *.res}
{$R ..\..\icon.RES}

var x : String;
begin
  Game := TSameGame.Create;
  Game.Run;
  Game.Free;
  {$IFDEF DEBUG}
  readln(x);
  {$EndIf}
end.


