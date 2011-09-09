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

  TResource = class(TManagedInterface)
    constructor Create(const Name, FilePath: string; ResType: TResourceType);
  protected
    FName     : string;
    FFilePath : string;
    FResType  : TResourceType;
    function GetResType: TResourceType; stdcall;
    function GetName: string; stdcall;
    function GetFilePath: string; stdcall;
  end;

implementation

uses
  JEN_Main;

constructor TResource.Create(const Name, FilePath: string; ResType: TResourceType);
begin
  FFilePath := FilePath;
  if Name <> '' then
    FName := Name
  else
    FName := '$' + Utils.IntToStr(LongInt(Self));
  FResType := ResType;
end;

function TResource.GetResType;
begin
  Result := FResType;
end;

function TResource.GetName: string;
begin
  Result := FName;
end;

function TResource.GetFilePath: string;
begin
  Result := FFilePath;
end;

end.
