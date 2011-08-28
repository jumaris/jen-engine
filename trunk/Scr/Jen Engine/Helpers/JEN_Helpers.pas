unit JEN_Helpers;

interface

uses
  JEN_Header,
  JEN_Camera3D,
  JEN_SystemInfo;

type
  THelpers = class(TInterfacedObject, IHelpers)
    constructor Create;
    procedure Free; stdcall;
  private
    FSystemInfo: ISystemInfo;
    function GetSystemInfo: ISystemInfo; stdcall;
  public
    function CreateLogFileOutput(FileName: String): ILogOutput; stdcall;
    function CreateCamera3D: ICamera3d; stdcall;
  end;

implementation

uses
  JEN_Log;

constructor THelpers.Create;
begin
  FSystemInfo := TSystem.Create;
end;

procedure THelpers.Free;
begin
end;

function THelpers.GetSystemInfo: ISystemInfo;
begin
  Result := FSystemInfo;
end;

function THelpers.CreateLogFileOutput(FileName: String): ILogOutput;
begin
  Result := TFileLog.Create(FileName);
end;

function THelpers.CreateCamera3D: ICamera3d;
begin
  Result := TCamera3D.Create;
end;

end.
