unit uglview;

{$i config.inc}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  OpenGLContext, uIO64, GL, GLu, glext, ExtCtrls, uMath;

type

  { Tglview }

  Tglview = class(TForm)
    GLContext: TOpenGLControl;
    IdleTimer: TIdleTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure GLContextMouseDown(Sender: TOBject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GLContextMouseLeave(Sender: TObject);
    procedure GLContextMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure GLContextMouseUp(Sender: TOBject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GLContextMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure GLContextMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure GLContextPaint(Sender: TObject);
    procedure GLContextResize(Sender: TObject);
    procedure IdleTimerTimer(Sender: TObject);
  private
    { private declarations }
  public
    IO64:TIO64;
    Config:TConfig;
    MyModel:TModel;
    sx,sy:integer;
    mdown:boolean;
    XAngle,YAngle,XPos,YPos,ZPos,ZoomLevel:glFloat;
    { public declarations }
  end;

var
  glview: Tglview;

implementation

{ Tglview }

procedure Tglview.FormCreate(Sender: TObject);

  function cdup(a:string):string;
  var i:integer;
  begin
    i:=length(a)-1;
    while (i>0)and(a[i]<>DirectorySeparator) do dec(i);
     if i>0 then Result:=Copy(a,1,i)
           else Result:=a;
  end;
  
begin
  GLContext.MakeCurrent();
  Config:=TConfig.Create('../var/conf/glview.ini');
  Config.Load();
  Config.AegisDir:=cdup(ExtractFilePath(ParamStr(0)));
  IO64:=TIO64.Create(Config);

  InitOpenGL();
  
  IO64.LoadSkyBox('default.skybox');
  IO64.AddLightSource().LoadPropertiesFromFile('sun.xml');

  MyModel:=IO64.GetResource('Model.ms3d') as TModel;

  ZoomLevel:=100;
  XAngle:=0;
  YAngle:=0;
  IO64.Camera.Rotation:=vector(XAngle,YAngle,0);
  IO64.Camera.Position:=vector(0,0,ZoomLevel)*IO64.Camera.ModelViewMatrix;

  glClearColor(0,0,0,0);
  glColor4f(1,1,1,1);

  GLContextResize(self);
  IdleTimer.Enabled:=true;
end;

procedure Tglview.FormDestroy(Sender: TObject);
begin
  IO64.Free();
  Config.Save();
  Config.Free();
end;

procedure Tglview.GLContextMouseDown(Sender: TOBject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  sx:=x;
  sy:=y;
  mdown:=true;
end;

procedure Tglview.GLContextMouseLeave(Sender: TObject);
begin
  mdown:=false;
end;

procedure Tglview.GLContextMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if mdown then
   begin
    XAngle+=(y-sy);
    YAngle+=(x-sx);
    IO64.Camera.Rotation:=vector(XAngle,YAngle,0);
    IO64.Camera.Position:=vector(0,0,ZoomLevel)*IO64.Camera.ModelViewMatrix;
    
    sx:=x;
    sy:=y;
   end;
end;

procedure Tglview.GLContextMouseUp(Sender: TOBject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  mdown:=false;
end;

procedure Tglview.GLContextMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  ZoomLevel+=10;
  
  IO64.Camera.Rotation:=vector(XAngle,YAngle,0);
  IO64.Camera.Position:=vector(0,0,ZoomLevel)*IO64.Camera.ModelViewMatrix;

  Handled:=true;
end;

procedure Tglview.GLContextMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  ZoomLevel-=10;

  IO64.Camera.Rotation:=vector(XAngle,YAngle,0);
  IO64.Camera.Position:=vector(0,0,ZoomLevel)*IO64.Camera.ModelViewMatrix;

  Handled:=true;
end;

procedure Tglview.GLContextPaint(Sender: TObject);
begin
  glClear(GL_DEPTH_BUFFER_BIT);
  
  IO64.Draw();

  MyModel.Draw();
  
  IO64.DrawLensFlare();

  glFlush();
  
  GLContext.SwapBuffers();
end;

procedure Tglview.GLContextResize(Sender: TObject);
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
  GLContext.MakeCurrent();
  GLContext.Paint();
end;

procedure Tglview.IdleTimerTimer(Sender: TObject);
begin
  GLContext.Paint();
end;

initialization
  {$I uglview.lrs}

end.

