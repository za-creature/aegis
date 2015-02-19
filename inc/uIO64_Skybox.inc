{TSkybox}

procedure TSkyBox.LoadFromFile(filename:ansistring);
var f:TXMLDocument;
    c:TDOMNodeList;
    i:integer;
    cd,src,face:ansistring;
begin
  cd:=GetCurrentDir();
  SetCurrentDir(ExtractFilePath(filename));

  try
   ReadXMLFile(f,filename);
  except
  end;
  try
   width:=StrToInt(f.DocumentElement.Attributes.GetNamedItem('width').NodeValue);
   height:=StrToInt(f.DocumentElement.Attributes.GetNamedItem('height').NodeValue);
   depth:=StrToInt(f.DocumentElement.Attributes.GetNamedItem('depth').NodeValue);
  except
   f.Free();
   exit();
  end;

  c:=f.DocumentElement.ChildNodes;

  for i:=0 to c.Count-1 do
   with c.Item[i] do
    begin
     if NodeName='face' then
      begin
       if Attributes.GetNamedItem('position')<>nil then face:=Attributes.GetNamedItem('position').NodeValue;
       if Attributes.GetNamedItem('src')<>nil then src:=Attributes.GetNamedItem('src').NodeValue;
       if face='front' then FrontFace:=FOwner.GetResource(src) as TTexture;
       if face='back' then BackFace:=FOwner.GetResource(src) as TTexture;
       if face='left' then LeftFace:=FOwner.GetResource(src) as TTexture;
       if face='right' then RightFace:=FOwner.GetResource(src) as TTexture;
       if face='top' then TopFace:=FOwner.GetResource(src) as TTexture;
       if face='bottom' then BottomFace:=FOwner.GetResource(src) as TTexture;
      end;
    end;

  //release used structures
  c.Free();
  f.Free();

  DrawDepth:=50;
  //restore state
  SetCurrentDir(cd);
end;

procedure TSkyBox.doFree();
begin
  FrontFace.MarkUnused();
  BackFace.MarkUnused();
  LeftFace.MarkUnused();
  RightFace.MarkUnused();
  TopFace.MarkUnused();
  BottomFace.MarkUnused();
end;

procedure TSkyBox.SetDrawDepth(const AValue: glFloat);

  function bmax(a,b:integer):integer;{inline;}
  begin
    if b>a then exit(b);
    Result:=a;
  end;

var max:integer;
begin
  FDrawDepth:=AValue;
  
  max:=bmax(bmax(width,height),bmax(width,depth));
  
  w:=glFloat(width/max*FDrawDepth/2);
  h:=glFloat(height/max*FDrawDepth/2);
  d:=glFloat(depth/max*FDrawDepth/2);
end;

procedure TSkyBox.Draw();
var p:vec3;
begin
  p:=FOwner.Camera.Position;
  // make the skybox relative to the camera position
  SkyboxVertex[0][0] := p[0]-w;
  SkyboxVertex[0][1] := p[1]+h;
  SkyboxVertex[0][2] := p[2]-d;

  SkyboxVertex[1][0] := p[0]+w;
  SkyboxVertex[1][1] := p[1]+h;
  SkyboxVertex[1][2] := p[2]-d;

  SkyboxVertex[2][0] := p[0]+w;
  SkyboxVertex[2][1] := p[1]-h;
  SkyboxVertex[2][2] := p[2]-d;

  SkyboxVertex[3][0] := p[0]-w;
  SkyboxVertex[3][1] := p[1]-h;
  SkyboxVertex[3][2] := p[2]-d;

  SkyboxVertex[4][0] := p[0]-w;
  SkyboxVertex[4][1] := p[1]+h;
  SkyboxVertex[4][2] := p[2]+d;

  SkyboxVertex[5][0] := p[0]+w;
  SkyboxVertex[5][1] := p[1]+h;
  SkyboxVertex[5][2] := p[2]+d;

  SkyboxVertex[6][0] := p[0]+w;
  SkyboxVertex[6][1] := p[1]-h;
  SkyboxVertex[6][2] := p[2]+d;

  SkyboxVertex[7][0] := p[0]-w;
  SkyboxVertex[7][1] := p[1]-h;
  SkyboxVertex[7][2] := p[2]+d;


  glDisable(GL_DEPTH_TEST);
  glDisable(GL_LIGHTING);

  glPushMatrix();
   glColor3f(1,1,1);
   
   //Front
   glBindTexture(GL_TEXTURE_2D,FrontFace.Handle);
   glBegin(GL_QUADS);
    glTexCoord2f(0,0);
    glVertex3fv(@SkyboxVertex[0]);
    glTexCoord2f(1,0);
    glVertex3fv(@SkyboxVertex[1]);
    glTexCoord2f(1,1);
    glVertex3fv(@SkyboxVertex[2]);
    glTexCoord2f(0,1);
    glVertex3fv(@SkyboxVertex[3]);
   glEnd();

   //Back
   glBindTexture(GL_TEXTURE_2D,BackFace.Handle);
   glBegin(GL_QUADS);
    glTexCoord2f(0,0);
    glVertex3fv(@SkyboxVertex[5]);
    glTexCoord2f(1,0);
    glVertex3fv(@SkyboxVertex[4]);
    glTexCoord2f(1,1);
    glVertex3fv(@SkyboxVertex[7]);
    glTexCoord2f(0,1);
    glVertex3fv(@SkyboxVertex[6]);
   glEnd();

   //Left
   glBindTexture(GL_TEXTURE_2D,LeftFace.Handle);
   glBegin(GL_QUADS);
    glTexCoord2f(0,0);
    glVertex3fv(@SkyboxVertex[4]);
    glTexCoord2f(1,0);
    glVertex3fv(@SkyboxVertex[0]);
    glTexCoord2f(1,1);
    glVertex3fv(@SkyboxVertex[3]);
    glTexCoord2f(0,1);
    glVertex3fv(@SkyboxVertex[7]);
   glEnd();
   
   //Right
   glBindTexture(GL_TEXTURE_2D,RightFace.Handle);
   glBegin(GL_QUADS);
    glTexCoord2f(0,0);
    glVertex3fv(@SkyboxVertex[1]);
    glTexCoord2f(1,0);
    glVertex3fv(@SkyboxVertex[5]);
    glTexCoord2f(1,1);
    glVertex3fv(@SkyboxVertex[6]);
    glTexCoord2f(0,1);
    glVertex3fv(@SkyboxVertex[2]);
   glEnd();

   //Top
   glBindTexture(GL_TEXTURE_2D,TopFace.Handle);
   glBegin(GL_QUADS);
    glTexCoord2f(0,1);
    glVertex3fv(@SkyboxVertex[4]);
    glTexCoord2f(1,1);
    glVertex3fv(@SkyboxVertex[5]);
    glTexCoord2f(1,0);
    glVertex3fv(@SkyboxVertex[1]);
    glTexCoord2f(0,0);
    glVertex3fv(@SkyboxVertex[0]);
   glEnd();
   
   //Bottom
   glBindTexture(GL_TEXTURE_2D,BottomFace.Handle);
   glBegin(GL_QUADS);
    glTexCoord2f(0,0);
    glVertex3fv(@SkyboxVertex[3]);
    glTexCoord2f(1,0);
    glVertex3fv(@SkyboxVertex[2]);
    glTexCoord2f(1,1);
    glVertex3fv(@SkyboxVertex[6]);
    glTexCoord2f(0,1);
    glVertex3fv(@SkyboxVertex[7]);
   glEnd();

  glPopMatrix();

  glEnable(GL_LIGHTING);
  glEnable(GL_DEPTH_TEST);
end;
