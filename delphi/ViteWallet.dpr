program ViteWallet;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'ui\uMain.pas' {MainForm},
  uWalletDashboardFrame in 'ui\uWalletDashboardFrame.pas' {WalletDashboardFrame: TFrame},
  DelphiZXIngQRCode in 'src\DelphiZXIngQRCode.pas',
  uAppState in 'src\uAppState.pas',
  uStringUtils in 'src\uStringUtils.pas',
  uViteService in 'src\uViteService.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.