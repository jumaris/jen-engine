unit JEN_Resource;

interface

uses
  JEN_Header,
  JEN_Utils;

const
  TResourceStringName : array[TResourceType] of string = ('shader', 'texture');

type
  TResource = class(TInterfacedObject, IResource)
    constructor Create(const Name: string); virtual;
  public
    Name : string;
    Ref  : LongInt;
  end;

  TResLoader = class
  public
    ExtString : string;
    ResType : TResourceType;
    function Load(const Stream : TStream;var Resource : TResource) : Boolean; virtual; abstract;
  end;

implementation

uses
  JEN_Main;

constructor TResource.Create;
begin
  Self.Name := Name;
  Ref := 1;
  ResMan.Add(Self);
end;


end.
