library JEN;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  JEN_Main in '..\Jen Engine\JEN_Main.pas',
  JEN_DDSTexture in '..\Jen Engine\Core\JEN_DDSTexture.pas',
  JEN_Display in '..\Jen Engine\Core\JEN_Display.pas',
  JEN_Log in '..\Jen Engine\Core\JEN_Log.pas',
  JEN_Resource in '..\Jen Engine\Core\JEN_Resource.pas',
  JEN_ResourceManager in '..\Jen Engine\Core\JEN_ResourceManager.pas',
  JEN_GeometryBuffer in '..\Jen Engine\Render\JEN_GeometryBuffer.pas',
  JEN_Render in '..\Jen Engine\Render\JEN_Render.pas',
  JEN_Shader in '..\Jen Engine\Render\JEN_Shader.pas',
  CoreX_XML in '..\Jen Engine\Utils\CoreX_XML.pas',
  JEN_Math in '..\Include\Delphi\JEN_Math.pas',
  JEN_OpenGLHeader in '..\Jen Engine\Utils\JEN_OpenGLHeader.pas',
  JEN_Utils in '..\Jen Engine\Utils\JEN_Utils.pas',
  JEN_Header in '..\Include\Delphi\JEN_Header.pas',
  JEN_Render2D in '..\Jen Engine\Render\JEN_Render2D.pas',
  JEN_Console in '..\Jen Engine\Core\JEN_Console.pas',
  JEN_Camera3D in '..\Jen Engine\Helpers\JEN_Camera3D.pas',
  JEN_SystemInfo in '..\Jen Engine\Helpers\JEN_SystemInfo.pas',
  JEN_Helpers in '..\Jen Engine\Helpers\JEN_Helpers.pas',
  JEN_Input in '..\Jen Engine\Core\JEN_Input.pas';

exports
  pGetEngine name 'GetJenEngine';

{$R *.res}
{$R ..\icon.RES}

begin

end.


