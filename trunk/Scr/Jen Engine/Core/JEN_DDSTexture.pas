unit JEN_DDSTexture;

interface

uses
  JEN_Header,
  JEN_OpenGlHeader,
  JEN_Utils,
  JEN_Math,
  JEN_Resource,
  JEN_Texture;

type
  TDDSLoader = class(TResLoader)
    constructor Create;
  public
    function Load(Stream: IStream; var Resource: IResource): Boolean; override;
  end;

implementation

uses
  JEN_Main;

constructor TDDSLoader.Create;
begin
  inherited;
  ExtString := 'dds';
  ResType := rtTexture;
end;

function TDDSLoader.Load(Stream: IStream; var Resource: IResource): Boolean;
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

{$REGION 'CONSTANS'}
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
{$ENDREGION}

var
  Header  : TDDSHeader;
  Format  : TTextureFormat;
  st      : GLEnum;
  i,s     : LongInt;
  w,h     : LongInt;
  Mips    : Byte;
  Data    : Pointer;
  Samples : LongInt;
  Size    : LongWord;
  Texture : ITexture;

  function GetLoadFormat(const DDS: TDDSHeader): TTextureFormat;
  begin
    Result := tfoNone;
    with DDS do
      if pfFlags and DDPF_FOURCC = DDPF_FOURCC then
      begin
        case pfFourCC of
        // Compressed
          FOURCC_DXT1 :
           if pfFlags xor DDPF_ALPHAPIXELS > 0 then
             Result := tfoDXT1a
           else
             Result := tfoDXT1c;
          FOURCC_DXT3 : Result := tfoDXT3;
          FOURCC_DXT5 : Result := tfoDXT5;
        // Float
          FOURCC_R16F          : Result := tfoR16F;
          FOURCC_G16R16F       : Result := tfoGR16F;
          FOURCC_A16B16G16R16F : Result := tfoBGRA16F;
          FOURCC_R32F          : Result := tfoR32F;
          FOURCC_G32R32F       : Result := tfoGR32F;
          FOURCC_A32B32G32R32F : Result := tfoBGRA32F;
        end
      end else
        case pfRGBbpp of
           8 :
            if (pfFlags and DDPF_LUMINANCE > 0) and (pfRBitMask xor $FF = 0) then
              Result := tfoL8
            else
              if (pfFlags and DDPF_ALPHA > 0) and (pfABitMask xor $FF = 0) then
                Result := tfoA8;
          16 :
              if pfFlags and DDPF_ALPHAPIXELS > 0 then
              begin
                if (pfFlags and DDPF_LUMINANCE > 0) and (pfRBitMask xor $FF + pfABitMask xor $FF00 = 0) then
                  Result := tfoAL8
                else
                  if pfFlags and DDPF_RGB > 0 then
                    if pfRBitMask xor $0F00 + pfGBitMask xor $00F0 + pfBBitMask xor $0F + pfABitMask xor $F000 = 0 then
                      Result := tfoBGRA4
                    else
                      if pfRBitMask xor $7C00 + pfGBitMask xor $03E0 + pfBBitMask xor $1F + pfABitMask xor $8000 = 0 then
                        Result := tfoBGR5A1;
              end else
                if pfFlags and DDPF_RGB > 0 then
                  if pfRBitMask xor $F800 + pfGBitMask xor $07E0 + pfBBitMask xor $1F = 0 then
                    Result := tfoBGR565;
          24 :
            if pfRBitMask xor $FF0000 + pfGBitMask xor $FF00 + pfBBitMask xor $FF = 0 then
              Result := tfoBGR8;
          32 :
            if pfRBitMask xor $00FF0000 + pfGBitMask xor $FF00 + pfBBitMask xor $FF + pfABitMask xor $FF000000 = 0 then
              Result := tfoBGRA8;
        end;
  end;

begin
  Result := False;
  if not Assigned(Resource) then Exit;
  Texture := Resource as ITexture;

  if (Stream.Size < 128) then
  begin
    LogOut('Wrong dds file', lmWarning);
    Exit;
  end;

  Stream.Read(Header, 128);

  if( (Header.dwMagic <> Magic)
      or (Header.dwSize <> 124)
      or (Header.dwFlags and DDSD_PIXELFORMAT = 0)
      or (Header.dwFlags and DDSD_CAPS = 0) ) then
        begin
          LogOut('Wrong dds header', lmWarning);
          Exit;
        end;

  Format := GetLoadFormat(Header);
  if Format = tfoNone then
  begin
    LogOut('Not supported texture format: ' + Stream.Name, lmWarning);
    Exit;
  end;

  with Header, TextureFormatInfo[Format] do
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

    Mips := max(Mips, 1);

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
    Texture.Format := Format;
    Texture.Bind;

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

        Stream.Read(Data^, Size);
        Texture.DataSet(w, h, Size, Data, i);
      end;
    end;

    FreeMemory(Data);
  end;

  Texture.Filter := tfiAniso;
  Texture.Flip(True, False);
  Result := True;
end;

end.
