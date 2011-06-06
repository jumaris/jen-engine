unit JEN_Helpers;

interface

uses
  JEN_Header,
  JEN_Camera3D,
  JEN_SystemInfo;

type
  THelpers = class(TInterfacedObject, IHelpers)
    constructor Create;
  private
    FSystemInfo: ISystemInfo;
    function GetSystemInfo: ISystemInfo; stdcall;
  public
    function CreateCamera3D: ICamera3d; stdcall;
  end;

implementation

constructor THelpers.Create;
begin
  FSystemInfo := TSystem.Create;
end;

function THelpers.GetSystemInfo: ISystemInfo;
begin
  Result := FSystemInfo;
end;

function THelpers.CreateCamera3D: ICamera3d;
begin
  Result := TCamera3D.Create;
end;


end.
