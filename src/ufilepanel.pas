{
   Double Commander
   -------------------------------------------------------------------------
   A single file panel of the main window.

   A file panel is a self contained widget set which is placed in the main
   window. It consists of:

     - an optional drive toolbar (disk panel),
     - a tools row (drive list button, directory hotlist button, ...),
     - a notebook with file view tabs.

   Copyright (C) 2012-2024  Alexander Koblov (alexx2000@mail.ru)
   Copyright (C) 2012  Przemyslaw Nagay (cobines@gmail.com)

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

unit uFilePanel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, StdCtrls, Buttons, Toolwin,
  uFileView,
  uFileViewNotebook,
  uFilePanelSelect,
  KASToolBar,
  KASToolPanel;

const
  {en
     Height of the tools row.
  }
  FILE_PANEL_TOOLS_HEIGHT = 28;

  {en
     Width of the drive list button.
  }
  FILE_PANEL_DRIVE_BUTTON_WIDTH = 48;

  {en
     Width of the small buttons of the tools row.
  }
  FILE_PANEL_SMALL_BUTTON_WIDTH = 23;

type

  {en
     Event of a button of the file panel tools row. The index of the panel
     which owns the button is passed explicitly, because the Tag property of
     the buttons is used for other purposes.
   }
  TFilePanelButtonEvent = procedure(Sender: TObject;
                                    aPanelIndex: TFilePanelIndex) of object;

  { TFilePanel }

  TFilePanel = class(TComponent)
  private
    FIndex: TFilePanelIndex;
    FContainer: TPanel;
    FDiskPanel: TKASToolPanel;
    FToolsPanel: TPanel;
    FDiskToolBar: TKASToolBar;
    FNotebook: TFileViewNotebook;
    FbtnDrive: TSpeedButton;
    FbtnHome: TSpeedButton;
    FbtnUp: TSpeedButton;
    FbtnRoot: TSpeedButton;
    FbtnHotList: TSpeedButton;
    FbtnEqual: TSpeedButton;
    FpbxDrive: TPaintBox;
    FlblDriveInfo: TLabel;

    FOnButtonClick: TFilePanelButtonEvent;
    FOnHotListButtonClick: TFilePanelButtonEvent;
    FOnDriveButtonClick: TFilePanelButtonEvent;
    FOnDriveButtonMouseUp: TMouseEvent;
    FOnEqualButtonClick: TFilePanelButtonEvent;
    FOnDriveInfoResize: TNotifyEvent;
    FOnDriveInfoDblClick: TNotifyEvent;
    FOnDrivePaint: TNotifyEvent;

    procedure btnClick(Sender: TObject);
    procedure btnHotListClick(Sender: TObject);
    procedure btnDriveClick(Sender: TObject);
    procedure btnDriveMouseUp(Sender: TObject; Button: TMouseButton;
                             Shift: TShiftState; X, Y: Integer);
    procedure btnEqualClick(Sender: TObject);
    procedure lblDriveInfoResize(Sender: TObject);
    procedure lblDriveInfoDblClick(Sender: TObject);
    procedure pbxDrivePaint(Sender: TObject);
    function GetActiveView: TFileView;
  public
    constructor Create(AOwner: TComponent; AIndex: TFilePanelIndex;
                       AParent: TWinControl);
    destructor Destroy; override;

    {en
       Assigns the notebook which shows the file views of this panel.
     }
    procedure SetNotebook(AValue: TFileViewNotebook);

    {en
       Repositions the child controls of the panel.
     }
    procedure UpdateLayout;

    property Index: TFilePanelIndex read FIndex;
    property Container: TPanel read FContainer;
    property DiskPanel: TKASToolPanel read FDiskPanel;
    property ToolsPanel: TPanel read FToolsPanel;
    property DiskToolBar: TKASToolBar read FDiskToolBar;
    property Notebook: TFileViewNotebook read FNotebook;
    property btnDrive: TSpeedButton read FbtnDrive;
    property btnHome: TSpeedButton read FbtnHome;
    property btnUp: TSpeedButton read FbtnUp;
    property btnRoot: TSpeedButton read FbtnRoot;
    property btnHotList: TSpeedButton read FbtnHotList;
    property btnEqual: TSpeedButton read FbtnEqual;
    property pbxDrive: TPaintBox read FpbxDrive;
    property lblDriveInfo: TLabel read FlblDriveInfo;
    property ActiveView: TFileView read GetActiveView;

    property OnButtonClick: TFilePanelButtonEvent read FOnButtonClick write FOnButtonClick;
    property OnHotListButtonClick: TFilePanelButtonEvent read FOnHotListButtonClick write FOnHotListButtonClick;
    property OnDriveButtonClick: TFilePanelButtonEvent read FOnDriveButtonClick write FOnDriveButtonClick;
    property OnDriveButtonMouseUp: TMouseEvent read FOnDriveButtonMouseUp write FOnDriveButtonMouseUp;
    property OnEqualButtonClick: TFilePanelButtonEvent read FOnEqualButtonClick write FOnEqualButtonClick;
    property OnDriveInfoResize: TNotifyEvent read FOnDriveInfoResize write FOnDriveInfoResize;
    property OnDriveInfoDblClick: TNotifyEvent read FOnDriveInfoDblClick write FOnDriveInfoDblClick;
    property OnDrivePaint: TNotifyEvent read FOnDrivePaint write FOnDrivePaint;
  end;

implementation

{ TFilePanel }

constructor TFilePanel.Create(AOwner: TComponent; AIndex: TFilePanelIndex;
                              AParent: TWinControl);
begin
  inherited Create(AOwner);
  FIndex := AIndex;

  FContainer := TPanel.Create(AOwner);
  FContainer.Name := Format('pnlFilePanel%d', [Ord(AIndex) + 1]);
  FContainer.Parent := AParent;
  FContainer.Align := alNone;
  FContainer.BevelOuter := bvNone;
  FContainer.Caption := '';

  FToolsPanel := TPanel.Create(AOwner);
  FToolsPanel.Name := Format('pnlFilePanel%dTools', [Ord(AIndex) + 1]);
  FToolsPanel.Parent := FContainer;
  FToolsPanel.Align := alNone;
  FToolsPanel.AutoSize := False;
  FToolsPanel.BevelInner := bvNone;
  FToolsPanel.BevelOuter := bvNone;
  FToolsPanel.Caption := '';
  FToolsPanel.DoubleBuffered := True;
  FToolsPanel.Height := FILE_PANEL_TOOLS_HEIGHT;

  FDiskPanel := TKASToolPanel.Create(AOwner);
  FDiskPanel.Name := Format('pnlFilePanel%dDisk', [Ord(AIndex) + 1]);
  FDiskPanel.Parent := FContainer;
  FDiskPanel.Align := alNone;
  FDiskPanel.AutoSize := True;
  FDiskPanel.Caption := '';
  FDiskPanel.EdgeBorders := [ebTop, ebBottom];

  FDiskToolBar := TKASToolBar.Create(AOwner);
  FDiskToolBar.Name := Format('dskFilePanel%d', [Ord(AIndex) + 1]);
  FDiskToolBar.Parent := FDiskPanel;

  // The controls of the tools row are aligned automatically by the LCL.
  // The order of creation is important for the right aligned buttons:
  // the last created one is placed closest to the right edge.
  FbtnDrive := TSpeedButton.Create(FToolsPanel);
  FbtnDrive.Name := Format('btnFilePanel%dDrive', [Ord(AIndex) + 1]);
  FbtnDrive.Parent := FToolsPanel;
  FbtnDrive.Align := alNone;
  FbtnDrive.Caption := '';
  FbtnDrive.Constraints.MinHeight := 24;
  FbtnDrive.Width := FILE_PANEL_DRIVE_BUTTON_WIDTH;
  FbtnDrive.OnClick := @btnDriveClick;
  FbtnDrive.OnMouseUp := @btnDriveMouseUp;

  FlblDriveInfo := TLabel.Create(FToolsPanel);
  FlblDriveInfo.Name := Format('lblFilePanel%dDriveInfo', [Ord(AIndex) + 1]);
  FlblDriveInfo.Parent := FToolsPanel;
  FlblDriveInfo.Align := alNone;
  FlblDriveInfo.Alignment := taCenter;
  FlblDriveInfo.Caption := '';
  FlblDriveInfo.ParentColor := False;
  FlblDriveInfo.OnDblClick := @lblDriveInfoDblClick;
  FlblDriveInfo.OnResize := @lblDriveInfoResize;

  FbtnHotList := TSpeedButton.Create(FToolsPanel);
  FbtnHotList.Name := Format('btnFilePanel%dHotList', [Ord(AIndex) + 1]);
  FbtnHotList.Parent := FToolsPanel;
  FbtnHotList.Align := alNone;
  FbtnHotList.Caption := '*';
  FbtnHotList.Constraints.MinHeight := 24;
  FbtnHotList.Hint := 'Directory Hotlist';
  FbtnHotList.Width := FILE_PANEL_SMALL_BUTTON_WIDTH;
  FbtnHotList.OnClick := @btnHotListClick;

  FbtnRoot := TSpeedButton.Create(FToolsPanel);
  FbtnRoot.Name := Format('btnFilePanel%dRoot', [Ord(AIndex) + 1]);
  FbtnRoot.Parent := FToolsPanel;
  FbtnRoot.Align := alNone;
  FbtnRoot.Caption := DirectorySeparator;
  FbtnRoot.Constraints.MinHeight := 24;
  FbtnRoot.Hint := 'Go to root directory';
  FbtnRoot.Width := FILE_PANEL_SMALL_BUTTON_WIDTH;
  FbtnRoot.OnClick := @btnClick;

  FbtnUp := TSpeedButton.Create(FToolsPanel);
  FbtnUp.Name := Format('btnFilePanel%dUp', [Ord(AIndex) + 1]);
  FbtnUp.Parent := FToolsPanel;
  FbtnUp.Align := alNone;
  FbtnUp.Caption := '..';
  FbtnUp.Constraints.MinHeight := 24;
  FbtnUp.Hint := 'Go to parent directory';
  FbtnUp.Width := FILE_PANEL_SMALL_BUTTON_WIDTH;
  FbtnUp.OnClick := @btnClick;

  FbtnHome := TSpeedButton.Create(FToolsPanel);
  FbtnHome.Name := Format('btnFilePanel%dHome', [Ord(AIndex) + 1]);
  FbtnHome.Parent := FToolsPanel;
  FbtnHome.Align := alNone;
  FbtnHome.Caption := '~';
  FbtnHome.Constraints.MinHeight := 24;
  FbtnHome.Hint := 'Go to home directory';
  FbtnHome.Width := FILE_PANEL_SMALL_BUTTON_WIDTH;
  FbtnHome.OnClick := @btnClick;

  FbtnEqual := TSpeedButton.Create(FToolsPanel);
  FbtnEqual.Name := Format('btnFilePanel%dEqual', [Ord(AIndex) + 1]);
  FbtnEqual.Parent := FToolsPanel;
  FbtnEqual.Align := alNone;
  FbtnEqual.Caption := '<';
  FbtnEqual.Constraints.MinHeight := 24;
  FbtnEqual.Hint := 'Show current directory of another panel in this panel';
  FbtnEqual.Width := FILE_PANEL_SMALL_BUTTON_WIDTH;
  FbtnEqual.OnClick := @btnEqualClick;

  FpbxDrive := TPaintBox.Create(FToolsPanel);
  FpbxDrive.Name := Format('pbxFilePanel%dDrive', [Ord(AIndex) + 1]);
  FpbxDrive.Parent := FToolsPanel;
  FpbxDrive.Align := alNone;
  FpbxDrive.Caption := '';
  FpbxDrive.Height := 10;
  FpbxDrive.OnPaint := @pbxDrivePaint;

  UpdateLayout;
end;

destructor TFilePanel.Destroy;
begin
  inherited Destroy;
end;

procedure TFilePanel.SetNotebook(AValue: TFileViewNotebook);
begin
  FNotebook := AValue;
  if Assigned(FNotebook) then
    FNotebook.Parent := FContainer;
  UpdateLayout;
end;

function TFilePanel.GetActiveView: TFileView;
begin
  if Assigned(FNotebook) then
    Result := FNotebook.ActiveView
  else
    Result := nil;
end;

procedure TFilePanel.UpdateLayout;
var
  Top: Integer;
  AWidth, AHeight, X, AButtonHeight: Integer;
begin
  if not Assigned(FContainer) then Exit;

  Top := 0;
  AWidth := FContainer.Width;

  if FDiskPanel.Visible then
  begin
    FDiskPanel.SetBounds(0, Top, AWidth, FDiskPanel.Height);
    Inc(Top, FDiskPanel.Height);
  end;

  if FToolsPanel.Visible then
  begin
    AHeight := FToolsPanel.Height;
    FToolsPanel.SetBounds(0, Top, AWidth, AHeight);

    AButtonHeight := AHeight - 2;
    if AButtonHeight < 24 then
      AButtonHeight := 24;

    // The small buttons are placed from the right edge to the left.
    X := AWidth;
    if FbtnEqual.Visible then
    begin
      Dec(X, FbtnEqual.Width);
      FbtnEqual.SetBounds(X, 1, FbtnEqual.Width, AButtonHeight);
    end;
    if FbtnHome.Visible then
    begin
      Dec(X, FbtnHome.Width);
      FbtnHome.SetBounds(X, 1, FbtnHome.Width, AButtonHeight);
    end;
    if FbtnUp.Visible then
    begin
      Dec(X, FbtnUp.Width);
      FbtnUp.SetBounds(X, 1, FbtnUp.Width, AButtonHeight);
    end;
    if FbtnRoot.Visible then
    begin
      Dec(X, FbtnRoot.Width);
      FbtnRoot.SetBounds(X, 1, FbtnRoot.Width, AButtonHeight);
    end;
    if FbtnHotList.Visible then
    begin
      Dec(X, FbtnHotList.Width);
      FbtnHotList.SetBounds(X, 1, FbtnHotList.Width, AButtonHeight);
    end;

    if FbtnDrive.Visible then
      FbtnDrive.SetBounds(0, 1, FbtnDrive.Width, AButtonHeight);

    if X <= FbtnDrive.Width + 4 then
      X := FbtnDrive.Width + 4;

    if FlblDriveInfo.Visible then
      FlblDriveInfo.SetBounds(FbtnDrive.Width + 2, 1, X - FbtnDrive.Width - 4,
                              AButtonHeight - 2)
    else if FpbxDrive.Visible then
      FpbxDrive.SetBounds(FbtnDrive.Width + 2, 1, X - FbtnDrive.Width - 4, 10);

    Inc(Top, AHeight);
  end;

  // The free space indicator is drawn over the lower part of the drive
  // info label.


  if Assigned(FNotebook) then
    FNotebook.SetBounds(0, Top, AWidth, FContainer.Height - Top);
end;

procedure TFilePanel.btnClick(Sender: TObject);
begin
  if Assigned(FOnButtonClick) then
    FOnButtonClick(Sender, FIndex);
end;

procedure TFilePanel.btnHotListClick(Sender: TObject);
begin
  if Assigned(FOnHotListButtonClick) then
    FOnHotListButtonClick(Sender, FIndex);
end;

procedure TFilePanel.btnDriveClick(Sender: TObject);
begin
  if Assigned(FOnDriveButtonClick) then
    FOnDriveButtonClick(Sender, FIndex);
end;

procedure TFilePanel.btnDriveMouseUp(Sender: TObject; Button: TMouseButton;
                                    Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FOnDriveButtonMouseUp) then
    FOnDriveButtonMouseUp(Sender, Button, Shift, X, Y);
end;

procedure TFilePanel.btnEqualClick(Sender: TObject);
begin
  if Assigned(FOnEqualButtonClick) then
    FOnEqualButtonClick(Sender, FIndex);
end;

procedure TFilePanel.lblDriveInfoResize(Sender: TObject);
begin
  if Assigned(FOnDriveInfoResize) then
    FOnDriveInfoResize(Sender);
end;

procedure TFilePanel.lblDriveInfoDblClick(Sender: TObject);
begin
  if Assigned(FOnDriveInfoDblClick) then
    FOnDriveInfoDblClick(Sender);
end;

procedure TFilePanel.pbxDrivePaint(Sender: TObject);
begin
  if Assigned(FOnDrivePaint) then
    FOnDrivePaint(Sender);
end;

end.
