unit JEN_Resource;

interface

uses
  JEN_Utils;

type
  TResourceType = (rtShader, rtTexture);
  TTextureFilter =  (tfNone, tfBilinear, tfTrilinear, tfAniso);


const
  TResourceStringName : array[TResourceType] of string = ('shader', 'texture');

type
  TResource = class
    constructor Create(const Name: string); virtual;
  public
    Name : string;
    Ref  : LongInt;
  end;

  TResLoader = class
  public
    ExtString : string;
    Resource : TResourceType;
    function Load(const Stream : TStream;var Resource : TResource) : Boolean; virtual; abstract;
  end;

implementation

constructor TResource.Create;
begin
  Self.Name := Name;
  Ref := 1;
end;


end.
