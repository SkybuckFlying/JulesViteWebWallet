unit uStringUtils;

interface

uses
  System.SysUtils;

type
  TStringUtils = class
  public
    {
      Replicates the functionality of the ellipsisAddr.js utility.
      Truncates a string if it's longer than a certain threshold,
      showing the beginning and end parts separated by '...'.

      @param AAddr The address string to truncate.
      @param ALen The base length for the parts to show.
      @param APrefixExtraLen An extra length to add to the prefix.
    }
    class function EllipsisAddr(const AAddr: string; const ALen: Integer = 10; const APrefixExtraLen: Integer = 5): string;
  end;

implementation

{ TStringUtils }

class function TStringUtils.EllipsisAddr(const AAddr: string; const ALen: Integer = 10; const APrefixExtraLen: Integer = 5): string;
var
  PrefixLen, SuffixLen: Integer;
begin
  if AAddr.IsEmpty then
  begin
    Result := '';
    Exit;
  end;

  PrefixLen := APrefixExtraLen + ALen;
  SuffixLen := ALen;

  // This logic is a direct port of the original JavaScript implementation.
  // It truncates the string if its length exceeds the combined prefix and suffix length.
  if AAddr.Length > (PrefixLen + SuffixLen) then
    // TStringHelper.Substring is 0-indexed for the start and takes a length parameter.
    Result := AAddr.Substring(0, PrefixLen) + '...' + AAddr.Substring(AAddr.Length - SuffixLen)
  else
    Result := AAddr;
end;

end.