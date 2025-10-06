unit uViteService;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  System.Net.HttpClient, System.Generics.Collections;

const
  VITE_NODE_URL = 'https://node.vite.net/gvite/json-rpc';

type
  // Based on https://docs.vite.org/api/
  TTokenInfo = record
    TokenName: string;
    TokenSymbol: string;
    TotalSupply: string;
    Decimals: Byte;
    Owner: string;
    TokenId: string;
  end;

  TBalanceInfo = record
    TokenInfo: TTokenInfo;
    Balance: string;
    TransactionCount: string;
  end;

  TAccountInfo = record
    Address: string;
    BlockCount: string;
    BalanceInfoMap: TDictionary<string, TBalanceInfo>;
  end;

  TViteService = class
  private
    FHttpClient: TNetHTTPClient;
    function ParseAccountInfo(const AJson: string): TAccountInfo;
  public
    constructor Create;
    destructor Destroy; override;

    function GetAccountInfo(const AAddress: string): TAccountInfo;
  end;

implementation

{ TViteService }

constructor TViteService.Create;
begin
  inherited Create;
  FHttpClient := TNetHTTPClient.Create(nil);
end;

destructor TViteService.Destroy;
begin
  FHttpClient.Free;
  inherited Destroy;
end;

function TViteService.ParseAccountInfo(const AJson: string): TAccountInfo;
var
  JsonObj, ResultObj, BalanceInfoMapObj, BalanceInfoItemObj, TokenInfoObj: TJSONValue;
  Pair: TJSONPair;
begin
  Result := Default(TAccountInfo);
  Result.BalanceInfoMap := TDictionary<string, TBalanceInfo>.Create;

  JsonObj := TJSONObject.ParseJSONValue(AJson);
  if not Assigned(JsonObj) then Exit;
  try
    ResultObj := (JsonObj as TJSONObject).GetValue<TJSONObject>('result');
    if not Assigned(ResultObj) then Exit;

    Result.Address := (ResultObj as TJSONObject).GetValue<string>('address');
    Result.BlockCount := (ResultObj as TJSONObject).GetValue<string>('blockCount');

    BalanceInfoMapObj := (ResultObj as TJSONObject).GetValue<TJSONObject>('balanceInfoMap');
    if Assigned(BalanceInfoMapObj) then
    begin
      for Pair in (BalanceInfoMapObj as TJSONObject) do
      begin
        var BalanceInfoRec: TBalanceInfo;
        BalanceInfoItemObj := Pair.JsonValue;

        BalanceInfoRec.Balance := (BalanceInfoItemObj as TJSONObject).GetValue<string>('balance');
        BalanceInfoRec.TransactionCount := (BalanceInfoItemObj as TJSONObject).GetValue<string>('transactionCount');

        TokenInfoObj := (BalanceInfoItemObj as TJSONObject).GetValue<TJSONObject>('tokenInfo');
        if Assigned(TokenInfoObj) then
        begin
          BalanceInfoRec.TokenInfo.TokenId := (TokenInfoObj as TJSONObject).GetValue<string>('tokenId');
          BalanceInfoRec.TokenInfo.TokenName := (TokenInfoObj as TJSONObject).GetValue<string>('tokenName');
          BalanceInfoRec.TokenInfo.TokenSymbol := (TokenInfoObj as TJSONObject).GetValue<string>('tokenSymbol');
          BalanceInfoRec.TokenInfo.Decimals := StrToIntDef((TokenInfoObj as TJSONObject).GetValue<string>('decimals'), 0);
          BalanceInfoRec.TokenInfo.Owner := (TokenInfoObj as TJSONObject).GetValue<string>('owner');
          BalanceInfoRec.TokenInfo.TotalSupply := (TokenInfoObj as TJSONObject).GetValue<string>('totalSupply');
        end;

        Result.BalanceInfoMap.Add(Pair.JsonString.Value, BalanceInfoRec);
      end;
    end;
  finally
    JsonObj.Free;
  end;
end;

function TViteService.GetAccountInfo(const AAddress: string): TAccountInfo;
var
  JsonRequest: TJSONObject;
  RequestStream: TStringStream;
  ResponseContent: string;
begin
  JsonRequest := TJSONObject.Create;
  try
    JsonRequest.AddPair('jsonrpc', TJSONString.Create('2.0'));
    JsonRequest.AddPair('id', TJSONNumber.Create(1));
    JsonRequest.AddPair('method', TJSONString.Create('ledger_getAccountInfo'));
    JsonRequest.AddPair('params', TJSONArray.Create.Add(TJSONString.Create(AAddress)));

    RequestStream := TStringStream.Create(JsonRequest.ToString, TEncoding.UTF8);
    try
      ResponseContent := FHttpClient.Post(VITE_NODE_URL, RequestStream).ContentAsString;
      Result := ParseAccountInfo(ResponseContent);
    finally
      RequestStream.Free;
    end;
  finally
    JsonRequest.Free;
  end;
end;

end.