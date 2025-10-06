program ViteWallet;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'ui\uMain.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.