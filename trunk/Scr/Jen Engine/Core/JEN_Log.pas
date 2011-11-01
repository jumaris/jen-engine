unit JEN_Log;

interface

uses
  JEN_Header,
  JEN_Utils;

type
  TFileLog = class
    constructor Create(FileName : String);
  private
  class var
    Stream : IStream;
    class procedure AddMsg(MType: TLogMsg; Text: PWideChar); static; stdcall;
  end;

implementation

uses
  JEN_MAIN;

constructor TFileLog.Create(FileName : String);
var
  S : AnsiString;
  Major : LongInt;
  Minor : LongInt;
  Build : LongInt;
  Str   : array[1..4] of string;
begin
  Stream := Helpers.CreateStream(PWideChar(FileName));

  Helpers.SystemInfo.WindowsVersion(Major, Minor, Build);
  SetLength(S,80);
  FillChar(S[1],80,ord('*'));
  AddMsg(lmHeaderMsg, 'JenEngine');
  Str[1] := 'Windows version: '+Utils.IntToStr(Major)+'.'+Utils.IntToStr(Minor)+' (Buid '+Utils.IntToStr(Build)+')'+Utils.IntToStr(Helpers.SystemInfo.CPUCount);
  Str[2] := 'CPU            : '+Helpers.SystemInfo.CPUName+'(~'+Utils.IntToStr(Helpers.SystemInfo.CPUSpeed)+')x';
  Str[3] := 'RAM Total      : '+Utils.IntToStr(Helpers.SystemInfo.RAMTotal)+'Mb';
  Str[4] := 'RAM Available  : '+Utils.IntToStr(Helpers.SystemInfo.RAMFree)+'Mb';
  AddMsg(lmHeaderMsg, PWideChar(Str[1]));
  AddMsg(lmHeaderMsg, PWideChar(Str[2]));
  AddMsg(lmHeaderMsg, PWideChar(Str[3]));
  AddMsg(lmHeaderMsg, PWideChar(Str[4]));

  Engine.AddEventProc(evLogMsg, @AddMsg);
end;

class procedure TFileLog.AddMsg(MType: TLogMsg; Text: PWideChar);
var
  str,line : String;
  tstr : String;
  TimeStr : String;
  h,m,s,start,i,j : LongInt;
begin
  if Pointer(Text) = nil then
    Exit;

  h := Trunc(Utils.RealTime/3600000);
  m := Trunc(Utils.RealTime/60000);
  s := Trunc(Utils.RealTime/1000) - m*60;
  m := m - h*60;

  TimeStr := '';
  if h > 0 then
    TimeStr := Utils.IntToStr(h) + ':';

  tstr := '0' + Utils.IntToStr(m);
  TimeStr := TimeStr + Copy(tstr, Length(tstr)-1, 2) + ':';

  tstr := '0' + Utils.IntToStr(s);
  TimeStr := TimeStr + Copy(tstr, Length(tstr)-1, 2);
                         {
  if (Utils.Time - LastUpdate > 9999) then
    tstr := '9999'
  else
    tstr := '0000' + Utils.IntToStr(Utils.Time - LastUpdate);

  TimeStr := TimeStr + Copy(tstr, Length(tstr)-3, 4);  }

  case MType of
    lmHeaderMsg,lmInfo:
      str := Text+#13#10;

    lmNotify :
      str := '[' + TimeStr + '] ' + Text+#13#10;

    lmCode:
      begin
        i := 1;
        j := 1;
        str := 'Source code:'+#13#10;

        while Text[i] <> #0 do
        begin
          start := i;
          while not (AnsiChar(Text[i]) in [#0, #09, #10, #13]) do Inc(i);

          if Text[i] = #0 then
            break;

          if Text[i] = #09 then
          begin
            line := line + Copy(Text, start, i-start) + '   ';
            Inc(i);
            Continue;
          end;

          tstr := '000'+ Utils.IntToStr(j);
          str := str + Copy(tstr, Length(tstr)-2, 3) + ':' + Line + Copy(Text, start, i-start) + #13#10;
          Line := '';
          Inc(j);

          if Text[i] = #13 then Inc(i);
          if Text[i] = #10 then Inc(i);
        end;

      end;

    lmWarning :
      str := '[' + TimeStr + '] WARNING: ' + Text+#13#10;

    lmError :
      str := '[' + TimeStr + '] ERROR: ' + Text+#13#10;
  end;

  Stream.Write(str[1], Length(str)*2);
end;

end.
