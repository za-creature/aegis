{TModel}

procedure TModel.Draw();
var hj,j,i:integer;
    m:byte;
    rot,trans,anorm,avert:vec3;
    amat:mat4;
    alpha,t:single;
    src,dst:TKeyframe;
begin
  if self=nil then exit;

  t:=(TimePassed(TimeBase) div 10 mod MaxTime)/1000;
  //recalculate skeleton position
  for i:=0 to High(Joint) do
   begin
    //rotation
    j:=0;
    hj:=length(Joint[i].KeyFramesRotation);
    while (j<hj)and(Joint[i].KeyFramesRotation[j].time<t) do inc(j);

    if (j>0)and(j<hj) then
     begin
      src:=Joint[i].KeyFramesRotation[j-1];
      dst:=Joint[i].KeyFramesRotation[j];
      
      alpha:=(t-src.time)/(dst.time-src.time);
      
      rot:=src.data-alpha*(src.data-dst.data);
     end   else
     begin
      if j=hj then rot:=Joint[i].KeyFramesRotation[j-1].data
              else rot:=Joint[i].KeyFramesRotation[j].data;
     end;
    
    //translation
    j:=0;
    hj:=length(Joint[i].KeyFramesTranslation);
    while (j<hj)and(Joint[i].KeyFramesTranslation[j].time<t) do inc(j);

    if (j>0)and(j<hj) then
     begin
      src:=Joint[i].KeyFramesTranslation[j-1];
      dst:=Joint[i].KeyFramesTranslation[j];

      alpha:=(t-src.time)/(dst.time-src.time);

      trans:=src.data-alpha*(src.data-dst.data);
     end   else
     begin
      if j=hj then trans:=Joint[i].KeyFramesTranslation[j-1].data
              else trans:=Joint[i].KeyFramesTranslation[j].data;
     end;

    LoadIdentity      (amat);
    SetRotationRadians(rot,amat);
    SetTranslation    (trans,amat);
    
    if i=0 then Joint[i].AbsoluteMatrix:=Joint[i].RelativeMatrix
           else Joint[i].AbsoluteMatrix:=Joint[Joint[i].parent].AbsoluteMatrix*Joint[i].RelativeMatrix;

    Joint[i].AbsoluteMatrix:=Joint[i].AbsoluteMatrix*amat;
   end;

  for i:=0 to High(Mesh) do
   begin
    m:=Mesh[i].MaterialIndex;
    glMaterialf(GL_FRONT_AND_BACK,GL_SHININESS,Material[m].Shininess);
    glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT,Material[m].Ambient);
    glMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR,Material[m].Specular);
    glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE,Material[m].Diffuse);
    glMaterialfv(GL_FRONT_AND_BACK,GL_EMISSION,Material[m].Emissive);

    if Material[m].TexID<>nil then glBindTexture(GL_TEXTURE_2D,Material[m].TexID.Handle);

    glBegin(GL_TRIANGLES);
     for j:=0 to High(Mesh[i].VertexArray) do
      begin
       amat:=Joint[Mesh[i].BoneIndexArray[j]].AbsoluteMatrix;
       glTexCoord2fv(@Mesh[i].TexCoordArray[j]);
       anorm:=MultiplyAsVector(vec3(Mesh[i].NormalArray[j]),amat);
       //anorm:=vec3(Mesh[i].NormalArray[j]);
       avert:=vec3(Mesh[i].VertexArray[j])*amat;
       glNormal3fv(@anorm);
       glVertex3fv(@avert);
      end;
    glEnd();
   end;
end;

procedure TModel.LoadFromFile(filename:ansistring);
var ext:ansistring;
begin
     ext:=ExtractFileExt(filename);
     if ext='.ms3d' then LoadFromMS3D(filename);
end;

