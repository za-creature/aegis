unit uNewMapDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, Buttons, ExtCtrls, DOM, XMLread;

type

  { TNewMapDialog }
  
  TTilesetPreview=class(TObject)
   public
    Filename,Name,Version,Author:ansistring;
    PreviewImages:array of TBitmap;
    LayerNames:array of ansistring;
    constructor Create(AFilename:ansistring);
    procedure Free();
  end;

  TNewMapDialog = class(TForm)
    PreviewLabel: TLabel;
    FilenameLabel: TLabel;
    AuthorLabel: TLabel;
    VersionLabel: TLabel;
    TilesetCombobox: TComboBox;
    PreviewImage: TImage;
    TilesetGroupbox: TGroupBox;
    OkButton: TButton;
    CancelButton: TButton;
    HorizLabel: TLabel;
    VertLabel: TLabel;
    SizeCustom: TRadioButton;
    SizeVertTrackbar: TTrackBar;
    SizeHuge: TRadioButton;
    SizeLarge: TRadioButton;
    SizeMedium: TRadioButton;
    SizeSmall: TRadioButton;
    SizeGroupBox: TGroupBox;
    SizeHorizTrackbar: TTrackBar;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure RadioChange(Sender: TObject);
    procedure RefreshButtonClick(Sender: TObject);
    procedure TilesetComboboxSelect(Sender: TObject);
    procedure TrackbarChange(Sender: TObject);
    function Execute():boolean;
  private
    { private declarations }
    function GetMapWidth():integer;
    function GetMapHeight():integer;
    FMapTileset:TTilesetPreview;
  public
    { public declarations }
    property MapWidth:integer read GetMapWidth;
    property MapHeight:integer read GetMapHeight;
    property MapTileset:TTilesetPreview read FMapTileset;
    AegisDir:ansistring;
    
  end; 

var
  NewMapDialog: TNewMapDialog;

implementation

{TTilesetPreview}

constructor TTilesetPreview.Create(AFilename:ansistring);

  procedure AddLayer(elem:TDOMNode);
  var x,y,i:integer;
      c:TDOMNodeList;
      tmpfilename:ansistring;
      aimg,tmp:TBitmap;
  begin
    setLength(PreviewImages,Length(PreviewImages)+1);
    setLength(LayerNames,Length(LayerNames)+1);
    if elem.Attributes.GetNamedItem('name')<>nil then LayerNames[High(LayerNames)]:=elem.Attributes.GetNamedItem('name').NodeValue
                                                 else LayerNames[High(LayerNames)]:='Unnamed Layer';
    c:=elem.ChildNodes;

    with c do
     for i:=0 to Count-1 do
      begin
       if Item[i].NodeName='texture' then
        begin
         //get proper name
         tmpfilename:=Item[i].Attributes.GetNamedItem('src').NodeValue;
         if not FileExists(tmpfilename) then tmpfilename:=NewMapDialog.AegisDir+'media\texture\'+tmpfilename;
         
         DoDirSeparators(tmpfilename);


         //create image
         aimg:=TBitmap.Create();
         aimg.Width:=32;
         aimg.Height:=32;
         
         //resize from 128x128 to 32x32
         tmp:=TBitmap.Create();
         try
          tmp.LoadFromFile(tmpfilename)
         except
          tmp.Free();
          aimg.Free();
          c.Free();
          raise Exception.Create('');
         end;
         for x:=0 to 31 do
          for y:=0 to 31 do
           aimg.Canvas.Pixels[x,y]:=tmp.Canvas.Pixels[x*4,y*4];
         tmp.Free();

         //save image
         PreviewImages[High(PreviewImages)]:=aimg;
         break;
        end;
      end;
      
    c.Free();
  end;

var f:TXMLDocument;
    e:TDOMNodeList;
    i:integer;
    cd:ansistring;
begin
  inherited Create();
  Filename:=AFilename;
  DoDirSeparators(Filename);
  //read XML data
  
  //save state
  cd:=GetCurrentDir();
  SetCurrentDir(ExtractFileDir(filename));
  try
   ReadXMLFile(f,filename);
  except
   SetCurrentDir(cd);
   Free();
   exit();
  end;

  //read attribs
  if f.DocumentElement.Attributes.GetNamedItem('name')<>nil then Name:=f.DocumentElement.Attributes.GetNamedItem('name').NodeValue
                                                            else Name:='Unnamed Tileset';
  if f.DocumentElement.Attributes.GetNamedItem('version')<>nil then Version:=f.DocumentElement.Attributes.GetNamedItem('version').NodeValue
                                                               else Version:='N/A';
  if f.DocumentElement.Attributes.GetNamedItem('author')<>nil then Author:=f.DocumentElement.Attributes.GetNamedItem('author').NodeValue
                                                              else Author:='N/A';

  //read layers
  e:=f.DocumentElement.ChildNodes;
  
  try
   with e do
    for i:=0 to Count-1 do
     if Item[i].NodeName='layer' then AddLayer(Item[i]);
  except
   //release images
   for i:=0 to High(PreviewImages) do PreviewImages[i].Free();
   setLength(LayerNames,0);
   setLength(PreviewImages,0);
   e.Free();
   //release document
   f.Free();
   //restore state
   SetCurrentDir(cd);
   raise Exception.Create('');
  end;

  e.Free();
  //release document
  f.Free();
  //restore state
  SetCurrentDir(cd)
