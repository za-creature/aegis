unit uMain;

{$i config.inc}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, StdCtrls, Graphics, Dialogs,
  OpenGLContext, GL, ComCtrls, uIO64, uMath, Buttons, GLext, GLu, LCLType, Math,
  ExtCtrls, uCamera, Menus, uNewMapDialog, uAboutDialog, uEditorOptionsDialog;
  
const ver='0.35';
const aegver='0.73';
type

  { TMain }

  TMain = class(TForm)
    ActionLabel: TLabel;
    CircleButton: TSpeedButton;
    GLContext: TOpenGLControl;
    OpenDialog: TOpenDialog;
    ProgressLabel: TLabel;
    ProgressBar: TProgressBar;
    ProgressPanel: TPanel;
    SaveDialog: TSaveDialog;
    Tile0: TSpeedButton;
    Tile1: TSpeedButton;
    Tile2: TSpeedButton;
    Tile3: TSpeedButton;
    Tile4: TSpeedButton;
    Tile5: TSpeedButton;
    Tile6: TSpeedButton;
    Tile7: TSpeedButton;
    LandscapeSheet: TTabSheet;
    LowerButton: TSpeedButton;
    EditorOptions: TMenuItem;
    MyMainMenu: TMainMenu;
    FileMI: TMenuItem;
    ExitMI: TMenuItem;
    Edit: TMenuItem;
    HelpMI: TMenuItem;
    AboutMI: TMenuItem;
    GridMI: TMenuItem;
    ComponentPaletteMI: TMenuItem;
    SmoothButton: TSpeedButton;
    NoiseButton: TSpeedButton;
    TilesetNameLabel: TLabel;
    ViewportMI: TMenuItem;
    OptionsMI: TMenuItem;
    ViewMI: TMenuItem;
    RedoMI: TMenuItem;
    UndoMI: TMenuItem;
    SaveAsMI: TMenuItem;
    SaveMI: TMenuItem;
    OpenMI: TMenuItem;
    NewMI: TMenuItem;
    ObjectSheet: TTabSheet;
    PageController: TPageControl;
    PaletteShapeLabel: TLabel;
    PaletteSizeLabel: TLabel;
    PlateauButton: TSpeedButton;
    RaiseButton: TSpeedButton;
    SizeHugeButton: TSpeedButton;
    SizeLargeButton: TSpeedButton;
    SizeNormalButton: TSpeedButton;
    SizeSmallButton: TSpeedButton;
    SizeTinyButton: TSpeedButton;
    SquareButton: TSpeedButton;
    SteepnessLabel: TLabel;
    SteepnessBar: TTrackBar;
    MyTimer: TTimer;
    procedure AboutMIClick(Sender: TObject);
    procedure CircleButtonClick(Sender: TObject);
    procedure ComponentPaletteMIClick(Sender: TObject);
    procedure EditorOptionsClick(Sender: TObject);
    procedure ExitMIClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure GLContextKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GLContextKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    Procedure GLContextMouseDown(Sender: TOBject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure GLContextMouseEnter(Sender: TObject);
    procedure GLContextMouseLeave(Sender: TObject);
    procedure GlContextMouseMove(Sender: Tobject; Shift: Tshiftstate; X, Y: Integer);
    Procedure GLContextMouseUp(Sender: TOBject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    Procedure GLContextMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    Procedure GLContextMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure GLContextPaint(Sender: TObject);
    procedure GLContextResize(Sender: TObject);
    procedure GridMIClick(Sender: TObject);
    procedure Loop(Sender:TObject);
    procedure LowerButtonClick(Sender: TObject);
    procedure NewMIClick(Sender: TObject);
    procedure NoiseButtonClick(Sender: TObject);
    procedure OpenMIClick(Sender: TObject);
    procedure PlateauButtonClick(Sender: TObject);
    procedure RaiseButtonClick(Sender: TObject);
    procedure SaveMIClick(Sender: TObject);
    procedure SizeHugeButtonClick(Sender: TObject);
    procedure SizeLargeButtonClick(Sender: TObject);
    procedure SizeNormalButtonClick(Sender: TObject);
    procedure SizeSmallButtonClick(Sender: TObject);
    procedure SizeTinyButtonClick(Sender: TObject);
    procedure SmoothButtonClick(Sender: TObject);
    procedure SquareButtonClick(Sender: TObject);
    procedure SteepnessBarChange(Sender: TObject);
    procedure Tile0Click(Sender: TObject);
    procedure Tile1Click(Sender: TObject);
    procedure Tile2Click(Sender: TObject);
    procedure Tile3Click(Sender: TObject);
    procedure Tile4Click(Sender: TObject);
    procedure Tile5Click(Sender: TObject);
    procedure Tile6Click(Sender: TObject);
    procedure Tile7Click(Sender: TObject);
    procedure ViewportMIClick(Sender: TOBject);
    procedure CallAfterConstruction(Sender:TObject);
    procedure onStateChange(i:integer);
  private
    { private declarations }
    Input:TInput;
    Config:TConfig;
    IO64:TIO64;
    MyMap:TMap;
    MyTileset:TTilesetPreview;

    DialogOpen:boolean;
    CurrentTile,editAction,lastclickX,lastclickY:integer;
    mousein,isCircle,camtilt,cammove:boolean;
    LoopOn:boolean;
    dist,maxheight:glFloat;

    ray:TRay;
    mylightsource:TLightSource;
  public
    { public declarations }
  end; 

var
  Main: TMain;

implementation

{ TMain }

procedure TMain.FormCreate(Sender: TObject);

  function Parse(s:ansistring):ansistring;
  var i:integer;
  begin
    i:=length(s);
    while (s[i]<>DirectorySeparator) do dec(i);
    dec(i);
    while (s[i]<>DirectorySeparator) do dec(i);
    Result:=copy(s,1,i);
  end;
  
var AegisDir:ansistring;
begin
  {$ifdef debug_l1}
  writeln('main: Creating Context');
  {$endif}
  {$ifdef debug_l1}
  writeln(' main: Initializing OpenGL 1.5');
  {$endif}
  InitOpenGL();
  {$ifdef debug_l1}
  writeln(' main: Loading the configuration file');
  {$endif}
  AegisDir:=Parse(ParamStr(0));
  Config:=TConfig.Create(AegisDir+'var\conf\editor.ini');
  Config.Load();
  Config.AegisDir:=AegisDir;
  if GLContext.MakeCurrent() then GLContext.Paint();
  {$ifdef debug_l1}
  writeln(' main: Linking with io64');
  {$endif}
  IO64:=TIO64.Create(Config);
  IO64.onStateChange:=@onStateChange;

  {$ifdef debug_l1}
  writeln(' main: Creating Light Source');
  {$endif}
  MyLightSource:=IO64.AddLightSource();
  MyLightSource.LoadPropertiesFromFile('sun.xml');
  {$ifdef debug_l1}
  writeln(' main: Setting the viewport');
  {$endif}
  IO64.Camera.SetviewPort(0,100,0,60,0,0);
  if Config.SyncControlEnabled then
   begin
    {$ifdef debug_l1}
    writeln(' main: Updating VSync');
    {$endif}
    if Config.vsync then wglSwapIntervalEXT(1)
                    else wglSwapIntervalEXT(0);
   end;
  {$ifdef debug_l1}
  writeln(' main: Loading Skybox');
  {$endif}
  IO64.LoadSkyBox(AegisDir+'media\skybox\default.skybox');

  {$ifdef debug_l1}
  writeln('main: Run()');
  {$endif}

  dist:=1;
  EditAction:=1;
  isCircle:=true;
  maxheight:=0.1;

  GridMI.Checked:=Config.showwire;
  PageController.Visible:=Config.ViewComponentPalette;
  ComponentPaletteMI.Checked:=Config.ViewComponentPalette;
  GLContext.Visible:=Config.ViewViewport;
  ViewportMI.Checked:=Config.ViewViewport;

  GLContextResize(self);
end;

procedure TMain.ExitMIClick(Sender: TObject);
begin
  Close();
end;

procedure TMain.ComponentPaletteMIClick(Sender: TObject);
begin
  Config.ViewComponentPalette:=not(Config.ViewComponentPalette);
  PageController.Visible:=Config.ViewComponentPalette;
  ComponentPaletteMI.Checked:=Config.ViewComponentPalette;
end;

procedure TMain.EditorOptionsClick(Sender: TObject);
begin
  DialogOpen:=true;
  if EditorOptionsDialog.Execute(Config) then
   begin
     if MyMap<>nil then
      begin
       MyMap.DrawGrid:=Config.showwire;
       MyMap.Segmentation:=Config.segmentation;
       GLContext.Paint();
      end;
     GridMI.Checked:=Config.showwire;
   end;
  DialogOpen:=false;
end;

procedure TMain.CircleButtonClick(Sender: TObject);
begin
  isCircle:=true;
end;

procedure TMain.AboutMIClick(Sender: TObject);
begin
  DialogOpen:=true;
  AboutDialog.Execute(ver,aegver);
  DialogOpen:=false;
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
     MyMap.Free();
     MyTileset.Free();
     {$ifdef debug_l1}
     writeln('main: Destroying Context');
     {$endif}
     {$ifdef debug_l1}
     writeln(' main: Unlinking io64');
     {$endif}
     IO64.Free();
     {$ifdef debug_l1}
     writeln(' main: Saving configuration file');
     {$endif}
     Config.Save();
     Config.Free();
     {$ifdef debug_l1}
     writeln(' main: Releasing OpenGL 1.5');
     {$endif}
     DoneOpenGL();
end;

procedure TMain.FormWindowStateChange(Sender: TObject);
begin
end;

procedure TMain.GLContextKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Input.Keys[Key and 255]:=true;
end;

procedure TMain.GLContextKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Input.Keys[Key and 255]:=false;
end;

Procedure TMain.GLContextMouseDown(Sender: TOBject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var c:vec3;
    avg,h,delta,adist,sx,sy:glFloat;
    rx,ry,pxc,i,j,tx,ty:integer;
begin
  {$ifdef debug_l1}
  writeln('main: Received Mouse Down Message. Processing');
  {$endif}
  if Button=mbLeft then
   begin
    if MyMap=nil then exit;
    {$ifdef debug_l2}
    writeln(' main: Creating a ray');
    {$endif}
    ray:=IO64.Camera.CreateRay(Input.MouseX,Input.MouseY);
    {$ifdef debug_l2}
    writeln(' main: Checking for collision');
    {$endif}
    c:=MyMap.Pick(Ray);
    if (c[0]<>-1234567)then
     begin
      {$ifdef debug_l3}
      writeln('  main: Collision found. Updating map');
      {$endif}

      sx:=glFloat((MyMap.width+1)/-2);
      sy:=glFloat((MyMap.height+1)/-2);

      sx:=c[0]-sx;
      sy:=c[2]-sy;

      tx:=integer(trunc(sx));
      ty:=integer(trunc(sy));
      rx:=integer(round(sx));
      ry:=integer(round(sy));
      
      //raise (TException.Create()? :D)
      if EditAction=1 then
       begin
        for i:=tx-1-trunc(dist) to tx+1+trunc(dist) do
         for j:=ty-1-trunc(dist) to ty+1+trunc(dist) do
          if (i>=0)and(i<=MyMap.width)and(j>=0)and(j<=MyMap.Height)then
           begin
            adist:=sqrt( sqr(sx-i)+sqr(sy-j));
            if adist<=dist then
             begin
              delta:=adist/dist;
              delta:=maxheight*sin(arctan(sqrt(1-delta*delta)/delta));
              MyMap.Heightmap[i,j]:=MyMap.Heightmap[i,j]+delta;
             end;
           end;
       end;
      //lower
      if EditAction=2 then
       begin
        for i:=tx-1-trunc(dist) to tx+1+trunc(dist) do
         for j:=ty-1-trunc(dist) to ty+1+trunc(dist) do
          if (i>=0)and(i<=MyMap.width)and(j>=0)and(j<=MyMap.Height)then
           begin
            adist:=sqrt( sqr(sx-i)+sqr(sy-j));
            if adist<=dist then
             begin
              delta:=adist/dist;
              delta:=maxheight*sin(arctan(sqrt(1-delta*delta)/delta));
              MyMap.Heightmap[i,j]:=MyMap.Heightmap[i,j]-delta;
             end;
           end;
       end;
      //plateau
      if EditAction=3 then
       begin
        h:=MyMap.Heightmap[tx,ty];
        for i:=tx-1-trunc(dist) to tx+1+trunc(dist) do
         for j:=ty-1-trunc(dist) to ty+1+trunc(dist) do
          if (i>=0)and(i<=MyMap.width)and(j>=0)and(j<=MyMap.Height)then
           begin
            adist:=sqrt( sqr(sx-i)+sqr(sy-j));
            if (adist<=dist)or(not isCircle) then MyMap.Heightmap[i,j]:=h;
           end;
       end;
      //smooth
      if EditAction=4 then
       begin
        h:=MyMap.Heightmap[tx,ty];
        avg:=0;
        pxc:=0;
        //get average
        for i:=tx-1-trunc(dist) to tx+1+trunc(dist) do
         for j:=ty-1-trunc(dist) to ty+1+trunc(dist) do
          if (i>=0)and(i<=MyMap.width)and(j>=0)and(j<=MyMap.Height)then
           begin
            adist:=sqrt( sqr(sx-i)+sqr(sy-j));
            if (adist<=dist)or(not isCircle) then
             begin
              avg+=MyMap.Heightmap[i,j];
              inc(pxc);
             end;
           end;
        if pxc<>0 then avg/=pxc;
        //alpha
        for i:=tx-1-trunc(dist) to tx+1+trunc(dist) do
         for j:=ty-1-trunc(dist) to ty+1+trunc(dist) do
          if (i>=0)and(i<=MyMap.width)and(j>=0)and(j<=MyMap.Height)then
           begin
            adist:=sqrt( sqr(sx-i)+sqr(sy-j));
            if (adist<=dist)or(not isCircle) then
             MyMap.Heightmap[i,j]:=MyMap.Heightmap[i,j]+(maxheight/10)*(avg-MyMap.Heightmap[i,j]);
           end;
       end;
      //noise
      if EditAction=5 then
       begin
        Randomize();
        for i:=tx-1-trunc(dist) to tx+1+trunc(dist) do
         for j:=ty-1-trunc(dist) to ty+1+trunc(dist) do
          if (i>=0)and(i<=MyMap.width)and(j>=0)and(j<=MyMap.Height)then
           begin
            adist:=sqrt( sqr(sx-i)+sqr(sy-j));
            if (adist<=dist)or(not isCircle) then
             MyMap.Heightmap[i,j]:=MyMap.Heightmap[i,j]+(Random()-0.5)*maxheight;
           end;
       end;
      //texture
      if EditAction=6 then
       begin
        for i:=rx-trunc(dist) to rx+trunc(dist) do
         for j:=ry-trunc(dist) to ry+trunc(dist) do
          if (i>=0)and(i<=MyMap.width)and(j>=0)and(j<=MyMap.Height)then
           begin
            adist:=sqrt( sqr(rx-i)+sqr(ry-j));
            if (adist<=dist)or(not isCircle) then
             MyMap.TextureMap[i,j]:=CurrentTile;
           end;
       end;

     end;
  end             else
 if Button=mbMiddle then
  begin
   camtilt:=true;
   lastclickx:=x;
   lastclicky:=y;
  end               else
 if Button=mbRight then
  begin
   cammove:=true;
   lastclickx:=x;
   lastclicky:=y;
  end;
end;

procedure TMain.GLContextMouseEnter(Sender: TObject);
begin
  {$ifdef debug_l1}
  writeln('main: Received Mouse Enter Message. Resuming main thread');
  {$endif}
  mousein:=true;
  MyTimer.Enabled:=true;
end;

procedure TMain.GLContextMouseLeave(Sender: TObject);
begin
  {$ifdef debug_l1}
  writeln('main: Received Mouse Leave Message. Pausing main thread');
  {$endif}
  mousein:=false;
  camtilt:=false;
  MyTimer.Enabled:=false;
end;

procedure Tmain.GLContextMouseMove(Sender: Tobject; Shift: Tshiftstate; X,
  Y: Integer);
begin
  {$ifdef debug_l4}
  writeln('main: Received Mouse Move Message: (',x,' ',y,'). Processing');
  {$endif}
  Input.MouseX:=X;
  Input.MouseY:=Y;
  if camtilt then
   begin
    IO64.Camera.Tilt(180*Config.TiltSensitivity*(Y-lastclickY)/GLContext.Height,180*Config.TiltSensitivity*(X-lastclickX)/GLContext.Width,0);
    lastclickx:=x;
    lastclicky:=y;
   end;
  if cammove then
   begin
    IO64.Camera.Move(X-lastclickX,Y-lastclickY,Config.MoveSensitivity/10);
    lastclickx:=x;
    lastclicky:=y;
   end;
end;

Procedure TMain.GLContextMouseUp(Sender: TOBject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  {$ifdef debug_l1}
  writeln('main: Received Mouse Up Message. Processing');
  {$endif}
  if button=mbMiddle then camtilt:=false;
  if button=mbRight then cammove:=false;
end;

Procedure TMain.GLContextMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  {$ifdef debug_l1}
  writeln('main: Received Mouse Wheel Down Message. Processing');
  {$endif}
  Handled:=true;
  IO64.Camera.ZoomOut(Config.WheelSensitivity);
end;

Procedure TMain.GLContextMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  {$ifdef debug_l1}
  writeln('main: Received Mouse Wheel Up Message. Processing');
  {$endif}
  Handled:=true;
  IO64.Camera.ZoomIn(Config.WheelSensitivity);
end;

procedure TMain.GLContextPaint(Sender: TObject);
begin
  if GLContext.MakeCurrent() then
   begin
    glClear(GL_DEPTH_BUFFER_BIT);
    
    //let IO64 do all the necesarry painting
    IO64.Draw();

    MyMap.Draw();

    IO64.DrawLensFlare();

    glFlush();

    GLContext.SwapBuffers();
   end;
end;

procedure TMain.Loop(Sender:TObject);
begin
     //if we're still painting, skip a frame
     Application.ProcessMessages();
     if not (LoopOn or DialogOpen) then
      begin
       LoopOn:=true;
       
       if Input.Keys[VK_L] then
        begin
         Input.Keys[VK_L]:=false;
         MyLightSource.Enabled:=not(MyLightSource.Enabled);
        end;
       if Input.Keys[VK_G] then
        begin
         Input.Keys[VK_G]:=false;
         GridMIClick(Sender);
        end;

       GLContext.Paint();
       LoopOn:=false;
      end;
end;

procedure TMain.LowerButtonClick(Sender: TObject);
begin
  editAction:=2;
end;

procedure TMain.NewMIClick(Sender: TObject);
begin
  DialogOpen:=true;
  if NewMapDialog.Execute() then
   begin
    //release old resources
    MyMap.Free();
    MyMap:=nil;
    MyTileset.Free();
    MyTileset:=nil;
    //update GUI
    MyTileset:=NewMapDialog.MapTileset;
    TilesetNameLabel.Caption:=MyTileset.Name;

    if High(Mytileset.PreviewImages)>=0 then
     begin
      Tile0.Glyph.Assign(MyTileset.PreviewImages[0]);
      Tile0.Enabled:=true;
     end
    else
     begin
      Tile0.Glyph.Canvas.FillRect(0,0,32,32);
      Tile0.Enabled:=false;
     end;
    if High(Mytileset.PreviewImages)>=1 then
     begin
      Tile1.Glyph.Assign(MyTileset.PreviewImages[1]);
      Tile1.Enabled:=true;
     end
    else
     begin
      Tile1.Glyph.Canvas.FillRect(0,0,32,32);
      Tile1.Enabled:=false;
     end;
    if High(Mytileset.PreviewImages)>=2 then
     begin
      Tile2.Glyph.Assign(MyTileset.PreviewImages[2]);
      Tile2.Enabled:=true;
     end
    else
     begin
      Tile2.Glyph.Canvas.FillRect(0,0,32,32);
      Tile2.Enabled:=false;
     end;
    if High(Mytileset.PreviewImages)>=3 then
     begin
      Tile3.Glyph.Assign(MyTileset.PreviewImages[3]);
      Tile3.Enabled:=true;
     end
    else
     begin
      Tile3.Glyph.Canvas.FillRect(0,0,32,32);
      Tile3.Enabled:=false;
     end;
    if High(Mytileset.PreviewImages)>=4 then
     begin
      Tile4.Glyph.Assign(MyTileset.PreviewImages[4]);
      Tile4.Enabled:=true;
     end
    else
     begin
      Tile4.Glyph.Canvas.FillRect(0,0,32,32);
      Tile4.Enabled:=false;
     end;
    if High(Mytileset.PreviewImages)>=5 then
     begin
      Tile5.Glyph.Assign(MyTileset.PreviewImages[5]);
      Tile5.Enabled:=true;
     end
    else
     begin
      Tile5.Glyph.Canvas.FillRect(0,0,32,32);
      Tile5.Enabled:=false;
     end;
    if High(Mytileset.PreviewImages)>=6 then
     begin
      Tile6.Glyph.Assign(MyTileset.PreviewImages[6]);
      Tile6.Enabled:=true;
     end
    else
     begin
      Tile6.Glyph.Canvas.FillRect(0,0,32,32);
      Tile6.Enabled:=false;
     end;
    if High(Mytileset.PreviewImages)>=7 then
     begin
      Tile7.Glyph.Assign(MyTileset.PreviewImages[7]);
      Tile7.Enabled:=true;
     end
    else
     begin
      Tile7.Glyph.Canvas.FillRect(0,0,32,32);
      Tile7.Enabled:=false;
     end;
    
    //create new resources

    ProgressBar.Position:=0;
    Enabled:=false;
    ProgressPanel.Show();;
    Application.ProcessMessages();

    MyMap:=TMap.Create(IO64,NewMapDialog.MapWidth,NewMapDialog.MapHeight,Mytileset.Filename);
    MyMap.DrawGrid:=Config.ShowWire;

    ProgressPanel.Hide();
    Enabled:=true;
    GLContext.Paint();
    Application.ProcessMessages();
   end;
  DialogOpen:=false;
end;

procedure TMain.NoiseButtonClick(Sender: TObject);
begin
  editAction:=5;
end;

procedure TMain.OpenMIClick(Sender: TObject);
begin
  DialogOpen:=true;
  if OpenDialog.Execute() then
   begin
    MyMap.Free();
    MyMap:=nil;
    MyTileset.Free();
    MyTileset:=nil;
    //create new resources

    ProgressBar.Position:=0;
    Enabled:=false;
    ProgressPanel.Show();;
    Application.ProcessMessages();

    MyMap:=TMap.Create(IO64,OpenDialog.Filename);
    MyMap.DrawGrid:=Config.ShowWire;

    ProgressPanel.Hide();
    Enabled:=true;
    GLContext.Paint();
    Application.ProcessMessages();


    //update GUI
    MyTileset:=TTilesetPreview.Create(IO64.Config.AegisDir+'media\tileset\'+MyMap.Tileset);
    TilesetNameLabel.Caption:=MyTileset.Name;

    if High(MyTileset.PreviewImages)>=0 then
     begin
      Tile0.Glyph.Assign(MyTileset.PreviewImages[0]);
      Tile0.Enabled:=true;
     end
    else
     begin
      Tile0.Glyph.Canvas.FillRect(0,0,32,32);
      Tile0.Enabled:=false;
     end;
    if High(MyTileset.PreviewImages)>=1 then
     begin
      Tile1.Glyph.Assign(MyTileset.PreviewImages[1]);
      Tile1.Enabled:=true;
     end
    else
     begin
      Tile1.Glyph.Canvas.FillRect(0,0,32,32);
      Tile1.Enabled:=false;
     end;
    if High(MyTileset.PreviewImages)>=2 then
     begin
      Tile2.Glyph.Assign(MyTileset.PreviewImages[2]);
      Tile2.Enabled:=true;
     end
    else
     begin
      Tile2.Glyph.Canvas.FillRect(0,0,32,32);
      Tile2.Enabled:=false;
     end;
    if High(MyTileset.PreviewImages)>=3 then
     begin
      Tile3.Glyph.Assign(MyTileset.PreviewImages[3]);
      Tile3.Enabled:=true;
     end
    else
     begin
      Tile3.Glyph.Canvas.FillRect(0,0,32,32);
      Tile3.Enabled:=false;
     end;
    if High(MyTileset.PreviewImages)>=4 then
     begin
      Tile4.Glyph.Assign(MyTileset.PreviewImages[4]);
      Tile4.Enabled:=true;
     end
    else
     begin
      Tile4.Glyph.Canvas.FillRect(0,0,32,32);
      Tile4.Enabled:=false;
     end;
    if High(MyTileset.PreviewImages)>=5 then
     begin
      Tile5.Glyph.Assign(MyTileset.PreviewImages[5]);
      Tile5.Enabled:=true;
     end
    else
     begin
      Tile5.Glyph.Canvas.FillRect(0,0,32,32);
      Tile5.Enabled:=false;
     end;
    if High(MyTileset.PreviewImages)>=6 then
     begin
      Tile6.Glyph.Assign(MyTileset.PreviewImages[6]);
      Tile6.Enabled:=true;
     end
    else
     begin
      Tile6.Glyph.Canvas.FillRect(0,0,32,32);
      Tile6.Enabled:=false;
     end;
    if High(MyTileset.PreviewImages)>=7 then
     begin
      Tile7.Glyph.Assign(MyTileset.PreviewImages[7]);
      Tile7.Enabled:=true;
     end
    else
     begin
      Tile7.Glyph.Canvas.FillRect(0,0,32,32);
      Tile7.Enabled:=false;
     end;
   end;
  DialogOpen:=false;
end;

procedure TMain.PlateauButtonClick(Sender: TObject);
begin
  editAction:=3;
end;

procedure TMain.RaiseButtonClick(Sender: TObject);
begin
  editAction:=1;
end;

procedure TMain.SaveMIClick(Sender: TObject);
begin
  if (MyMap<>nil)and(SaveDialog.Execute()) then MyMap.SaveToFile(SaveDialog.Filename);
end;

procedure TMain.SizeHugeButtonClick(Sender: TObject);
begin
  dist:=8;
end;

procedure TMain.SizeLargeButtonClick(Sender: TObject);
begin
  dist:=5;
end;

procedure TMain.SizeNormalButtonClick(Sender: TObject);
begin
  dist:=3;
end;

procedure TMain.SizeSmallButtonClick(Sender: TObject);
begin
  dist:=2;
end;

procedure TMain.SizeTinyButtonClick(Sender: TObject);
begin
  dist:=1;
end;

procedure TMain.SmoothButtonClick(Sender: TObject);
begin
  EditAction:=4;
end;

procedure TMain.SquareButtonClick(Sender: TObject);
begin
  isCircle:=false;
end;

procedure TMain.SteepnessBarChange(Sender: TObject);
begin
  maxheight:=SteepnessBar.Position/100;
end;

procedure TMain.Tile0Click(Sender: TObject);
begin
  EditAction:=6;
  CurrentTile:=0;
end;

procedure TMain.Tile1Click(Sender: TObject);
begin
  EditAction:=6;
  CurrentTile:=1;
end;

procedure TMain.Tile2Click(Sender: TObject);
begin
  EditAction:=6;
  CurrentTile:=2;
end;

procedure TMain.Tile3Click(Sender: TObject);
begin
  EditAction:=6;
  CurrentTile:=3;
end;

procedure TMain.Tile4Click(Sender: TObject);
begin
  EditAction:=6;
  CurrentTile:=4;
end;

procedure TMain.Tile5Click(Sender: TObject);
begin
  EditAction:=6;
  CurrentTile:=5;
end;

procedure TMain.Tile6Click(Sender: TObject);
begin
  EditAction:=6;
  CurrentTile:=6;
end;

procedure TMain.Tile7Click(Sender: TObject);
begin
  EditAction:=6;
  CurrentTile:=7;
end;

procedure TMain.ViewportMIClick(Sender: TObject);
begin
  Config.ViewViewport:=not(Config.ViewViewport);
  GLContext.Visible:=Config.ViewViewport;
  ViewportMI.Checked:=Config.ViewViewport;
end;

procedure TMain.GLContextResize(Sender: TObject);
begin
  {$ifdef debug_l1}
  writeln('main: Resizing context to '+IntToStr(GLContext.Width)+'/'+IntToStr(GLContext.Height));
  {$endif}
  if GLContext.Height=0 then
   begin
    {$ifdef debug_l2}
    writeln(' main: Normalizing the context height');
    {$endif}
    GLContext.Height:=1;
   end                  else
    begin
    {$ifdef debug_l2}
    writeln(' main: Updating the viewport');
    {$endif}
    glViewport(0, 0, GLContext.Width,GLContext.Height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45.0,GLContext.Width/GLContext.Height,1,100000);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity;
   end;
  GLContext.Paint();
end;

procedure TMain.GridMIClick(Sender: TObject);
begin
     Config.showwire:=not(Config.showwire);
     if MyMap<>nil then
      begin
       MyMap.DrawGrid:=Config.showwire;
       GLContext.Paint();
      end;
     GridMI.Checked:=Config.showwire;
end;

procedure TMain.CallAfterConstruction(Sender:TObject);
begin
  NewMapDialog.AegisDir:=Config.AegisDir;
end;

procedure TMain.onStateChange(i: integer);
begin
  ProgressBar.Position:=i;
  Application.ProcessMessages();
end;


initialization
  {$I uMain.lrs}
end.
