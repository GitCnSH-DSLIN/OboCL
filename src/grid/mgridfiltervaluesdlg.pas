// This is part of the Obo Component Library
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// This software is distributed without any warranty.
//
// @author Domenico Mammola (mimmo71@gmail.com - www.mammola.net)
unit mGridFilterValuesDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel,
  CheckLst, ExtCtrls, ComCtrls, StdCtrls, Menus, ListFilterEdit, EditBtn;

resourcestring
  SExportValuesMenuCaption = 'Export values...';
  SWarningFileExists = 'File exists';
  SAskOverwriteFile = 'File already exists. Overwrite it?';
  SFilterModeContains = 'Contains';
  SFilterModeStartsWith = 'Starts with';
  SFilterModeEndsWith = 'Ends with';

type
  { TFilterValuesDlg }

  TFilterValuesDlg = class(TForm)
    BtnAddAll: TButton;
    BtnClear: TButton;
    ButtonPanel1: TButtonPanel;
    ListBoxToBeFiltered: TListBox;
    ListBoxFilter: TListBox;
    ListFilterEditAdvanced: TListFilterEdit;
    MI_AdvancesSearhEndsWith: TMenuItem;
    MI_AdvancedSearchStartsWith: TMenuItem;
    MI_AdvancedSearchContains: TMenuItem;
    MI_ExportValues: TMenuItem;
    PageControlFilter: TPageControl;
    PanelTop: TPanel;
    PanelRight: TPanel;
    PanelLeft: TPanel;
    PopupMenuAdvancedSearch: TPopupMenu;
    PopupMenuValues: TPopupMenu;
    Splitter1: TSplitter;
    TSAdvanced: TTabSheet;
    TSSimple: TTabSheet;
    ValuesListBox: TCheckListBox;
    ListFilterEdit: TListFilterEdit;
    procedure BtnAddAllClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListBoxFilterClick(Sender: TObject);
    procedure ListBoxToBeFilteredClick(Sender: TObject);
    function ListFilterEditAdvancedFilterItemEx(const ACaption: string; ItemData: Pointer; out Done: Boolean): Boolean;
    procedure MI_AdvancedSearchContainsClick(Sender: TObject);
    procedure MI_AdvancedSearchStartsWithClick(Sender: TObject);
    procedure MI_AdvancesSearhEndsWithClick(Sender: TObject);
    procedure MI_ExportValuesClick(Sender: TObject);
  private
  public
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
    procedure Init (const aList : TStringList);
    procedure GetCheckedValues (aList : TStringList);
  end;

implementation

uses
  StrUtils,
  mWaitCursor, mFormSetup;

{$R *.lfm}

{ TFilterValuesDlg }

procedure TFilterValuesDlg.BtnClearClick(Sender: TObject);
begin
  ListBoxFilter.Clear;
end;

procedure TFilterValuesDlg.FormCreate(Sender: TObject);
begin
  MI_ExportValues.Caption:= SExportValuesMenuCaption;
  MI_AdvancedSearchContains.Caption:= SFilterModeContains;
  MI_AdvancedSearchStartsWith.Caption:= SFilterModeStartsWith;
  MI_AdvancesSearhEndsWith.Caption:= SFilterModeEndsWith;
end;

procedure TFilterValuesDlg.FormShow(Sender: TObject);
begin
  PageControlFilter.ActivePageIndex:= 0;
  ListFilterEdit.SetFocus;
end;

procedure TFilterValuesDlg.ListBoxFilterClick(Sender: TObject);
begin
  if ListBoxFilter.ItemIndex >= 0 then
    ListBoxFilter.Items.Delete(ListBoxFilter.ItemIndex);
end;

procedure TFilterValuesDlg.ListBoxToBeFilteredClick(Sender: TObject);
var
  tmp : string;
begin
  if ListBoxToBeFiltered.ItemIndex >= 0 then
  begin
    tmp := ListBoxToBeFiltered.Items[ListBoxToBeFiltered.ItemIndex];
    if ListBoxFilter.Items.IndexOf(tmp) < 0 then
      ListBoxFilter.Items.Append(tmp);
  end;
end;

function TFilterValuesDlg.ListFilterEditAdvancedFilterItemEx(const ACaption: string; ItemData: Pointer; out Done: Boolean): Boolean;
begin
  Result := false;
  Done := false;
  if MI_AdvancedSearchContains.Checked then
    exit
  else if MI_AdvancedSearchStartsWith.Checked then
  begin
    if fsoCaseSensitive in ListFilterEditAdvanced.FilterOptions then
      Result := StartsStr(ListFilterEditAdvanced.Filter, ACaption)
    else
      Result := StartsText(ListFilterEditAdvanced.Filter, ACaption);
    Done := true;
  end
  else if MI_AdvancesSearhEndsWith.Checked then
  begin
    if fsoCaseSensitive in ListFilterEditAdvanced.FilterOptions then
      Result := EndsStr(ListFilterEditAdvanced.Filter, ACaption)
    else
      Result := EndsText(ListFilterEditAdvanced.Filter, ACaption);
    Done := true;
  end;
