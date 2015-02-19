unit uMath;

{$mode objfpc}{$H+}
{$inline off}

interface

uses gl;
type mat4=array[0..3] of array[0..3] of glFloat;
     vec3=array[0..2] of glFloat;
     vpa=array[0..3] of glInt;
     vec2i=array[0..1] of glInt;
     vec4=array[0..3] of glFLoat;

function RayHitsTriangle(m_vOrigin,m_vDirection,v0,v1,v2:vec3;var pOut:vec3):boolean;{inline;}
function RayHitsTriangleDist(m_vOrigin,m_vDirection,v0,v1,v2:vec3;var pOut:vec3;var dist:glFloat):boolean;{inline;}
function CreateRay(MouseX,MouseY:glInt;proj:mat4;viewport:vpa):vec3;{inline;}
function Normalize(findnormal:vec3):vec3;{inline;}
function dot(v,v2:vec3):glFloat;{inline;  }
function cross(v,v2:vec3):vec3;{inline;    }
operator -(a,b:vec3):vec3;{inline;         }
operator +(a,b:vec3):vec3;{inline;         }
operator *(a:glFloat;b:vec3):vec3;{inline; }
operator *(b:vec3;a:glFloat):vec3;{inline; }
operator *(vec:vec3;mat:mat4):vec3;{inline; }
operator *(a,b:mat4):mat4;{inline;          }
function MultiplyAsVector(vec:vec3;mat:mat4):vec3;{inline;}
function vector(xc,yc,zc:glFloat):vec3;{inline;            }
function vector(xc,yc,zc,tc:glFloat):vec4;{inline;          }
function Normal(a,b,c:vec3):vec3;{inline;                    }
procedure InvMatrix(src:mat4;var dst:mat4);{inline;           }

procedure LoadIdentity(var a:mat4);{inline;}
function RotateVect(vec:vec3;mat:mat4):vec3;{inline;}
function InverseRotateVect(vec:vec3;mat:mat4):vec3;{inline;}
function TranslateVect(vec:vec3;mat:mat4):vec3;{inline;}
function InverseTranslateVect(vec:vec3;mat:mat4):vec3;{inline;}
procedure SetRotationRadians(angles:vec3; var mat:mat4);{inline;}
procedure SetRotationDegrees(angles:vec3; var mat:mat4);{inline;}
procedure SetInverseRotationRadians(angles:vec3;var mat:mat4);{inline;}
procedure SetInverseRotationDegrees(angles:vec3; var mat:mat4);{inline;}
procedure SetTranslation(translation:vec3;var mat:mat4);{inline;}
procedure SetInverseTranslation(translation:vec3;var mat:mat4);{inline;}

implementation

function dot(v,v2:vec3):glFloat;{inline;}
begin
 Result:=v[0]*v2[0]+v[1]*v2[1]+v[2]*v2[2];
end;

function cross(v,v2:vec3):vec3;{inline;}
begin
 Result[0] := (v[2]*v2[1]) - (v[1]*v2[2]);
 Result[1] := (v[0]*v2[2]) - (v[2]*v2[0]);
 Result[2] := (v[1]*v2[0]) - (v[0]*v2[1]);
end;

operator -(a,b:vec3):vec3;{inline;      }
begin
 Result[0]:=a[0]-b[0];
 Result[1]:=a[1]-b[1];
 Result[2]:=a[2]-b[2];
end;

operator +(a,b:vec3):vec3;{inline;}
begin
 Result[0]:=a[0]+b[0];
 Result[1]:=a[1]+b[1];
 Result[2]:=a[2]+b[2];
end;

operator *(a:glFloat;b:vec3):vec3;{inline;}
begin
 Result[0]:=a*b[0];
 Result[1]:=a*b[1];
 Result[2]:=a*b[2]
end;

operator *(b:vec3;a:glFloat):vec3;{inline;}
begin
 Result[0]:=a*b[0];
 Result[1]:=a*b[1];
 Result[2]:=a*b[2]
end;

operator *(a,b:mat4):mat4;{inline;}
var x,y,k:integer;
begin
  for x:=0 to 3 do
   for y:=0 to 3 do
    begin
     Result[x][y]:=0;
     for k:=0 to 3 do Result[x][y]+=a[x][k]*b[k][y];
    end;
end;

operator *(vec:vec3;mat:mat4):vec3;{inline;}
begin
 result[0] := glFloat(vec[0]*mat[0][0] + vec[1]*mat[0][1] + vec[2]*mat[0][2] + mat[0][3]);
 result[1] := glFloat(vec[0]*mat[1][0] + vec[1]*mat[1][1] + vec[2]*mat[1][2] + mat[1][3]);
 result[2] := glFloat(vec[0]*mat[2][0] + vec[1]*mat[2][1] + vec[2]*mat[2][2] + mat[2][3]);
end;

