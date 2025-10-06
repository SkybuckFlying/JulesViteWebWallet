unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Layouts, FMX.TabControl, uWalletDashboardFrame;

type
  TMainForm = class(TForm)
    NavPanel: TPanel;
    ButtonNavWallet: TButton;
    ButtonNavAssets: TButton;
    ButtonNavTrade: TButton;
    ButtonNavSettings: TButton;
    MainTabControl: TTabControl;
    TabWallet: TTabItem;
    TabAssets: TTabItem;
    LabelAssets: TLabel;
    TabTrade: TTabItem;
    LabelTrade: TLabel;
    TabSettings: TTabItem;
    LabelSettings: TLabel;
    procedure NavButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

constructor TMainForm.Create(AOwner: TComponent);
var
  WalletFrame: TWalletDashboardFrame;
begin
  inherited;
  // Assign a common event handler to all navigation buttons
  ButtonNavWallet.OnClick := NavButtonClick;
  ButtonNavAssets.OnClick := NavButtonClick;
  ButtonNavTrade.OnClick := NavButtonClick;
  ButtonNavSettings.OnClick := NavButtonClick;

  // Create and embed the Wallet Dashboard Frame
  WalletFrame := TWalletDashboardFrame.Create(Self);
  WalletFrame.Parent := TabWallet;
  WalletFrame.Align := TAlignLayout.Client;
end;

procedure TMainForm.NavButtonClick(Sender: TObject);
begin
  if Sender = ButtonNavWallet then
    MainTabControl.ActiveTab := TabWallet
  else if Sender = ButtonNavAssets then
    MainTabControl.ActiveTab := TabAssets
  else if Sender = ButtonNavTrade then
    MainTabControl.ActiveTab := TabTrade
  else if Sender = ButtonNavSettings then
    MainTabControl.ActiveTab := TabSettings;
end;

end.