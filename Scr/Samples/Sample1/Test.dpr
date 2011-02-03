program Test;

uses
  SomeGame in 'SomeGame.pas',
  JEN_Main in '..\..\Jen Engine\JEN_Main.pas',
  JEN_OpenGL in '..\..\Jen Engine\Render\JEN_OpenGL.pas',
  JEN_Render in '..\..\Jen Engine\Render\JEN_Render.pas',
  JEN_Math in '..\..\Jen Engine\Utils\JEN_Math.pas',
  JEN_OpenGLHeader in '..\..\Jen Engine\Utils\JEN_OpenGLHeader.pas',
  JEN_SystemInfo in '..\..\Jen Engine\Utils\JEN_SystemInfo.pas',
  JEN_Utils in '..\..\Jen Engine\Utils\JEN_Utils.pas',
  XSystem in '..\..\Jen Engine\Utils\XSystem.pas',
  JEN_Camera3D in '..\..\Jen Engine\Core\JEN_Camera3D.pas',
  JEN_GeometryBuffer in '..\..\Jen Engine\Render\JEN_GeometryBuffer.pas',
  JEN_DefConsoleLog in '..\..\Jen Engine\Core\JEN_DefConsoleLog.pas',
  JEN_Display in '..\..\Jen Engine\Core\JEN_Display.pas',
  JEN_Display_Window in '..\..\Jen Engine\Core\JEN_Display_Window.pas',
  JEN_Game in '..\..\Jen Engine\Core\JEN_Game.pas',
  JEN_Log in '..\..\Jen Engine\Core\JEN_Log.pas',
  JEN_ResourceManager in '..\..\Jen Engine\Core\JEN_ResourceManager.pas',
  JEN_DDSTexture in '..\..\Jen Engine\Core\JEN_DDSTexture.pas';

{$IFDEF DEBUG}
  {$APPTYPE CONSOLE}
{$EndIf}

{$R *.res}
{$R ..\..\icon.RES}

var h : THandle;
begin
  Game := TSameGame.Create;
  Game.Run;
  Game.Free;
  {$IFDEF DEBUG}
  h := CreateEventW(nil, true, false, '');
  WaitForSingleObject(h, 2500);
  {$EndIf}
end.


