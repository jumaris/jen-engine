unit JEN_Helpers;

interface

uses
  windows,
  sysutils,
  JEN_Header,
  JEN_Math,
  JEN_Camera2D,
  JEN_Camera3D,
  JEN_SystemInfo;

const
  LIST_DELTA = 32;

type
  TCharSet = set of AnsiChar;
  PByteArray = ^TByteArray;
  TByteArray = array [0..1] of byte;
  TItemArray = array of Pointer;

  TList = class(TInterfacedObject, IList)
    constructor Create;
    destructor Destroy; override;
  protected
    FCount: longint;
    FItems: TItemArray;
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
    FCount: LongInt;
    FItems: array of IUnknown;
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

  TStream = class(TInterfacedObject, IStream)
    constructor Create(const FileName: UnicodeString; RW: boolean);
    destructor Destroy; override;
  private
    FType: (stNone, stMemory, stFile);
    FName: UnicodeString;
    F: THandle;
    FPos: LongWord;
    FBPos: LongWord;
    FSize: LongWord;
    FMem: Pointer;
    function Valid: Boolean; stdcall;
    function GetName: PWideChar; stdcall;
    function GetSize: LongWord; stdcall;
    function GetPos: LongWord; stdcall;
    procedure SetPos(Value: LongWord); stdcall;
    function Read(out Buf; BufSize: LongWord): LongWord; stdcall;
    function Write(const Buf; BufSize: LongWord): LongWord; stdcall;
    //  function ReadAnsi: PAnsiChar; stdcall;
    procedure WriteAnsi(Value: PAnsiChar); stdcall;
    // function ReadUnicode: PWideChar; stdcall;
    procedure WriteUnicode(Value: PWideChar); stdcall;
  end;

  IHelpers = interface(JEN_Header.IHelpers)
    procedure Update;
    function GetRealTime: LongInt;
    procedure SetFreezeTime(Value: boolean);
    property FreezeTime: boolean write SetFreezeTime;
    property RealTime: LongInt read GetRealTime;
  end;

  THelpers = class(TInterfacedObject, IHelpers)
    constructor Create;
    procedure Free; stdcall;
  private
    FTimeFreq: int64;
    FTimeStart: LongInt;
    HWaitObj: THandle;
    FFreezeTime: LongInt;
    FCorrect: LongInt;
    FTime: LongInt;
    FSystemInfo: ISystemInfo;
    function GetRealTime: LongInt;
    function GetTime: LongInt; stdcall;
    function GetSystemInfo: ISystemInfo; stdcall;
  public
    procedure Sleep(Value: longword); stdcall;
    procedure SetFreezeTime(Value: boolean);
    procedure Update;
    procedure CreateList(out List: IList); stdcall;
    procedure CreateStream(out Stream: IStream; FileName: PWideChar; RW: Boolean = True); stdcall;
    procedure CreateCamera3D(out Camera: ICamera3d); stdcall;
    procedure CreateCamera2D(out Camera: ICamera2d); stdcall;
  end;

function MemCmp(p1, p2: Pointer; Size: LongInt): LongInt;
function LowerCase(const Str: UnicodeString): UnicodeString;
function TrimChars(const Str: UnicodeString; Chars: TCharSet): UnicodeString;
function Trim(const Str: UnicodeString): UnicodeString;
function DeleteChars(const Str: UnicodeString; Chars: TCharSet): UnicodeString;

          {
function IntToStr(Value: LongInt): UnicodeString;
function FloatToStr(Value: Single; Digits: LongInt = 8): UnicodeString;
function ExtractFileDir(const FileName: UnicodeString): UnicodeString;
function ExtractFileName(const FileName: UnicodeString; NoExt: boolean = False): UnicodeString;
function ExtractFileExt(const FileName: UnicodeString): UnicodeString;   }

implementation


        {
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
                  }
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

function LowerCase(const Str: UnicodeString): UnicodeString;
var
  i: LongInt;
begin
  Result := Str;
  for i := 1 to Length(Str) do
    if AnsiChar(Result[i]) in ['A'..'Z', 'À'..'ß'] then
      Result[i] := Chr(Ord(Result[i]) + 32);
end;

function TrimChars(const Str: UnicodeString; Chars: TCharSet): UnicodeString;
var
  i, j: LongInt;
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
  end
  else
    Result := '';
end;

