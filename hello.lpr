program hello;

{$i config.inc}
{$mode objfpc}{$H+}

{$ifdef mswindows}

{$ifdef debug_l1}
{$apptype console}
{$endif}

{$ifdef mswindows}
{$R res\aegis2.res}
{$endif}

{$endif}


uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Sysutils, Forms, uglview;


begin
  Application.Title:='glview';
  SetCurrentDir(ExtractFileName(ParamStr(0)));
  Application.Initialize;
  Application.CreateForm(Tglview, glview);
  Application.Run;
end.

