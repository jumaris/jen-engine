unit JEN_Resource;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils,
  JEN_Header,
  JEN_Helpers;

const
  TResourceStringName : array[TResourceType] of UnicodeString = ('shader', 'font', 'texture');

type
  TResLoader = class
  public
    ExtString : UnicodeString;
    ResType : TResourceType;
    function Load(Stream: IStream; var Resource: IResource): Boolean; virtual; abstract;
  end;

  TResource = class(TInterfacedObject)
    constructor Create(const FilePath: UnicodeString; ResType: TResourceType);
  protected
    FName     : UnicodeString;
    FFilePath : UnicodeString;
    FResType  : TResourceType;
    function GetResType: TResourceType; stdcall;
    function GetName: PWideChar; stdcall;
    function GetFilePath: PWideChar; stdcall;
  end;

implementation

uses
  JEN_Main;

constructor TResource.Create(const FilePath: UnicodeString; ResType: TResourceType);
begin
  FFilePath := FilePath;
  if FilePath <> '' then
    FName := ExtractFileName(FilePath)
  else
    FName := '$' + IntToStr(LongInt(Self));
  FResType := ResType;
end;

function TResource.GetResType;
begin
  Result := FResType;
end;

function TResource.GetName: PWideChar;
begin
  Result := PWideChar(FName);
end;

function TResource.GetFilePath: PWideChar;
begin
  Result := PWideChar(FFilePath);
end;

end.
