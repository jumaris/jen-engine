unit CoreX_XML;

{====================================================================}
{ LICENSE:                                                           }
{ Copyright (c) 2010, Timur "XProger" Gagiev                         }
{ All rights reserved.                                               }
{                                                                    }
{ Redistribution and use in source and binary forms, with or without }
{ modification, are permitted under the terms of the BSD License.    }
{====================================================================}
interface

uses
  JEN_Utils;

type
 TXMLParam = record
    Name  : string;
    Value : string;
  end;

  TXMLParams = class
    constructor Create(const Text: string);
  private
    FCount  : LongInt;
    FParams : array of TXMLParam;
    function GetParam(const Name: string): TXMLParam;
    function GetParamI(Idx: LongInt): TXMLParam;
  public
    property Count: LongInt read FCount;
    property Param[const Name: string]: TXMLParam read GetParam; default;
    property ParamI[Idx: LongInt]: TXMLParam read GetParamI;
  end;

  TXML = class
    class function Load(const Stream: TStream): TXML;
    constructor Create(const Text: string; BeginPos: LongInt);
    destructor Destroy; override;
  private
    FCount   : LongInt;
    FNode    : array of TXML;
    FTag     : string;
    FContent : string;
    FDataLen : LongInt;
    FParams  : TXMLParams;
    function GetNode(const TagName: string): TXML;
    function GetNodeI(Idx: LongInt): TXML;
  public
    property Count: LongInt read FCount;
    property Tag: string read FTag;
    property Content: string read FContent;
    property DataLen: LongInt read FDataLen;
    property Params: TXMLParams read FParams;
    property Node[const TagName: string]: TXML read GetNode; default;
    property NodeI[Idx: LongInt]: TXML read GetNodeI;
  end;

implementation

constructor TXMLParams.Create(const Text: string);
var
  i          : LongInt;
  Flag       : (F_BEGIN, F_NAME, F_VALUE);
  ParamIdx   : LongInt;
  IndexBegin : LongInt;
  ReadValue  : Boolean;
  TextFlag   : Boolean;
begin
  Flag       := F_BEGIN;
  ParamIdx   := -1;
  IndexBegin := 1;
  ReadValue  := False;
  TextFlag   := False;
  for i := 1 to Length(Text) do
    case Flag of
      F_BEGIN :
        if Text[i] <> ' ' then
        begin
          ParamIdx := Length(FParams);
          SetLength(FParams, ParamIdx + 1);
          FParams[ParamIdx].Name  := '';
          FParams[ParamIdx].Value := '';
          Flag := F_NAME;
          IndexBegin := i;
        end;
      F_NAME :
        if Text[i] = '=' then
        begin
          FParams[ParamIdx].Name := Trim(Copy(Text, IndexBegin, i - IndexBegin));
          Flag := F_VALUE;
          IndexBegin := i + 1;
        end;
      F_VALUE :
        begin
          if Text[i] = '"' then
            TextFlag := not TextFlag;
          if (Text[i] <> ' ') and (not TextFlag) then
            ReadValue := True
          else
            if ReadValue then
            begin
              FParams[ParamIdx].Value := TrimChars(Trim(Copy(Text, IndexBegin, i - IndexBegin)), ['"']);
              Flag := F_BEGIN;
              ReadValue := False;
              ParamIdx := -1;
            end else
              continue;
        end;
    end;
  if ParamIdx <> -1 then
    FParams[ParamIdx].Value := TrimChars(Trim(Copy(Text, IndexBegin, Length(Text) - IndexBegin + 1)), ['"']);
  FCount := Length(FParams);
end;

function TXMLParams.GetParam(const Name: string): TXMLParam;
const
  NullParam : TXMLParam = (Name: ''; Value: '');
var
  i : LongInt;
begin
  for i := 0 to Count - 1 do
    if FParams[i].Name = Name then
    begin
      Result.Name  := FParams[i].Name;
      Result.Value := FParams[i].Value;
      Exit;
    end;
  Result := NullParam;
end;

function TXMLParams.GetParamI(Idx: LongInt): TXMLParam;
begin
  Result.Name  := FParams[Idx].Name;
  Result.Value := FParams[Idx].Value;
end;

class function TXML.Load(const Stream: TStream): TXML;
var
  Text     : string;
  Size     : LongInt;
  UTF8Text : UTF8String;
