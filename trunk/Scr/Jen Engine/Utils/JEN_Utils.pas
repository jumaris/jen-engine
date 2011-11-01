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
  TItemArray = array of Pointer;

  TList = class(TInterfacedObject, IList)
    constructor Create;
    destructor Destroy; override;
  protected
    FCount : LongInt;
    FItems : TItemArray;
    function GetCount: LongInt; stdcall;
    function GetItem(idx: LongInt): Pointer; inline; stdcall;
    procedure SetItem(idx: LongInt; Value: Pointer); inline; stdcall;
  public
    function Add(p: Pointer): Pointer; stdcall;
    procedure Del(idx: LongInt); stdcall;
    procedure Clear; virtual; stdcall;
    procedure Sort(CompareFunc: TCompareFunc); stdcall;
    function IndexOf(p: Pointer): LongInt; stdcall;
    property Count: LongInt read FCount;
    property Items[Idx: LongInt]: Pointer read GetItem write SetItem; default;
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

  IUtils = interface(JEN_Header.IUtils)
    procedure Update;
    function GetRealTime: LongInt;
    procedure SetFreezeTime(Value: Boolean);
    property FreezeTime: Boolean write SetFreezeTime;
    property RealTime: LongInt read GetRealTime;

    function IntToStr(Value: LongInt): string;
    function StrToInt(const Str: string; Def: LongInt = 0): LongInt;
    function FloatToStr(Value: Single; Digits: LongInt = 8): string;
    function StrToFloat(const Str: string; Def: Single = 0): Single;
    function ExtractFileDir(const FileName: string): string;
    function ExtractFileName(const FileName: string; NoExt: Boolean = False): string;
    function ExtractFileExt(const FileName: string): string;
  end;

  TUtils = class(TInterfacedObject, IJenSubSystem, IUtils)
    constructor Create;
    procedure Free; stdcall;
  private
    FTimeFreq   : Int64;
    FTimeStart  : LongInt;
    HWaitObj    : THandle;
    FFreezeTime : LongInt;
    FCorrect    : LongInt;
    FTime       : LongInt;
    function GetRealTime : LongInt;
    function GetTime : LongInt; stdcall;
  public
    procedure Sleep(Value: LongWord); stdcall;
    procedure SetFreezeTime(Value: Boolean);
    procedure Update;
    function IntToStr(Value: LongInt): string;
    function StrToInt(const Str: string; Def: LongInt = 0): LongInt;
    function FloatToStr(Value: Single; Digits: LongInt = 8): string;
    function StrToFloat(const Str: string; Def: Single = 0): Single;
    function ExtractFileDir(const FileName: string): string;
    function ExtractFileName(const FileName: string; NoExt: Boolean): string;
    function ExtractFileExt(const FileName: string): string;
  end;

  TStream = class(TInterfacedObject, IStream)
    constructor Create(const FileName: string; RW: Boolean);
    destructor Destroy; override;
  private
    FType  : (stNone, stMemory, stFile);
    FName  : string;
    F      : THandle;
    FPos   : LongInt;
    FBPos  : LongInt;
    FSize  : LongInt;
    FMem   : Pointer;
    function Valid: Boolean; stdcall;
    function GetName: PWideChar; stdcall;
    function GetSize: LongInt; stdcall;
    function GetPos: LongInt; stdcall;
    procedure SetPos(Value: LongInt); stdcall;
    function Read(out Buf; BufSize: LongInt): LongWord; stdcall;
    function Write(const Buf; BufSize: LongInt): LongWord; stdcall;
  //  function ReadAnsi: PAnsiChar; stdcall;
    procedure WriteAnsi(Value: PAnsiChar); stdcall;
   // function ReadUnicode: PWideChar; stdcall;
    procedure WriteUnicode(Value: PWideChar); stdcall;
  end;
  TCharSet = set of AnsiChar;

function MemCmp(p1, p2: Pointer; Size: LongInt): LongInt;

function LowerCase(const Str: string): string;
function TrimChars(const Str: string; Chars: TCharSet): string;
function Trim(const Str: string): string;
function DeleteChars(const Str: string; Chars: TCharSet): string;

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

function TList.GetCount: LongInt;
begin
  Result := FCount;
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
  if not Assigned(p) then Exit;

  if FCount mod LIST_DELTA = 0 then
    SetLength(FItems, Length(FItems) + LIST_DELTA);

  FItems[FCount] := p;
  Result := p;

  Inc(FCount);
end;

procedure TInterfaceList.Del(Idx: LongInt);
begin
  if idx < 0  then Exit;
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
begin
  HWaitObj := CreateEvent(nil, True, False, '');

  QueryPerformanceFrequency(FTimeFreq);
  FTimeStart := GetRealTime;
end;

procedure TUtils.Free;
begin
  CloseHandle(HWaitObj);
end;

procedure TUtils.Sleep(Value: LongWord);
begin
  if Value > 0 then
    WaitForSingleObject(HWaitObj, Value);
end;

function TUtils.GetRealTime : LongInt;
var
  Count : Int64;
begin
  QueryPerformanceCounter(Count);
  Result := Trunc(1000 * (Count / FTimeFreq)) - FTimeStart + FCorrect;
end;

function TUtils.GetTime: LongInt;
begin
  Result := FTime;
end;

