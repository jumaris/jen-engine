unit JEN_RenderTarget;

interface

uses
  JEN_Header,
  JEN_OpenGLHeader,
  JEN_Texture;

type
  TRenderTarget = class(TInterfacedObject, IRenderTarget)
    constructor Create(Width, Height: LongWord; Format: TTextureFormat; Count: LongWord; Samples: LongWord; DepthBuffer: Boolean);
    destructor Destroy; override;
  private
    FID           : LongWord;
    FWidth        : LongWord;
    FHeight       : LongWord;
    FTexture      : array [TRenderChannel] of ITexture;
    FDepthBuf     : LongWord;
    FColChanCount : LongInt;
    function GetID: LongWord; stdcall;
    function GetWidth: LongWord; stdcall;
    function GetHeight: LongWord; stdcall;
    function GetColChanCount: LongInt; stdcall;
    function GetTexture(Channel: TRenderChannel): ITexture; stdcall;
  end;

implementation

uses
  JEN_Main;

constructor TRenderTarget.Create(Width, Height: LongWord; Format: TTextureFormat; Count: LongWord; Samples: LongWord; DepthBuffer: Boolean);
var
  i : Integer;
  Channel : TRenderChannel;
begin
//  if( numColBufs > RenderBuffer::MaxColorAttachmentCount ) return RenderBuffer();

  glGenFramebuffers(1, @FID);
  glBindFramebuffer(GL_FRAMEBUFFER, FID);

  FWidth := Width;
  FHeight := Height;

  for i := 0 to Count-1 do
  begin
    {if( samples > 0 )

				// Create a multisampled renderbuffer
				glGenRenderbuffersEXT( 1, &rb.colBufs[j] );
				glBindRenderbufferEXT( GL_RENDERBUFFER_EXT, rb.colBufs[j] );
				glRenderbufferStorageMultisampleEXT( GL_RENDERBUFFER_EXT, rb.samples,
													 glFormat, rb.width, rb.height );

				// Attach the renderbuffer
				glFramebufferRenderbufferEXT( GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT + j,
											  GL_RENDERBUFFER_EXT, rb.colBufs[j] );
			}

				// Create a color texture
    FTexture[TRenderChannel(i + Ord(rcColor0))] := ResMan.CreateTexture(Width, Height, Format);
    FTexture[TRenderChannel(i + Ord(rcColor0))].Clamp := true;

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + i, GL_TEXTURE_2D, FTexture[TRenderChannel(i + Ord(rcColor0))].ID, 0);
  end;
 {  glGenTextures( 1, &rb.colBufs[j] );
  glBindTexture( GL_TEXTURE_2D, rb.colBufs[j] );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, bilinear ? GL_LINEAR : GL_NEAREST );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, bilinear ? GL_LINEAR : GL_NEAREST );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );   }

  //  glFramebufferTexture2DEXT( GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT + j, GL_TEXTURE_2D, rb.colBufs[j], 0 );

 // end;


            {
  if DepthBuffer then
  begin
    gl_GenRenderbuffers(1, @DepthBuf);
    gl_BindRenderbuffer(GL_RENDERBUFFER, DepthBuf);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, Width, Height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, DepthBuf);
  end;
  }
  if glCheckFramebufferStatus(GL_FRAMEBUFFER) <> GL_FRAMEBUFFER_COMPLETE then
    LogOut('Error creating frame buffer object', lmWarning);

  FColChanCount := Count;
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
end;

destructor TRenderTarget.Destroy;
begin
  {if DepthBuf <> 0 then
    gl.DeleteRenderbuffers(1, @DepthBuf);
  gl.DeleteFramebuffers(1, @FrameBuf); }
end;

function TRenderTarget.GetID: LongWord;
begin
  Result := FId;
end;

function TRenderTarget.GetWidth: LongWord;
begin
  Result := FWidth;
end;

function TRenderTarget.GetHeight: LongWord;
begin
  Result := FHeight;
end;

function TRenderTarget.GetColChanCount: LongInt;
begin
  Result := FColChanCount;
end;

function TRenderTarget.GetTexture(Channel: TRenderChannel): ITexture;
begin
  Result := FTexture[Channel];
end;


end.
