{
   Double Commander
   -------------------------------------------------------------------------
   Dialog which asks the user to select one of the file panels.

   Copyright (C) 2012-2024  Alexander Koblov (alexx2000@mail.ru)

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>.
}

unit uFilePanelSelectDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, Forms, ExtCtrls;

type
  {en
     Description of a file panel which is shown in the selection dialog.
   }
  TFilePanelChoice = record
    Index: Integer;
    Caption: String;
    Path: String;
  end;

  {en
     Shows a modal dialog with the list of the file panels and returns the
     selected one.

     @param(ATitle
            Title of the dialog.)
     @param(Choices
            List of the panels to choose from.)
     @param(aIndex
            Index of the selected panel. It is not changed if the user
            has cancelled the dialog.)
   }
function SelectFilePanel(const ATitle: String;
                         const Choices: array of TFilePanelChoice;
                         out aIndex: Integer): Boolean;

implementation

type
  { TfrmFilePanelSelectDlg }

  TfrmFilePanelSelectDlg = class(TForm)
  private
    FChoices: array of TFilePanelChoice;
    FIndex: Integer;
    lstPanels: TListBox;
    procedure btnOKClick(Sender: TObject);
    procedure lstPanelsDblClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  public
    constructor CreateNew(AOwner: TComponent; ATitle: String;
                          const AChoices: array of TFilePanelChoice); reintroduce;
    property SelectedIndex: Integer read FIndex;
  end;

constructor TfrmFilePanelSelectDlg.CreateNew(AOwner: TComponent; ATitle: String;
                                              const AChoices: array of TFilePanelChoice);
var
  I: Integer;
  LblTitle: TLabel;
  BtnOK: TButton;
  BtnCancel: TButton;
  LblHint: TLabel;
begin
  inherited CreateNew(AOwner);
  SetLength(FChoices, Length(AChoices));
  for I := 0 to High(AChoices) do
    FChoices[I] := AChoices[I];
  FIndex := -1;

  Caption := ATitle;
  BorderStyle := bsDialog;
  ClientWidth := 420;
  ClientHeight := 280;
  FormStyle := fsNormal;

  LblTitle := TLabel.Create(Self);
  LblTitle.Parent := Self;
  LblTitle.Left := 12;
  LblTitle.Top := 12;
  LblTitle.Width := ClientWidth - 24;
  LblTitle.Height := 18;
  LblTitle.Caption := ATitle;

  lstPanels := TListBox.Create(Self);
  lstPanels.Parent := Self;
  lstPanels.Left := 12;
  lstPanels.Top := 36;
  lstPanels.Width := ClientWidth - 24;
  lstPanels.Height := ClientHeight - 100;
  lstPanels.ItemHeight := 20;
  lstPanels.OnDblClick := @lstPanelsDblClick;

  for I := 0 to High(FChoices) do
    lstPanels.Items.Add(FChoices[I].Caption);

  LblHint := TLabel.Create(Self);
  LblHint.Parent := Self;
  LblHint.Left := 12;
  LblHint.Top := ClientHeight - 58;
  LblHint.Width := ClientWidth - 24;
  LblHint.Height := 18;
  LblHint.Caption := '';

  BtnOK := TButton.Create(Self);
  BtnOK.Parent := Self;
  BtnOK.Left := ClientWidth - 190;
  BtnOK.Top := ClientHeight - 34;
  BtnOK.Width := 80;
  BtnOK.Height := 26;
  BtnOK.Caption := 'OK';
  BtnOK.Default := True;
  BtnOK.OnClick := @btnOKClick;

  BtnCancel := TButton.Create(Self);
  BtnCancel.Parent := Self;
  BtnCancel.Left := ClientWidth - 100;
  BtnCancel.Top := ClientHeight - 34;
  BtnCancel.Width := 80;
  BtnCancel.Height := 26;
  BtnCancel.Caption := 'Cancel';
  BtnCancel.Cancel := True;
  BtnCancel.OnClick := @btnCancelClick;

  if lstPanels.Items.Count > 0 then
  begin
    lstPanels.ItemIndex := 0;
    FIndex := 0;
  end;
end;

procedure TfrmFilePanelSelectDlg.btnOKClick(Sender: TObject);
begin
  if lstPanels.ItemIndex >= 0 then
    FIndex := FChoices[lstPanels.ItemIndex].Index;
  ModalResult := mrOk;
end;

procedure TfrmFilePanelSelectDlg.btnCancelClick(Sender: TObject);
begin
  FIndex := -1;
  ModalResult := mrCancel;
end;

procedure TfrmFilePanelSelectDlg.lstPanelsDblClick(Sender: TObject);
begin
  btnOKClick(Sender);
end;

function SelectFilePanel(const ATitle: String;
                         const Choices: array of TFilePanelChoice;
                         out aIndex: Integer): Boolean;
var
  Dlg: TfrmFilePanelSelectDlg;
begin
  Result := False;
  Dlg := TfrmFilePanelSelectDlg.CreateNew(Application, ATitle, Choices);
  try
    if Dlg.ShowModal = mrOk then
    begin
      aIndex := Dlg.SelectedIndex;
      Result := aIndex >= 0;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