procedure TModel.LoadFromMS3D(filename:ansistring);
var header:MS3DHeader;
    v:MS3DVertex;
    t:MS3DTriangle;
    m:MS3DMaterial;
    c,i,f,j,k:integer;
    a:byte;
    normal,_vertex:array[0..2] of glFloat;
    texcoord:array[0..1] of glFloat;
    name:array[0..31] of char;
    //temp data
    tmp,NumVertices:word;
    Vertex:array of TVertex;
    NumTriangles:word;
    Triangle:array of TTriangle;
    Joints:array of MS3DJoint;
    AnimationFPS,CurrentTime:single;
    TotalFrames:integer;
    amat:mat4;
    cd:ansistring;
begin
  cd:=GetCurrentdir();
  SetCurrentDir(ExtractFilePath(filename));

  f:=fileopen(filename,fmOpenRead);
  fileread(f,header,sizeof(header));
  if header.m_id<>'MS3D000000' then exit;//not a ms3d
  if (header.m_version<3)or(header.m_version>4)then exit; //unsupported version
  //vertices
  fileread(f,NumVertices,2);
  setLength(Vertex,NumVertices);
  for i:=0 to length(Vertex)-1 do
   begin
    fileread(f,v,sizeof(MS3DVertex));
    Vertex[i].boneID:=v.m_BoneID;
    Vertex[i].Location:=v.m_vertex;
   end;
  //triangles
  fileread(f,NumTriangles,2);
  setLength(Triangle,NumTriangles);
  for i:=0 to length(Triangle)-1 do
   begin
    fileread(f,t,sizeof(MS3DTriangle));
    Triangle[i].Normals:=t.m_VertexNormals;
    Triangle[i].Indices:=t.m_VertexIndices;
    Triangle[i].TexCoords[0]:=t.m_s;
    Triangle[i].TexCoords[1][0]:=glFloat(1.0-t.m_t[0]);
    Triangle[i].TexCoords[1][1]:=glFloat(1.0-t.m_t[1]);
    Triangle[i].TexCoords[1][2]:=glFloat(1.0-t.m_t[2]);
   end;
  //meshes
  fileread(f,tmp,2);
  setLength(Mesh,tmp);
  for i:=0 to length(Mesh)-1 do
   begin
    fileread(f,a,1);//flags ignored
    fileread(f,name,32);//name ignored;
    fileread(f,Mesh[i].NumTriangles,2);
    setLength(Mesh[i].TriangleIndices,Mesh[i].NumTriangles);
    for j:=0 to Mesh[i].NumTriangles-1 do
     fileread(f,Mesh[i].TriangleIndices[j],2);
    fileread(f,Mesh[i].materialIndex,1);
   end;
  //materials
  fileread(f,tmp,2);
  setLength(Material,tmp);
  for i:=0 to length(Material)-1 do
   begin
    fileread(f,m,sizeof(MS3DMaterial));
    Material[i].Ambient:=m.m_Ambient;
    Material[i].Diffuse:=m.m_Diffuse;
    Material[i].Specular:=m.m_Specular;
    Material[i].Emissive:=m.m_Emissive;
    Material[i].Texture:=m.m_texture;
    Material[i].Shininess:=m.m_shininess;
    if Material[i].Texture<>'' then
     Material[i].TexId:=FOwner.GetResource(Material[i].Texture) as TTexture;
   end;
  //keyframes
  FileRead(f,AnimationFPS,4);
  FileRead(f,CurrentTime,4);
  FileRead(f,TotalFrames,4);
  MaxTime:=Round((TotalFrames*1000)/AnimationFPS);
  
  FileRead(f,tmp,2);
  setLength(Joints,tmp);
  setLength(Joint,tmp);
  for i:=0 to High(Joints) do
   begin
    FileRead(f,Joints[i],sizeof(MS3DJoint));
    setLength(Joint[i].KeyFramesRotation,   Joints[i].numKeyFramesRot);
    setLength(Joint[i].KeyFramesTranslation,Joints[i].numKeyFramesTrans);
    FileRead(f,Joint[i].KeyFramesRotation   [0],SizeOf(TKeyFrame)*Length(Joint[i].KeyFramesRotation   ));
    FileRead(f,Joint[i].KeyFramesTranslation[0],SizeOf(TKeyFrame)*Length(Joint[i].KeyFramesTranslation));
   end;
   
  //build a tree
  
  //skip the need for a hash table
  for i:=1 to High(Joint) do
   for j:=0 to i-1 do
    if Joints[j].Name=Joints[i].ParentName then
     begin
      Joint[i].parent:=j;
      break;
     end;

  for i:=0 to high(Joint) do
   begin
    LoadIdentity(Joint[i].RelativeMatrix);
    SetRotationRadians(Joints[i].rotation,Joint[i].RelativeMatrix);
    SetTranslation    (Joints[i].position,Joint[i].RelativeMatrix);
    if i=0 then Joint[i].AbsoluteMatrix:=Joint[i].RelativeMatrix
           else Joint[i].AbsoluteMatrix:=Joint[Joint[i].parent].AbsoluteMatrix*Joint[i].RelativeMatrix;
   end;

  fileclose(f);

  //Vertex Arrays
  for i:=0 to length(Mesh)-1 do
   begin
    c:=0;
    setLength(Mesh[i].VertexArray,   Mesh[i].NumTriangles*3);
    setLength(Mesh[i].NormalArray,   Mesh[i].NumTriangles*3);
    setLength(Mesh[i].TexcoordArray, Mesh[i].NumTriangles*3);
    setLength(Mesh[i].BoneIndexArray,Mesh[i].NumTriangles*3);
    
    for j:=0 to length(Mesh[i].TriangleIndices)-1 do
     for k:=2 downto 0 do
      begin
       //switch coordinate system
       texcoord[0]:=  Triangle[Mesh[i].TriangleIndices[j]].Texcoords[0][k];
       texcoord[1]:=1-Triangle[Mesh[i].TriangleIndices[j]].Texcoords[1][k];
       //setup basic geometric values
       Mesh[i].BoneIndexArray[c]:=Vertex[Triangle[Mesh[i].TriangleIndices[j]].Indices[k]].BoneID;
       Mesh[i].VertexArray[c]:=TPoint3D(Vertex[Triangle[Mesh[i].TriangleIndices[j]].Indices[k]].Location);
       Mesh[i].NormalArray[c]:=TPoint3D(Triangle[Mesh[i].TriangleIndices[j]].Normals[k]);
       Mesh[i].TexCoordArray[c]:=TPoint2D(texcoord);
       //transform geometry according to skeleton
       if Mesh[i].BoneIndexArray[c]<>255 then
        begin
         amat:=Joint[Mesh[i].BoneIndexArray[c]].AbsoluteMatrix;
         Mesh[i].VertexArray[c]:=TPoint3D(InverseTranslateVect(vec3(Mesh[i].VertexArray[c]),amat));
         Mesh[i].VertexArray[c]:=TPoint3D(InverseRotateVect(vec3(Mesh[i].VertexArray[c]),amat));
         Mesh[i].NormalArray[c]:=TPoint3D(InverseRotateVect(vec3(Mesh[i].NormalArray[c]),amat));
        end;
       inc(c);
      end;
   end;
  //Free Temporary Data
  setLength(Vertex,0);
  setLength(Triangle,0);
  setLength(Joints,0);
  for i:=0 to length(Mesh)-1 do
   setLength(Mesh[i].TriangleIndices,0);
   
  TimeStamp(TimeBase);
   
  SetCurrentDir(cd);
end;

procedure TModel.doFree();
var i:integer;
begin
  //free meshes
  for i:=0 to High(Mesh) do
   begin
    setLength(Mesh[i].VertexArray,0);
    setLength(Mesh[i].NormalArray,0);
    setLength(Mesh[i].TexCoordArray,0);
    setLength(Mesh[i].BoneIndexArray,0);
   end;
  setLength(Mesh,0);
  //free keyframes
  for i:=0 to High(Joint) do
   begin
    setLength(Joint[i].KeyFramesRotation,0);
    setLength(Joint[i].KeyFramesTranslation,0);
   end;
  setLength(Joint,0);
  //free materials
  for i:=0 to High(Material) do
   if Material[i].TexID<>nil then Material[i].TexID.MarkUnused();
  setLength(Material,0);
end;
