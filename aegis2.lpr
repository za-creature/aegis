program aegis2;

{$I config.inc}
{$mode objfpc}{$H+}
{R res\aegis2.res}

{$ifdef debug_l1}
{$apptype console}
{$endif}


uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Sysutils, Forms, uMain, uNewMapDialog, uAboutDialog, uEditorOptionsDialog;

begin
  Application.Title:='Aegis';
  SetCurrentDir(ExtractFileName(ParamStr(0)));
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.CreateForm(TNewMapDialog, NewMapDialog);
  Application.CreateForm(TAboutDialog, AboutDialog);
  Application.CreateForm(TEditorOptionsDialog, EditorOptionsDialog);
  Main.CallAfterConstruction(Application);
  Application.Run;
end.

