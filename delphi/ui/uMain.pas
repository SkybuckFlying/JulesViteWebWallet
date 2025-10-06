unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.StdCtrls,
  uQRCodeFrame, FMX.Edit, FMX.Memo, uViteService, uStringUtils, System.Generics.Collections;

type
  TMainForm = class(TForm)
    QRCodeFrame1: TQRCodeFrame;
    EditQRCode: TEdit;
    ButtonGenerateQR: TButton;
    EditAddress: TEdit;
    ButtonGetInfo: TButton;
    MemoResult: TMemo;
    procedure ButtonGenerateQRClick(Sender: TObject);
    procedure ButtonGetInfoClick(Sender: TObject);
  private
    FViteService: TViteService;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited;
  FViteService := TViteService.Create;
end;

destructor TMainForm.Destroy;
begin
  FViteService.Free;
  inherited;
end;

procedure TMainForm.ButtonGenerateQRClick(Sender: TObject);
begin
  // Update the QR code with the text from the edit box
  QRCodeFrame1.Text := EditQRCode.Text;
end;

procedure TMainForm.ButtonGetInfoClick(Sender: TObject);
begin
  MemoResult.Lines.Clear;
  MemoResult.Lines.Add('Fetching account info...');
  ButtonGetInfo.Enabled := False; // Disable button during fetch

  TThread.CreateAnonymousThread(
    procedure
    var
      LAccountInfo: TAccountInfo;
      LErrorMsg: string;
    begin
      LErrorMsg := '';
      try
        // This network call runs in the background
        LAccountInfo := FViteService.GetAccountInfo(EditAddress.Text);
      except
        on E: Exception do
          LErrorMsg := 'Error: ' + E.Message;
      end;

      // Safely update the UI from the main thread
      TThread.Queue(nil,
        procedure
        var
          DisplayText: TStringBuilder;
          Pair: TPair<string, TBalanceInfo>;
        begin
          try
            MemoResult.Lines.Clear;
            if LErrorMsg <> '' then
            begin
              MemoResult.Lines.Add(LErrorMsg);
            end
            else if LAccountInfo.Address = '' then
            begin
               MemoResult.Lines.Add('Failed to fetch account info or address not found.');
            end
            else
            begin
              DisplayText := TStringBuilder.Create;
              try
                DisplayText.AppendLine('Address: ' + LAccountInfo.Address);
                DisplayText.AppendLine('Block Count: ' + LAccountInfo.BlockCount);
                DisplayText.AppendLine('--- Balances ---');

                for Pair in LAccountInfo.BalanceInfoMap do
                begin
                  DisplayText.AppendLine(Format('  %s (%s):', [Pair.Value.TokenInfo.TokenName, Pair.Value.TokenInfo.TokenSymbol]));
                  DisplayText.AppendLine('    Balance: ' + Pair.Value.Balance);
                  DisplayText.AppendLine('    Token ID: ' + TStringUtils.EllipsisAddr(Pair.Value.TokenInfo.TokenId));
                end;

                MemoResult.Lines.Text := DisplayText.ToString;
              finally
                DisplayText.Free;
                LAccountInfo.BalanceInfoMap.Free;
              end;
            end;
          finally
             ButtonGetInfo.Enabled := True; // Re-enable button
          end;
        end);
    end).Start;
end;

end.