unit uWalletDashboardFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Edit, FMX.Memo, uViteService, uStringUtils, uAppState, System.Generics.Collections, uQuotaHeadFrame,
  uQRCodeFrame;

type
  TWalletDashboardFrame = class(TFrame)
    PanelContent: TPanel;
    PanelMyQuota: TPanel;
    LabelMyQuota: TLabel;
    QRCodeFrame: TQRCodeFrame;
    PanelPledgeTx: TPanel;
    LabelPledgeTx: TLabel;
    EditAddress: TEdit;
    ButtonGetInfo: TButton;
    MemoResult: TMemo;
    PanelList: TPanel;
    LabelList: TLabel;
    procedure ButtonGetInfoClick(Sender: TObject);
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
begin
  inherited;

  // Create and embed the Header Frame
  HeaderFrame := TQuotaHeadFrame.Create(Self);
  HeaderFrame.Parent := Self;
  HeaderFrame.Align := TAlignLayout.Top;

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

procedure TWalletDashboardFrame.ButtonGetInfoClick(Sender: TObject);
begin
  MemoResult.Lines.Clear;
  MemoResult.Lines.Add('Fetching account and quota info...');
  ButtonGetInfo.Enabled := False;

  TThread.CreateAnonymousThread(
    procedure
    var
      LAccountInfo: TAccountInfo;
      LAccountQuota: TAccountQuota;
    begin
      try
        // Fetch both sets of data in the background
        LAccountInfo := FViteService.GetAccountInfo(EditAddress.Text);
        LAccountQuota := FViteService.GetAccountQuota(EditAddress.Text);

        // Safely update the global state from the main thread
        TThread.Queue(nil,
          procedure
          begin
            // Set both properties. The last one will trigger the UI update.
            TAppState.Instance.CurrentAccount := LAccountInfo;
            TAppState.Instance.CurrentQuota := LAccountQuota;
          end);
      except
        on E: Exception do
          TThread.Queue(nil, procedure begin MemoResult.Lines.Add('Error: ' + E.Message); end);
      end;
      TThread.Queue(nil, procedure begin ButtonGetInfo.Enabled := True; end);
    end).Start;
end;

procedure TWalletDashboardFrame.HandleStateChange(Sender: TObject);
var
  AccountInfo: TAccountInfo;
  DisplayText: TStringBuilder;
  Pair: TPair<string, TBalanceInfo>;
begin
  MemoResult.Lines.Clear;
  AccountInfo := TAppState.Instance.CurrentAccount;

  if AccountInfo.Address = '' then
  begin
     MemoResult.Lines.Add('No account data loaded.');
     QRCodeFrame.Text := ''; // Clear QR Code
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