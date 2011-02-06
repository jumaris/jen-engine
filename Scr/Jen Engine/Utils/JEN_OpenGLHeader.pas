unit JEN_OpenGLHeader;

interface

uses
  XSystem;

type
  GLboolean   = Boolean;
  GLubyte     = Byte;
  GLbitfield  = LongWord;
  GLbyte      = Shortint;
  GLshort     = SmallInt;
  GLushort    = Word;
  GLint       = Integer;
  GLuint      = LongWord;
  GLenum      = LongWord;
  GLfloat     = Single;
  GLdouble    = Double;
  GLsizei     = Integer;

  PGLboolean = ^GLboolean;
  PGLbyte    = ^GLbyte;
  PGLshort   = ^GLshort;
  PGLint     = ^GLint;
  PGLsizei   = ^GLsizei;
  PGLubyte   = ^GLubyte;
  PGLushort  = ^GLushort;
  PGLuint    = ^GLuint;
  PGLfloat   = ^GLfloat;

  PGLvoid     = Pointer;

const
// Boolean
  GL_FALSE                            = 0;
  GL_TRUE                             = 1;

// Pixel Format
  WGL_DRAW_TO_WINDOW_ARB              = $2001;
  WGL_ACCELERATION_ARB                = $2003;
  WGL_FULL_ACCELERATION_ARB           = $2027;
  WGL_SUPPORT_OPENGL_ARB              = $2010;
  WGL_DOUBLE_BUFFER_ARB               = $2011;
  WGL_PIXEL_TYPE_ARB                  = $2013;
  WGL_COLOR_BITS_ARB                  = $2014;
  WGL_RED_BITS_ARB                    = $2015;
  WGL_GREEN_BITS_ARB                  = $2017;
  WGL_BLUE_BITS_ARB                   = $2019;
  WGL_ALPHA_BITS_ARB                  = $201B;
  WGL_DEPTH_BITS_ARB                  = $2022;
  WGL_STENCIL_BITS_ARB                = $2023;
  WGL_TYPE_RGBA_ARB                   = $202B;
  WGL_SAMPLE_BUFFERS_ARB              = $2041;
  WGL_SAMPLES_ARB                     = $2042;

// Pixel Format
  GL_COLOR_INDEX                      = $1900;
  GL_STENCIL_INDEX                    = $1901;
  GL_DEPTH_COMPONENT                  = $1902;
  GL_RED                              = $1903;
  GL_GREEN                            = $1904;
  GL_BLUE                             = $1905;
  GL_ALPHA                            = $1906;
  GL_RGB                              = $1907;
  GL_RGBA                             = $1908;
  GL_LUMINANCE                        = $1909;
  GL_LUMINANCE_ALPHA                  = $190A;

// AttribMask
  GL_DEPTH_BUFFER_BIT                 = $00000100;
  GL_STENCIL_BUFFER_BIT               = $00000400;
  GL_COLOR_BUFFER_BIT                 = $00004000;

// Begin Mode
  GL_POINTS                           = $0000;
  GL_LINES                            = $0001;
  GL_LINE_LOOP                        = $0002;
  GL_LINE_STRIP                       = $0003;
  GL_TRIANGLES                        = $0004;
  GL_TRIANGLE_STRIP                   = $0005;
  GL_TRIANGLE_FAN                     = $0006;
  GL_QUADS                            = $0007;
  GL_QUAD_STRIP                       = $0008;
  GL_POLYGON                          = $0009;

// Alpha Function
  GL_NEVER                            = $0200;
  GL_LESS                             = $0201;
  GL_EQUAL                            = $0202;
  GL_LEQUAL                           = $0203;
  GL_GREATER                          = $0204;
  GL_NOTEQUAL                         = $0205;
  GL_GEQUAL                           = $0206;
  GL_ALWAYS                           = $0207;

// Blending Factor Dest
  GL_ZERO                             = 0;
  GL_ONE                              = 1;
  GL_SRC_COLOR                        = $0300;
  GL_ONE_MINUS_SRC_COLOR              = $0301;
  GL_SRC_ALPHA                        = $0302;
  GL_ONE_MINUS_SRC_ALPHA              = $0303;
  GL_DST_ALPHA                        = $0304;
  GL_ONE_MINUS_DST_ALPHA              = $0305;

// Blending Factor Src
  GL_DST_COLOR                        = $0306;
  GL_ONE_MINUS_DST_COLOR              = $0307;
  GL_SRC_ALPHA_SATURATE               = $0308;

