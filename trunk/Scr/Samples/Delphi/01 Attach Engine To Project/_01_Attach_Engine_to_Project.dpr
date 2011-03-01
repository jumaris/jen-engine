program _01_Attach_Engine_to_Project;

uses
  JEN_Main in '..\..\..\Jen Engine\JEN_Main.pas',
  JEN_OpenGL in '..\..\..\Jen Engine\Render\JEN_OpenGL.pas',
  JEN_Render in '..\..\..\Jen Engine\Render\JEN_Render.pas',
  JEN_Math in '..\..\..\Jen Engine\Utils\JEN_Math.pas',
  JEN_OpenGLHeader in '..\..\..\Jen Engine\Utils\JEN_OpenGLHeader.pas',
  JEN_SystemInfo in '..\..\..\Jen Engine\Utils\JEN_SystemInfo.pas',
  JEN_Utils in '..\..\..\Jen Engine\Utils\JEN_Utils.pas',
  XSystem in '..\..\..\Jen Engine\Utils\XSystem.pas',
  JEN_Camera3D in '..\..\..\Jen Engine\Core\JEN_Camera3D.pas',
  JEN_GeometryBuffer in '..\..\..\Jen Engine\Render\JEN_GeometryBuffer.pas',
  JEN_DefConsoleLog in '..\..\..\Jen Engine\Core\JEN_DefConsoleLog.pas',
  JEN_Display in '..\..\..\Jen Engine\Core\JEN_Display.pas',
  JEN_Display_Window in '..\..\..\Jen Engine\Core\JEN_Display_Window.pas',
  JEN_Log in '..\..\..\Jen Engine\Core\JEN_Log.pas',
  JEN_ResourceManager in '..\..\..\Jen Engine\Core\JEN_ResourceManager.pas',
  JEN_DDSTexture in '..\..\..\Jen Engine\Core\JEN_DDSTexture.pas',
  JEN_Shader in '..\..\..\Jen Engine\Render\JEN_Shader.pas',
  CoreX_XML in '..\..\..\Jen Engine\Utils\CoreX_XML.pas',
  JEN_Resource in '..\..\..\Jen Engine\Core\JEN_Resource.pas',
  JEN_Header in '..\..\..\Include\Delphi\JEN_Header.pas',
  SomeGame in 'SomeGame.pas';

{$R *.res}
{$R ..\..\..\icon.RES}


procedure pp;
var Engine : IJenEngine;
begin

  GetEngine(Engine);

end;

begin
 // Engine := nil;
 // Game := TSomeGame.Create;
  pp;

end.