function MultiplyAsVector(vec:vec3;mat:mat4):vec3;{inline;}
begin
 result[0] := glFloat(vec[0]*mat[0][0] + vec[1]*mat[0][1] + vec[2]*mat[0][2]{ + mat[0][3]});
 result[1] := glFloat(vec[0]*mat[1][0] + vec[1]*mat[1][1] + vec[2]*mat[1][2]{ + mat[1][3]});
 result[2] := glFloat(vec[0]*mat[2][0] + vec[1]*mat[2][1] + vec[2]*mat[2][2]{ + mat[2][3]});
end;

function vector(xc,yc,zc:glFloat):vec3;{inline;}
begin
     vector[0]:=xc;
     vector[1]:=yc;
     vector[2]:=zc;
end;

function vector(xc,yc,zc,tc:glFloat):vec4;{inline;}
begin
     vector[0]:=xc;
     vector[1]:=yc;
     vector[2]:=zc;
     vector[3]:=tc;
end;

function Normal(a,b,c:vec3):vec3;{inline;}
begin
     Result:=cross((b-a),(c-a));
end;

function Normalize(findnormal:vec3):vec3;{inline;}
var divider:glFloat;
begin
  divider:=sqrt(sqr(findnormal[0])+sqr(findnormal[1])+sqr(findnormal[2]));

  if divider=0 then exit;

  normalize[0] := findnormal[0] / divider;
  normalize[1] := findnormal[1] / divider;
  normalize[2] := findnormal[2] / divider;
end;

function CreateRay(MouseX,MouseY:glInt;proj:mat4;viewport:vpa):vec3;{inline;}
begin
  CreateRay[0]:=glFloat((2.0*(MouseX - viewport[0])/viewport[2]  - 1)/proj[0][0]);
  CreateRay[1]:=glFloat((-2.0*(MouseY - viewport[1])/viewport[3] + 1)/proj[1][1]);
  CreateRay[2]:=-1.0;
end;

function RayHitsTriangle(m_vOrigin,m_vDirection,v0,v1,v2:vec3;var pOut:vec3):boolean;{inline;}
var vNormal,vAux1,vAux2:vec3;
    b1,b2,b3,fDot,d,t:glFloat;
begin
  // get the triangle plane's normal and test for degenerate triangle or ray
  vAux1:= v1-v0;
  vAux2:= v2-v1;
  vNormal:=cross(vAux1,vAux2);
  if (vNormal[0]=0) and(vNormal[1]=0)and(vNormal[2]=0)or(m_vDirection[0]=0)and(m_vDirection[1]=0)and(m_vDirection[2]=0) then exit(false);
  // test for the correct facing, watch for NANs
  fDot := Dot(vNormal, m_vDirection);
  if(fDot>0) then
   begin
    fdot*=-1;
    vNormal[0]*=-1;
    vNormal[1]*=-1;
    vNormal[2]*=-1;
   end;

  // find the point's t and test for negative, watch for NANs
  // a*x + b*y + c*z = d

  d:=Dot(vNormal, v0);
  t:=d-Dot(vNormal,m_vOrigin);
  // the real t must be divided by dot which is always negative, this is done later
  if not(t<=0) then exit(false);

  // get the point and see if it is inside the triangle, using barycentric coords

  if fDot<>0 then pOut:= m_vOrigin+(t/fDot)*m_vDirection;

  vAux1:= pOut-v2;
  b1:=Dot(Cross(vAux2,vAux1),vNormal);
  vAux2:=v0-pOut;
  b2:=Dot(Cross(vAux2,vAux1),vNormal);
  vAux1:=v1-v0;
  b3:=Dot(Cross(vAux2,vAux1),vNormal);
  if ((b1<0)and(b2<0)and(b3<0))or((b1>0)and(b2>0)and(b3>0))then exit(true);
  exit(false);
end;

procedure InvMatrix(src:mat4;var dst:mat4);{inline;}
var i,j:byte;
begin
     //transpose-negate; only works for basic rotate/translate modelview
     for i:=0 to 3 do
      for j:=0 to 3 do
       dst[i][j]:=-src[j][i];
end;

function RayHitsTriangleDist(m_vOrigin,m_vDirection,v0,v1,v2:vec3;var pOut:vec3;var dist:glFloat):boolean;{inline;}
var vNormal,vAux1,vAux2:vec3;
    t,b1,b2,b3,fDot,d:glFloat;

begin
  // get the triangle plane's normal and test for degenerate triangle or ray
  vAux1:= v1-v0;
  vAux2:= v2-v1;
  vNormal:=cross(vAux1,vAux2);
  if (vNormal[0]=0)and(vNormal[1]=0)and(vNormal[2]=0)or(m_vDirection[0]=0)and(m_vDirection[1]=0)and(m_vDirection[2]=0) then exit(false);
  // test for the correct facing, watch for NANs
  fDot := Dot(vNormal, m_vDirection);

  // find the point's t and test for negative, watch for NANs
  // a*x + b*y + c*z = d

  d:=Dot(vNormal, v0);
  t:=d-Dot(vNormal,m_vOrigin);
  // the real t must be divided by dot which is always negative, this is done later
  if(not(t<=0)) then exit(false);

  // get the point and see if it is inside the triangle, using barycentric coords

  if fDot<>0 then
   begin
    pOut:= m_vOrigin+(t/fDot)*m_vDirection;
    dist:=t/fDot;
   end;

  vAux1:=pOut-v2;
  b1:=Dot(Cross(vAux2,vAux1),vNormal);
  vAux2:=v0-pOut;
  b2:=Dot(Cross(vAux2,vAux1),vNormal);
  vAux1:=v1-v0;
  b3:=Dot(Cross(vAux2,vAux1),vNormal);
  if ((b1<0)and(b2<0)and(b3<0))or((b1>0)and(b2>0)and(b3>0))then exit(true);
  Result:=false;
