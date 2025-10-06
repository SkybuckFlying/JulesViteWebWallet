unit uAppState;

interface

uses
  System.SysUtils, System.Classes, uViteService, uViteAccount;

type
  TAppState = class
  private
    class var FInstance: TAppState;
    FActiveAccount: TViteAccount;
    FCurrentAccountInfo: TAccountInfo;
    FCurrentQuota: TAccountQuota;
    FCurrentPledgeList: TPledgeListData;
    FOnStateChange: TNotifyEvent;
    procedure SetActiveAccount(const Value: TViteAccount);
    procedure SetCurrentAccountInfo(const Value: TAccountInfo);
    procedure SetCurrentPledgeList(const Value: TPledgeListData);
    procedure SetCurrentQuota(const Value: TAccountQuota);
  public
    class function Instance: TAppState;
    constructor Create;
    destructor Destroy; override;

    property ActiveAccount: TViteAccount read FActiveAccount write SetActiveAccount;
    property CurrentAccountInfo: TAccountInfo read FCurrentAccountInfo write SetCurrentAccountInfo;
    property CurrentPledgeList: TPledgeListData read FCurrentPledgeList write SetCurrentPledgeList;
    property CurrentQuota: TAccountQuota read FCurrentQuota write SetCurrentQuota;
    property OnStateChange: TNotifyEvent read FOnStateChange write FOnStateChange;
  end;

implementation

{ TAppState }

constructor TAppState.Create;
begin
  inherited;
end;

destructor TAppState.Destroy;
begin
  if Assigned(FCurrentAccountInfo.BalanceInfoMap) then
    FCurrentAccountInfo.BalanceInfoMap.Free;
  if Assigned(FCurrentPledgeList.StakeList) then
    SetLength(FCurrentPledgeList.StakeList, 0);
  if Assigned(FActiveAccount) then
    FActiveAccount.Free;
  inherited;
end;

class function TAppState.Instance: TAppState;
begin
  if not Assigned(FInstance) then
    FInstance := TAppState.Create;
  Result := FInstance;
end;

procedure TAppState.SetActiveAccount(const Value: TViteAccount);
begin
  if Assigned(FActiveAccount) then
    FActiveAccount.Free;
  FActiveAccount := Value;
  // Trigger the state change event so UI can update address displays
  if Assigned(FOnStateChange) then
    FOnStateChange(Self);
end;

procedure TAppState.SetCurrentAccountInfo(const Value: TAccountInfo);
begin
  // Free the old dictionary if it exists
  if Assigned(FCurrentAccountInfo.BalanceInfoMap) then
    FCurrentAccountInfo.BalanceInfoMap.Free;

  FCurrentAccountInfo := Value;

  // NOTE: We don't trigger state change here.
  // It's triggered by SetCurrentQuota to avoid multiple UI updates.
end;

procedure TAppState.SetCurrentPledgeList(const Value: TPledgeListData);
begin
  if Assigned(FCurrentPledgeList.StakeList) then
    SetLength(FCurrentPledgeList.StakeList, 0);
  FCurrentPledgeList := Value;
end;

procedure TAppState.SetCurrentQuota(const Value: TAccountQuota);
begin
  FCurrentQuota := Value;
  // Trigger the state change event
  if Assigned(FOnStateChange) then
    FOnStateChange(Self);
end;

initialization
  TAppState.FInstance := nil;

finalization
  if Assigned(TAppState.FInstance) then
    TAppState.FInstance.Free;

end.