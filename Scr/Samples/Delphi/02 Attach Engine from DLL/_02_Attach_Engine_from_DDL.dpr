program _02_Attach_Engine_from_DDL;

uses
  JEN_Header in '..\..\..\Include\Delphi\JEN_Header.pas';

{$R *.res}
{$R ..\..\..\icon.RES}

var Engine : IJenEngine;
begin
  GetEngine(Engine);
end.
