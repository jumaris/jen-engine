unit JEN_Render;
{$I Jen_config.INC}

interface

type
  TRender = class
  protected
    function GetValid : Boolean; virtual; abstract;
  public
    property IsValid  : Boolean read GetValid;
  end;

implementation

end.
