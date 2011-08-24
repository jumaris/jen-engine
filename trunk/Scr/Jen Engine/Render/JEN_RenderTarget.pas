unit JEN_RenderTarget;

interface

uses
  JEN_Header,
  JEN_OpenGLHeader;
                         {
type
  TRenderTarget = class
    constructor Create(Width, Height: LongInt; DepthBuffer: Boolean = True);
    destructor Destroy; override;
  private
    FrameBuf : LongWord;
    DepthBuf : LongWord;
    ChannelCount : LongInt;
    ChannelList  : array [0..Ord(High(TRenderChannel)) - 1] of TGLConst;
  public
    Texture : array [TRenderChannel] of TTexture;
    procedure Attach(Channel: TRenderChannel; Texture: TTexture; Target: TTextureTarget = ttTex2D);
  end;
        }
implementation
            {
constructor TRenderTarget.Create(Width, Height: LongInt; DepthBuffer: Boolean);
begin
  glGenFramebuffers(1, @FrameBuf);
  glBindFramebuffer(GL_FRAMEBUFFER, FrameBuf);
  if DepthBuffer then
  begin
    gl_GenRenderbuffers(1, @DepthBuf);
    gl_BindRenderbuffer(GL_RENDERBUFFER, DepthBuf);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, Width, Height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, DepthBuf);
  end;
//  Assert('Invalid frame buffer object', gl.CheckFramebufferStatus(GL_FRAMEBUFFER) <> GL_FRAMEBUFFER_COMPLETE);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
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
end;
      }
end.
