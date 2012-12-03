unit JEN_RenderTarget;

interface

uses
  JEN_OpenGLHeader,
  JEN_Header;

type
  TRenderTarget = class(TInterfacedObject, IRenderTarget)
    constructor Create(Width, Height: LongWord; CFormat: TTextureFormat; Count: LongInt; Samples: LongWord; DepthBuffer: Boolean; DFormat: TTextureFormat);
    destructor Destroy; override;
  private
    FID           : LongWord;
    FRB           : LongWord;
    FWidth        : LongWord;
    FHeight       : LongWord;
    FTexture      : array [TRenderChannel] of ITexture;
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

constructor TRenderTarget.Create(Width, Height: LongWord; CFormat: TTextureFormat; Count: LongInt; Samples: LongWord; DepthBuffer: Boolean; DFormat: TTextureFormat);
var
  i : Integer;
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
    FTexture[TRenderChannel(i + Ord(rcColor0))] := ResMan.CreateTexture(Width, Height, CFormat);
    FTexture[TRenderChannel(i + Ord(rcColor0))].Clamp := True;

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + i, GL_TEXTURE_2D, FTexture[TRenderChannel(i + Ord(rcColor0))].ID, 0);
  end;

  if (DepthBuffer) then
  begin
		{if(samples > 0) then

			// Create a multisampled renderbuffer
			glGenRenderbuffersEXT( 1, &rb.depthBuf );
			glBindRenderbufferEXT( GL_RENDERBUFFER_EXT, rb.depthBuf );
			glRenderbufferStorageMultisampleEXT( GL_RENDERBUFFER_EXT, rb.samples,
												 GL_DEPTH_COMPONENT, rb.width, rb.height );

			// Attach the renderbuffer
			glFramebufferRenderbufferEXT( GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
										  GL_RENDERBUFFER_EXT, rb.depthBuf );
		}
    begin
      FTexture[rcDepth] := ResMan.CreateTexture(Width, Height, DFormat);
      FTexture[rcDepth].Clamp := True;
			glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, FTexture[rcDepth].ID, 0 );
    end;
  end;



  //if DepthBuffer then

  begin
    glGenRenderbuffers(1, @FRB);
    glBindRenderbuffer(GL_RENDERBUFFER, FRB);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, Width, Height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, FRB);
   end;

  if glCheckFramebufferStatus(GL_FRAMEBUFFER) <> GL_FRAMEBUFFER_COMPLETE then
    Engine.Warning('Error creating frame buffer object');

  FColChanCount := Count;
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
end;

destructor TRenderTarget.Destroy;
begin
//  if DepthBuf <> 0 then
 //   gl_DeleteRenderbuffers(1, @DepthBuf);
  glDeleteRenderbuffers(1, @FRB);
  glDeleteFramebuffers(1, @FID);

end;

function TRenderTarget.GetID: LongWord; stdcall;
begin
  Result := FId;
end;

function TRenderTarget.GetWidth: LongWord; stdcall;
begin
  Result := FWidth;
end;

function TRenderTarget.GetHeight: LongWord; stdcall;
begin
  Result := FHeight;
end;

function TRenderTarget.GetColChanCount: LongInt; stdcall;
begin
  Result := FColChanCount;
end;

function TRenderTarget.GetTexture(Channel: TRenderChannel): ITexture; stdcall;
begin
  Result := FTexture[Channel];
end;


end.
