library JEN;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

uses
  SysUtils,
  Classes,
  JEN_Header in '..\Include\Delphi\JEN_Header.pas',
  JEN_Math in '..\Include\Delphi\JEN_Math.pas',
  JEN_Main in '..\Jen Engine\JEN_Main.pas',
  JEN_Console in '..\Jen Engine\Core\JEN_Console.pas',
  JEN_DDSTexture in '..\Jen Engine\Core\JEN_DDSTexture.pas',
  JEN_Debugger in '..\Jen Engine\Core\JEN_Debugger.pas',
  JEN_Display in '..\Jen Engine\Core\JEN_Display.pas',
  JEN_Font in '..\Jen Engine\Core\JEN_Font.pas',
  JEN_Game in '..\Jen Engine\Core\JEN_Game.pas',
  JEN_Input in '..\Jen Engine\Core\JEN_Input.pas',
  JEN_OpenGLHeader in '..\Jen Engine\Core\JEN_OpenGLHeader.pas',
  JEN_Resource in '..\Jen Engine\Core\JEN_Resource.pas',
  JEN_ResourceManager in '..\Jen Engine\Core\JEN_ResourceManager.pas',
  JEN_GeometryBuffer in '..\Jen Engine\Render\JEN_GeometryBuffer.pas',
  JEN_Render in '..\Jen Engine\Render\JEN_Render.pas',
  JEN_Render2D in '..\Jen Engine\Render\JEN_Render2D.pas',
  JEN_RenderTarget in '..\Jen Engine\Render\JEN_RenderTarget.pas',
  JEN_Shader in '..\Jen Engine\Render\JEN_Shader.pas',
  JEN_Texture in '..\Jen Engine\Render\JEN_Texture.pas',
  CoreX_XML in '..\Jen Engine\Helpers\CoreX_XML.pas',
  JEN_Camera2D in '..\Jen Engine\Helpers\JEN_Camera2D.pas',
  JEN_Camera3D in '..\Jen Engine\Helpers\JEN_Camera3D.pas',
  JEN_Helpers in '..\Jen Engine\Helpers\JEN_Helpers.pas',
  JEN_SystemInfo in '..\Jen Engine\Helpers\JEN_SystemInfo.pas';

exports
  GetEngine name 'GetJenEngine';

{$R ..\Resources\Resources.RES}

begin
  ReportMemoryLeaksOnShutdown := True;
  Engine := nil;
end.
