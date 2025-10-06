unit uAppState;

interface

uses
  System.SysUtils, System.Classes, uViteService;

type
  TAppState = class
  private
    class var FInstance: TAppState;
    FCurrentAccount: TAccountInfo;
    FCurrentQuota: TAccountQuota;
    FOnStateChange: TNotifyEvent;
    procedure SetCurrentAccount(const Value: TAccountInfo);
    procedure SetCurrentQuota(const Value: TAccountQuota);
  public
    class function Instance: TAppState;
    constructor Create;
    destructor Destroy; override;

    property CurrentAccount: TAccountInfo read FCurrentAccount write SetCurrentAccount;
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
  if Assigned(FCurrentAccount.BalanceInfoMap) then
    FCurrentAccount.BalanceInfoMap.Free;
  inherited;
end;

class function TAppState.Instance: TAppState;
begin
  if not Assigned(FInstance) then
    FInstance := TAppState.Create;
  Result := FInstance;
end;

procedure TAppState.SetCurrentAccount(const Value: TAccountInfo);
begin
  // Free the old dictionary if it exists
  if Assigned(FCurrentAccount.BalanceInfoMap) then
    FCurrentAccount.BalanceInfoMap.Free;

  FCurrentAccount := Value;

  // Trigger the state change event
  if Assigned(FOnStateChange) then
    FOnStateChange(Self);
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