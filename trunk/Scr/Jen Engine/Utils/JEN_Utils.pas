unit JEN_Utils;

interface

uses
  JEN_MATH,
  XSystem;

const
  LIST_DELTA = 32;

type
  TUtils = class
    constructor Create;
    destructor Destroy; override;
  private
    FTimeFreq : Int64;
    FTimeStart : LongInt;
    function GetTime : LongInt;
  public
    procedure Sleep(Value: LongWord);
    function IntToStr(Value: Integer): string;
    function StrToInt(const Str: string; Def: Integer = 0): Integer;
    function FloatToStr(Value: Single; Digits: Integer = 8): string;
    function StrToFloat(const Str: string; Def: Single = 0): Single;
    function ExtractFileDir(const FileName: string): string;
    function ExtractFileName(const FileName: string): string;
    function ExtractFileExt(const FileName: string): string;
    function ExtractFileNameNoExt(const FileName: string): string;
    property Time : LongInt read GetTime;
  end;

  TCompareFunc = function (Item1, Item2: Pointer): Integer;

  TItemArray = array of Pointer;

  TList = class
    constructor Create;
    destructor Destroy; override;
  protected
    FCount : Integer;
    FItems : TItemArray;
    function GetItem(idx: Integer): Pointer; inline;
    procedure SetItem(idx: Integer; Value: Pointer); inline;
  public
    function Add(p: Pointer): Pointer;
    procedure Del(idx: Integer);
    procedure Clear; virtual;
    procedure Sort(CompareFunc: TCompareFunc);
    function IndexOf(p: Pointer): Integer;
    property Count: Integer read FCount;
    property Items[Idx: Integer]: Pointer read GetItem write SetItem; default;
  end;

  TObjectList = class(TList)
  protected
    function GetItem(Idx: Integer): TObject; inline;
    procedure SetItem(Idx: Integer; Value: TObject); inline;
  public
    function Add(Obj: TObject): TObject;
    procedure Del(Idx: Integer);
    procedure Clear; override;
    function IndexOf(Obj: TObject): Integer;
    property Items[Idx: Integer]: TObject read GetItem write SetItem; default;
  end;

  TManager = class;

{ Managed Object Class }
  TManagedObj = class
    constructor Create(const ManagedName: AnsiString; Manager: TManager); virtual;
  protected
    FName     : AnsiString;
    FRefCount : Integer;
    FManager  : TManager;
  public
    function AddRef: Integer;
    function Release: Integer;
    procedure Free;
    property Name: AnsiString read FName;
  end;

  TManager = class(TObjectList)
  protected
    function GetItem(Idx: Integer): TManagedObj; inline;
  public
    function GetObj(const Name: AnsiString): TManagedObj;
    procedure Add(ManObj: TManagedObj);
    procedure Del(ManObj: TManagedObj);
    property Items[Idx: Integer]: TManagedObj read GetItem; default;
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
function LowerCase(const Str: string): string;
function TrimChars(const Str: string; Chars: TCharSet): string;
function Trim(const Str: string): string;
function DeleteChars(const Str: string; Chars: TCharSet): string;

implementation

uses
  JEN_MAIN;

procedure FreeAndNil(var Obj);
var
  Temp: TObject;
begin
  Temp := TObject(Obj);
  Pointer(Obj) := nil;
  Temp.Free;
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

{ TUtils }
constructor TUtils.Create;
var
  Count : Int64;
begin
  QueryPerformanceFrequency(FTimeFreq);
  QueryPerformanceCounter(Count);
  FTimeStart := Trunc(1000 * (Count / FTimeFreq));
end;

destructor TUtils.Destroy;
begin
  inherited;
end;

procedure TUtils.Sleep(Value: LongWord);
var h : THandle;
begin
  h := CreateEventW(nil, true, false, '');
  WaitForSingleObject(h, Value);
  CloseHandle(h);
end;

function TUtils.GetTime : LongInt;
var
  Count : Int64;
begin
  QueryPerformanceCounter(Count);
  Result := Trunc(1000 * (Count / FTimeFreq)) - FTimeStart;
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
  i : Integer;
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
  i: Integer;
