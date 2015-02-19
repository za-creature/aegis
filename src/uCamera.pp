unit uCamera;

{$mode objfpc}{$H+}

interface

uses
  gl,uMath;

type
  TRay=record
   Origin:vec3;
   Direction:vec3;
  end;

  { TCamera }

  TCamera=class(TObject)
   private
    rot,origin:vec3;
    mm,m:mat4;
    procedure SetOrigin(const AValue: vec3);
    procedure SetRotation(const AValue: vec3);
   public
    constructor Create();
    procedure Tilt(vax,vay,vaz:glFloat);
    {procedure MoveForward(speed:glFloat);
    procedure MoveBackward(speed:glFloat);
    procedure MoveLeft(speed:glFloat);
    procedure MoveRight(speed:glFloat);}
    procedure Move(x,y,speed:glFloat);
    procedure ZoomIn(speed:glFloat);
    procedure ZoomOut(speed:glFloat);
    
    procedure Translate(vpx,vpy,vpz:glFloat);
    procedure SetViewPort(vpx,vpy,vpz:glFloat;vax,vay,vaz:glFloat);
    function CreateRay(x,y:integer):TRay;
    
    property Rotation:vec3 read rot write SetRotation;
    property Position:vec3 read origin write SetOrigin;
    property MoveMatrix:mat4 read mm;
    property ModelviewMatrix:mat4 read m;
  end;

implementation

procedure TCamera.SetOrigin(const AValue: vec3);
begin
  origin:=avalue;
end;

procedure TCamera.SetRotation(const AValue: vec3);
begin
  rot:=avalue;
  
  glPushMatrix();
   glLoadIdentity();
   glrotatef(rot[1],0.0,1.0,0.0);
   //glrotatef(rot[2],0.0,0.0,1.0);
   glGetFloatv(GL_MODELVIEW_MATRIX,@mm);

   glLoadIdentity();
   glrotatef(rot[0],1.0,0.0,0.0);
   glrotatef(rot[1],0.0,1.0,0.0);
   glrotatef(rot[2],0.0,0.0,1.0);
   glGetFloatv(GL_MODELVIEW_MATRIX,@m);
  glPopMatrix();
end;

constructor TCamera.Create();
begin
 inherited Create();
end;

procedure TCamera.Tilt(vax,vay,vaz:glFloat);
begin
  Rotation:=Rotation+vector(vax,vay,vaz);
end;

procedure TCamera.ZoomIn(speed:glFloat);
begin
    origin+=4.8*vector(0,0,-speed)*m;
end;

procedure TCamera.ZoomOut(speed:glFloat);
begin
    origin+=4.8*vector(0,0,speed)*m;
end;

{procedure TCamera.MoveForward(speed:glFloat);
begin
    origin+=vector(0,0,-speed)*mm;
end;
procedure TCamera.MoveBackward(speed:glFloat);

begin
    origin+=vector(0,0,speed)*mm;
end;
procedure TCamera.MoveLeft(speed:glFloat);
begin
    origin+=vector(-speed,0,0)*mm;
end;
procedure TCamera.MoveRight(speed:glFloat);
begin
    origin+=vector(speed,0,0)*mm;
end;}

procedure TCamera.Move(x,y,speed:glFloat);
begin
    origin+=vector(x*speed,0,y*speed)*mm;
end;

procedure TCamera.Translate(vpx,vpy,vpz:glFloat);
begin
  Position:=Position+vector(vpx,vpy,vpz);
end;

procedure TCamera.SetViewPort(vpx,vpy,vpz:glFloat;vax,vay,vaz:glFloat);
begin
 Translate(vpx,vpy,vpz);
 Tilt(vax,vay,vaz);
end;

function TCamera.CreateRay(x,y:integer):TRay;
var proj:mat4;
    viewport:vpa;
begin
    Result.Origin:=Origin;
    glGetFloatv(GL_PROJECTION_MATRIX, @proj);
    glGetIntegerv(GL_VIEWPORT,@viewport);
    Result.Direction:=Normalize(uMath.CreateRay(x,y,proj,viewport)*ModelViewMatrix);
end;

end.

