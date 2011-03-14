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

  TResourceList = class
    constructor Create;
    destructor Destroy; override;
  protected
    FCount : Integer;
    FItems : array of IResource;
    function GetItem(idx: Integer): IResource; inline;
    procedure SetItem(idx: Integer; Value: IResource); inline;
  public
    function Add(p: IResource): IResource;
    procedure Del(idx: Integer);
    procedure Clear; virtual;
    property Count: Integer read FCount;
    property Items[Idx: Integer]: IResource read GetItem write SetItem; default;
  end;

implementation

uses
  JEN_Main;
              {
constructor TResource.Create;
begin
  Self.Name := Name;
  Ref := 1;
  ResMan.Add(Self);
end;
                 }
constructor TResourceList.Create;
begin
  FCount := 0;
  FItems := nil;
end;

destructor TResourceList.Destroy;
begin
  Clear;
  inherited;
end;

function TResourceList.Add(p: IResource): IResource;
begin
  if FCount mod LIST_DELTA = 0 then
    SetLength(FItems, Length(FItems) + LIST_DELTA);
  FItems[FCount] := p;
  Result := p;
  Inc(FCount);
end;

procedure TResourceList.Del(Idx: Integer);
var
  i : Integer;
begin
  for i := Idx to FCount - 2 do
    FItems[i] := FItems[i + 1];
  Dec(FCount);

  if Length(FItems) - FCount + 1 > LIST_DELTA then
    SetLength(FItems, Length(FItems) - LIST_DELTA);
end;

procedure TResourceList.Clear;
begin
  FCount := 0;
  FItems := nil;
end;

function TResourceList.GetItem(Idx: Integer): IResource;
begin
  Result := FItems[Idx];
end;

procedure TResourceList.SetItem(Idx: Integer; Value: IResource);
begin
  FItems[Idx] := Value;
end;



end.
