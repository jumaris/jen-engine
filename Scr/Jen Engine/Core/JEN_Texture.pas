unit JEN_Texture;

interface

uses
  JEN_ResourceManager,
  JEN_OpenglHeader;

type

  TMipMap = record
    Size : LongWord;
    Data : Pointer;
  end;

  TTextureInfo = record
    Format  : LongWord;
    Format2 : LongWord;
    MipMaps : array of TMipMap;
  end;

implementation

end.
