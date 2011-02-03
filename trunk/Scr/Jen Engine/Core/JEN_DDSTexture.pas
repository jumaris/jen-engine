unit JEN_DDSTexture;

interface

uses
  JEN_OpenGlHeader,
  JEN_Utils,
  JEN_Math,
  JEN_ResourceManager;

type
  TDDSLoader = class(TResLoader)
  constructor Create;
  public
    procedure Load(Stream : TStream; var Resource : TResource); override;
  end;

implementation

uses
  JEN_Main;

constructor TDDSLoader.Create;
begin
  inherited;
  Ext := 'dds';
  Resource := rtTexture;
end;

procedure TDDSLoader.Load(Stream : TStream; var Resource : TResource);
type
  TloadFormat = (lfNULL, lfDXT1c, lfDXT1a, lfDXT3, lfDXT5, lfA8, lfL8, lfAL8, lfBGRA8, lfBGR8, lfBGR5A1, lfBGR565, lfBGRA4, lfR16F, lfR32F, lfGR16F, lfGR32F, lfBGRA16F, lfBGRA32F);

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

const
  Magic                = $20534444;

  //  DDS_header.dwFlags
  DDSD_CAPS            = $00000001;
  DDSD_PIXELFORMAT     = $00001000;
  {
#define DDSD_HEIGHT                 0x00000002
#define DDSD_WIDTH                  0x00000004
#define DDSD_PITCH                  0x00000008
#define
#define DDSD_MIPMAPCOUNT            0x00020000
#define DDSD_LINEARSIZE             0x00080000
#define DDSD_DEPTH                  0x00800000
                                          }

  FOURCC_DXT1          = $31545844;
  FOURCC_DXT3          = $33545844;
  FOURCC_DXT5          = $35545844;
  FOURCC_R16F          = $0000006F;
  FOURCC_G16R16F       = $00000070;
  FOURCC_A16B16G16R16F = $00000071;
  FOURCC_R32F          = $00000072;
  FOURCC_G32R32F       = $00000073;
  FOURCC_A32B32G32R32F = $00000074;
                        {
//  DDS_header.sCaps.dwCaps1
#define DDSCAPS_COMPLEX             0x00000008
#define DDSCAPS_TEXTURE             0x00001000
#define DDSCAPS_MIPMAP              0x00400000
                     }     {
//  DDS_header.sCaps.dwCaps2
#define DDSCAPS2_CUBEMAP            0x00000200
#define DDSCAPS2_CUBEMAP_POSITIVEX  0x00000400
#define DDSCAPS2_CUBEMAP_NEGATIVEX  0x00000800
#define DDSCAPS2_CUBEMAP_POSITIVEY  0x00001000
#define DDSCAPS2_CUBEMAP_NEGATIVEY  0x00002000
#define DDSCAPS2_CUBEMAP_POSITIVEZ  0x00004000
#define DDSCAPS2_CUBEMAP_NEGATIVEZ  0x00008000
#define DDSCAPS2_VOLUME             0x00200000
                        }
  DDPF_ALPHAPIXELS = $01;
  DDPF_ALPHA       = $02;
  DDPF_FOURCC      = $04;
  DDPF_RGB         = $40;
  DDPF_LUMINANCE   = $020000;
  DDSD_MIPMAPCOUNT = $020000;
  DDSCAPS2_CUBEMAP = $0200;

  DDSLoadFormat : array[TloadFormat] of record
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
    (Compressed: False; Swap : True;  DivSize: 1; BlockBytes:  2; InternalFormat: GL_RGB5_A1; ExternalFormat: GL_BGRA; DataType: GL_UNSIGNED_SHORT_1_5_5_5_REV),
    (Compressed: False; Swap : True;  DivSize: 1; BlockBytes:  2; InternalFormat: GL_RGB5; ExternalFormat: GL_RGB; DataType: GL_UNSIGNED_SHORT_5_6_5),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  2; InternalFormat: GL_RGBA4; ExternalFormat: GL_BGRA; DataType: GL_UNSIGNED_SHORT_4_4_4_4_REV),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  2; InternalFormat: GL_R16F; ExternalFormat: GL_RED; DataType: GL_HALF_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  4; InternalFormat: GL_R32F; ExternalFormat: GL_RED; DataType: GL_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  4; InternalFormat: GL_RG16F; ExternalFormat: GL_RG; DataType: GL_HALF_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  8; InternalFormat: GL_RG32F; ExternalFormat: GL_RG; DataType: GL_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes:  8; InternalFormat: GL_RGBA16F; ExternalFormat: GL_RGBA; DataType: GL_HALF_FLOAT),
    (Compressed: False; Swap : False; DivSize: 1; BlockBytes: 16; InternalFormat: GL_RGBA32F; ExternalFormat: GL_RGBA; DataType: GL_FLOAT)
  );

