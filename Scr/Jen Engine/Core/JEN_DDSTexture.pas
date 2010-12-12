unit JEN_DDSTexture;

interface

uses
  JEN_Utils,
  JEN_Math,
  JEN_ResourceManager,
  JEN_Texture;

type
  TDDSLoader = class(TResLoader)
  constructor Create;
  public
    function Load(Stream : TStream): TResource; override;
  end;

implementation

uses
  JEN_Main;

constructor TDDSLoader.Create;
begin
  inherited;
  Ext := 'dds';
end;

function TDDSLoader.Load(Stream : TStream): TResource;
const
  Magic = $20534444;
type
  TDDSHeader = record
    dwMagic       : LongWord;
    dwSize        : LongInt;
    dwFlags       : LongWord;
    dwHeight      : LongWord;
    dwWidth       : LongWord;
    dwPOLSize     : LongWord;
    dwDepth       : LongWord;
    dwMipMapCount : LongInt;
    dwReserved1 : array [0..10] of LongWord;
    dwSize2     : LongWord;
    pfFlags     : LongWord;
    pfFourCC    : LongWord;
    pfRGBbpp    : LongWord;
    pfRBitMask  : LongWord;
    pfGBitMask  : LongWord;
    pfBBitMask  : LongWord;
    pfABitMask  : LongWord;
    dwCaps1     : LongWord;
    dwCaps2     : LongWord;
    dwReserved2 : array [0..2] of LongWord;
  end;
var
  Header : TDDSHeader;
begin
  if (Stream.Size < 128) then
    Exit(nil);

  Stream.Read(Header, 128);

  if(Header.dwMagic <> Magic) then
    LogOut( 'Wrong dds format', lmWarning );

  Stream.Pos := 4 + Min(Header.dwSize,124);

  Result := nil;
end;

end.
