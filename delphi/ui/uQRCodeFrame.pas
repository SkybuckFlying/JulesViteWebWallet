unit uQRCodeFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  DelphiZXIngQRCode; // Use the new library

type
  TQRCodeFrame = class(TFrame)
    Image: TImage;
  private
    FText: string;
    procedure SetText(const Value: string);
    procedure GenerateQRCode;
  public
    property Text: string read FText write SetText;
  end;

implementation

{$R *.fmx}

{ TQRCodeFrame }

procedure TQRCodeFrame.GenerateQRCode;
var
  QRCode: TDelphiZXingQRCode;
  Bitmap: TBitmap;
  ModuleSize: Single;
  Row, Col: Integer;
  Rect: TRectF;
begin
  // Clear the image if there is no text
  if FText.IsEmpty then
  begin
    if Assigned(Image.Bitmap) then
      Image.Bitmap.SetSize(0,0);
    Exit;
  end;

  QRCode := TDelphiZXingQRCode.Create;
  try
    // Configure and generate the QR code data
    QRCode.Encoding := TQRCodeEncoding.qrUTF8NoBOM;
    QRCode.QuietZone := 2;
    QRCode.Data := FText;

    // Check if QR code was generated successfully
    if (QRCode.Rows = 0) or (QRCode.Columns = 0) then
      Exit;

    // Prepare a bitmap to draw on
    Bitmap := TBitmap.Create(Round(Image.Width), Round(Image.Height));
    try
      // Calculate the size of each module
      ModuleSize := Min(Bitmap.Width / QRCode.Columns, Bitmap.Height / QRCode.Rows);

      // Start drawing
      Bitmap.Canvas.BeginScene;
      try
        // Clear background to white
        Bitmap.Canvas.Clear(TAlphaColors.White);

        // Set the fill color for the QR code modules
        Bitmap.Canvas.Fill.Color := TAlphaColors.Black;

        // Iterate through each module and draw the black squares
        for Row := 0 to QRCode.Rows - 1 do
        begin
          for Col := 0 to QRCode.Columns - 1 do
          begin
            if QRCode.IsBlack[Row, Col] then
            begin
              Rect := TRectF.Create(Col * ModuleSize, Row * ModuleSize, (Col + 1) * ModuleSize, (Row + 1) * ModuleSize);
              Bitmap.Canvas.FillRect(Rect, 0, 0, [], 1);
            end;
          end;
        end;
      finally
        Bitmap.Canvas.EndScene;
      end;

      // Assign the newly created bitmap to the image component
      Image.Bitmap.Assign(Bitmap);
    finally
      Bitmap.Free;
    end;
  finally
    QRCode.Free;
  end;
end;

procedure TQRCodeFrame.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    GenerateQRCode;
  end;
end;

end.