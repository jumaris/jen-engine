unit JEN_RenderTarget;

interface

uses
  JEN_Header,
  JEN_OpenGLHeader,
  JEN_Texture;
          {
type
  TRenderTarget = class
    constructor Create(Width, Height: LongInt;Format: TTextureFormat; Count: LongWord; Samples: LongWord; DepthBuffer: Boolean);
    destructor Destroy; override;
  private
    FrameBuf : LongWord;
    DepthBuf : LongWord;
    ChannelCount : LongInt;
    ChannelList  : array [0..Ord(High(TRenderChannel)) - 1] of GLenum;
  public
    Texture : array [TRenderChannel] of ITexture;
    procedure Attach(Channel: TRenderChannel; Texture: ITexture; Target: TTextureTarget = ttTex2D);
  end;     }

implementation
                 {
constructor TRenderTarget.Create(Width, Height: LongInt; Format: TTextureFormat; Count: LongWord; Samples: LongWord; DepthBuffer: Boolean);
var
  i : Integer;
begin

  if( numColBufs > RenderBuffer::MaxColorAttachmentCount ) return RenderBuffer();

  glGenFramebuffers(1, @FrameBuf);
  glBindFramebuffer(GL_FRAMEBUFFER, FrameBuf);

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
        {
  glGenTextures( 1, &rb.colBufs[j] );
  glBindTexture( GL_TEXTURE_2D, rb.colBufs[j] );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, bilinear ? GL_LINEAR : GL_NEAREST );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, bilinear ? GL_LINEAR : GL_NEAREST );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );   }

  //  glFramebufferTexture2DEXT( GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT + j, GL_TEXTURE_2D, rb.colBufs[j], 0 );

 // end;


              {
  TextureFormatInfo

  if DepthBuffer then
  begin
    gl_GenRenderbuffers(1, @DepthBuf);
    gl_BindRenderbuffer(GL_RENDERBUFFER, DepthBuf);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, Width, Height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, DepthBuf);
  end;
//  Assert('Invalid frame buffer object', gl.CheckFramebufferStatus(GL_FRAMEBUFFER) <> GL_FRAMEBUFFER_COMPLETE);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);         }     {
end;

destructor TRenderTarget.Destroy;
begin
  if DepthBuf <> 0 then
    gl.DeleteRenderbuffers(1, @DepthBuf);
  gl.DeleteFramebuffers(1, @FrameBuf);
end;

procedure TRenderTarget.Attach(Channel: TRenderChannel; Texture: TTexture; Target: TTextureTarget);
var
  TargetID  : TGLConst;
  TextureID : LongWord;
begin
  if Target = ttTex2D then
    TargetID := GL_TEXTURE_2D
  else
    TargetID := TGLConst(Ord(GL_TEXTURE_CUBE_MAP_POSITIVE_X) + Ord(Target) - 1);

  if Texture <> nil then
    TextureID := Texture.FID
  else
    TextureID := 0;

  gl.BindFramebuffer(GL_FRAMEBUFFER, FrameBuf);
  if Channel = rcDepth then
    gl.FramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, TargetID, TextureID, 0)
  else
    gl.FramebufferTexture2D(GL_FRAMEBUFFER, TGLConst(Ord(GL_COLOR_ATTACHMENT0) + Ord(Channel) - 1), TargetID, TextureID, 0);

  Self.Texture[Channel] := Texture;
  ChannelCount := 0;
  for Channel := rcColor0 to High(Self.Texture) do
    if Self.Texture[Channel] <> nil then
    begin
      ChannelList[ChannelCount] := TGLConst(Ord(GL_COLOR_ATTACHMENT0) + Ord(Channel) - 1);
      Inc(ChannelCount);
    end;
  gl.BindFramebuffer(GL_FRAMEBUFFER, 0);
end;    }

end.
