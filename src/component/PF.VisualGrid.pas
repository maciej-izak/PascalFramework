﻿unit PF.VisualGrid;

{$I pf.inc}

interface

uses
  Classes, SysUtils, StdCtrls, ExtCtrls, Controls, Grids, ComCtrls, Types
  {$IFNDEF FPC}
  ,Tabs
  {$ENDIF};

type
  TSortDirection = (sdNone, sdAscending, sdDescending);
  TFilterType = (ftMatchTextExact, ftMatchTextBeginning, ftMatchTextEnd,
    ftMatchTextAnywhere, ftNumericEQ, ftNumericLT, ftNumericLTE, ftNumericGT,
    ftNumericGTE, ftNumericBetweenInclusive, ftNumericBetweenExclusive);

  TColumnFilter = record
    ColumnName: utf8string;
    Sort: TSortDirection;
    Filter: TFilterType;
    FilterText: utf8string;
    FilterNumeric1: Int64;
    FilterNumeric2: Int64;
  end;

  TArray<T> = array of T;

  TFilterCriteria = TArray<TColumnFilter>;

  TDataTable = record
  public
    //Name : utf8string;
    Columns: TArray<utf8string>;
    Rows : TArray<Variant>;
  end;

  IDataSource = interface
    function FetchPage(APageIndex, APageSize : Integer; out APageCount : Integer; AFilter: TFilterCriteria): TDataTable;
  end;

  TDrawVisualCellEvent = procedure(Sender: TObject; ACol, ARow: Longint;
    Rect: TRect; State: TGridDrawState; const RowData: Variant; var Handled: boolean) of object;

  TCustomVisualGrid = class(TWinControl)
  protected const
    PAGE_NAVIGATION_FIRST    = 1;
    PAGE_NAVIGATION_PREVIOUS = 2;
    PAGE_NAVIGATION_NEXT     = 3;
    PAGE_NAVIGATION_LAST     = 4;
  protected { component interface part }
    FSearchLabel: TLabel;
    FSearchEdit: TEdit;
    FTopPanel: TPanel;
    FTopPanelRight: TPanel;
    FBottomPanel: TPanel;
    FBottomCenterPanel: TPanel;
    FBottomRightPanel: TPanel;

    FButtonFirst: TButton;
    FButtonLast: TButton;
    FButtonNext: TButton;
    FButtonPrevious: TButton;

    FPageIndexEdit: TEdit;
    FPageCountLabel: TLabel;

    FPageSizeEdit: TEdit;
    FPageSizeLabel: TLabel;
    FAllRecordsCountLabel: TLabel;

    FDrawGrid: TDrawGrid;
  protected { events for UI }
    procedure StandardDrawCell(Sender: TObject; ACol, ARow: Longint;
      Rect: TRect; State: TGridDrawState);
    procedure PageIndexEditChange(Sender: TObject);
    procedure PageNavigationClick(Sender: TObject);
  private
    procedure ClickTest(Sender: TObject);
    procedure SetPageIndex(const Value: Integer);
    procedure SetPageSize(const Value: Integer);
  protected { TComponent }
    procedure Loaded; override;
  protected
    FPageIndexUpdate: boolean;
    FDataTable: TDataTable;
    FDataSource: IDataSource;
    FPageSize: Integer;
    FPageIndex: Integer;
    FPageCount: Integer;

    FColumns: TStrings;
    FOnDrawVisualCell: TDrawVisualCellEvent;

    procedure SetColumns(const Value: TStrings);
    procedure RefreshGrid;
    procedure ReloadColumns;
    procedure SetDataSource(ADataSource: IDataSource);
    procedure DoDrawCell(Sender: TObject; ACol, ARow: Longint;
      Rect: TRect; State: TGridDrawState; const RowData: Variant);
    procedure RefreshPageIndexInterface;
    procedure RefreshPageIndexData(ARefreshColumns: boolean);
    procedure SetPageIndexEditText(const AStr: utf8string);
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
    property Columns: TStrings read FColumns write SetColumns;
    property DataSource: IDataSource read FDataSource write SetDataSource;
    property PageSize: Integer read FPageSize write SetPageSize default 100;
    property PageIndex: Integer read FPageIndex write SetPageIndex default -1;

    property OnDrawVisualCell: TDrawVisualCellEvent read FOnDrawVisualCell write FOnDrawVisualCell;
  end;

  TVisualGrid = class(TCustomVisualGrid)
  published
    property Align;
    property Columns;
    property PageSize;

    property OnDrawVisualCell;
  end;


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Pascal Framework', [TVisualGrid]);
end;

{ TCustomVisualGrid }

procedure TCustomVisualGrid.ClickTest(Sender: TOBject);
begin
  TButton(Sender).Caption := Format('%dx%d', [FSearchEdit.Left,FSearchEdit.Top]);
end;