// DrawBuffer Mode
  GL_FRONT                            = $0404;
  GL_BACK                             = $0405;
  GL_FRONT_AND_BACK                   = $0408;

// Tests
  GL_DEPTH_TEST                       = $0B71;
  GL_STENCIL_TEST                     = $0B90;
  GL_ALPHA_TEST                       = $0BC0;
  GL_SCISSOR_TEST                     = $0C11;

// GetTarget
  GL_POLYGON_MODE                     = $0B40;
  GL_CULL_FACE                        = $0B44;
  GL_LIGHTING                         = $0B50;
  GL_LIGHT0                           = $4000;
  GL_COLOR_MATERIAL                   = $0B57;
  GL_NORMALIZE                        = $0BA1;
  GL_VIEWPORT                         = $0BA2;
  GL_MODELVIEW_MATRIX                 = $0BA6;
  GL_PROJECTION_MATRIX                = $0BA7;
  GL_TEXTURE_MATRIX                   = $0BA8;
  GL_BLEND                            = $0BE2;

// Data Types
  GL_BYTE                             = $1400;
  GL_UNSIGNED_BYTE                    = $1401;
  GL_SHORT                            = $1402;
  GL_UNSIGNED_SHORT                   = $1403;
  GL_INT                              = $1404;
  GL_UNSIGNED_INT                     = $1405;
  GL_FLOAT                            = $1406;
  GL_HALF_FLOAT                       = $140B;
  GL_UNSIGNED_INT_8_8_8_8             = $8035;

              {
// Matrix Mode
  GL_MODELVIEW                        = $1700;
  GL_PROJECTION                       = $1701;
  GL_TEXTURE                          = $1702;
                         }

// PolygonMode
  GL_POINT                            = $1B00;
  GL_LINE                             = $1B01;
  GL_FILL                             = $1B02;

// List mode
  GL_COMPILE                          = $1300;
  GL_COMPILE_AND_EXECUTE              = $1301;

// StencilOp
{      GL_ZERO }
{  GL_KEEP                             = $1E00;
  GL_REPLACE                          = $1E01;
  GL_INCR                             = $1E02;
  GL_DECR                             = $1E03;        ]
{      GL_INVERT }
                {
 // LightParameter
  GL_AMBIENT                          = $1200;
  GL_DIFFUSE                          = $1201;
  GL_SPECULAR                         = $1202;
  GL_POSITION                         = $1203;
  GL_SPOT_DIRECTION                   = $1204;
  GL_SPOT_EXPONENT                    = $1205;
  GL_SPOT_CUTOFF                      = $1206;
  GL_CONSTANT_ATTENUATION             = $1207;
  GL_LINEAR_ATTENUATION               = $1208;
  GL_QUADRATIC_ATTENUATION            = $1209;
                           }
// GetString Parameter
  GL_VENDOR                           = $1F00;
  GL_RENDERER                         = $1F01;
  GL_VERSION                          = $1F02;
  GL_EXTENSIONS                       = $1F03;

// TextureEnvParameter
  GL_TEXTURE_ENV_MODE                 = $2200;
  GL_TEXTURE_ENV_COLOR                = $2201;

// TextureEnvTarget
  GL_TEXTURE_ENV                      = $2300;

// Texture Filter
  GL_NEAREST                          = $2600;
  GL_LINEAR                           = $2601;
  GL_NEAREST_MIPMAP_NEAREST           = $2700;
  GL_LINEAR_MIPMAP_NEAREST            = $2701;
  GL_NEAREST_MIPMAP_LINEAR            = $2702;
  GL_LINEAR_MIPMAP_LINEAR             = $2703;

  GL_TEXTURE_MAG_FILTER               = $2800;
  GL_TEXTURE_MIN_FILTER               = $2801;
  GL_TEXTURE_WRAP_S                   = $2802;
  GL_TEXTURE_WRAP_T                   = $2803;

// Texture Wrap Mode
  GL_REPEAT                           = $2901;
  GL_CLAMP_TO_EDGE                    = $812F;
  GL_TEXTURE_BASE_LEVEL               = $813C;
  GL_TEXTURE_MAX_LEVEL                = $813D;

