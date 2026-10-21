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

type

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

    FOnButtonClick: TNotifyEvent;
    FOnDriveButtonClick: TNotifyEvent;
    FOnEqualButtonClick: TNotifyEvent;
    FOnDriveInfoResize: TNotifyEvent;
    FOnDriveInfoDblClick: TNotifyEvent;
    FOnDrivePaint: TNotifyEvent;

    procedure btnClick(Sender: TObject);
    procedure btnDriveClick(Sender: TObject);
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

    {en
       Re-applies the anchoring of the drive info controls. Must be called
       when the "drives list button" option changes.
     }
    procedure UpdateAnchors;

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

    property OnButtonClick: TNotifyEvent read FOnButtonClick write FOnButtonClick;
    property OnDriveButtonClick: TNotifyEvent read FOnDriveButtonClick write FOnDriveButtonClick;
    property OnEqualButtonClick: TNotifyEvent read FOnEqualButtonClick write FOnEqualButtonClick;
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

  // The tools row is created first, so that the disk panel (which is
  // created later) is placed above it by the alignment code.
  FToolsPanel := TPanel.Create(AOwner);
  FToolsPanel.Name := Format('pnlFilePanel%dTools', [Ord(AIndex) + 1]);
  FToolsPanel.Parent := FContainer;
  FToolsPanel.Align := alNone;
  FToolsPanel.BevelInner := bvNone;
  FToolsPanel.BevelOuter := bvNone;
  FToolsPanel.ChildSizing.TopBottomSpacing := 2;
  FToolsPanel.DoubleBuffered := True;

  FDiskPanel := TKASToolPanel.Create(AOwner);
  FDiskPanel.Name := Format('pnlFilePanel%dDisk', [Ord(AIndex) + 1]);
  FDiskPanel.Parent := FContainer;
  FDiskPanel.Align := alNone;
  FDiskPanel.AutoSize := True;
  FDiskPanel.EdgeBorders := [ebTop, ebBottom];

  FDiskToolBar := TKASToolBar.Create(AOwner);
  FDiskToolBar.Name := Format('dskFilePanel%d', [Ord(AIndex) + 1]);
  FDiskToolBar.Parent := FDiskPanel;

  FbtnDrive := TSpeedButton.Create(FToolsPanel);
  FbtnDrive.Name := Format('btnFilePanel%dDrive', [Ord(AIndex) + 1]);
  FbtnDrive.Parent := FToolsPanel;
  FbtnDrive.Align := alLeft;
  FbtnDrive.Caption := '';
  FbtnDrive.Constraints.MinHeight := 24;
  FbtnDrive.Width := 48;
  FbtnDrive.OnClick := @btnDriveClick;

  FbtnEqual := TSpeedButton.Create(FToolsPanel);
  FbtnEqual.Name := Format('btnFilePanel%dEqual', [Ord(AIndex) + 1]);
  FbtnEqual.Parent := FToolsPanel;
  FbtnEqual.Caption := '<';
  FbtnEqual.Constraints.MinHeight := 24;
  FbtnEqual.Hint := 'Show current directory of another panel in this panel';
  FbtnEqual.Width := 23;
  FbtnEqual.OnClick := @btnEqualClick;

  FbtnHome := TSpeedButton.Create(FToolsPanel);
  FbtnHome.Name := Format('btnFilePanel%dHome', [Ord(AIndex) + 1]);
  FbtnHome.Parent := FToolsPanel;
  FbtnHome.Caption := '~';
  FbtnHome.Constraints.MinHeight := 24;
  FbtnHome.Hint := 'Go to home directory';
  FbtnHome.Width := 23;
  FbtnHome.OnClick := @btnClick;

  FbtnUp := TSpeedButton.Create(FToolsPanel);
  FbtnUp.Name := Format('btnFilePanel%dUp', [Ord(AIndex) + 1]);
  FbtnUp.Parent := FToolsPanel;
  FbtnUp.Caption := '..';
  FbtnUp.Constraints.MinHeight := 24;
  FbtnUp.Hint := 'Go to parent directory';
  FbtnUp.Width := 23;
  FbtnUp.OnClick := @btnClick;

  FbtnRoot := TSpeedButton.Create(FToolsPanel);
  FbtnRoot.Name := Format('btnFilePanel%dRoot', [Ord(AIndex) + 1]);
  FbtnRoot.Parent := FToolsPanel;
  FbtnRoot.Caption := DirectorySeparator;
  FbtnRoot.Constraints.MinHeight := 24;
  FbtnRoot.Hint := 'Go to root directory';
  FbtnRoot.Width := 23;
  FbtnRoot.OnClick := @btnClick;

  FbtnHotList := TSpeedButton.Create(FToolsPanel);
  FbtnHotList.Name := Format('btnFilePanel%dHotList', [Ord(AIndex) + 1]);
  FbtnHotList.Parent := FToolsPanel;
  FbtnHotList.Caption := '*';
  FbtnHotList.Constraints.MinHeight := 24;
  FbtnHotList.Hint := 'Directory Hotlist';
  FbtnHotList.Width := 23;
  FbtnHotList.OnClick := @btnClick;

  FlblDriveInfo := TLabel.Create(FToolsPanel);
  FlblDriveInfo.Name := Format('lblFilePanel%dDriveInfo', [Ord(AIndex) + 1]);
  FlblDriveInfo.Parent := FToolsPanel;
  FlblDriveInfo.Alignment := taCenter;
  FlblDriveInfo.BorderSpacing.Left := 2;
  FlblDriveInfo.BorderSpacing.Right := 2;
  FlblDriveInfo.ParentColor := False;
  FlblDriveInfo.OnDblClick := @lblDriveInfoDblClick;
  FlblDriveInfo.OnResize := @lblDriveInfoResize;

  FpbxDrive := TPaintBox.Create(FToolsPanel);
  FpbxDrive.Name := Format('pbxFilePanel%dDrive', [Ord(AIndex) + 1]);
  FpbxDrive.Parent := FToolsPanel;
  FpbxDrive.Height := 10;
  FpbxDrive.BorderSpacing.Left := 2;
  FpbxDrive.BorderSpacing.Right := 2;
  FpbxDrive.OnPaint := @pbxDrivePaint;

  // Anchor the buttons to the right edge of the tools row, from the right
  // to the left: equal, home, up, root, hotlist.
  FbtnEqual.AnchorSide[akTop].Control := FToolsPanel;
  FbtnEqual.AnchorSide[akTop].Side := asrTop;
  FbtnEqual.AnchorSide[akRight].Control := FToolsPanel;
  FbtnEqual.AnchorSide[akRight].Side := asrBottom;
  FbtnEqual.AnchorSide[akBottom].Control := FToolsPanel;
  FbtnEqual.AnchorSide[akBottom].Side := asrBottom;

  FbtnHome.AnchorSide[akTop].Control := FToolsPanel;
  FbtnHome.AnchorSide[akTop].Side := asrTop;
  FbtnHome.AnchorSide[akRight].Control := FbtnEqual;
  FbtnHome.AnchorSide[akRight].Side := asrLeft;
  FbtnHome.AnchorSide[akBottom].Control := FToolsPanel;
  FbtnHome.AnchorSide[akBottom].Side := asrBottom;

  FbtnUp.AnchorSide[akTop].Control := FToolsPanel;
  FbtnUp.AnchorSide[akTop].Side := asrTop;
  FbtnUp.AnchorSide[akRight].Control := FbtnHome;
  FbtnUp.AnchorSide[akRight].Side := asrLeft;
  FbtnUp.AnchorSide[akBottom].Control := FToolsPanel;
  FbtnUp.AnchorSide[akBottom].Side := asrBottom;

  FbtnRoot.AnchorSide[akTop].Control := FToolsPanel;
  FbtnRoot.AnchorSide[akTop].Side := asrTop;
  FbtnRoot.AnchorSide[akRight].Control := FbtnUp;
  FbtnRoot.AnchorSide[akRight].Side := asrLeft;
  FbtnRoot.AnchorSide[akBottom].Control := FToolsPanel;
  FbtnRoot.AnchorSide[akBottom].Side := asrBottom;

  FbtnHotList.AnchorSide[akTop].Control := FToolsPanel;
  FbtnHotList.AnchorSide[akTop].Side := asrTop;
  FbtnHotList.AnchorSide[akRight].Control := FbtnRoot;
  FbtnHotList.AnchorSide[akRight].Side := asrLeft;
  FbtnHotList.AnchorSide[akBottom].Control := FToolsPanel;
  FbtnHotList.AnchorSide[akBottom].Side := asrBottom;

  FpbxDrive.AnchorSide[akTop].Control := FlblDriveInfo;
  FpbxDrive.AnchorSide[akTop].Side := asrBottom;
  FpbxDrive.AnchorSide[akLeft].Control := FlblDriveInfo;
  FpbxDrive.AnchorSide[akLeft].Side := asrLeft;
  FpbxDrive.AnchorSide[akRight].Control := FlblDriveInfo;
  FpbxDrive.AnchorSide[akRight].Side := asrRight;

  UpdateAnchors;
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

