unit uEditorOptionsDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, Buttons, uIO64;

type

  { TEditorOptionsDialog }

  TEditorOptionsDialog = class(TForm)
    CancelButton: TButton;
    OkButton: TButton;
    InvertMoveSensitivityCheckbox: TCheckBox;
    InvertTiltSensitivityCheckbox: TCheckBox;
    InvertWheelSensitivityCheckbox: TCheckBox;
    MoveSensitivityLabel: TLabel;
    MouseOptionsGroupbox: TGroupBox;
    TiltSensitivityTrackbar: TTrackBar;
    WheelSensitivityTrackbar: TTrackBar;
    TiltSensitivityLabel: TLabel;
    MoveSensitivityTrackbar: TTrackBar;
    WheelSensitivityLabel: TLabel;
    ViewGridCheckbox: TCheckBox;
    ViewNormalsCheckbox: TCheckBox;
    SegmentationLabel: TLabel;
    MapOptionsGroupbox: TGroupBox;
    SegmentationTrackbar: TTrackBar;
  private
    { private declarations }
  public
    { public declarations }
    function Execute(config:TConfig):boolean;
  end; 
  
var
  EditorOptionsDialog: TEditorOptionsDialog;

implementation

function TEditorOptionsDialog.Execute(config:TConfig):boolean;
begin
     ViewNormalsCheckbox.Checked:=config.ShowNormals;
     ViewGridCheckbox.Checked:=Config.showwire;
     SegmentationTrackbar.Position:=config.Segmentation;
     
     if config.WheelSensitivity>0 then
      begin
       InvertWheelSensitivityCheckbox.Checked:=false;
       WheelSensitivityTrackbar.Position:=integer(round(config.WheelSensitivity*100));
      end                         else
      begin
       InvertWheelSensitivityCheckbox.Checked:=true;
       WheelSensitivityTrackbar.Position:=integer(round(config.WheelSensitivity*-100));
      end;
     if config.MoveSensitivity>0 then
      begin
       InvertMoveSensitivityCheckbox.Checked:=false;
       MoveSensitivityTrackbar.Position:=integer(round(config.MoveSensitivity*100));
      end                         else
      begin
       InvertMoveSensitivityCheckbox.Checked:=true;
       MoveSensitivityTrackbar.Position:=integer(round(config.MoveSensitivity*-100));
      end;
     if config.TiltSensitivity>0 then
      begin
       InvertTiltSensitivityCheckbox.Checked:=false;
       TiltSensitivityTrackbar.Position:=integer(round(config.TiltSensitivity*100));
      end                         else
      begin
       InvertTiltSensitivityCheckbox.Checked:=true;
       TiltSensitivityTrackbar.Position:=integer(round(config.TiltSensitivity*-100));
      end;

     Result:=ShowModal()=mrOk;
     
     if Result then
      begin
       config.ShowNormals:=ViewNormalsCheckbox.Checked;
       config.ShowWire:=ViewGridCheckbox.Checked;
       config.Segmentation:=SEgmentationTrackbar.Position;
       if InvertWheelSensitivityCheckbox.Checked then config.WheelSensitivity:=single(WheelSensitivityTrackbar.Position/-100)
                                                 else config.WheelSensitivity:=single(WheelSensitivityTrackbar.Position/100);
       if InvertMoveSensitivityCheckbox.Checked then config.MoveSensitivity:=single(MoveSensitivityTrackbar.Position/-100)
                                                else config.MoveSensitivity:=single(MoveSensitivityTrackbar.Position/100);
       if InvertTiltSensitivityCheckbox.Checked then config.TiltSensitivity:=single(TiltSensitivityTrackbar.Position/-100)
                                                else config.TiltSensitivity:=single(TiltSensitivityTrackbar.Position/100);
      end;
end;

initialization
  {$I uEditorOptionsDialog.lrs}

end.