function Trim(const Str: UnicodeString): UnicodeString;
begin
  Result := TrimChars(Str, [#9, #10, #13, #32]);
end;

function DeleteChars(const Str: UnicodeString; Chars: TCharSet): UnicodeString;
var
  i, j: LongInt;
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

// Converting
{$REGION 'Converting'}
{
function IntToStr(Value: LongInt): UnicodeString;
var
  Res : UnicodeString[32];
begin
  Str(Value, Res);
  Result := UnicodeString(Res);
end;

function StrToInt(const Str: UnicodeString; Def: LongInt): LongInt;
var
  Code : LongInt;
begin
  Val(Str, Result, Code);
  if Code <> 0 then
    Result := Def;
end;

function FloatToStr(Value: Single; Digits: LongInt = 8): UnicodeString;
var
  Res : UnicodeString[32];
begin
  Str(Value:0:Digits, Res);
  Result := UnicodeString(Res);
end;

function StrToFloat(const Str: UnicodeString; Def: Single): Single;
var
  Code : LongInt;
begin
  Val(Str, Result, Code);
  if Code <> 0 then
    Result := Def;
end;         }
               {
function BoolToStr(Value: Boolean): UnicodeString;
begin
  if Value then
    Result := 'True'
  else
    Result := 'False';
end;

function StrToBool(const Str: UnicodeString; Def: Boolean = False): Boolean;
var
  LStr : UnicodeString;
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
              {
function ExtractFileDir(const FileName: UnicodeString): UnicodeString;
var
  i: LongInt;
begin
  for i := Length(FileName) downto 1 do
    if (FileName[i] in ['\', '/', '|']) then
      Exit(Copy(FileName, 1, i));
  Result := '';
end;

function ExtractFileName(const FileName: UnicodeString; NoExt: boolean): UnicodeString;
var
  i: LongInt;
begin
  Result := Copy(FileName, Length(ExtractFileDir(FileName)) + 1, Length(FileName));
  if NoExt then
  begin
    for i := Length(Result) - 1 downto 2 do
      if (Result[i] = '.') and (Result[i - 1] <> '.') then
        Break;
    Result := Copy(Result, 0, i - 1);
  end;
end;

function ExtractFileExt(const FileName: UnicodeString): UnicodeString;
var
  i: LongInt;
begin
  Result := '';
  for i := Length(FileName) downto 1 do
    if (FileName[i] = '.') then
      Result := Copy(FileName, i + 1, length(FileName) - 1);
end;
               }
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
var
  s : UnicodeString;
begin
  if not Assigned(p) then
    Exit;

  if FCount mod LIST_DELTA = 0 then
    SetLength(FItems, Length(FItems) + LIST_DELTA);

  FItems[FCount] := p;
  Result := p;

  Inc(FCount);
end;

procedure TInterfaceList.Del(Idx: LongInt);
begin
  if idx < 0 then
    Exit;
  FItems[Idx] := FItems[FCount - 1];
  Dec(FCount);

  if Length(FItems) - FCount + 1 > LIST_DELTA then
    SetLength(FItems, Length(FItems) - LIST_DELTA);
end;

procedure TInterfaceList.Clear;
var
  i: LongInt;
begin
  for i := 0 to FCount - 1 do
    FItems[i] := nil;

  FCount := 0;
end;

function TInterfaceList.IndexOf(p: IUnknown): LongInt;
var
  i: LongInt;
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

function TList.Add(p: Pointer): Pointer; stdcall;
begin
  if FCount mod LIST_DELTA = 0 then
    SetLength(FItems, Length(FItems) + LIST_DELTA);
  FItems[FCount] := p;
  Result := p;
  Inc(FCount);
end;

procedure TList.Del(Idx: LongInt); stdcall;
var
  i: LongInt;
begin
  for i := Idx to FCount - 2 do
    FItems[i] := FItems[i + 1];
  Dec(FCount);

  if Length(FItems) - FCount + 1 > LIST_DELTA then
    SetLength(FItems, Length(FItems) - LIST_DELTA);
end;

procedure TList.Clear; stdcall;
begin
  FCount := 0;
  FItems := nil;
end;

procedure TList.Sort(CompareFunc: TCompareFunc); stdcall;

  procedure SortFragment(L, R: LongInt);
  var
    i, j: LongInt;
    P, T: Pointer;
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

function TList.IndexOf(p: Pointer): LongInt; stdcall;
var
  i: LongInt;
begin
  for i := 0 to FCount - 1 do
    if FItems[i] = p then
    begin
      Result := i;
      Exit;
    end;
  Result := -1;
end;

function TList.GetCount: LongInt; stdcall;
begin
  Result := FCount;
end;

function TList.GetItem(Idx: LongInt): Pointer; stdcall;
begin
  Result := FItems[Idx];
end;

procedure TList.SetItem(Idx: LongInt; Value: Pointer); stdcall;
begin
  FItems[Idx] := Value;
end;

{$ENDREGION}

// TFileStream
{$REGION 'TStream'}
constructor TStream.Create(const FileName: UnicodeString; RW: boolean);
var
  Res: HRSRC;
begin
  FType := stNone;
  FName := ExtractFileName(FileName);

  if FileName[1] = '|' then
  begin
    if Length(FileName) > 1 then
      Res := FindResourceW(HInstance, @FileName[2], PWideChar(RT_RCDATA))
    else
      Exit;

    F := LoadResource(HInstance, Res);
    FSize := SizeofResource(HInstance, Res);
    FMem := LockResource(F);

    if Assigned(FMem) then
      FType := stMemory;
  end
  else
  begin
    {$I-}
    FileMode := 2;

    if RW then
      F := CreateFileW(PWideChar(FileName), GENERIC_WRITE or GENERIC_READ,
        FILE_SHARE_READ, nil, CREATE_ALWAYS, 0, 0)
    else
      F := CreateFileW(PWideChar(FileName), GENERIC_READ, FILE_SHARE_READ,
        nil, OPEN_EXISTING, 0, 0);

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

function TStream.Valid: boolean; stdcall;
begin
  Result := FType <> stNone;
end;

function TStream.GetName: PWideChar; stdcall;
begin
  Result := PWideChar(FName);
end;

function TStream.GetSize: LongWord; stdcall;
begin
  Result := FSize;
end;

function TStream.GetPos: LongWord; stdcall;
begin
  Result := FPos;
end;

procedure TStream.SetPos(Value: LongWord); stdcall;
begin
  FPos := Value;
  if FType = stFile then
    SetFilePointer(F, FBPos + FPos, nil, FILE_BEGIN);
end;

function TStream.Read(out Buf; BufSize: LongWord): LongWord; stdcall;
begin
  case FType of
    stMemory:
    begin
      Result := Min(FPos + BufSize, FSize) - FPos;
      Move(FMem^, Buf, Result);
    end;
    stFile: ReadFile(F, Buf, BufSize, Result, nil);
    else
      Exit;
  end;

  Inc(FPos, Result);
end;

function TStream.Write(const Buf; BufSize: LongWord): LongWord; stdcall;
begin
  case FType of
    stMemory:
    begin
      Result := Min(FPos + BufSize, FSize) - FPos;
      Move(Buf, FMem^, Result);
    end;
    stFile: WriteFile(F, Buf, BufSize, Result, nil);
    else
      Exit;

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
procedure TStream.WriteAnsi(Value: PAnsiChar); stdcall;
var
  Len: word;
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
procedure TStream.WriteUnicode(Value: PWideChar); stdcall;
var
  Len: word;
begin
  if not Valid then
    Exit;
  Len := Length(Value);
  Write(Len, SizeOf(Len));
  Write(Value[1], Len * 2);
end;

{$ENDREGION}

constructor THelpers.Create;
begin
  HWaitObj := CreateEvent(nil, True, False, '');

  QueryPerformanceFrequency(FTimeFreq);
  FTimeStart := GetRealTime;

  FSystemInfo := TSystem.Create;
end;

procedure THelpers.Free; stdcall;
begin
  CloseHandle(HWaitObj);
end;

procedure THelpers.Sleep(Value: LongWord); stdcall;
begin
  if Value > 0 then
    WaitForSingleObject(HWaitObj, Value);
end;

function THelpers.GetRealTime: LongInt;
var
  Count: int64;
begin
  QueryPerformanceCounter(Count);
  Result := Trunc(1000 * (Count / FTimeFreq)) - FTimeStart + FCorrect;
end;

function THelpers.GetTime: LongInt; stdcall;
begin
  Result := FTime;
end;

procedure THelpers.SetFreezeTime(Value: Boolean);
begin
  if Value then
    FFreezeTime := GetRealTime
  else
    Dec(FCorrect, GetRealTime - FFreezeTime);
end;

procedure THelpers.Update;
begin
  FTime := GetRealTime;
end;

function THelpers.GetSystemInfo: ISystemInfo; stdcall;
begin
  Result := FSystemInfo;
end;

procedure THelpers.CreateList(out List: IList); stdcall;
begin
  List := TList.Create;
end;

procedure THelpers.CreateStream(out Stream: IStream; FileName: PWideChar; RW: Boolean = True); stdcall;
begin
  Stream := TStream.Create(FileName, RW);
end;

procedure THelpers.CreateCamera3D(out Camera: ICamera3d); stdcall;
begin
  Camera := TCamera3D.Create;
end;

procedure THelpers.CreateCamera2D(out Camera: ICamera2d); stdcall;
begin
  Camera := TCamera2D.Create;
end;


end.

