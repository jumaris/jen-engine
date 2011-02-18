unit JEN_Main;

interface

uses
  JEN_Utils,
  JEN_SystemInfo,
  JEN_Game,
  JEN_Log,
  JEN_DefConsoleLog,
  JEN_Display,
  JEN_Display_Window,
  JEN_OpenGLHeader,
  JEN_OpenGL,
  JEN_Render,
  JEN_ResourceManager,
  JEN_DDSTexture,
  JEN_Shader,
  JEN_Camera3D,
  JEN_Math,
  XSystem;

const
  lmInfo       = TLogMsg.lmInfo;
  lmNotify     = TLogMsg.lmNotify;
  lmWarning    = TLogMsg.lmWarning;
  lmError      = TLogMsg.lmError;

  btNone        = TBlendType.btNone;
  btNormal      = TBlendType.btNormal;
  btAdd         = TBlendType.btAdd;
  btMult        = TBlendType.btMult;
  btOne         = TBlendType.btOne;
  btNoOverride  = TBlendType.btNoOverride;
  btAddAlpha    = TBlendType.btAddAlpha;

  cfNone        = TCullFace.cfNone;
  cfFront       = TCullFace.cfFront;
  cfBack        = TCullFace.cfBack;

  mtViewProj    = TMatrixType.mtViewProj;
  mtModel       = TMatrixType.mtModel;
  mtProj        = TMatrixType.mtProj;
  mtView        = TMatrixType.mtView;

type
  TGame           = JEN_GAME.TGame;

  TDisplayWindow  = JEN_Display_Window.TDisplayWindow;
  TGLRender       = JEN_OpenGL.TGLRender;

  TCamera3D       = JEN_Camera3D.TCamera3D;

  TFileStream     = JEN_Utils.TFileStream;

  TResourceManager= JEN_ResourceManager.TResourceManager;
  TDDSLoader      = JEN_DDSTexture.TDDSLoader;
  TTexture        = JEN_ResourceManager.TTexture;
  TShader         = JEN_Shader.TShader;

var
  Utils        : TUtils;
  SystemParams : TSystem;
  Log          : TLog;
  Game         : TGame;

  Display      : TDisplay;
  Render       : TRender;
  ResMan       : TResourceManager;

procedure LogOut(const Text: String; MType: TLogMsg);

implementation

procedure LogOut(const Text: String; MType: TLogMsg);
begin
  Log.AddMsg(Text, MType);
end;

initialization
begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$EndIf}
  Utils := TUtils.Create;
  SystemParams := TSystem.Create;
  Log := TLog.Create;
{$IFDEF DEBUG}
  AllocConsole;
  SetConsoleTitleW('Jen Console');
  TDefConsoleLog.Create;
{$EndIf}
  Log.Init;
end;

finalization
begin
  Utils.Free;
  SystemParams.Free;
  Log.Free;
end;

end.
