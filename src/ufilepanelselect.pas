unit uFilePanelSelect;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  {en
     Number of file panels shown in the main window.
  }
  FILE_PANEL_COUNT = 4;

  {en
     Number of rows of the file panel grid.
  }
  FILE_PANEL_ROWS = 2;

  {en
     Number of columns of the file panel grid.
  }
  FILE_PANEL_COLUMNS = 2;

type
  {en
     Index of a file panel.

     The panels are laid out in a grid, in reading order:
       0 - top left, 1 - top right, 2 - bottom left, 3 - bottom right.
  }
  TFilePanelIndex = 0..FILE_PANEL_COUNT - 1;

  {en
     Legacy left/right panel selector.

     It is kept for compatibility with the Lua scripting API and with the
     Total Commander compatibility map, where panels are addressed by their
     historical left/right meaning. New code must use TFilePanelIndex.
  }
  TFilePanelSelect = (fpLeft, fpRight);

  {en
     Converts a legacy left/right selector to a file panel index.
  }
function FilePanelIndexOf(aSelect: TFilePanelSelect): TFilePanelIndex;

  {en
     Returns the human readable position of the file panel in the grid.
   }
function FilePanelPositionName(aIndex: TFilePanelIndex): String;

implementation

function FilePanelPositionName(aIndex: TFilePanelIndex): String;
begin
  case aIndex of
    0: Result := 'top left';
    1: Result := 'top right';
    2: Result := 'bottom left';
    3: Result := 'bottom right';
  else
    Result := '';
  end;
end;

function FilePanelIndexOf(aSelect: TFilePanelSelect): TFilePanelIndex;
begin
  case aSelect of
    fpLeft:  Result := 0;
    fpRight: Result := 1;
  else
    Result := 0;
  end;
end;

end.