procedure TUtils.SetFreezeTime(Value: Boolean);
begin
  if Value then
    FFreezeTime := GetRealTime
  else
    Dec(FCorrect, GetRealTime - FFreezeTime);
end;

procedure TUtils.Update;
begin
  FTime := GetRealTime;
end;

function TUtils.IntToStr(Value: LongInt): string;
var
  Res : string[32];
begin
  Str(Value, Res);
  Result := string(Res);
end;

function TUtils.StrToInt(const Str: string; Def: LongInt): LongInt;
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
    Result := 'True'
  else
    Result := 'False';
end;

function TUtils.StrToBool(const Str: string; Def: Boolean = False): Boolean;
var
  LStr : string;
begin
  LStr := LowerCase(Str);
  if LStr = 'True' then
    Result := True
  else
    if LStr = 'False' then
      Result := False
    else
      Result := Def;
end;     }

function TUtils.ExtractFileDir(const FileName: string): string;
var
  i : LongInt;
begin
  for i := Length(FileName) downto 1 do
    if (FileName[i] in ['\', '/', '|']) then
      Exit(Copy(FileName, 1, i));
  Result := '';
end;

function TUtils.ExtractFileName(const FileName: string; NoExt: Boolean): string;
var
  i: LongInt;
begin
  Result := Copy(FileName, Length(ExtractFileDir(FileName)) + 1, Length(FileName));
  if NoExt then
  begin
    for i := Length(Result) - 1 downto 2 do
      if (Result[i] = '.') and (Result[i - 1] <> '.') then Break;
    Result := Copy(Result, 0, i - 1);
  end;
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
{$ENDREGION}

// TFileStream
{$REGION 'TStream'}
constructor TStream.Create(const FileName: string; RW: Boolean);
var
  Res : HRSRC;
begin
  FType := stNone;
  FName := Utils.ExtractFileName(FileName);

  if FileName[1] = '|' then
  begin
    if Length(FileName) > 1 then
      Res := FindResource(HInstance, @FileName[2], RT_RCDATA)
    else
      Exit;

    F := LoadResource(HInstance, Res);
    FSize := SizeofResource(HInstance, Res);
    FMem := LockResource(F);

    if Assigned(FMem) then
      FType := stMemory;
  end else
  begin
    {$I-}
    FileMode := 2;

    if RW then
      F := CreateFile(PChar(FileName), GENERIC_WRITE or GENERIC_READ, FILE_SHARE_READ, nil, CREATE_ALWAYS, 0, 0)
    else
      F := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);

    if F = INVALID_HANDLE_VALUE then
      Exit;

    FType := stFile;
    FSize := GetFileSize(F, nil);
  end;

end;

destructor TStream.Destroy;
begin
  if FType = stFile then
    CloseHandle(F);
end;

function TStream.Valid: Boolean;
begin
  Result := FType <> stNone;
end;

function TStream.GetName: PWideChar;
begin
  Result := PWideChar(FName);
end;

function TStream.GetSize: LongInt;
begin
  Result := FSize;
end;

function TStream.GetPos: LongInt;
begin
  Result := FPos;
end;

procedure TStream.SetPos(Value: LongInt);
begin
  FPos := Value;
  if FType = stFile then
    SetFilePointer(F, FBPos + FPos, nil, FILE_BEGIN);
end;

function TStream.Read(out Buf; BufSize: LongInt): LongWord;
begin
  case FType of
    stMemory :
    begin
      Result := Min(FPos + BufSize, FSize) - FPos;
      Move(FMem^, Buf, Result);
    end;
    stFile: ReadFile(F, Buf, BufSize, Result, nil);
    else Exit;
  end;

  Inc(FPos, Result);
end;

function TStream.Write(const Buf; BufSize: LongInt): LongWord;
begin
  case FType of
    stMemory :
    begin
      Result := Min(FPos + BufSize, FSize) - FPos;
      Move(Buf, FMem^, Result);
    end;
    stFile: WriteFile(F, Buf, BufSize, Result, nil);
    else Exit;

  end;
  Inc(FPos, Result);
  Inc(FSize, Max(0, FPos - FSize));
end;
                      {
function TStream.ReadAnsi: PAnsiChar;
var
  Len : Word;
  Str : AnsiString;
begin
  if not Valid then
    Exit;
  Read(Len, SizeOf(Len));
  if Len > 0 then
  begin
    SetLength(Str, Len);
    Read(Str[1], Len);
    Result := PAnsiChar(Str);
  end else
    Result := '';
end;
             }
procedure TStream.WriteAnsi(Value: PAnsiChar);
var
  Len : Word;
begin
  if not Valid then
    Exit;
  Len := Length(Value);
  Write(Len, SizeOf(Len));
  if Len > 0 then
    Write(Value[1], Len);
end;
                {
function TStream.ReadUnicode: WideString;
var
  Len : Word;
begin
  if not Valid then
    Exit;
  Read(Len, SizeOf(Len));
  SetLength(Result, Len);
  Read(Result[1], Len * 2);
end;
                 }
procedure TStream.WriteUnicode(Value: PWideChar);
var
  Len : Word;
begin
  if not Valid then
    Exit;
  Len := Length(Value);
  Write(Len, SizeOf(Len));
  Write(Value[1], Len * 2);
end;
{$ENDREGION}

end.
