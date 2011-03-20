unit JEN_Resource;

interface

uses
  JEN_Header,
  JEN_Utils;

const
  TResourceStringName : array[TResourceType] of string = ('shader', 'texture');

type
  TResLoader = class
  public
    ExtString : string;
    ResType : TResourceType;
    function Load(const Stream : TStream;var Resource : IResource) : Boolean; virtual; abstract;
  end;

implementation

uses
  JEN_Main;

end.
