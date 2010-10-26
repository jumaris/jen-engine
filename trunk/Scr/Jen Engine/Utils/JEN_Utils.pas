unit JEN_Utils;

interface

uses
  XSystem;

const
  LIST_DELTA = 32;

type
  TUtils = class
    constructor Create;
    destructor Destroy; override;
  private
    FTimeFreq   : Int64;
    FTimeStart  : LongInt;
    function GetTime : LongInt;
  public
    function IntToStr(Value: Integer): WideString;
    function StrToInt(const Str: String; Def: Integer = 0): Integer;
    function FloatToStr(Value: Single; Digits: Integer = 8): String;
    function StrToFloat(const Str: String; Def: Single = 0): Single;
    property Time : LongInt Read GetTime;
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

  TFileStream = class
    class function Init(const FileName: string; RW: Boolean = False): TFileStream; overload;
    destructor Destroy; override;
  private
    FSize  : LongInt;
    FPos   : LongInt;
    FBPos  : LongInt;
    F      : LongWord;
    Mem    : Pointer;
    procedure SetPos(Value: LongInt);
  {$IFNDEF NO_FILESYS}
    procedure SetBlock(BPos, BSize: LongInt);
  {$ENDIF}
  public
    function Read(out Buf; BufSize: LongInt): LongWord;
    function Write(const Buf; BufSize: LongInt): LongWord;
    function ReadAnsi: AnsiString;
    procedure WriteAnsi(const Value: AnsiString);
    function ReadUnicode: WideString;
    procedure WriteUnicode(const Value: WideString);
    property Size: LongInt read FSize;
    property Pos: LongInt read FPos write SetPos;
  end;

implementation

uses
  JEN_MATH;

{ TUtils }
constructor TUtils.Create;
var
  Count : Int64;
begin
  inherited;
  QueryPerformanceFrequency(FTimeFreq);
  QueryPerformanceCounter(Count);
  FTimeStart := Trunc(1000 * (Count / FTimeFreq));
end;

destructor TUtils.Destroy;
begin
  inherited;
end;

function TUtils.GetTime : LongInt;
var
  Count : Int64;
begin
  QueryPerformanceCounter(Count);
  Result := Trunc(1000 * (Count / FTimeFreq)) - FTimeStart;
end;

function TUtils.IntToStr(Value: LongInt): WideString;
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

{ TList }
constructor TList.Create;
begin
  inherited;
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
  inherited Create;
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
  i   : Integer;
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

class function TFileStream.Init(const FileName: string; RW: Boolean): TFileStream;
var
  i, io : LongInt;
begin
  Result := nil;

  io := 1;
  Result := TFileStream.Create;
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