// Textures
  GL_TEXTURE_2D                       = $0DE1;
  GL_TEXTURE0                         = $84C0;
  GL_TEXTURE_MAX_ANISOTROPY           = $84FE;
  GL_MAX_TEXTURE_MAX_ANISOTROPY       = $84FF;
  GENERATE_MIPMAP_SGIS                = $8191;

 // GL_EXT_texture
  GL_ALPHA4                           = $803B;
  GL_ALPHA8                           = $803C;
  GL_ALPHA12                          = $803D;
  GL_ALPHA16                          = $803E;
  GL_LUMINANCE4                       = $803F;
  GL_LUMINANCE8                       = $8040;
  GL_LUMINANCE12                      = $8041;
  GL_LUMINANCE16                      = $8042;
  GL_LUMINANCE4_ALPHA4                = $8043;
  GL_LUMINANCE6_ALPHA2                = $8044;
  GL_LUMINANCE8_ALPHA8                = $8045;
  GL_LUMINANCE12_ALPHA4               = $8046;
  GL_LUMINANCE12_ALPHA12              = $8047;
  GL_LUMINANCE16_ALPHA16              = $8048;
  GL_INTENSITY                        = $8049;
  GL_INTENSITY4                       = $804A;
  GL_INTENSITY8                       = $804B;
  GL_INTENSITY12                      = $804C;
  GL_INTENSITY16                      = $804D;
  GL_RGB2                             = $804E;
  GL_RGB4                             = $804F;
  GL_RGB5                             = $8050;
  GL_RGB8                             = $8051;
  GL_RGB10                            = $8052;
  GL_RGB12                            = $8053;
  GL_RGB16                            = $8054;
  GL_RGBA2                            = $8055;
  GL_RGBA4                            = $8056;
  GL_RGB5_A1                          = $8057;
  GL_RGBA8                            = $8058;
  GL_RGB10_A2                         = $8059;
  GL_RGBA12                           = $805A;
  GL_RGBA16                           = $805B;
  GL_BGR                              = $80E0;
  GL_BGRA                             = $80E1;

  GL_COMPRESSED_RED                   = $8225;
  GL_COMPRESSED_RG                    = $8226;
  GL_RGBA32F                          = $8814;
  GL_RGB32F                           = $8815;
  GL_RGBA16F                          = $881A;
  GL_RGB16F                           = $881B;

// GL_ARB_texture_rg
  GL_RG                               = $8227;
  GL_RG_INTEGER                       = $8228;
  GL_R8                               = $8229;
  GL_R16                              = $822A;
  GL_RG8                              = $822B;
  GL_RG16                             = $822C;
  GL_R16F                             = $822D;
  GL_R32F                             = $822E;
  GL_RG16F                            = $822F;
  GL_RG32F                            = $8230;
  GL_R8I                              = $8231;
  GL_R8UI                             = $8232;
  GL_R16I                             = $8233;
  GL_R16UI                            = $8234;
  GL_R32I                             = $8235;
  GL_R32UI                            = $8236;
  GL_RG8I                             = $8237;
  GL_RG8UI                            = $8238;
  GL_RG16I                            = $8239;
  GL_RG16UI                           = $823A;
  GL_RG32I                            = $823B;
  GL_RG32UI                           = $823C;

{
  GL_PROXY_TEXTURE_1D                 = $8063;
  GL_PROXY_TEXTURE_2D                 = $8064;
  GL_TEXTURE_TOO_LARGE                = $8065;
 }
  // GL_EXT_texture3D
  GL_PACK_SKIP_IMAGES                 = $806B;
  GL_PACK_IMAGE_HEIGHT                = $806C;
  GL_UNPACK_SKIP_IMAGES               = $806D;
  GL_UNPACK_IMAGE_HEIGHT              = $806E;
  GL_TEXTURE_3D                       = $806F;
  GL_PROXY_TEXTURE_3D                 = $8070;
  GL_TEXTURE_DEPTH                    = $8071;
  GL_TEXTURE_WRAP_R                   = $8072;
  GL_MAX_3D_TEXTURE_SIZE              = $8073;

  // GL_EXT_texture_compression_s3tc
  GL_COMPRESSED_RGB_S3TC_DXT1         = $83F0;
  GL_COMPRESSED_RGBA_S3TC_DXT1        = $83F1;
  GL_COMPRESSED_RGBA_S3TC_DXT3        = $83F2;
  GL_COMPRESSED_RGBA_S3TC_DXT5        = $83F3;


  GL_UNSIGNED_BYTE_2_3_3_REV          = $8362;
  GL_UNSIGNED_SHORT_5_6_5             = $8363;
  GL_UNSIGNED_SHORT_5_6_5_REV         = $8364;
  GL_UNSIGNED_SHORT_4_4_4_4_REV       = $8365;
  GL_UNSIGNED_SHORT_1_5_5_5_REV       = $8366;
  GL_UNSIGNED_INT_8_8_8_8_REV         = $8367;
  GL_UNSIGNED_INT_2_10_10_10_REV      = $8368;

  // GL_EXT_texture_cube_map
  GL_NORMAL_MAP                       = $8511;
  GL_REFLECTION_MAP                   = $8512;
  GL_TEXTURE_CUBE_MAP                 = $8513;
  GL_TEXTURE_BINDING_CUBE_MAP         = $8514;
  GL_TEXTURE_CUBE_MAP_POSITIVE_X      = $8515;
  GL_TEXTURE_CUBE_MAP_NEGATIVE_X      = $8516;
  GL_TEXTURE_CUBE_MAP_POSITIVE_Y      = $8517;
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Y      = $8518;
  GL_TEXTURE_CUBE_MAP_POSITIVE_Z      = $8519;
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Z      = $851A;
  GL_PROXY_TEXTURE_CUBE_MAP           = $851B;
  GL_MAX_CUBE_MAP_TEXTURE_SIZE        = $851C;

