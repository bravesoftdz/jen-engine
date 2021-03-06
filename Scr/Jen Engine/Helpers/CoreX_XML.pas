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
  SysUtils,
  JEN_Header,
  JEN_Helpers,
  JEN_Math;

type
  TXMLParams = class(TInterfacedObject, IXMLParams)
    constructor Create(const Text: UnicodeString);
  private
    FCount  : LongInt;
    FParams : array of record
      Name  : UnicodeString;
      Value : UnicodeString;
    end;
    function GetParam(Name: PWideChar): TXMLParam; stdcall;
    function GetParamI(Idx: LongInt): TXMLParam; stdcall;
    function GetCount: LongInt; stdcall;
  end;

  TXML = class(TInterfacedObject, IXML)
    class function Load(Stream: IStream): IXML;
    constructor Create(const Text: UnicodeString; BeginPos: LongInt);
    destructor Destroy; override;
  private
    FCount   : LongInt;
    FNode    : array of IXML;
    FTag     : UnicodeString;
    FContent : UnicodeString;
    FDataLen : LongInt;
    FParams  : IXMLParams;
    function GetCount: LongInt; stdcall;
    function GetTag: PWideChar; stdcall;
    function GetContent: PWideChar; stdcall;
    function GetDataLen: LongInt; stdcall;
    function GetParams: IXMLParams; stdcall;
    function GetNode(TagName: PWideChar): IXML; stdcall;
    function GetNodeI(Idx: LongInt): IXML; stdcall;
  end;

implementation

constructor TXMLParams.Create(const Text: UnicodeString);
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

function TXMLParams.GetCount: LongInt; stdcall;
begin
  Result := FCount;
end;

function TXMLParams.GetParam(Name: PWideChar): TXMLParam; stdcall;
const
  NullParam : TXMLParam = (Name: ''; Value: '');
var
  i : LongInt;
begin
  for i := 0 to FCount - 1 do
    if FParams[i].Name = Name then
    begin
      Result.Name  := PWideChar(FParams[i].Name);
      Result.Value := PWideChar(FParams[i].Value);
      Exit;
    end;
  Result := NullParam;
end;

function TXMLParams.GetParamI(Idx: LongInt): TXMLParam; stdcall;
begin
  Result.Name  := PWideChar(FParams[Idx].Name);
  Result.Value := PWideChar(FParams[Idx].Value);
end;

class function TXML.Load(Stream: IStream): IXML;
var
  Text     : UnicodeString;
  Size     : LongInt;
  UTF8Text : UTF8String;
begin
  if Assigned(Stream) and Stream.Valid then
  begin
    Size := Stream.Size;
    SetLength(UTF8Text, Max(Size,1));
    Stream.Read(UTF8Text[1], Size);
    Text := UTF8Decode(UTF8Text);
    Result := Create(Text, 1);
  end else
    Result := nil;
end;

constructor TXML.Create(const Text: UnicodeString; BeginPos: LongInt);
var
  i, j : LongInt;
  Flag : (F_BEGIN, F_TAG, F_PARAMS, F_CONTENT, F_END);
  BeginIndex : LongInt;
  TextFlag   : Boolean;
  d : string;

  function TrimCode(const Text: UnicodeString): UnicodeString;
  var
    Start, k, t : PWideChar;
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
      while not (AnsiChar(t^) in [#0, #10, #13]) do Inc(t);
      Len := t - Start;

      k := Start;
      if (Len > 1) and (t^ <> #0) then
      begin
        while (k - Start < Tab) and (k - Start <= Len) and (AnsiChar(k^) in [#9, #32]) do Inc(k);

        if (Tab = MaxInt) then
          Tab := k - Start;

        Insert( Copy(Start, k - Start+1, Len - (k - Start) )+ #13#10, Result, Length(Result)+1 );
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
d := Text[i];
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
            '<' :
            begin
              if (Copy(Text, i, 9) = '<![CDATA[') then
              begin
                j := Pos(']]>', Copy(Text, i+9, Length(Text)));
                FContent := TrimCode(Copy(Text, i+9, j));
                i := i + j + 12;
                Continue;
              end;

              if  FContent = '' then
                FContent := Trim(Copy(Text, BeginIndex, i - BeginIndex));

            // is new tag or tag closing?
              for j := i + 1 to Length(Text) do
                if Text[j] = '>' then
                begin
                  if Trim(Copy(Text, i + 1, j - i - 1)) <> '/' + FTag then
                  begin
                    SetLength(FNode, Length(FNode) + 1);
                    FNode[Length(FNode) - 1] := TXML.Create(Text, i);
                    if FNode[Length(FNode) - 1].DataLen = 0 then
                      break;
                    i := i + FNode[Length(FNode) - 1].DataLen - 1;
                    BeginIndex := i + 1;
                  end else
                  begin
                    i := j - 1;
                    Flag := F_END;
                  end;
                  break;
                end;
            end;
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
begin
  FNode := nil;
  FParams := nil;
end;

function TXML.GetCount: LongInt; stdcall;
begin
  Result := FCount;
end;

function TXML.GetTag: PWideChar; stdcall;
begin
  Result := PWideChar(FTag);
end;

function TXML.GetContent: PWideChar; stdcall;
begin
  Result := PWideChar(FContent);
end;

function TXML.GetDataLen: LongInt; stdcall;
begin
  Result := FDataLen;
end;

function TXML.GetParams: IXMLParams; stdcall;
begin
  Result := FParams;
end;

function TXML.GetNode(TagName: PWideChar): IXML; stdcall;
var
  i : LongInt;
begin
  for i := 0 to FCount - 1 do
    if UnicodeString(FNode[i].Tag) = UnicodeString(TagName) then
    begin
      Result := FNode[i];
      Exit;
    end;
  Result := nil;
end;

function TXML.GetNodeI(Idx: LongInt): IXML; stdcall;
begin
  Result := FNode[Idx];
end;

end.