constructor TCustomVisualGrid.Create(Owner: TComponent);
begin
  inherited;

  { component layout }

  ControlStyle := ControlStyle - [csAcceptsControls];

  FTopPanel := TPanel.Create(Self);
  FTopPanel.ControlStyle := FTopPanel.ControlStyle - [csAcceptsControls];
  FTopPanel.Parent := Self;
  with FTopPanel do
  begin
    Align := alTop;
    BevelOuter := bvNone;
    Height := 40;

    FTopPanelRight := TPanel.Create(Self);
    FTopPanelRight.ControlStyle := FTopPanelRight.ControlStyle - [csAcceptsControls];
    FTopPanelRight.Parent := FTopPanel;
    with FTopPanelRight do
    begin
      BevelOuter := bvNone;
      Align := alRight;
      Height := 40;
      Width := 177;

      FSearchLabel := TLabel.Create(Self);
      FSearchLabel.Parent := FTopPanelRight;
      with FSearchLabel do
      begin
        Left := 7;
        Top := 13;
        Width := 37;
        Height := 13;
        Caption := 'Search:';
      end;

      FSearchEdit := TEdit.Create(Self);
      FSearchEdit.Parent := FTopPanelRight;
      with FSearchEdit do
      begin
        Left := 50;
        Top := 10;
        Width := 121;
        Height := 21;
      end;
    end;
  end;

  FBottomPanel := TPanel.Create(Self);
  FBottomPanel.ControlStyle := FBottomPanel.ControlStyle - [csAcceptsControls];
  FBottomPanel.Parent := Self;
  with FBottomPanel do
  begin
    Align := alBottom;
    BevelOuter := bvNone;
    Height := 40;

    FBottomRightPanel := TPanel.Create(Self);
    FBottomRightPanel.ControlStyle := FBottomRightPanel.ControlStyle - [csAcceptsControls];
    FBottomRightPanel.Parent := FBottomPanel;
    with FBottomRightPanel do
    begin
      Width := 217;
      Height := 40;
      Align := alRight;
      BevelOuter := bvNone;
      FPageIndexEdit := TEdit.Create(Self);
      FPageIndexEdit.Parent := FBottomRightPanel;
      with FPageIndexEdit do
      begin
        Left := 61;
        Top := 10;
        Width := 56;
        Height := 21;
        OnChange := PageIndexEditChange;
      end;
      FPageCountLabel := TLabel.Create(Self);
      FPageCountLabel.Parent := FBottomRightPanel;
      with FPageCountLabel do
      begin
        Left := 118;
        Top := 13;
        Width := 36;
        Height := 13;
        Caption := '/';
      end;
      FButtonFirst := TButton.Create(Self);
      FButtonFirst.Parent := FBottomRightPanel;
      with FButtonFirst do
      begin
        Left := 8;
        Top := 8;
        Width := 25;
        Height := 25;
        Caption := #9198;
        OnClick := PageNavigationClick;
        Tag := PAGE_NAVIGATION_FIRST;
      end;
      FButtonPrevious := TButton.Create(Self);
      FButtonPrevious.Parent := FBottomRightPanel;
      with FButtonPrevious do
      begin
        Left := 32;
        Top := 8;
        Width := 25;
        Height := 25;
        Caption := #9204;
        OnClick := PageNavigationClick;
        Tag := PAGE_NAVIGATION_PREVIOUS;
      end;
      FButtonNext := TButton.Create(Self);
      FButtonNext.Parent := FBottomRightPanel;
      with FButtonNext do
      begin
        Left := 160;
        Top := 8;
        Width := 25;
        Height := 25;
        Caption := #9205;
        OnClick := PageNavigationClick;
        Tag := PAGE_NAVIGATION_NEXT;
      end;
      FButtonLast := TButton.Create(Self);
      FButtonLast.Parent := FBottomRightPanel;
      with FButtonLast do
      begin
        Left := 184;
        Top := 8;
        Width := 25;
        Height := 25;
        Caption := #9197;
        OnClick := PageNavigationClick;
        Tag := PAGE_NAVIGATION_LAST;
      end;
    end;

    FBottomCenterPanel := TPanel.Create(Self);
    FBottomCenterPanel.ControlStyle := FBottomCenterPanel.ControlStyle - [csAcceptsControls];
    FBottomCenterPanel.Parent := FBottomPanel;
    with FBottomCenterPanel do
    begin
      Align := alClient;
      BevelOuter := bvNone;
      FAllRecordsCountLabel := TLabel.Create(Self);
      FAllRecordsCountLabel.Parent := FBottomCenterPanel;
      with FAllRecordsCountLabel do
      begin
        Left := 7;
        Top := 13;
        Width := 31;
        Height := 13;
        Caption := 'Total: ';
      end;
      FPageSizeLabel := TLabel.Create(Self);
      FPageSizeLabel.Parent := FBottomCenterPanel;
      with FPageSizeLabel do
      begin
        Left := 126;
        Top := 13;
        Width := 31;
        Height := 13;
        Caption := 'Page size:'
      end;
      FPageSizeEdit := TEdit.Create(Self);
      FPageSizeEdit.Parent := FBottomCenterPanel;
      with FPageSizeEdit do
      begin
        Left := 181;
        Top := 10;
        Width := 52;
        Height := 21;
      end;
    end;
  end;

  FDrawGrid := TDrawGrid.Create(Self);
  FDrawGrid.Parent := Self;
  FDrawGrid.Align := alClient;
  FDrawGrid.OnDrawCell := StandardDrawCell;

  { default values for properties }

  FColumns := TStringList.Create;
  FPageSize := 100;
  PageIndex := -1;

  with TButton.Create(Self) do
  begin
    Left := 0;
    Top := 0;
    Parent := Self;
    OnClick := ClickTest;
    Caption := 'Test';
  end;
