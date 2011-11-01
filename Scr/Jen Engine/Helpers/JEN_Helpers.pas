unit JEN_Helpers;

interface

uses
  JEN_Header,
  JEN_Utils,
  JEN_Camera2D,
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
    function CreateStream(FileName: PWideChar; RW: Boolean): IStream; stdcall;
    function CreateCamera3D: ICamera3d; stdcall;
    function CreateCamera2D: ICamera2d; stdcall;
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

function THelpers.CreateStream(FileName: PWideChar; RW: Boolean): IStream;
begin
  Result := TStream.Create(FileName, RW);
end;

function THelpers.CreateCamera3D: ICamera3d;
begin
  Result := TCamera3D.Create;
end;

function THelpers.CreateCamera2D: ICamera2d;
begin
  Result := TCamera2D.Create;
end;


end.
