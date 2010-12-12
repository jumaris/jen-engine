unit JEN_Texture;

interface

uses
  JEN_ResourceManager;

type
  TTexture = class(TResource)
  end;

  TMipMap = record
    Size : LongWord;
    Data : Pointer;
  end;

  TTextureInfo = record
    Format : LongWord;
    Format2 : LongWord;
    MipMaps : array of TMipMap;
  end;

implementation

end.
