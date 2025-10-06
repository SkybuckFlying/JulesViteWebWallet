unit uPledgeTxFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Edit,
  uAppState, uStringUtils;

type
  TPledgeTxFrame = class(TFrame)
    LabelFromAddrCaption: TLabel;
    LabelFromAddr: TLabel;
    LabelAmountCaption: TLabel;
    EditAmount: TEdit;
    LabelBeneficiaryCaption: TLabel;
    EditBeneficiary: TEdit;
    ButtonSubmit: TButton;
    procedure ButtonSubmitClick(Sender: TObject);
  private
    procedure HandleStateChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses FMX.Dialogs;

{$R *.fmx}

{ TPledgeTxFrame }

constructor TPledgeTxFrame.Create(AOwner: TComponent);
begin
  inherited;
  TAppState.Instance.OnStateChange := HandleStateChange;
  HandleStateChange(Self); // Initial render
end;

destructor TPledgeTxFrame.Destroy;
begin
  TAppState.Instance.OnStateChange := nil;
  inherited;
end;

procedure TPledgeTxFrame.ButtonSubmitClick(Sender: TObject);
begin
  // Placeholder for now. This will eventually call the service to send the transaction.
  ShowMessage('Transaction signing is not yet implemented.');
end;

procedure TPledgeTxFrame.HandleStateChange(Sender: TObject);
var
  ActiveAccount: TViteAccount;
begin
  ActiveAccount := TAppState.Instance.ActiveAccount;
  if Assigned(ActiveAccount) then
  begin
    LabelFromAddr.Text := TStringUtils.EllipsisAddr(ActiveAccount.Address, 20, 20);
    LabelFromAddr.FontColor := TAlphaColors.Black;
    LabelFromAddr.Settings.Font.Style := [];
    EditBeneficiary.Text := ActiveAccount.Address;
  end
  else
  begin
    LabelFromAddr.Text := '(No active account)';
    LabelFromAddr.FontColor := TAlphaColors.Gray;
    LabelFromAddr.Settings.Font.Style := [fsItalic];
    EditBeneficiary.Text := '';
  end;
end;

end.