procedure TFilePanel.UpdateAnchors;
begin
  FlblDriveInfo.AnchorSide[akTop].Control := FToolsPanel;
  FlblDriveInfo.AnchorSide[akTop].Side := asrTop;
  FlblDriveInfo.AnchorSide[akBottom].Control := FToolsPanel;
  FlblDriveInfo.AnchorSide[akBottom].Side := asrBottom;

  if FbtnDrive.Visible then
  begin
    FlblDriveInfo.AnchorSide[akLeft].Control := FbtnDrive;
    FlblDriveInfo.AnchorSide[akLeft].Side := asrRight;
    FlblDriveInfo.AnchorSide[akRight].Control := FbtnHotList;
    FlblDriveInfo.AnchorSide[akRight].Side := asrLeft;
  end
  else
  begin
    FlblDriveInfo.AnchorSide[akLeft].Control := FToolsPanel;
    FlblDriveInfo.AnchorSide[akLeft].Side := asrLeft;
    FlblDriveInfo.AnchorSide[akRight].Control := FToolsPanel;
    FlblDriveInfo.AnchorSide[akRight].Side := asrRight;
  end;
end;

procedure TFilePanel.UpdateLayout;
var
  Top: Integer;
begin
  Top := 0;

  if FDiskPanel.Visible then
  begin
    FDiskPanel.SetBounds(0, Top, FContainer.Width, FDiskPanel.Height);
    Inc(Top, FDiskPanel.Height);
  end;

  if FToolsPanel.Visible then
  begin
    FToolsPanel.SetBounds(0, Top, FContainer.Width, FToolsPanel.Height);
    Inc(Top, FToolsPanel.Height);
  end;

  if Assigned(FNotebook) then
    FNotebook.SetBounds(0, Top, FContainer.Width, FContainer.Height - Top);
end;

procedure TFilePanel.btnClick(Sender: TObject);
begin
  if Assigned(FOnButtonClick) then
    FOnButtonClick(Sender);
end;

procedure TFilePanel.btnDriveClick(Sender: TObject);
begin
  if Assigned(FOnDriveButtonClick) then
    FOnDriveButtonClick(Sender);
end;

procedure TFilePanel.btnEqualClick(Sender: TObject);
begin
  if Assigned(FOnEqualButtonClick) then
    FOnEqualButtonClick(Sender);
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
