unit JEN_DDSTexture;

interface

uses
  JEN_OpenGlHeader,
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

  TloadFormat =  (lfNULL, lfDXT1c, lfDXT1a, lfDXT3, lfDXT5, lfA8, lfL8, lfAL8, lfBGRA8, lfBGR8, lfBGR5A1, lfBGR565, lfBGRA4{, lfR16F, lfR32F, lfGR16F, lfGR32F, lfBGRA16F, lfBGRA32F});
  var DDSLoadFormat : array[TloadFormat] of record
    Compressed : boolean;
    Swap : boolean;
    DivSize : Byte;
    BlockBytes : Byte;
    InternalFormat : GLenum;
    ExternalFormat : GLenum;
    DataType : GLenum;
  end = (
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  1; InternalFormat: GL_FALSE; ExternalFormat: GL_FALSE; DataType: GL_FALSE),
    (Compressed: True;  Swap : False; DivSize: 4; BlockBytes:  8; InternalFormat: GL_COMPRESSED_RGB_S3TC_DXT1; ExternalFormat: GL_FALSE; DataType: GL_FALSE),
    (Compressed: True;  Swap : False; DivSize: 4; BlockBytes:  8; InternalFormat: GL_COMPRESSED_RGBA_S3TC_DXT1; ExternalFormat: GL_FALSE; DataType: GL_FALSE),
    (Compressed: True;  Swap : False; DivSize: 4; BlockBytes: 16; InternalFormat: GL_COMPRESSED_RGBA_S3TC_DXT3; ExternalFormat: GL_FALSE; DataType: GL_FALSE),
    (Compressed: True;  Swap : False; DivSize: 4; BlockBytes: 16; InternalFormat: GL_COMPRESSED_RGBA_S3TC_DXT5; ExternalFormat: GL_FALSE; DataType: GL_FALSE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  1; InternalFormat: GL_ALPHA8; ExternalFormat: GL_ALPHA; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  1; InternalFormat: GL_LUMINANCE8; ExternalFormat: GL_LUMINANCE; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  2; InternalFormat: GL_LUMINANCE8_ALPHA8; ExternalFormat: GL_LUMINANCE_ALPHA; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  4; InternalFormat: GL_RGBA8; ExternalFormat: GL_BGRA; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  3; InternalFormat: GL_RGB8; ExternalFormat: GL_BGR; DataType: GL_UNSIGNED_BYTE),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  2; InternalFormat: GL_RGB5_A1; ExternalFormat: GL_BGRA; DataType: GL_UNSIGNED_SHORT_1_5_5_5_REV),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  2; InternalFormat: GL_RGB5; ExternalFormat: GL_RGB; DataType: GL_UNSIGNED_SHORT_5_6_5),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  2; InternalFormat: GL_RGBA4; ExternalFormat: GL_BGRA; DataType: GL_UNSIGNED_SHORT_4_4_4_4_REV){,
   { (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  2; InternalFormat: GL_R16F; ExternalFormat: GL_RED; DataType: GL_HALF_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  4; InternalFormat: GL_R32F; ExternalFormat: GL_RED; DataType: GL_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  4; InternalFormat: GL_RG16F; ExternalFormat: GL_RG; DataType: GL_HALF_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  8; InternalFormat: GL_RG32F; ExternalFormat: GL_RG; DataType: GL_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  8; InternalFormat: GL_RGBA16F; ExternalFormat: GL_RGBA; DataType: GL_HALF_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes: 16; InternalFormat: GL_RGBA32F; ExternalFormat: GL_RGBA; DataType: GL_FLOAT)        }
  );


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