var
  Header : TDDSHeader;
  Format : TLoadFormat;
  st     : GLEnum;
  i,s    : Integer;
  w,h    : Integer;
  Mips   : Byte;
  Data    : Pointer;
  Samples : LongInt;
  Size    : LongWord;
  Texture : TTexture;

  function GetLoadFormat(const DDS: TDDSHeader): TLoadFormat;
  begin
    Result := lfNULL;
    with DDS do
      if pfFlags and DDPF_FOURCC = DDPF_FOURCC then
      begin
        case pfFourCC of
        // Compressed
          FOURCC_DXT1 :
           if pfFlags xor DDPF_ALPHAPIXELS > 0 then
             Result := lfDXT1a
           else
             Result := lfDXT1c;
          FOURCC_DXT3 : Result := lfDXT3;
          FOURCC_DXT5 : Result := lfDXT5;
        // Float
          FOURCC_R16F          : Result := lfR16F;
          FOURCC_G16R16F       : Result := lfGR16F;
          FOURCC_A16B16G16R16F : Result := lfBGRA16F;
          FOURCC_R32F          : Result := lfR32F;
          FOURCC_G32R32F       : Result := lfGR32F;
          FOURCC_A32B32G32R32F : Result := lfBGRA32F;
        end
      end else
        case pfRGBbpp of
           8 :
            if (pfFlags and DDPF_LUMINANCE > 0) and (pfRBitMask xor $FF = 0) then
              Result := lfL8
            else
              if (pfFlags and DDPF_ALPHA > 0) and (pfABitMask xor $FF = 0) then
                Result := lfA8;
          16 :
              if pfFlags and DDPF_ALPHAPIXELS > 0 then
              begin
                if (pfFlags and DDPF_LUMINANCE > 0) and (pfRBitMask xor $FF + pfABitMask xor $FF00 = 0) then
                  Result := lfAL8
                else
                  if pfFlags and DDPF_RGB > 0 then
                    if pfRBitMask xor $0F00 + pfGBitMask xor $00F0 + pfBBitMask xor $0F + pfABitMask xor $F000 = 0 then
                      Result := lfBGRA4
                    else
                      if pfRBitMask xor $7C00 + pfGBitMask xor $03E0 + pfBBitMask xor $1F + pfABitMask xor $8000 = 0 then
                        Result := lfBGR5A1;
              end else
                if pfFlags and DDPF_RGB > 0 then
                  if pfRBitMask xor $F800 + pfGBitMask xor $07E0 + pfBBitMask xor $1F = 0 then
                    Result := lfBGR565;
          24 :
            if pfRBitMask xor $FF0000 + pfGBitMask xor $FF00 + pfBBitMask xor $FF = 0 then
              Result := lfBGR8;
          32 :
            if pfRBitMask xor $FF0000 + pfGBitMask xor $FF00 + pfBBitMask xor $FF + pfABitMask xor $FF000000 = 0 then
              Result := lfBGRA8;
        end;
  end;

begin

             {
  if (Stream.Size < 128) then
  begin
    Stream.Free;
    Exit;
  end;

  Stream.Read(Header, 128);

  if( (Header.dwMagic <> Magic)
      or (Header.dwSize <> 124)
      or (Header.dwFlags and DDSD_PIXELFORMAT = 0)
      or (Header.dwFlags and DDSD_CAPS = 0) ) then
        begin
          LogOut('Wrong dds header', lmWarning);
          Stream.Free;
          Exit;
        end;

  Format := GetLoadFormat(Header);
  if Format = lfNULL then
  begin
    LogOut('Not supported texture format: ' + Stream.Name, lmWarning);
    Stream.Free;
    Exit();
  end;

  with Header, DDSLoadFormat[Format] do
  begin
    if dwFlags and DDSD_MIPMAPCOUNT = 0 then
       dwMipMapCount := 1;
    Mips := dwMipMapCount;

    for i := 0 to dwMipMapCount - 1 do
      if Min(dwWidth shr i, dwHeight shr i) < 4 then
      begin
        Mips := i;
        break;
      end;
          {
    Texture := TTexture.Create(Name);
    // 2D image
    Texture.Sampler := GL_TEXTURE_2D;
    Samples := 1;
    // CubeMap image
    if dwCaps2 and DDSCAPS2_CUBEMAP > 0 then
    begin
      Texture.Sampler := GL_TEXTURE_CUBE_MAP;
      Samples := 6;
    end;
    // 3D image
    ///...

    Data := GetMemory((dwWidth div DivSize) * (dwHeight div DivSize) * BlockBytes);

    glGenTextures(1, @Texture.FID);
    glBindTexture(Texture.Sampler, Texture.FID);

    for s := 0 to Samples - 1 do
    begin
      case Texture.Sampler of
        GL_TEXTURE_CUBE_MAP :
          st := (GL_TEXTURE_CUBE_MAP_POSITIVE_X) + s;
      else
        st := Texture.Sampler;
      end;

      for i := 0 to dwMipMapCount - 1 do
      begin
        w := dwWidth shr i;
        h := dwHeight shr i;
        Size := ((w div DivSize) * (h div DivSize) * BlockBytes);
        if i >= Mips then
        begin
          Stream.Pos := Stream.Pos + Size;
          continue;
        end;

        logout(Utils.inttostr(Byte(Compressed)),lmNotify);
        Stream.Read(Data^, Size);
        if Compressed then
          glCompressedTexImage2D(st, i, InternalFormat, w, h, 0, Size, Data)
        else
          glTexImage2D(st, i, InternalFormat, w, h, 0, ExternalFormat, DataType, Data);
      end;
    end;

    FreeMemory(Data); }
 { end;
               {
  glTexParameteri(Texture.Sampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
  glTexParameteri(Texture.Sampler, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(Texture.Sampler, GL_TEXTURE_MAX_LEVEL, Mips - 1);

  Result := Texture;    }
end;

end.
