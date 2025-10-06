unit uQuotaHeadFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  uAppState, uViteService, System.Generics.Collections;

const
  VITE_TOKEN_ID = 'tti_5649544520544f4b454e6e40';

type
  TQuotaHeadFrame = class(TFrame)
    LayoutMain: TLayout;
    LabelTitle: TLabel;
    LabelAvailableBalanceCaption: TLabel;
    LabelAvailableBalance: TLabel;
    LabelQuotaCaption: TLabel;
    LabelQuota: TLabel;
  private
    procedure HandleStateChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses System.Math;

{$R *.fmx}

{ TQuotaHeadFrame }

constructor TQuotaHeadFrame.Create(AOwner: TComponent);
begin
  inherited;
  TAppState.Instance.OnStateChange := HandleStateChange;
  // Trigger initial state render to show default values
  HandleStateChange(Self);
end;

destructor TQuotaHeadFrame.Destroy;
begin
  TAppState.Instance.OnStateChange := nil;
  inherited;
end;

procedure TQuotaHeadFrame.HandleStateChange(Sender: TObject);
var
  AccountInfo: TAccountInfo;
  AccountQuota: TAccountQuota;
  BalanceInfo: TBalanceInfo;
  ViteBalance, CurrentQuotaValue: Extended;
  ViteBalanceStr: string;
  UT: Integer;
begin
  AccountInfo := TAppState.Instance.CurrentAccount;
  AccountQuota := TAppState.Instance.CurrentQuota;

  // Update Quota from the real API call result
  if (AccountQuota.CurrentQuota <> '') and TryStrToFloat(AccountQuota.CurrentQuota, CurrentQuotaValue) then
  begin
    UT := Floor(CurrentQuotaValue / QUOTA_PER_UT);
    LabelQuota.Text := UT.ToString + ' UT';
  end
  else
  begin
    LabelQuota.Text := '0 UT';
  end;

  // Update Available Balance
  if Assigned(AccountInfo.BalanceInfoMap) and AccountInfo.BalanceInfoMap.TryGetValue(VITE_TOKEN_ID, BalanceInfo) then
  begin
    // The balance is a string representing a large integer (atomic units). VITE has 18 decimals.
    // Using Extended for floating point division for display.
    if TryStrToFloat(BalanceInfo.Balance, ViteBalance) then
    begin
       ViteBalanceStr := Format('%.8f', [ViteBalance / 1e18]);
       LabelAvailableBalance.Text := ViteBalanceStr;
    end
    else
    begin
      LabelAvailableBalance.Text := '0 (Parse Error)';
    end;
  end
  else
  begin
    LabelAvailableBalance.Text := '0';
  end;
end;

end.