unit ColorButton2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls, Buttons, ExtCtrls;

type
  TColorButton = class(TButton)
  private
    FShowBackColor: Boolean;
    FCanvas       : TCanvas;
    FIsFocused    : Boolean;
    FBackColor    : TColor;
    FForeColor    : TColor;
    FHoverColor   : TColor;
    procedure SetBackColor(const Value: TColor);
    procedure SetForeColor(const Value: TColor);
    procedure SetHoverColor(const Value: TColor);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;

    procedure SetButtonStyle(Value: Boolean); override;
    procedure DrawButton(Rect: TRect; State: UINT);

    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CNMeasureItem(var Message: TWMMeasureItem); message CN_MEASUREITEM;
    procedure CNDrawItem(var Message: TWMDrawItem); message CN_DRAWITEM;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property BackColor : TColor read FBackColor write SetBackColor default clBtnFace;
    property ForeColor : TColor read FForeColor write SetForeColor default clBtnText;
    property HoverColor: TColor read FHoverColor write SetHoverColor default clBtnFace;
  end;

procedure Register;

implementation

constructor TColorButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FShowBackColor := True;
  FCanvas        := TCanvas.Create;
  FBackColor     := clBtnFace;
  FForeColor     := clBtnText;
  FHoverColor    := clBtnFace;
end;

destructor TColorButton.Destroy;
begin
  FreeAndNil(FCanvas);
  inherited Destroy;
end;

procedure TColorButton.WndProc(var Message: TMessage);
begin
  if (Message.Msg = CM_MOUSELEAVE) then
  begin
    FShowBackColor := True;
    Invalidate;
  end
  else if (Message.Msg = CM_MOUSEENTER) then
  begin
    FShowBackColor := False;
    Invalidate;
  end;
  inherited;
end;

procedure TColorButton.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or BS_OWNERDRAW;
end;

procedure TColorButton.SetButtonStyle(Value: Boolean);
begin
  if Value <> FIsFocused then
  begin
    FIsFocused := Value;
    Invalidate;
  end;
end;

procedure TColorButton.CNMeasureItem(var Message: TWMMeasureItem);
begin
  with Message.MeasureItemStruct^ do
  begin
    itemWidth  := Width;
    itemHeight := Height;
  end;
end;

procedure TColorButton.CNDrawItem(var Message: TWMDrawItem);
var
  SaveIndex: Integer;
begin
  with Message.DrawItemStruct^ do
  begin
    SaveIndex := SaveDC(hDC);
    FCanvas.Lock;
    try
      FCanvas.Handle := hDC;
      FCanvas.Font   := Font;
      FCanvas.Brush  := Brush;
      DrawButton(rcItem, itemState);
    finally
      FCanvas.Handle := 0;
      FCanvas.Unlock;
      RestoreDC(hDC, SaveIndex);
    end;
  end;
  Message.Result := 1;
end;

procedure TColorButton.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TColorButton.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TColorButton.SetBackColor(const Value: TColor);
begin
  if FBackColor <> Value then
  begin
    FBackColor := Value;
    Invalidate;
  end;
end;

procedure TColorButton.SetForeColor(const Value: TColor);
begin
  if FForeColor <> Value then
  begin
    FForeColor := Value;
    Invalidate;
  end;
end;

procedure TColorButton.SetHoverColor(const Value: TColor);
begin
  if FHoverColor <> Value then
  begin
    FHoverColor := Value;
    Invalidate;
  end;
end;

procedure TColorButton.DrawButton(Rect: TRect; State: UINT);

var
  Flags, OldMode                 : Longint;
  IsDown, HasFocus, IsDisabled   : Boolean;
  OldBrushColor                  : TColor;
  OldBrushStyle                  : TBrushStyle;
  OldPenColor                    : TColor;
  OldPenWidth                    : Integer;
  OriginalRect                   : TRect;
  CaptionText                    : string;

begin
  CaptionText  := Caption;
  OriginalRect := Rect;
  Flags        := DFCS_BUTTONPUSH or DFCS_ADJUSTRECT;
  IsDown       := State and ODS_SELECTED <> 0;
  IsDisabled   := State and ODS_DISABLED <> 0;
  HasFocus     := State and ODS_FOCUS <> 0;

  if IsDown then
    Flags := Flags or DFCS_PUSHED;
  if IsDisabled then
    Flags := Flags or DFCS_INACTIVE;

  OldBrushStyle := FCanvas.Brush.Style;
  OldBrushColor := FCanvas.Brush.Color;
  OldPenColor   := FCanvas.Pen.Color;
  OldPenWidth   := FCanvas.Pen.Width;

  if (FIsFocused or HasFocus) then
  begin
    FCanvas.Pen.Color   := clWindowFrame;
    FCanvas.Pen.Width   := 1;
    FCanvas.Brush.Style := bsClear;
    FCanvas.Rectangle(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
    InflateRect(Rect, -1, -1);
  end;

  if IsDown then
  begin
    FCanvas.Pen.Color   := clBtnShadow;
    FCanvas.Pen.Width   := 1;
    FCanvas.Brush.Style := bsSolid;
    FCanvas.Brush.Color := clBtnFace;
    FCanvas.Rectangle(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
    InflateRect(Rect, -1, -1);
  end
  else
  begin
    DrawFrameControl(FCanvas.Handle, Rect, DFC_BUTTON, Flags);
  end;

  // Restore brush style before FillRect so the fill is applied correctly
  FCanvas.Brush.Style := OldBrushStyle;

  if IsDown then
    OffsetRect(Rect, 1, 1);

  if FShowBackColor then
    FCanvas.Brush.Color := BackColor
  else
    FCanvas.Brush.Color := HoverColor;
  FCanvas.FillRect(Rect);

  OldMode            := SetBkMode(FCanvas.Handle, TRANSPARENT);
  FCanvas.Font.Color := ForeColor;
  if IsDisabled then
    DrawState(FCanvas.Handle, FCanvas.Brush.Handle, nil, NativeInt(CaptionText), 0,
      ((Rect.Right - Rect.Left) - FCanvas.TextWidth(CaptionText)) div 2,
      ((Rect.Bottom - Rect.Top) - FCanvas.TextHeight(CaptionText)) div 2, 0, 0, DST_TEXT or DSS_DISABLED)
  else
  begin
    InflateRect(Rect, -4, -4);
    DrawText(FCanvas.Handle, PChar(CaptionText), -1, Rect, DT_WORDBREAK or DT_CENTER);
  end;

  SetBkMode(FCanvas.Handle, OldMode);

  if (FIsFocused and HasFocus) then
  begin
    Rect := OriginalRect;
    InflateRect(Rect, -4, -4);
    FCanvas.Pen.Color   := clWindowFrame;
    FCanvas.Brush.Color := clBtnFace;
    DrawFocusRect(FCanvas.Handle, Rect);
  end;

  FCanvas.Pen.Color   := OldPenColor;
  FCanvas.Pen.Width   := OldPenWidth;
  FCanvas.Brush.Color := OldBrushColor;
end;

procedure Register;
begin
  RegisterComponents('Standard', [TColorButton]);
end;

initialization

RegisterClass(TColorButton); // needed for persistence at runtime

end.