begin
  if Stream <> nil then
  begin
    Size := Stream.Size;
    SetLength(UTF8Text, Size);
    Stream.Read(UTF8Text[1], Size);
    Text := UTF8ToString(UTF8Text);
    Result := Create(Text, 1);
    Stream.Free;
  end else
    Result := nil;
end;

constructor TXML.Create(const Text: string; BeginPos: LongInt);
var
  i, j : LongInt;
  Flag : (F_BEGIN, F_TAG, F_PARAMS, F_CONTENT, F_END);
  BeginIndex : LongInt;
  TextFlag   : Boolean;

  function TrimCode(const Text: string): string;
  var
    Start, k, t : PChar;
    Tab, Len : LongInt;
  begin
    if Pointer(Text) = nil then
      Exit('');

    Result := '';
    t := Pointer(Text);
    Tab := MaxInt;

    while (t^ <> #0) do
    begin
      Start := t;
      while not (t^ in [#0, #10, #13]) do Inc(t);
      Len := t - Start;

      k := Start;
      if (Len > 1) and (t^ <> #0) then
      begin
        while (k - Start < Tab) and (k - Start <= Len) and (k^ in [#9, #32]) do Inc(k);

        if (Tab = MaxInt) then
          Tab := k - Start;

        Insert( Copy(Start, k - Start+1, Len - (k - Start) )+ #10, Result, Length(Result)+1 );
      end;

      if t^ = #13 then Inc(t);
      if t^ = #10 then Inc(t);
    end;
    Result := Result;
  end;

begin
  TextFlag := False;
  Flag     := F_BEGIN;
  i := BeginPos - 1;

  BeginIndex := BeginPos;
  FContent := '';
  while i <= Length(Text) do
  begin
    Inc(i);
    case Flag of
    // waiting for new tag '<...'
      F_BEGIN :
        if Text[i] = '<' then
        begin
          Flag := F_TAG;
          BeginIndex := i + 1;
        end;
    // waiting for tag name '... ' or '.../' or '...>'
      F_TAG :
        begin
          case Text[i] of
            '>' : Flag := F_CONTENT;
            '/' : Flag := F_END;
            ' ' : Flag := F_PARAMS;
            '?', '!' :
              begin
                Flag := F_BEGIN;
                continue;
              end
          else
            continue;
          end;
          FTag := Trim(Copy(Text, BeginIndex, i - BeginIndex));
          BeginIndex := i + 1;
        end;
    // parse tag parameters
      F_PARAMS :
        begin
          if Text[i] = '"' then
            TextFlag := not TextFlag;
          if not TextFlag then
          begin
            case Text[i] of
              '>' : Flag := F_CONTENT;
              '/' : Flag := F_END;
            else
              continue;
            end;
            FParams := TXMLParams.Create(Trim(Copy(Text, BeginIndex, i - BeginIndex)));
            BeginIndex := i + 1;
          end;
        end;
    // parse tag content
      F_CONTENT :
        begin
          case Text[i] of
            '"' : TextFlag := not TextFlag;
            '<' :
              if not TextFlag then
              begin
                FContent := FContent + TrimCode(Copy(Text, BeginIndex, i - BeginIndex));

              // is new tag or my tag closing?
                for j := i to Length(Text) do
                  if Text[j] = '>' then
                  begin
                    if Trim(Copy(Text, i + 1, j - i - 1)) <> '/' + FTag then
                    begin
                      SetLength(FNode, Length(FNode) + 1);
                      FNode[Length(FNode) - 1] := TXML.Create(Text, i - 1);
                      i := i + FNode[Length(FNode) - 1].DataLen;
                      BeginIndex := i + 1;
                    end else
                      Flag := F_END;
                    break;
                  end;
              end
          end;
        end;
    // waiting for close tag
      F_END :
        if Text[i] = '>' then
        begin
          FDataLen := i - BeginPos;
          break;
        end;
    end;
  end;
  FCount := Length(FNode);
end;

destructor TXML.Destroy;
var
  i : LongInt;
begin
  for i := 0 to Count - 1 do
    NodeI[i].Free;
  Params.Free;
end;

function TXML.GetNode(const TagName: string): TXML;
var
  i : LongInt;
begin
  for i := 0 to Count - 1 do
    if FNode[i].Tag = TagName then
    begin
      Result := FNode[i];
      Exit;
    end;
  Result := nil;
end;

function TXML.GetNodeI(Idx: LongInt): TXML;
begin
  Result := FNode[Idx];
end;

end.
