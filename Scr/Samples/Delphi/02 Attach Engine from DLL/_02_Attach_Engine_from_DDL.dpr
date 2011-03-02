program _02_Attach_Engine_from_DDL;

uses
  JEN_Header in '..\..\..\Include\Delphi\JEN_Header.pas';

{$R *.res}
{$R ..\..\..\icon.RES}

var Engine : IJenEngine;
var Display : IDisplay;
begin
  GetEngine(Engine);
  //Engine.GetSubSystem(ssDisplay, IEngineSubSystem(Display));
//  Display.Init;
end.