begin
  Result := '';
  for i := Length(FileName) downto 1 do
  if (FileName[i] = '.')  then
    Result := Copy(FileName, i+1, length(FileName)-1);
end;

function TUtils.ExtractFileNameNoExt(const FileName: string): string;
var
  i: Integer;
begin
  Result := '';
  if Length(FileName) > 0 then begin
    Result := ExtractFileName(FileName);
    for i := Length(Result) - 1 downto 2 do
     if (Result[i] = '.') and (Result[i - 1] <> '.') then Break;
    Result := Copy(Result, 0, i - 1);
  end;
end;

{ TList }
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

procedure TList.Del(Idx: Integer);
var
  i : Integer;
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

  procedure SortFragment(L, R: Integer);
  var
    i, j : Integer;
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

function TList.IndexOf(p: Pointer): Integer;
var
  i : Integer;
begin
  for i := 0 to FCount - 1 do
    if FItems[i] = p then
    begin
      Result := i;
      Exit;
    end;
  Result := -1;
end;

function TList.GetItem(Idx: Integer): Pointer;
begin
  Result := FItems[Idx];
end;

procedure TList.SetItem(Idx: Integer; Value: Pointer);
begin
  FItems[Idx] := Value;
end;

{ TObjectList }
function TObjectList.Add(Obj: TObject): TObject;
begin
  Result := TObject(inherited Add(Pointer(Obj)));
end;

procedure TObjectList.Del(Idx: Integer);
begin
  TObject(FItems[Idx]).Free;
  inherited;
end;

procedure TObjectList.Clear;
var
  i : Integer;
begin
  for i := 0 to Count - 1 do
    TObject(FItems[i]).Free;
  inherited;
end;

function TObjectList.IndexOf(Obj: TObject): Integer;
begin
  Result := inherited IndexOf(Pointer(Obj));
end;

function TObjectList.GetItem(Idx: Integer): TObject;
begin
  Result := TObject(FItems[Idx]);
end;

procedure TObjectList.SetItem(Idx: Integer; Value: TObject);
begin
  TObject(FItems[Idx]) := Value;
end;

{ TManagedObj }
constructor TManagedObj.Create(const ManagedName: AnsiString; Manager: TManager);
begin
  FManager := Manager;
  FName    := ManagedName;
  FManager.Add(Self);
  FRefCount := 1;
end;

procedure TManagedObj.Free;
begin
  if Release <= 0 then
    FManager.Del(Self);
end;

function TManagedObj.AddRef: Integer;
begin
  Inc(FRefCount);
  Result := FRefCount;
end;

function TManagedObj.Release: Integer;
begin
  Dec(FRefCount);
  Result := FRefCount;
end;

{ TManager }
function TManager.GetObj(const Name: AnsiString): TManagedObj;
var
  i : Integer;
begin
  Result := nil;
  if Name <> '' then
    for i := 0 to Count - 1 do
      if TManagedObj(FItems[i]).Name = Name then
      begin
        Result := TManagedObj(FItems[i]);
        Result.AddRef;
        break;
      end;
end;

procedure TManager.Add(ManObj: TManagedObj);
begin
  inherited Add(ManObj);
end;

procedure TManager.Del(ManObj: TManagedObj);
var
  i : Integer;
begin
  for i := 0 to Count - 1 do
    if FItems[i] = Pointer(ManObj) then
    begin
      inherited Del(i);
      break;
    end;
end;

function TManager.GetItem(Idx: Integer): TManagedObj;
begin
  Result := TManagedObj(FItems[Idx]);
end;

class function TFileStream.Open(const FileName: string; RW: Boolean): TFileStream;
var
  i, io : LongInt;
begin
  Result := nil;

  io := 1;
  Result := TFileStream.Create;
  Result.FName := Utils.ExtractFileName(FileName);
  {$I-}
  FileMode := 2;

  if RW then
    Result.F := CreateFileW(PChar(FileName), GENERIC_WRITE or GENERIC_READ, FILE_SHARE_READ, nil, CREATE_ALWAYS, 0, 0)
  else
    Result.F := CreateFileW(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);

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

end.