end;

destructor TCustomVisualGrid.Destroy;
begin
  FColumns.Free;
  inherited;
end;

procedure TCustomVisualGrid.DoDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState; const RowData: Variant);
var
  LText: utf8string;
begin
  if ARow = 0 then
  begin
    if ACol < FColumns.Count then
      LText := FColumns[ACol];
    FDrawGrid.Canvas.TextRect(Rect, Rect.Left+2, Rect.Top+2, LText)
  end
  else
    FDrawGrid.Canvas.TextRect(Rect, Rect.Left+2, Rect.Top+2, RowData);
end;

procedure TCustomVisualGrid.Loaded;
begin
  inherited;
  ReloadColumns;
end;

procedure TCustomVisualGrid.PageIndexEditChange(Sender: TObject);
var
  LPageIndex: Integer;
begin
  if FPageIndexUpdate then
    Exit;
  // value in edit has increased value by 1 (more readable for end user)
  LPageIndex := Pred(StrToIntDef(FPageIndexEdit.Text, Succ(FPageIndex)));
  if (LPageIndex < 0) then
  begin
    LPageIndex := 0;
    SetPageIndexEditText('1');
  end;
  if (LPageIndex > FPageCount-1) then
  begin
    LPageIndex := FPageCount-1;
    SetPageIndexEditText(IntToStr(FPageCount));
  end;

  PageIndex := LPageIndex;
end;

procedure TCustomVisualGrid.PageNavigationClick(Sender: TObject);
begin
  if FPageCount = 0 then
    Exit;
  case TButton(Sender).Tag of
    PAGE_NAVIGATION_FIRST: PageIndex := 0;
    PAGE_NAVIGATION_PREVIOUS: PageIndex := PageIndex - 1;
    PAGE_NAVIGATION_NEXT: PageIndex := PageIndex + 1;
    PAGE_NAVIGATION_LAST: PageIndex := FPageCount - 1;
  end;
end;

procedure TCustomVisualGrid.RefreshGrid;
begin

end;

procedure TCustomVisualGrid.RefreshPageIndexData(ARefreshColumns: boolean);
var
  LFilter: TFilterCriteria;
  i: Integer;
begin
  if Assigned(FDataSource) then
  begin
    if FPageIndex >= FPageCount then
      FPageIndex := FPageCount - 1;

    FDataTable := FDataSource.FetchPage(FPageIndex, FPageSize, FPageCount, LFilter);

    if (FPageIndex = -1) and (Length(FDataTable.Rows) > 0) then
      FPageIndex := 0;

    if ARefreshColumns then
    begin
      FColumns.Clear;
      for i := 0 to High(FDataTable.Columns) do
        FColumns.Add(FDataTable.Columns[i]);
      ReloadColumns;
    end;
    FDrawGrid.RowCount := Length(FDataTable.Rows) + 1;
  end;
  RefreshPageIndexInterface;
  FDrawGrid.Refresh;
end;

procedure TCustomVisualGrid.RefreshPageIndexInterface;
begin
  SetPageIndexEditText(IntToStr(Succ(FPageIndex)));
  FPageCountLabel.Caption := Format('/%d',[FPageCount]);
end;

procedure TCustomVisualGrid.ReloadColumns;
begin
  FDrawGrid.ColCount := FColumns.Count;
end;

procedure TCustomVisualGrid.SetColumns(const Value: TStrings);
begin
  FColumns.Assign(Value);
  ReloadColumns;
end;

procedure TCustomVisualGrid.SetDataSource(ADataSource: IDataSource);
begin
  if FDataSource = ADataSource then
    Exit;

  FDataSource := ADataSource;

  RefreshPageIndexData(true);
end;

procedure TCustomVisualGrid.SetPageIndex(const Value: Integer);
begin
  if FPageIndex = Value then
    Exit;


  FPageIndex := Value;
  RefreshPageIndexData(false)
end;

procedure TCustomVisualGrid.SetPageIndexEditText(const AStr: utf8string);
begin
  FPageIndexUpdate := True;
  FPageIndexEdit.Text := AStr;
  FPageIndexUpdate := false;
end;

procedure TCustomVisualGrid.SetPageSize(const Value: Integer);
begin
  FPageSize := Value;
end;

procedure TCustomVisualGrid.StandardDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  LHandled: boolean;
  LCellData: Variant;
begin
  LHandled := False;
  if (ARow > 0) and Assigned(FDataSource) then
    LCellData := FDataTable.Rows[ARow-1]._(ACol);

  if Assigned(FOnDrawVisualCell) then
    FOnDrawVisualCell(Self, ACol, ARow, Rect, State, LCellData, LHandled);
  if not LHandled then
    DoDrawCell(Self, ACol, ARow, Rect, State, LCellData);
end;

end.