// FBO
  GL_FRAMEBUFFER                      = $8D40;
  GL_RENDERBUFFER                     = $8D41;
  GL_DEPTH_COMPONENT24                = $81A6;
  GL_COLOR_ATTACHMENT0                = $8CE0;
  GL_DEPTH_ATTACHMENT                 = $8D00;
  GL_FRAMEBUFFER_BINDING              = $8CA6;
  GL_FRAMEBUFFER_COMPLETE             = $8CD5;

// Shaders
  GL_FRAGMENT_SHADER                  = $8B30;
  GL_VERTEX_SHADER                    = $8B31;
  GL_COMPILE_STATUS                   = $8B81;
  GL_LINK_STATUS                      = $8B82;
  GL_INFO_LOG_LENGTH                  = $8B84;

// VBO
  GL_BUFFER_SIZE                      = $8764;
  GL_ARRAY_BUFFER                     = $8892;
  GL_ELEMENT_ARRAY_BUFFER             = $8893;
  GL_WRITE_ONLY                       = $88B9;
  GL_STREAM_DRAW                      = $88E0;
  GL_STATIC_DRAW                      = $88E4;

  GL_TEXTURE_COORD_ARRAY              = $8078;
  GL_NORMAL_ARRAY                     = $8075;
  GL_COLOR_ARRAY                      = $8076;
  GL_VERTEX_ARRAY                     = $8074;

