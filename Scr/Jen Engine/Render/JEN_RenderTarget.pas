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
    FID : LongWord;
    FTexture : array [TRenderChannel] of ITexture;
    FDepthBuf : LongWord;
    FChannelCount : LongInt;
    FChannelList : array [0..Ord(High(TRenderChannel)) - 1] of GLenum;
    function GetID: LongWord;
    function GetDrawBuffers: PLongWord;
    function GetChannelCount: LongInt;
    function GetTexture(Channel: TRenderChannel): ITexture;
  public
  //  procedure Attach(Channel: TRenderChannel; Texture: ITexture; Target: TTextureTarget = ttTex2D);
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

  FChannelCount := 0;
  for Channel := rcColor0 to High(TRenderChannel) do
    if FTexture[Channel] <> nil then
    begin
      FChannelList[FChannelCount] := Ord(GL_COLOR_ATTACHMENT0) + Ord(Channel) - 1;
      Inc(FChannelCount);
    end;

  glBindFramebuffer(GL_FRAMEBUFFER, 0);
end;

destructor TRenderTarget.Destroy;
begin
  {if DepthBuf <> 0 then
    gl.DeleteRenderbuffers(1, @DepthBuf);
  gl.DeleteFramebuffers(1, @FrameBuf); }
end;
              {
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
end;          }

function TRenderTarget.GetID: LongWord;
begin
  Result := FId;
end;

function TRenderTarget.GetDrawBuffers: PLongWord;
begin
  Result := @FChannelList[0];
end;

function TRenderTarget.GetChannelCount: LongInt;
begin
  Result := FChannelCount;
end;

function TRenderTarget.GetTexture(Channel: TRenderChannel): ITexture;
begin
  Result := FTexture[Channel];
end;


end.
