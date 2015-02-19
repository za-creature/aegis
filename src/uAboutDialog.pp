unit uAboutDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ExtCtrls;

type

  { TAboutDialog }

  TAboutDialog = class(TForm)
    CloseButton: TButton;
    CopyrightLabel: TLabel;
    Image1: TImage;
    AegisVersionLabel: TLabel;
    RightsLabel: TLabel;
    VersionLabel: TLabel;
  private
    { private declarations }
  public
    { public declarations }
    function Execute(ver,aegver:string):boolean;
  end; 

var
  AboutDialog: TAboutDialog;

implementation

function TAboutDialog.Execute(ver,aegver:string):boolean;
const targetcpu={$i %fpctargetcpu};
      targetos={$i %fpctargetos};
begin
     VersionLabel.Caption:='GameLabs Map Editor v'+ver;
     AegisVersionLabel.Caption:='Using Aegis v'+aegver+'-'+targetcpu+'-'+targetos;
     ShowModal();
     Result:=true;
end;

initialization
  {$I uAboutDialog.lrs}

end.