end;

procedure LoadIdentity(var a:mat4);{inline;}
var x,y:integer;
begin
     for x:=0 to 3 do
      for y:=0 to 3 do
       if x<>y then a[x][y]:=0
               else a[x][y]:=1;
end;

function RotateVect(vec:vec3;mat:mat4):vec3;{inline;}
begin
  Result[0] := vec[0] * mat[0][0] + vec[1] * mat[0][1] + vec[2] * mat[0][2];
  Result[1] := vec[0] * mat[1][0] + vec[1] * mat[1][1] + vec[2] * mat[1][2];
  Result[2] := vec[0] * mat[2][0] + vec[1] * mat[2][1] + vec[2] * mat[2][2];
end;

function InverseRotateVect(vec:vec3;mat:mat4):vec3;{inline;}
begin
  Result[0]:= vec[0] * mat[0][0] + vec[1] * mat[1][0] + vec[2] * mat[2][0];
  Result[1]:= vec[0] * mat[0][1] + vec[1] * mat[1][1] + vec[2] * mat[2][1];
  Result[2]:= vec[0] * mat[0][2] + vec[1] * mat[1][2] + vec[2] * mat[2][2];
end;

function TranslateVect(vec:vec3;mat:mat4):vec3;{inline;}
begin
  Result[0] := vec[0] + mat[0][3];
  Result[1] := vec[1] + mat[1][3];
  Result[2] := vec[2] + mat[2][3];
end;

function InverseTranslateVect(vec:vec3;mat:mat4):vec3;{inline;}
begin
  Result[0] := vec[0] - mat[0][3];
  Result[1] := vec[1] - mat[1][3];
  Result[2] := vec[2] - mat[2][3];
end;

procedure SetRotationRadians(angles:vec3; var mat:mat4);{inline;}
var srsp,crsp,cr,sr,cp,sp,cy,sy:glDouble;
begin
  cr := cos(angles[0]);
  sr := sin(angles[0]);
  cp := cos(angles[1]);
  sp := sin(angles[1]);
  cy := cos(angles[2]);
  sy := sin(angles[2]);

  mat[0][0] := cp*cy;
  mat[1][0] := cp*sy;
  mat[2][0] := -sp;
  mat[3][0] := 0;

  srsp := sr*sp;
  crsp := cr*sp;

  mat[0][1] := srsp*cy-cr*sy;
  mat[1][1] := srsp*sy+cr*cy;
  mat[2][1] := sr*cp;

  mat[0][2] := crsp*cy+sr*sy;
  mat[1][2] := crsp*sy-sr*cy;
  mat[2][2] := cr*cp;
end;

procedure SetRotationDegrees(angles:vec3; var mat:mat4);{inline;}
begin
  SetRotationRadians(vector(angles[0]*180/pi,angles[1]*180/pi,angles[2]*180/pi),mat);
end;

procedure SetInverseRotationRadians(angles:vec3;var mat:mat4);{inline;}
var srsp,crsp,cr,sr,cp,sp,cy,sy:glDouble;
begin
  cr := cos(angles[0]);
  sr := sin(angles[0]);
  cp := cos(angles[1]);
  sp := sin(angles[1]);
  cy := cos(angles[2]);
  sy := sin(angles[2]);

  mat[0][0] := cp*cy;
  mat[0][1] := cp*sy;
  mat[0][2] := -sp;

  srsp := sr*sp;
  crsp := cr*sp;

  mat[1][0] := srsp*cy-cr*sy;
  mat[1][1] := srsp*sy+cr*cy;
  mat[1][2] := sr*cp;

  mat[2][3] := crsp*cy+sr*sy;
  mat[2][3] := crsp*sy-sr*cy;
  mat[2][3] := cr*cp;
end;

procedure SetInverseRotationDegrees(angles:vec3; var mat:mat4);{inline;}
begin
  SetInverseRotationRadians(vector(angles[0]*180/pi,angles[1]*180/pi,angles[2]*180/pi),mat);
end;

procedure SetTranslation(translation:vec3;var mat:mat4);{inline;}
begin
  mat[0][3] := translation[0];
  mat[1][3] := translation[1];
  mat[2][3] := translation[2];
end;

procedure SetInverseTranslation(translation:vec3;var mat:mat4);{inline;}
begin
  mat[0][3] := -translation[0];
  mat[1][3] := -translation[1];
  mat[2][3] := -translation[2];
end;

end.

