unit JEN_Utils;

interface

uses
  JEN_Header,
  JEN_MATH,
  Windows;

const
  LIST_DELTA = 32;

type
  PByteArray = ^TByteArray;
  TByteArray = array [0..1] of Byte;
  TCompareFunc = function (Item1, Item2: Pointer): LongInt;
  TItemArray = array of Pointer;

  TList = class
    constructor Create;
    destructor Destroy; override;
  protected
    FCount : LongInt;
    FItems : TItemArray;
    function GetItem(idx: LongInt): Pointer; inline;
    procedure SetItem(idx: LongInt; Value: Pointer); inline;
  public
    function Add(p: Pointer): Pointer;
    procedure Del(idx: LongInt);
    procedure Clear; virtual;
    procedure Sort(CompareFunc: TCompareFunc);
    function IndexOf(p: Pointer): LongInt;
    property Count: LongInt read FCount;
    property Items[Idx: LongInt]: Pointer read GetItem write SetItem; default;
  end;

  TObjectList = class(TList)
  protected
    function GetItem(Idx: LongInt): TObject; inline;
    procedure SetItem(Idx: LongInt; Value: TObject); inline;
  public
    function Add(Obj: TObject): TObject;
    procedure Del(Idx: LongInt);
    procedure Clear; override;
    function IndexOf(Obj: TObject): LongInt;
    property Items[Idx: LongInt]: TObject read GetItem write SetItem; default;
  end;

  TInterfaceList = class
    constructor Create;
    destructor Destroy; override;
  protected
    FCount : LongInt;
    FItems : array of IUnknown;
    function GetItem(idx: LongInt): IUnknown; inline;
    procedure SetItem(idx: LongInt; Value: IUnknown); inline;
  public
    function Add(p: IUnknown): IUnknown;
    procedure Del(idx: LongInt);
    procedure Clear; virtual;
    function IndexOf(p: IUnknown): LongInt;
    property Count: LongInt read FCount;
    property Items[Idx: LongInt]: IUnknown read GetItem write SetItem; default;
  end;

  TManagedInterface = class(TObject, IInterface, IManagedInterface)
  private
    procedure SetManager(Value: Pointer) stdcall;
  protected
    FRefCount : LongInt;
    FManager  : TInterfaceList;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: LongInt; stdcall;
    function _Release: LongInt; stdcall;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    class function NewInstance: TObject; override;
    property RefCount: LongInt read FRefCount;
  end;

  TUtils = class(TInterfacedObject, IJenSubSystem, IUtils)
    constructor Create;
    destructor Destroy; override;
  private
    FTimeFreq   : Int64;
    FTimeStart  : LongInt;
    HWaitObj    : THandle;
    FTime       : LongInt;
    function GetTime : LongInt; stdcall;
  public
    procedure Sleep(Value: LongWord); stdcall;
    procedure Update; stdcall;
    function IntToStr(Value: LongInt): string; stdcall;
    function StrToInt(const Str: string; Def: LongInt = 0): LongInt; stdcall;
    function FloatToStr(Value: Single; Digits: LongInt = 8): string; stdcall;
    function StrToFloat(const Str: string; Def: Single = 0): Single; stdcall;
    function ExtractFileDir(const FileName: string): string; stdcall;
    function ExtractFileName(const FileName: string): string; stdcall;
    function ExtractFileExt(const FileName: string): string; stdcall;
    function ExtractFileNameNoExt(const FileName: string): string; stdcall;
    property Time : LongInt read GetTime;
  end;

  TStream = class
  private
    FSize  : LongInt;
    FPos   : LongInt;
    FName  : String;
    procedure SetPos(Value: LongInt); virtual; abstract;
    procedure SetBlock(BPos, BSize: LongInt); virtual; abstract;
  public
    function Read(out Buf; BufSize: LongInt): LongWord; virtual; abstract;
    function Write(const Buf; BufSize: LongInt): LongWord; virtual; abstract;
    function ReadAnsi: AnsiString; virtual; abstract;
    procedure WriteAnsi(const Value: AnsiString); virtual; abstract;
    function ReadUnicode: WideString; virtual; abstract;
    procedure WriteUnicode(const Value: WideString); virtual; abstract;

    property Size: LongInt read FSize;
    property Pos: LongInt read FPos write SetPos;
    property Name: String read FName;
  end;

  TFileStream = class(TStream)
    class function Open(const FileName: string; RW: Boolean = False): TFileStream;
    destructor Destroy; override;
  private
    FBPos  : LongInt;
    F      : LongWord;
    procedure SetPos(Value: LongInt); override;
    procedure SetBlock(BPos, BSize: LongInt); override;
  public
    function Read(out Buf; BufSize: LongInt): LongWord; override;
    function Write(const Buf; BufSize: LongInt): LongWord; override;
    function ReadAnsi: AnsiString; override;
    procedure WriteAnsi(const Value: AnsiString); override;
    function ReadUnicode: WideString; override;
    procedure WriteUnicode(const Value: WideString); override;
  end;

  TCharSet = set of AnsiChar;