end;

procedure TTilesetPreview.Free();
var i:integer;
begin
  if self<>nil then
   begin
    for i:=0 to High(PreviewImages) do PreviewImages[i].Free();
    setLength(LayerNames,0);
    setLength(PreviewImages,0);
    inherited Free();
   end;
end;

{ TNewMapDialog }

procedure TNewMapDialog.TrackbarChange(Sender: TObject);
begin
     SizeCustom.Checked:=true;
end;

procedure TNewMapDialog.RadioChange(Sender: TObject);
begin
     if SizeSmall.Checked then
      begin
       SizeHorizTrackbar.Position:=1;
       SizeVertTrackbar.Position:=1;
      end                  else
     if SizeMedium.Checked then
      begin
       SizeHorizTrackbar.Position:=2;
       SizeVertTrackbar.Position:=2;
      end                  else
     if SizeLarge.Checked then
      begin
       SizeHorizTrackbar.Position:=4;
       SizeVertTrackbar.Position:=4;
      end                  else
     if SizeHuge.Checked then
      begin
       SizeHorizTrackbar.Position:=8;
       SizeVertTrackbar.Position:=8;
      end;
end;

procedure TNewMapDialog.FormDestroy(Sender: TObject);
begin
end;

procedure TNewMapDialog.OkButtonClick(Sender: TObject);
var i:integer;
begin
  if TilesetCombobox.ItemIndex>=0 then
   begin
    FMapTileset:=(TilesetCombobox.Items.Objects[TilesetCombobox.ItemIndex] as TTilesetPreview);
    //ensure that the selected item is not released
    TilesetCombobox.Items.Delete(TilesetCombobox.ItemIndex);
   end;
end;

procedure TNewMapDialog.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var i:integer;
begin
  if ModalResult<>mrOk then FMapTileset:=nil;
  for i:=0 to TilesetCombobox.Items.Count-1 do
   (TilesetCombobox.Items.Objects[i] as TTilesetPreview).Free();
  TilesetCombobox.Items.Clear();
end;

procedure TNewMapDialog.RefreshButtonClick(Sender: TObject);
var t:TSearchRec;
    cd:ansistring;
    i:integer;
    PreviewObject:TTilesetPreview = nil;
begin
  //save state
  cd:=GetCurrentDir();
  SetCurrentDir(AegisDir+'media'+DirectorySeparator+'tileset');
  //clear old
  for i:=0 to TilesetCombobox.Items.Count-1 do
   TilesetCombobox.Items.Objects[i].Free();
  TilesetCombobox.Items.Clear();
  //get new
  if FindFirst('*.tileset',faAnyFile,t)=0 then
   repeat
    try
     PreviewObject:=TTilesetPreview.Create(t.Name);
    except
     PreviewObject:=nil;
    end;
    if PreviewObject<>nil then TilesetCombobox.Items.AddObject(PreviewObject.Name,PreviewObject);
    PreviewObject:=nil;
   until FindNext(t)<>0;
  FindClose(t);
  if TilesetCombobox.Items.Count=0 then
   begin
    TilesetCombobox.ItemIndex:=-1;
    OkButton.Enabled:=false;
   end
  else
   begin
    TilesetCombobox.ItemIndex:=0;
    OkButton.Enabled:=true;
   end;
  TilesetComboboxSelect(self);
  //restore state
  SetCurrentDir(cd);
end;

procedure TNewMapDialog.TilesetComboboxSelect(Sender: TObject);
var i:integer;
begin
  if TilesetCombobox.ItemIndex<>-1 then
   with (TilesetCombobox.Items.Objects[TilesetCombobox.ItemIndex] as TTilesetPreview) do
    begin
     FilenameLabel.Caption:='Filename: '+Filename;
     AuthorLabel.Caption:='Author: '+Author;
     VersionLabel.Caption:='Version: '+Version;
     PreviewImage.Canvas.Brush.Color:=clForm;
     PreviewImage.Canvas.FillRect(0,0,PreviewImage.Width,PreviewImage.Height);
     for i:=0 to High(PreviewImages) do
      PreviewImage.Canvas.Draw((i mod 4)*32,(i div 4)*32,PreviewImages[i]);
    end                            else
    begin
     FilenameLabel.Caption:='Filename: ';
     AuthorLabel.Caption:='Author: ';
     VersionLabel.Caption:='Version: ';
     PreviewImage.Canvas.Brush.Color:=clForm;
     PreviewImage.Canvas.FillRect(0,0,PreviewImage.Width,PreviewImage.Height);
    end;
end;

function TNewMapDialog.Execute():boolean;
begin
     RefreshButtonClick(self);
     Result:=ShowModal()=mrOk;
end;

function TNewMapDialog.GetMapWidth():integer;
begin
     Result:=SizeHorizTrackbar.Position*64;
end;
function TNewMapDialog.GetMapHeight():integer;
begin
     Result:=SizeVertTrackbar.Position*64;
end;

initialization
  {$I uNewMapDialog.lrs}

end.