// Queries
  GL_SAMPLES_PASSED                   = $8914;
  GL_QUERY_COUNTER_BITS               = $8864;
  GL_CURRENT_QUERY                    = $8865;
  GL_QUERY_RESULT                     = $8866;
  GL_QUERY_RESULT_AVAILABLE           = $8867;

  GL_CLIENT_PIXEL_STORE_BIT = $00000001;
  GL_CLIENT_VERTEX_ARRAY_BIT = $00000002;
  GL_CLIENT_ALL_ATTRIB_BITS = $FFFFFFFF;
  GL_POLYGON_OFFSET_FACTOR = $8038;
  GL_POLYGON_OFFSET_UNITS = $2A00;
  GL_POLYGON_OFFSET_POINT = $2A01;
  GL_POLYGON_OFFSET_LINE = $2A02;
  GL_POLYGON_OFFSET_FILL = $8037;

  procedure glFinish; stdcall; external opengl32;
  procedure glFlush; stdcall; external opengl32;

  function  glGetString(name: GLenum): PAnsiChar; stdcall; external opengl32;
  procedure glHint(target, mode: GLenum); stdcall; external opengl32;
  procedure glShadeModel(mode: GLenum); stdcall; external opengl32;

  // Clear
  procedure glClear(mask: GLbitfield); stdcall; external opengl32;
  procedure glClearColor(red, green, blue, alpha: GLfloat); stdcall; external opengl32;
  procedure glClearDepth(depth: GLdouble); stdcall; external opengl32;
  // Get
  procedure glGetFloatv(pname: GLenum; params: PGLfloat); stdcall; external opengl32;
  procedure glGetIntegerv(pname: GLenum; params: PGLint); stdcall; external opengl32;
  // State
  procedure glBegin(mode: GLenum); stdcall; external opengl32;
  procedure glEnd; stdcall; external opengl32;
  procedure glEnable(cap: GLenum); stdcall; external opengl32;
  procedure glEnableClientState(aarray: GLenum); stdcall; external opengl32;
  procedure glDisable(cap: GLenum); stdcall; external opengl32;
  procedure glDisableClientState(aarray: GLenum); stdcall; external opengl32;
  // Viewport
  procedure glViewport(x, y: GLint; width, height: GLsizei); stdcall; external opengl32;
  procedure glOrtho(left, right, bottom, top, zNear, zFar: GLdouble); stdcall; external opengl32;
  procedure glScissor(x, y: GLint; width, height: GLsizei); stdcall; external opengl32;
  // Depth
  procedure glDepthFunc(func: GLenum); stdcall; external opengl32;
  procedure glDepthMask(flag: GLboolean); stdcall; external opengl32;
  // Color
 { procedure glColor4ub(red, green, blue, alpha: GLubyte); stdcall; external opengl32;
  procedure glColor4ubv(v: PGLubyte); stdcall; external opengl32;
  procedure glColor4f(red, green, blue, alpha: GLfloat); stdcall; external opengl32;
  procedure glColorMask(red, green, blue, alpha: GLboolean); stdcall; external opengl32;    }
  // Alpha
  procedure glAlphaFunc(func: GLenum; ref: GLfloat); stdcall; external opengl32;
  procedure glBlendFunc(sfactor, dfactor: GLenum); stdcall; external opengl32;
  // CullFace
  procedure glCullFace(mode: GLenum); stdcall; external opengl32;
  // Matrix
  procedure glPushMatrix; stdcall; external opengl32;
  procedure glPopMatrix; stdcall; external opengl32;
  procedure glMatrixMode(mode: GLenum); stdcall; external opengl32;
  procedure glLoadIdentity; stdcall; external opengl32;
  procedure glLoadMatrixf(const m: PGLfloat); stdcall; external opengl32;
  procedure glMultMatrixf(const m: PGLfloat); stdcall; external opengl32;
  procedure glRotatef(angle, x, y, z: GLfloat); stdcall; external opengl32;
  procedure glScalef(x, y, z: GLfloat); stdcall; external opengl32;
  procedure glTranslatef(x, y, z: GLfloat); stdcall; external opengl32;
  // Vertex
  procedure glVertex2f(x, y: GLfloat); stdcall; external opengl32;
  procedure glVertex2fv(v: PGLfloat); stdcall; external opengl32;
  procedure glVertex3f(x, y, z: GLfloat); stdcall; external opengl32;
  procedure glVertexPointer(size: GLint; atype: GLenum; stride: GLsizei; const pointer: Pointer); stdcall; external opengl32;

  // TexCoords
  procedure glTexCoord2f(s, t: GLfloat); stdcall; external opengl32;
  procedure glTexCoord2fv(v: PGLfloat); stdcall; external opengl32;
  procedure glTexCoordPointer(size: GLint; atype: GLenum; stride: GLsizei; const pointer: Pointer); stdcall; external opengl32;

  // Texture
  procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;
  procedure glGenTextures(n: GLsizei; textures: PGLuint); stdcall; external opengl32;
  procedure glDeleteTextures(n: GLsizei; const textures: PGLuint); stdcall; external opengl32;
  procedure glTexParameterf(target: GLenum; pname: GLenum; param: GLfloat); stdcall; external opengl32;
  procedure glTexParameteri(target: GLenum; pname: GLenum; param: GLint); stdcall; external opengl32;
  procedure glPixelStorei(pname: GLenum; param: GLint); stdcall; external opengl32;
  procedure glTexImage2D(target: GLenum; level, internalformat: GLint; width, height: GLsizei; border: GLint; format, atype: GLenum; const pixels: Pointer); stdcall; external opengl32;
  procedure glTexSubImage2D(target: GLenum; level, xoffset, yoffset: GLint; width, height: GLsizei; format, atype: GLenum; const pixels: Pointer); stdcall; external opengl32;
  procedure glGetTexImage(target: GLenum; level: GLint; format: GLenum; atype: GLenum; pixels: Pointer); stdcall; external opengl32;
  procedure glCopyTexSubImage2D(target: GLenum; level, xoffset, yoffset, x, y: GLint; width, height: GLsizei); stdcall; external opengl32;
  procedure glTexEnvi(target: GLenum; pname: GLenum; param: GLint); stdcall; external opengl32;
  function  gluBuild2DMipmaps(target: GLenum; components, width, height: GLint; format, atype: GLenum; const data: Pointer): Integer; stdcall; external opengl32;

  // Normal
  procedure glNormal3f(x, y, z: GLfloat); stdcall; external opengl32;
  procedure glNormalPointer(atype: GLenum; stride: GLsizei; const pointer: Pointer); stdcall; external opengl32;

  procedure glDrawElements(mode: GLenum; count: GLsizei; atype: GLenum; const indices: Pointer); stdcall; external opengl32;
  procedure glPushClientAttrib(mask: GLbitfield ); stdcall; external opengl32;
  procedure glPopClientAttrib; stdcall; external opengl32;
  procedure glPolygonMode(face: GLenum; mode: GLenum); stdcall; external opengl32;

