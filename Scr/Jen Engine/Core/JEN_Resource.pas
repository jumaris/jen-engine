unit JEN_Resource;

interface

uses
  JEN_Header,
  JEN_Utils;

const
  TResourceStringName : array[TResourceType] of string = ('shader', 'font', 'texture', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '');

type
  TResLoader = class
  public
    ExtString : string;
    ResType : TResourceType;
    function Load(Stream: IStream; var Resource: IResource): Boolean; virtual; abstract;
  end;

  TResource = class(TInterfacedObject)
    constructor Create(const FilePath: string; ResType: TResourceType);
  protected
    FName     : string;
    FFilePath : string;
    FResType  : TResourceType;
    function GetResType: TResourceType; stdcall;
    function GetName: PWideChar; stdcall;
    function GetFilePath: PWideChar; stdcall;
  end;

implementation

uses
  JEN_Main;

constructor TResource.Create(const FilePath: string; ResType: TResourceType);
begin
  FFilePath := Utils.ExtractFileDir(PWideChar(FilePath));
  if FilePath <> '' then
    FName := Utils.ExtractFileName(PWideChar(FilePath))
  else
    FName := '$' + Utils.IntToStr(LongInt(Self));
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