procedure FreeAndNil(var Obj); inline;
function MemCmp(p1, p2: Pointer; Size: LongInt): LongInt;

function LowerCase(const Str: string): string;
function TrimChars(const Str: string; Chars: TCharSet): string;
function Trim(const Str: string): string;
function DeleteChars(const Str: string; Chars: TCharSet): string;

function ExtractFileDir(const Path: string): string;

implementation

uses
  JEN_MAIN;

function InterlockedIncrement(var Addend: LongInt): LongInt;
asm
      MOV   EDX,1
      XCHG  EAX,EDX
 LOCK XADD  [EDX],EAX
      INC   EAX
end;

function InterlockedDecrement(var Addend: LongInt): LongInt;
asm
      MOV   EDX,-1
      XCHG  EAX,EDX
 LOCK XADD  [EDX],EAX
      DEC   EAX
end;

procedure FreeAndNil(var Obj);
var
  Temp: TObject;
begin
  Temp := TObject(Obj);
  Pointer(Obj) := nil;
  Temp.Free;
end;

function MemCmp(p1, p2: Pointer; Size: LongInt): LongInt;
asm
       PUSH    ESI
       PUSH    EDI
       MOV     ESI,P1
       MOV     EDI,P2
       XOR     EAX,EAX
       REPE    CMPSB
       JE      @@1
       MOVZX   EAX,BYTE PTR [ESI-1]
       MOVZX   EDX,BYTE PTR [EDI-1]
       SUB     EAX,EDX
@@1:   POP     EDI
       POP     ESI
end;

function LowerCase(const Str: string): string;
var
  i : LongInt;
begin
  Result := Str;
  for i := 1 to Length(Str) do
    if AnsiChar(Result[i]) in ['A'..'Z', 'À'..'ß'] then
      Result[i] := Chr(Ord(Result[i]) + 32);
end;

function TrimChars(const Str: string; Chars: TCharSet): string;
var
  i, j : LongInt;
begin
  j := Length(Str);
  i := 1;
  while (i <= j) and (AnsiChar(Str[i]) in Chars) do
    Inc(i);
  if i <= j then
  begin
    while AnsiChar(Str[j]) in Chars do
      Dec(j);
    Result := Copy(Str, i, j - i + 1);
  end else
    Result := '';
end;