end;

procedure TFilterValuesDlg.MI_AdvancedSearchContainsClick(Sender: TObject);
begin
  if not MI_AdvancedSearchContains.Checked then
  begin
    MI_AdvancedSearchContains.Checked := true;
    MI_AdvancedSearchStartsWith.Checked:= false;
    MI_AdvancesSearhEndsWith.Checked:= false;
    ListFilterEditAdvanced.InvalidateFilter;
    ListFilterEditAdvanced.ForceFilter(ListFilterEditAdvanced.Filter);
  end;
end;

procedure TFilterValuesDlg.MI_AdvancedSearchStartsWithClick(Sender: TObject);
begin
  if not MI_AdvancedSearchStartsWith.Checked then
  begin
    MI_AdvancedSearchContains.Checked := false;
    MI_AdvancedSearchStartsWith.Checked:= true;
    MI_AdvancesSearhEndsWith.Checked:= false;
    ListFilterEditAdvanced.InvalidateFilter;
    ListFilterEditAdvanced.ForceFilter(ListFilterEditAdvanced.Filter);
  end;
end;

procedure TFilterValuesDlg.MI_AdvancesSearhEndsWithClick(Sender: TObject);
begin
  if not MI_AdvancesSearhEndsWith.Checked then
  begin
    MI_AdvancedSearchContains.Checked := false;
    MI_AdvancedSearchStartsWith.Checked:= false;
    MI_AdvancesSearhEndsWith.Checked:= true;
    ListFilterEditAdvanced.InvalidateFilter;
    ListFilterEditAdvanced.ForceFilter(ListFilterEditAdvanced.Filter);
  end;
end;

procedure TFilterValuesDlg.MI_ExportValuesClick(Sender: TObject);
var
  dlg : TSaveDialog;
  tmpList : TStringList;
  i : integer;
begin
  dlg := TSaveDialog.Create(Self);
  try
    dlg.DefaultExt:= 'txt';
    dlg.Filter:='Text file|*.txt';

    if dlg.Execute then
    begin
      if (not FileExists(dlg.FileName)) or (MessageDlg(SWarningFileExists, SAskOverwriteFile, mtConfirmation, mbYesNo, 0) = mrYes) then
      begin
        tmpList := TStringList.Create;
        try
          if PageControlFilter.ActivePageIndex = 0 then
          begin
            for i := 0 to ValuesListBox.Count - 1 do
              tmpList.Append(ValuesListBox.Items[i]);
          end
          else
            tmpList.AddStrings(ListBoxToBeFiltered.Items);

          tmpList.SaveToFile(dlg.FileName);
        finally
          tmpList.Free;
        end;
      end;
    end;
  finally
    dlg.Free;
  end;
end;

constructor TFilterValuesDlg.CreateNew(AOwner: TComponent; Num: Integer);
begin
  inherited CreateNew(AOwner, Num);
  SetupFormAndCenter(Self);
end;

procedure TFilterValuesDlg.BtnAddAllClick(Sender: TObject);
var
  i : integer;
begin
  try
    TWaitCursor.ShowWaitCursor('TFilterValuesDlg.BtnAddAllClick');
    ListBoxFilter.Items.BeginUpdate;
    try
      for i := 0 to ListBoxToBeFiltered.Count - 1 do
      begin
        if ListBoxFilter.Items.IndexOf(ListBoxToBeFiltered.Items[i]) < 0 then
          ListBoxFilter.Items.Add(ListBoxToBeFiltered.Items[i]);
      end;
    finally
      ListBoxFilter.Items.EndUpdate;
    end;
  finally
    TWaitCursor.UndoWaitCursor('TFilterValuesDlg.BtnAddAllClick');
  end;
end;

procedure TFilterValuesDlg.Init(const aList: TStringList);
begin
  try
    TWaitCursor.ShowWaitCursor('TFilterValuesDlg.Init');
    ListFilterEdit.FilteredListbox := ValuesListBox;
    ValuesListBox.Items.BeginUpdate;
    try
      ListFilterEdit.Items.AddStrings(aList);
    finally
      ValuesListBox.Items.EndUpdate;
    end;
    ListFilterEdit.ForceFilter('#');
    ListFilterEdit.ResetFilter;

    ListFilterEditAdvanced.FilteredListbox := ListBoxToBeFiltered;
    ListFilterEditAdvanced.Items.AddStrings(aList);
    ListFilterEditAdvanced.ForceFilter('#');
    ListFilterEditAdvanced.ResetFilter;
  finally
    TWaitCursor.UndoWaitCursor('TFilterValuesDlg.Init');
  end;
end;

procedure TFilterValuesDlg.GetCheckedValues(aList: TStringList);
var
  i : integer;
begin
  if PageControlFilter.ActivePageIndex = 0 then
  begin
    for i := 0 to ValuesListBox.Count - 1 do
    begin
      if ValuesListBox.Checked[i] then
        aList.Append(ValuesListBox.Items[i]);
    end;
  end
  else
    aList.AddStrings(ListBoxFilter.Items);
end;

end.

