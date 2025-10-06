unit uWalletDashboardFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Edit, FMX.Memo, uViteService, uStringUtils, uAppState, System.Generics.Collections, uQuotaHeadFrame,
  uQRCodeFrame, uPledgeTxFrame, uPledgeListFrame;

type
  TWalletDashboardFrame = class(TFrame)
    PanelMyQuota: TPanel;
    LabelMyQuota: TLabel;
    QRCodeFrame: TQRCodeFrame;
    LabelAddressCaption: TLabel;
    LabelAddress: TLabel;
    ButtonRefreshData: TButton;
    MemoResult: TMemo;
    PanelStaking: TPanel;
    procedure ButtonRefreshDataClick(Sender: TObject);
  private
    FViteService: TViteService;
    procedure HandleStateChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$R *.fmx}

{ TWalletDashboardFrame }

constructor TWalletDashboardFrame.Create(AOwner: TComponent);
var
  HeaderFrame: TQuotaHeadFrame;
  PledgeTxFrame: TPledgeTxFrame;
  PledgeListFrame: TPledgeListFrame;
begin
  inherited;

  // Create and embed the Header Frame
  HeaderFrame := TQuotaHeadFrame.Create(Self);
  HeaderFrame.Parent := Self;
  HeaderFrame.Align := TAlignLayout.Top;

  // Create and embed the Staking Frames
  PledgeTxFrame := TPledgeTxFrame.Create(Self);
  PledgeTxFrame.Parent := PanelStaking;
  PledgeTxFrame.Align := TAlignLayout.Top;

  PledgeListFrame := TPledgeListFrame.Create(Self);
  PledgeListFrame.Parent := PanelStaking;
  PledgeListFrame.Align := TAlignLayout.Client;


  FViteService := TViteService.Create;
  TAppState.Instance.OnStateChange := HandleStateChange;
  // Trigger initial state render
  HandleStateChange(Self);
end;

destructor TWalletDashboardFrame.Destroy;
begin
  TAppState.Instance.OnStateChange := nil;
  FViteService.Free;
  inherited;
end;

procedure TWalletDashboardFrame.ButtonRefreshDataClick(Sender: TObject);
var
  ActiveAddress: string;
begin
  if not Assigned(TAppState.Instance.ActiveAccount) then
  begin
    MemoResult.Lines.Text := 'No active account set.';
    Exit;
  end;

  ActiveAddress := TAppState.Instance.ActiveAccount.Address;
  MemoResult.Lines.Clear;
  MemoResult.Lines.Add('Fetching account, quota, and pledge info for ' + ActiveAddress);
  ButtonRefreshData.Enabled := False;

  TThread.CreateAnonymousThread(
    procedure
    var
      LAccountInfo: TAccountInfo;
      LAccountQuota: TAccountQuota;
      LPledgeList: TPledgeListData;
    begin
      try
        // Fetch all data in the background using the active address
        LAccountInfo := FViteService.GetAccountInfo(ActiveAddress);
        LAccountQuota := FViteService.GetAccountQuota(ActiveAddress);
        LPledgeList := FViteService.GetAccountPledgeList(ActiveAddress, 0, 50);

        // Safely update the global state from the main thread
        TThread.Queue(nil,
          procedure
          begin
            // Set all properties. The last one will trigger the UI update.
            TAppState.Instance.CurrentAccountInfo := LAccountInfo;
            TAppState.Instance.CurrentPledgeList := LPledgeList;
            TAppState.Instance.CurrentQuota := LAccountQuota; // Triggers OnStateChange
          end);
      except
        on E: Exception do
          TThread.Queue(nil, procedure begin MemoResult.Lines.Add('Error: ' + E.Message); end);
      end;
      TThread.Queue(nil, procedure begin ButtonRefreshData.Enabled := True; end);
    end).Start;
end;

procedure TWalletDashboardFrame.HandleStateChange(Sender: TObject);
var
  AccountInfo: TAccountInfo;
  ActiveAccount: TViteAccount;
  DisplayText: TStringBuilder;
  Pair: TPair<string, TBalanceInfo>;
begin
  ActiveAccount := TAppState.Instance.ActiveAccount;
  AccountInfo := TAppState.Instance.CurrentAccountInfo;

  // Update the displayed address
  if Assigned(ActiveAccount) then
    LabelAddress.Text := TStringUtils.EllipsisAddr(ActiveAccount.Address, 20, 20)
  else
    LabelAddress.Text := '(No active account)';

  // Update account info display in the memo
  MemoResult.Lines.Clear;
  if AccountInfo.Address = '' then
  begin
     MemoResult.Lines.Add('No account data loaded. Click "Refresh Data".');
     // Still update QR code if there is an active account
     if Assigned(ActiveAccount) then
       QRCodeFrame.Text := ActiveAccount.Address
     else
       QRCodeFrame.Text := '';
     Exit;
  end;

  // Update QR Code with the current address
  QRCodeFrame.Text := AccountInfo.Address;

  DisplayText := TStringBuilder.Create;
  try
    DisplayText.AppendLine('Address: ' + AccountInfo.Address);
    DisplayText.AppendLine('Block Count: ' + AccountInfo.BlockCount);
    DisplayText.AppendLine('--- Balances ---');

    for Pair in AccountInfo.BalanceInfoMap do
    begin
      DisplayText.AppendLine(Format('  %s (%s):', [Pair.Value.TokenInfo.TokenName, Pair.Value.TokenInfo.TokenSymbol]));
      DisplayText.AppendLine('    Balance: ' + Pair.Value.Balance);
      DisplayText.AppendLine('    Token ID: ' + TStringUtils.EllipsisAddr(Pair.Value.TokenInfo.TokenId));
    end;

    MemoResult.Lines.Text := DisplayText.ToString;
  finally
    DisplayText.Free;
  end;
end;

end.