function Trim(const Str: string): string;
begin
  Result := TrimChars(Str, [#9, #10, #13, #32]);
end;

function DeleteChars(const Str: string; Chars: TCharSet): string;
var
  i, j : LongInt;
begin
  j := 0;
  SetLength(Result, Length(Str));
  for i := 1 to Length(Str) do
    if not (AnsiChar(Str[i]) in Chars) then
    begin
      Inc(j);
      Result[j] := Str[i];
    end;
  SetLength(Result, j);
end;

function ExtractFileDir(const Path: string): string;
var
  i : LongInt;
begin
  for i := Length(Path) downto 1 do
    if (Path[i] = '\') or (Path[i] = '/') then
    begin
      Result := Copy(Path, 1, i);
      Exit;
    end;
  Result := '';
end;

// TList
{$REGION 'TList'}
constructor TList.Create;
begin
  FCount := 0;
  FItems := nil;
end;

destructor TList.Destroy;
begin
  Clear;
  inherited;
end;

function TList.Add(p: Pointer): Pointer;
begin
  if FCount mod LIST_DELTA = 0 then
    SetLength(FItems, Length(FItems) + LIST_DELTA);
  FItems[FCount] := p;
  Result := p;
  Inc(FCount);
end;

procedure TList.Del(Idx: LongInt);
var
  i : LongInt;
begin
  for i := Idx to FCount - 2 do
    FItems[i] := FItems[i + 1];
  Dec(FCount);

  if Length(FItems) - FCount + 1 > LIST_DELTA then
    SetLength(FItems, Length(FItems) - LIST_DELTA);
end;

procedure TList.Clear;
begin
  FCount := 0;
  FItems := nil;
end;

procedure TList.Sort(CompareFunc: TCompareFunc);

  procedure SortFragment(L, R: LongInt);
  var
    i, j : LongInt;
    P, T : Pointer;
  begin
    repeat
      i := L;
      j := R;
      P := FItems[(L + R) div 2];
      repeat
        while CompareFunc(FItems[i], P) < 0 do
          Inc(i);
        while CompareFunc(FItems[j], P) > 0 do
          Dec(j);
        if i <= j then
        begin
          T := FItems[i];
          FItems[i] := FItems[j];
          FItems[j] := T;
          Inc(i);
          Dec(j);
        end;
      until i > j;
      if L < j then
        SortFragment(L, j);
      L := i;
    until i >= R;
  end;

begin
  if FCount > 1 then
    SortFragment(0, FCount - 1);
end;

function TList.IndexOf(p: Pointer): LongInt;
var
  i : LongInt;
begin
  for i := 0 to FCount - 1 do
    if FItems[i] = p then
    begin
      Result := i;
      Exit;
    end;
  Result := -1;
end;

function TList.GetItem(Idx: LongInt): Pointer;
begin
  Result := FItems[Idx];
end;

procedure TList.SetItem(Idx: LongInt; Value: Pointer);
begin
  FItems[Idx] := Value;
end;
{$ENDREGION}

// TObjectList
{$REGION 'TObjectList'}
function TObjectList.Add(Obj: TObject): TObject;
begin
  Result := TObject(inherited Add(Pointer(Obj)));
end;

procedure TObjectList.Del(Idx: LongInt);
begin
  TObject(FItems[Idx]).Free;
  inherited;
end;

procedure TObjectList.Clear;
var
  i : LongInt;
begin
  for i := 0 to Count - 1 do
    TObject(FItems[i]).Free;
  inherited;
end;

function TObjectList.IndexOf(Obj: TObject): LongInt;
begin
  Result := inherited IndexOf(Pointer(Obj));
end;

function TObjectList.GetItem(Idx: LongInt): TObject;
begin
  Result := TObject(FItems[Idx]);
end;

procedure TObjectList.SetItem(Idx: LongInt; Value: TObject);
begin
  TObject(FItems[Idx]) := Value;
end;
{$ENDREGION}

// TManagedInterfacedObj
{$REGION 'TManagedInterfacedObj'}
procedure TManagedInterface.SetManager(Value: Pointer);
begin
  FManager := Value;
end;

procedure TManagedInterface.AfterConstruction;
begin
  InterlockedDecrement(FRefCount);
end;

procedure TManagedInterface.BeforeDestruction;
begin
  if RefCount <> 0 then
    System.Error(reInvalidPtr);
end;

class function TManagedInterface.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TManagedInterface(Result).FRefCount := 1;
end;

function TManagedInterface.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TManagedInterface._AddRef: LongInt;
begin
  Result := InterlockedIncrement(FRefCount);
end;

function TManagedInterface._Release: LongInt;
var
  Manager : TInterfaceList;
begin
  Result := InterlockedDecrement(FRefCount);
  case Result of
    0: Destroy;
    1: if(Assigned(FManager)) then
      begin
        Manager := FManager;
        FManager := nil;
        Manager.Del(Manager.IndexOf(self));
      end;
  end;

end;
{$ENDREGION}

// TInterfaceList
{$REGION 'TInterfaceList'}
constructor TInterfaceList.Create;
begin
  FCount := 0;
  FItems := nil;
end;

destructor TInterfaceList.Destroy;
begin
  Clear;
  inherited;
end;

function TInterfaceList.Add(p: IUnknown): IUnknown;
begin
  if FCount mod LIST_DELTA = 0 then
    SetLength(FItems, Length(FItems) + LIST_DELTA);
  FItems[FCount] := p;
  Result := p;
  (p as IManagedInterface).SetManager(self);
  Inc(FCount);
end;

procedure TInterfaceList.Del(Idx: LongInt);
begin
  if idx < 0  then Exit;     {
  for i := Idx to FCount - 2 do
    FItems[i] := FItems[i + 1];   }
  FItems[Idx] := FItems[FCount - 1];
  Dec(FCount);

  if Length(FItems) - FCount + 1 > LIST_DELTA then
    SetLength(FItems, Length(FItems) - LIST_DELTA);
end;

procedure TInterfaceList.Clear;
var
  i : LongInt;
begin
  for i := 0 to FCount - 1 do
    FItems[i] := nil;
  FCount := 0;
end;

function TInterfaceList.IndexOf(p: IUnknown): LongInt;
var
  i : LongInt;
begin
  Result := -1;
  for i := 0 to FCount - 1 do
    if Pointer(FItems[i]) = Pointer(p) then
      Exit(i);
end;

function TInterfaceList.GetItem(Idx: LongInt): IUnknown;
begin
  Result := FItems[Idx];
end;

procedure TInterfaceList.SetItem(Idx: LongInt; Value: IUnknown);
begin
  FItems[Idx] := IUnknown(Value);
end;
{$ENDREGION}

// TUtils
{$REGION 'TUtils'}
constructor TUtils.Create;
var
  Count : Int64;
begin
  HWaitObj := CreateEvent(nil, true, false, '');

  QueryPerformanceFrequency(FTimeFreq);
  QueryPerformanceCounter(Count);
  FTimeStart := Trunc(1000 * (Count / FTimeFreq));
end;

destructor TUtils.Destroy;
begin
  inherited;
  CloseHandle(HWaitObj);
end;

procedure TUtils.Sleep(Value: LongWord);
begin
  if Value > 0 then
  WaitForSingleObject(HWaitObj, Value);
end;

function TUtils.GetTime: LongInt;
begin
  Result := FTime;
end;

procedure TUtils.Update; stdcall;
var
  Count : Int64;
begin
  QueryPerformanceCounter(Count);
  FTime := Trunc(1000 * (Count / FTimeFreq)) - FTimeStart;
end;

function TUtils.IntToStr(Value: LongInt): String;
var
  Res : string[32];
begin
  Str(Value, Res);
  Result := string(Res);
end;

function TUtils.StrToInt(const Str: String; Def: LongInt): LongInt;
var
  Code : LongInt;
begin
  Val(Str, Result, Code);
  if Code <> 0 then
    Result := Def;
end;

function TUtils.FloatToStr(Value: Single; Digits: LongInt = 8): String;
var
  Res : string[32];
begin
  Str(Value:0:Digits, Res);
  Result := string(Res);
end;

function TUtils.StrToFloat(const Str: String; Def: Single): Single;
var
  Code : LongInt;
begin
  Val(Str, Result, Code);
  if Code <> 0 then
    Result := Def;
end;
               {
function TUtils.BoolToStr(Value: Boolean): string;
begin
  if Value then
    Result := 'true'
  else
    Result := 'false';
end;

function TUtils.StrToBool(const Str: string; Def: Boolean = False): Boolean;
var
  LStr : string;
begin
  LStr := LowerCase(Str);
  if LStr = 'true' then
    Result := True
  else
    if LStr = 'false' then
      Result := False
    else
      Result := Def;
end;     }

function TUtils.ExtractFileDir(const FileName: string): string;
var
  i : LongInt;
begin
  for i := Length(FileName) downto 1 do
    if (FileName[i] = '\') or (FileName[i] = '/') then
      Exit(Copy(FileName, 1, i));
  Result := '';
end;

function TUtils.ExtractFileName(const FileName: string): string;
begin
  Result := Copy(FileName, Length(ExtractFileDir(FileName)) + 1, Length(FileName));
end;

function TUtils.ExtractFileExt(const FileName: string): string;
var
  i: LongInt;
begin
  Result := '';
  for i := Length(FileName) downto 1 do
  if (FileName[i] = '.')  then
    Result := Copy(FileName, i+1, length(FileName)-1);
end;

function TUtils.ExtractFileNameNoExt(const FileName: string): string;
var
  i: LongInt;
begin
  Result := '';
  if Length(FileName) > 0 then begin
    Result := ExtractFileName(FileName);
    for i := Length(Result) - 1 downto 2 do
     if (Result[i] = '.') and (Result[i - 1] <> '.') then Break;
    Result := Copy(Result, 0, i - 1);
  end;
end;
{$ENDREGION}

// TFileStream
{$REGION 'TFileStream'}
class function TFileStream.Open(const FileName: string; RW: Boolean): TFileStream;
begin
  Result := TFileStream.Create;
  Result.FName := Utils.ExtractFileName(FileName);
  {$I-}
  FileMode := 2;

  if RW then
    Result.F := CreateFile(PChar(FileName), GENERIC_WRITE or GENERIC_READ, FILE_SHARE_READ, nil, CREATE_ALWAYS, 0, 0)
  else
    Result.F := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);

  if Result.F <> INVALID_HANDLE_VALUE then
  begin
    Result.FSize  := GetFileSize(Result.F, nil);
    Result.FPos   := 0;
    Result.FBPos  := 0;
  end else
  begin
  //  Assert('Can''t open "' + FileName + '"');
    Result.Free;
    Result := nil;
  end;

end;

destructor TFileStream.Destroy;
begin
  CloseHandle(F);
end;

procedure TFileStream.SetPos(Value: LongInt);
begin
  FPos := Value;
  SetFilePointer(F, FBPos + FPos, nil, FILE_BEGIN);
end;

procedure TFileStream.SetBlock(BPos, BSize: LongInt);
begin
  FSize := BSize;
  FBPos := BPos;
  Pos := 0;
end;

function TFileStream.Read(out Buf; BufSize: LongInt): LongWord;
begin
  ReadFile(F, Buf, BufSize, Result, nil);
  Inc(FPos, Result);
end;

function TFileStream.Write(const Buf; BufSize: LongInt): LongWord;
begin
  WriteFile(F, Buf, BufSize, Result, nil);
  Inc(FPos, Result);
  Inc(FSize, Max(0, FPos - FSize));
end;

function TFileStream.ReadAnsi: AnsiString;
var
  Len : Word;
begin
  Read(Len, SizeOf(Len));
  if Len > 0 then
  begin
    SetLength(Result, Len);
    Read(Result[1], Len);
  end else
    Result := '';
end;

procedure TFileStream.WriteAnsi(const Value: AnsiString);
var
  Len : Word;
begin
  Len := Length(Value);
  Write(Len, SizeOf(Len));
  if Len > 0 then
    Write(Value[1], Len);
end;

function TFileStream.ReadUnicode: WideString;
var
  Len : Word;
begin
  Read(Len, SizeOf(Len));
  SetLength(Result, Len);
  Read(Result[1], Len * 2);
end;

procedure TFileStream.WriteUnicode(const Value: WideString);
var
  Len : Word;
begin
  Len := Length(Value);
  Write(Len, SizeOf(Len));
  Write(Value[1], Len * 2);
end;
{$ENDREGION}

end.
