unit uPledgeListFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  uAppState, uViteService, uStringUtils;

type
  TPledgeListFrame = class(TFrame)
    LabelTitle: TLabel;
    ListViewPledges: TListView;
  private
    procedure HandleStateChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  System.DateUtils, System.Math;

{$R *.fmx}

{ TPledgeListFrame }

constructor TPledgeListFrame.Create(AOwner: TComponent);
begin
  inherited;
  TAppState.Instance.OnStateChange := HandleStateChange;
  HandleStateChange(Self); // Initial render
end;

destructor TPledgeListFrame.Destroy;
begin
  TAppState.Instance.OnStateChange := nil;
  inherited;
end;

procedure TPledgeListFrame.HandleStateChange(Sender: TObject);
var
  PledgeList: TPledgeListData;
  Pledge: TPledge;
  ListItem: TListViewItem;
  Amount: Extended;
  WithdrawalTime: TDateTime;
begin
  PledgeList := TAppState.Instance.CurrentPledgeList;
  ListViewPledges.Items.Clear;

  if not Assigned(PledgeList.StakeList) then
    Exit;

  for Pledge in PledgeList.StakeList do
  begin
    ListItem := ListViewPledges.Items.Add;

    // Beneficiary
    ListItem.Text := TStringUtils.EllipsisAddr(Pledge.Beneficiary, 15, 15);

    // Amount
    if TryStrToFloat(Pledge.StakeAmount, Amount) then
      ListItem.Objects.FindObjectT<TListItemText>('Detail').Text := Format('%.4f', [Amount / 1e18])
    else
      ListItem.Objects.FindObjectT<TListItemText>('Detail').Text := '0';

    // Withdrawal Time
    WithdrawalTime := UnixToDateTime(Pledge.ExpirationTime);
    ListItem.Objects.FindObjectT<TListItemText>('Text').Text := FormatDateTime('yyyy-mm-dd hh:nn:ss', WithdrawalTime);
  end;
end;

end.