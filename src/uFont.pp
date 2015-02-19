unit uFont;

{$i config.inc}
{$mode objfpc}{$H+}

interface

uses
  Windows,Classes, SysUtils,gl,glu;
Type Tfont=class(Tobject)
      public
       Constructor Create(dc:hDC;width:integer;face:string);
       procedure GotoXy(tx,ty:integer);
       procedure SetColor(tr,tg,tb:glFloat);
       procedure DrawText(s:string);
       procedure DrawText(s:string;tx,ty:integer;tr,tg,tb:glFloat);
       destructor Destroy();override;
       procedure StartDrawMode();
       procedure EndDrawMode();
      private
       viewport:array[0..3] of glint;
       w,x,y:glsizei;
       r,g,b:glFloat;
       base:gluint;
     end;

implementation

destructor Tfont.Destroy();
begin
 glDeleteLists(base,96);
 inherited Destroy();
end;

constructor Tfont.Create(dc:hDC;width:integer;face:string);
var font:hfont;
begin
  w:=width;
  base := glGenLists(96);
  font := CreateFont(-width,0,0,0,FW_NORMAL,0,0,0,ANSI_CHARSET,OUT_TT_PRECIS,CLIP_DEFAULT_PRECIS,ANTIALIASED_QUALITY,FF_DONTCARE or DEFAULT_PITCH,pchar(face));
  SelectObject(dc,font);
  wglUseFontBitmaps(dc,32,96,base);
  inherited Create();
end;
procedure Tfont.GotoXy(tx,ty:integer);
begin
 x:=tx;
 y:=ty;
end;
procedure Tfont.SetColor(tr,tg,tb:glFloat);
begin
 r:=tr;
 g:=tg;
 b:=tb;
end;

procedure Tfont.DrawText(s:string);
begin
 DrawText(s,x,y,r,g,b);
end;
procedure Tfont.DrawText(s:string;tx,ty:integer;tr,tg,tb:glFloat);
var i:integer;
begin
   glColor4f(tr,tg,tb,1);
   glRasterPos2f(tx,viewport[3]-ty-w);
   for i:=1 to length(s) do glCallList(base-32+byte(s[i]));
end;

procedure TFont.StartDrawMode();
begin
  glPushMatrix();
  
   glPushAttrib(GL_TRANSFORM_BIT);
   glGetIntegerv(GL_VIEWPORT, viewport);
   glMatrixMode(GL_PROJECTION);
   glPushMatrix();
   glLoadIdentity();
   
   gluOrtho2D(viewport[0],viewport[2],viewport[1],viewport[3]);
   glPopAttrib();
   
   glDisable(GL_TEXTURE_2D);
   glDisable(GL_LIGHTING);
   glDisable(GL_DEPTH_TEST);
   glLoadIdentity();
end;

procedure TFont.EndDrawMode();
begin
   glEnable(GL_DEPTH_TEST);
   glEnable(GL_LIGHTING);
   glEnable(GL_TEXTURE_2D);
   
   glPushAttrib(GL_TRANSFORM_BIT);
   glMatrixMode(GL_PROJECTION);
   glPopMatrix();
   glPopAttrib();
  glPopMatrix();
end;


end.