var
  wglChoosePixelFormatARB: function(hdc: HDC; const piAttribIList: PGLint; const pfAttribFList: PGLfloat; nMaxFormats: GLuint; piFormats: PGLint; nNumFormats: PGLuint): LongBool; stdcall;
  wglSwapIntervalEXT: function(interval: GLint): LongBool; stdcall;

  glActiveTexture: procedure(texture: GLenum); stdcall;

  glBindBuffer: procedure(target: GLenum; buffer: GLuint); stdcall;
  glDeleteBuffers: procedure(n: GLsizei; buffers : PGLuint); stdcall;
  glGenBuffers: procedure(n: GLsizei; buffers : PGLuint); stdcall;
  glIsBuffer: function (buffer: GLuint): GLboolean; stdcall;
  glBufferData: procedure(target: GLenum; size: GLsizei; data: PGLvoid; usage: GLenum); stdcall;
  glBufferSubData: procedure(target: GLenum; offset: GLint; size: GLsizei; data: PGLvoid); stdcall;
  glMapBuffer: function(target: GLenum; access: GLenum): PGLvoid; stdcall;
  glUnmapBuffer: function(target: GLenum) :GLboolean; stdcall;
  glGetBufferParameteriv: procedure(target: GLenum; pname: GLenum; params: PGLint); stdcall;

  glCompressedTexImage3D: procedure(target: GLenum; level: GLint; internalformat: GLenum; width: GLsizei; height: GLsizei; depth: GLsizei; border: GLint; imageSize: GLsizei; const data: PGLvoid); stdcall;
  glCompressedTexImage2D: procedure(target: GLenum; level: GLint; internalformat: GLenum; width: GLsizei; height: GLsizei; border: GLint; imageSize: GLsizei; const data: PGLvoid); stdcall;
  glCompressedTexImage1D: procedure(target: GLenum; level: GLint; internalformat: GLenum; width: GLsizei; border: GLint; imageSize: GLsizei; const data: PGLvoid); stdcall;


function LoadGLLibraly: Boolean;
function glGetProc(const Proc: PAnsiChar; var OldResult: Boolean): Pointer;

implementation

uses
  JEN_MAIN;

function glGetProc(const Proc: PAnsiChar; var OldResult: Boolean): Pointer;
begin
  if not OldResult then Exit(nil);

  Result := wglGetProcAddress(Proc);    {
  if not Assigned(Result) then
  begin
    S := Proc + 'ARB';
    Result := wglGetProcAddress(PAnsiChar(S));
  end;
  if not Assigned(Result) then
  begin
    S := Proc + 'EXT';
    Result := wglGetProcAddress(PAnsiChar(S));
  end;                            }
  if not Assigned(Result) then
  begin
    LogOut('Cannot load procedure ' + Proc, lmError);
    OldResult := false;
  end;
end;

function LoadGLLibraly : Boolean;
begin
  Result := true;

  wglSwapIntervalEXT := glGetProc('wglSwapIntervalEXT', Result);

  glActiveTexture := glGetProc('glActiveTexture', Result);

  glBindBuffer    := glGetProc('glBindBuffer', Result);
  glDeleteBuffers := glGetProc('glDeleteBuffers', Result);
  glGenBuffers    := glGetProc('glGenBuffers', Result);
  glIsBuffer      := glGetProc('glIsBuffer', Result);
  glBufferData    := glGetProc('glBufferData', Result);
  glBufferSubData := glGetProc('glBufferSubData', Result);
  glMapBuffer     := glGetProc('glMapBuffer', Result);
  glUnmapBuffer   := glGetProc('glUnmapBuffer', Result);
  glGetBufferParameteriv := glGetProc('glGetBufferParameteriv', Result);

  glCompressedTexImage3D := glGetProc('glCompressedTexImage3D', Result);
  glCompressedTexImage2D := glGetProc('glCompressedTexImage2D', Result);
  glCompressedTexImage1D := glGetProc('glCompressedTexImage1D', Result);

  Set8087CW($133F);
end;

end.
