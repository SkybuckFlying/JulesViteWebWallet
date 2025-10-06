unit uViteService;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  System.Net.HttpClient, System.Generics.Collections;

const
  VITE_NODE_URL = 'https://node.vite.net/gvite/json-rpc';
  QUOTA_PER_UT = 21000;

type
  TAccountQuota = record
    CurrentQuota: string;
    MaxQuota: string;
    PledgeAmount: string;
  end;

  TPledge = record
    Beneficiary: string;
    StakeAmount: string;
    ExpirationHeight: string;
    ExpirationTime: Int64;
  end;

  TPledgeListData = record
    TotalStakeCount: Integer;
    TotalStakeAmount: string;
    StakeList: TArray<TPledge>;
  end;

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
    function ParseAccountQuota(const AJson: string): TAccountQuota;
    function ParseAccountPledgeList(const AJson: string): TPledgeListData;
  public
    constructor Create;
    destructor Destroy; override;

    function GetAccountInfo(const AAddress: string): TAccountInfo;
    function GetAccountQuota(const AAddress: string): TAccountQuota;
    function GetAccountPledgeList(const AAddress: string; PageIndex, PageSize: Integer): TPledgeListData;

    // TODO: Implement the full transaction signing logic for this method.
    // This will require porting the @vite/vitejs library's AccountBlock
    // creation, signing (ed25519), and PoW calculation logic.
    procedure StakeForQuota(const ABeneficiaryAddress: string; const AAmount: string);
  end;

implementation

{ TViteService }

function TViteService.ParseAccountPledgeList(const AJson: string): TPledgeListData;
var
  JsonObj, ResultObj, StakeListArray: TJSONValue;
  I: Integer;
  PledgeObj: TJSONObject;
begin
  Result := Default(TPledgeListData);
  Result.StakeList := [];

  JsonObj := TJSONObject.ParseJSONValue(AJson);
  if not Assigned(JsonObj) then Exit;
  try
    ResultObj := (JsonObj as TJSONObject).GetValue<TJSONObject>('result');
    if not Assigned(ResultObj) then Exit;

    Result.TotalStakeAmount := (ResultObj as TJSONObject).GetValue<string>('totalStakeAmount');
    Result.TotalStakeCount := StrToIntDef((ResultObj as TJSONObject).GetValue<string>('totalStakeCount'), 0);

    StakeListArray := (ResultObj as TJSONObject).GetValue('stakeList');
    if Assigned(StakeListArray) and (StakeListArray is TJSONArray) then
    begin
      SetLength(Result.StakeList, (StakeListArray as TJSONArray).Count);
      for I := 0 to (StakeListArray as TJSONArray).Count - 1 do
      begin
        PledgeObj := (StakeListArray as TJSONArray).Items[I] as TJSONObject;
        Result.StakeList[I].Beneficiary := PledgeObj.GetValue<string>('beneficiary');
        Result.StakeList[I].StakeAmount := PledgeObj.GetValue<string>('stakeAmount');
        Result.StakeList[I].ExpirationHeight := PledgeObj.GetValue<string>('expirationHeight');
        Result.StakeList[I].ExpirationTime := StrToInt64Def(PledgeObj.GetValue<string>('expirationTime'), 0);
      end;
    end;
  finally
    JsonObj.Free;
  end;
end;

function TViteService.GetAccountPledgeList(const AAddress: string; PageIndex, PageSize: Integer): TPledgeListData;
var
  JsonRequest: TJSONObject;
  RequestStream: TStringStream;
  ResponseContent: string;
begin
  JsonRequest := TJSONObject.Create;
  try
    JsonRequest.AddPair('jsonrpc', TJSONString.Create('2.0'));
    JsonRequest.AddPair('id', TJSONNumber.Create(1));
    JsonRequest.AddPair('method', TJSONString.Create('contract_getStakeList'));

    var ParamsArray := TJSONArray.Create;
    ParamsArray.Add(TJSONString.Create(AAddress));
    ParamsArray.Add(TJSONNumber.Create(PageIndex));
    ParamsArray.Add(TJSONNumber.Create(PageSize));
    JsonRequest.AddPair('params', ParamsArray);

    RequestStream := TStringStream.Create(JsonRequest.ToString, TEncoding.UTF8);
    try
      ResponseContent := FHttpClient.Post(VITE_NODE_URL, RequestStream).ContentAsString;
      Result := ParseAccountPledgeList(ResponseContent);
    finally
      RequestStream.Free;
    end;
  finally
    JsonRequest.Free;
  end;
end;

function TViteService.ParseAccountQuota(const AJson: string): TAccountQuota;
var
  JsonObj, ResultObj: TJSONValue;
begin
  Result := Default(TAccountQuota);

  JsonObj := TJSONObject.ParseJSONValue(AJson);
  if not Assigned(JsonObj) then Exit;
  try
    ResultObj := (JsonObj as TJSONObject).GetValue<TJSONObject>('result');
    if not Assigned(ResultObj) then Exit;

    Result.CurrentQuota := (ResultObj as TJSONObject).GetValue<string>('currentQuota');
    Result.MaxQuota := (ResultObj as TJSONObject).GetValue<string>('maxQuota');
    Result.PledgeAmount := (ResultObj as TJSONObject).GetValue<string>('pledgeAmount');
  finally
    JsonObj.Free;
  end;
end;

function TViteService.GetAccountQuota(const AAddress: string): TAccountQuota;
var
  JsonRequest: TJSONObject;
  RequestStream: TStringStream;
  ResponseContent: string;
begin
  JsonRequest := TJSONObject.Create;
  try
    JsonRequest.AddPair('jsonrpc', TJSONString.Create('2.0'));
    JsonRequest.AddPair('id', TJSONNumber.Create(1));
    JsonRequest.AddPair('method', TJSONString.Create('contract_getQuotaByAccount'));
    JsonRequest.AddPair('params', TJSONArray.Create.Add(TJSONString.Create(AAddress)));

    RequestStream := TStringStream.Create(JsonRequest.ToString, TEncoding.UTF8);
    try
      ResponseContent := FHttpClient.Post(VITE_NODE_URL, RequestStream).ContentAsString;
      Result := ParseAccountQuota(ResponseContent);
    finally
      RequestStream.Free;
    end;
  finally
    JsonRequest.Free;
  end;
end;

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

procedure TViteService.StakeForQuota(const ABeneficiaryAddress, AAmount: string);
begin
  // This method is a placeholder. The actual implementation will require:
  // 1. Creating an AccountBlock for the 'stakeForQuota' transaction.
  // 2. Setting the parameters (beneficiary, amount).
  // 3. Setting the provider and the active account's private key.
  // 4. Auto-setting the previous block hash and height.
  // 5. Calculating the required Proof of Work (PoW).
  // 6. Signing the block.
  // 7. Sending the raw transaction to the node.
end;

end.