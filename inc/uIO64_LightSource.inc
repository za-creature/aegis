{TLightSource}

constructor TLightSource.Create(AOwner:TIO64);
var i:integer;
begin
  inherited Create();
  FOwner:=AOwner;
  
  radialblur:=FOwner.GetResource('radial.bmp') as TTexture;

  FEnabled:=true;
  id:=-1;
end;

procedure TLightSource.LoadPropertiesFromFile(AFilename: ansistring);
var f:TXMLDocument;
    ctype,cd:ansistring;
    c:TDOMNodeList;
    x,y,z,r,g,b:glFloat;
    i:integer;
begin
  if not fileexists(AFilename) then AFilename:=FOwner.Config.AegisDir+'media'+DirectorySeparator+'lightsource'+DirectorySeparator+AFilename;
  cd:=GetCurrentDir();
  SetCurrentDir(ExtractFilePath(AFilename));
  try
   ReadXMLFile(f,AFilename);
  except
  end;
  
  c:=f.DocumentElement.ChildNodes;
  
  for i:=0 to c.Count-1 do
   begin
    with c.Item[i] do
     begin
      if NodeName='position' then
       begin
        x:=glFloat(StrToFloat(Attributes.GetNamedItem('x').NodeValue));
        y:=glFloat(StrToFloat(Attributes.GetNamedItem('y').NodeValue));
        z:=glFloat(StrToFloat(Attributes.GetNamedItem('z').NodeValue));
        Position:=vector(x,y,z,1);
       end;
      if NodeName='color' then
       begin
        x:=glFloat(StrToFloat(Attributes.GetNamedItem('r').NodeValue));
        y:=glFloat(StrToFloat(Attributes.GetNamedItem('g').NodeValue));
        z:=glFloat(StrToFloat(Attributes.GetNamedItem('b').NodeValue));
        ctype:=Attributes.GetNamedItem('type').NodeValue;
        if ctype='ambient' then Ambient:=vector(x,y,z,1);
        if ctype='diffuse' then Diffuse:=vector(x,y,z,1);
        if ctype='specular' then Specular:=vector(x,y,z,1);
       end;
      if NodeName='spot_exponent' then
       begin
        x:=glFloat(StrToFloat(Attributes.GetNamedItem('value').NodeValue));
        SpotExponent:=x;
       end;
      if NodeName='spot_direction' then
       begin
        x:=glFloat(StrToFloat(Attributes.GetNamedItem('x').NodeValue));
        y:=glFloat(StrToFloat(Attributes.GetNamedItem('y').NodeValue));
        z:=glFloat(StrToFloat(Attributes.GetNamedItem('z').NodeValue));
        SpotDirection:=Vector(x,y,z);
       end;
      if NodeName='spot_cutoff' then
       begin
        x:=glFloat(StrToFloat(Attributes.GetNamedItem('value').NodeValue));
        SpotCutoff:=x;
       end;
      if NodeName='attenuation' then
       begin
        x:=glFloat(StrToFloat(Attributes.GetNamedItem('value').NodeValue));
        ctype:=Attributes.GetNamedItem('type').NodeValue;
        if ctype='constant' then ConstantAttenuation:=x;
        if ctype='linear' then LinearAttenuation:=x;
        if ctype='quadratic' then QuadraticAttenuation:=x;
       end;
      if NodeName='lens_flare' then
       begin
        ctype:=Attributes.GetNamedItem('value').NodeValue;
        if ctype='true' then LensFlare:=Attributes.GetNamedItem('src').NodeValue;
       end;
      if NodeName='haze' then
       begin
        ctype:=Attributes.GetNamedItem('value').NodeValue;
        Haze:=ctype='true';
       end;
      if NodeName='is_true_light' then
       begin
        ctype:=Attributes.GetNamedItem('value').NodeValue;
        isTrueLight:=ctype='true';
       end;
     end;
   end;
  
  c.Free();
  
  f.Free();
  SetCurrentDir(cd);
end;

procedure TLightSource.SavePropertiesToFile(AFilename: ansistring);
begin

end;

procedure TLightSource.Free();
begin
  isTrueLight:=false;
  //release resources
  radialblur.MarkUnused();
  //free
  inherited Free();
end;

procedure TLightSource.Draw();
var s:vec3;
    scale:glFloat;
    dx,dy:gluint;
begin
  if (FEnabled)and(hit) then
   begin
    if haze then
     begin
      s:=FOwner.Camera.Position-pvec3(@pos)^;
      scale:=sqrt(sqr(s[0])+sqr(s[1])+sqr(s[2]));
      //when this happens, the object and light source collide and thus, the
      //light source is way past the near clipping plane
      if scale=0 then exit;
      
      //this should be rewritten to be perspective-correct
      scale:=100000/scale;
      glColor3fv(spec);
      glBindTexture(GL_TEXTURE_2D,radialblur.Handle);
      glBegin(GL_QUADS);
       gltexcoord2f(0,0);
       glVertex3f(rx-scale,ry+scale,0);
       gltexcoord2f(1,0);
       glVertex3f(rx+scale,ry+scale,0);
       gltexcoord2f(1,1);
       glVertex3f(rx+scale,ry-scale,0);
       gltexcoord2f(0,1);
       glVertex3f(rx-scale,ry-scale,0);
      glEnd();
     end;
    if FInternalFlare<>nil then
     begin
      dx:=gluint(trunc(rx));
      dy:=gluint(trunc(ry));
      FInternalFlare.Draw(dx,dy);
     end;
   end;
end;

procedure TLightSource.Loop();
var SampleCount:integer;
begin
     if (FEnabled)and((FInternalFlare<>nil)or(haze)) then
      begin
       //check if hit

       if FOwner.Config.QueriesEnabled then
        begin
         glBeginQueryARB(GL_SAMPLES_PASSED_ARB,FOwner.MyQuery);

          glBegin(GL_POINTS);
           glVertex3fv(pos);
          glEnd();

         glEndQueryARB(GL_SAMPLES_PASSED_ARB);

         glGetQueryObjectuivARB(FOwner.MyQuery, GL_QUERY_RESULT_ARB, @sampleCount);
         hit:=Samplecount>0;
        end
       else hit:=false;
       //if hit then compute projection
       if hit then
        begin
         glRenderMode(GL_FEEDBACK);

          glBegin(GL_POINTS);
           glVertex3fv(pos);
          glEnd();

         glRenderMode(GL_RENDER);

         rx:=FOwner.LightOut[1];
         ry:=FOwner.LightOut[2];
        end;
      end;
end;

procedure TLightSource.SetAmbient(v:vec4);
begin
     amb:=v;
     if IsTrueLight then glLightfv(GL_LIGHT0+id,GL_AMBIENT,amb);
end;

procedure TLightSource.SetConstantAttenuation(const AValue: glFloat);
begin
  FConstantAttenuation:=AValue;
  if IsTrueLight then glLightfv(GL_LIGHT0+id,GL_CONSTANT_ATTENUATION,@FConstantAttenuation);
end;

procedure TLightSource.SetDiffuse(v:vec4);
begin
     diff:=v;
     if IsTrueLight then glLightfv(GL_LIGHT0+id,GL_DIFFUSE,diff);
end;

procedure TLightSource.SetLensFlare(const AValue: ansistring);
begin
  if FLensFlare=AValue then exit;
  FInternalFlare.MarkUnused();
  FLensFlare:=AValue;
  FInternalFlare:=FOwner.GetResource(FLensFlare) as TLensFlare;
end;

procedure TLightSource.SetLinearAttenuation(const AValue: glFloat);
begin
  FLinearAttenuation:=AValue;
  if IsTrueLight then glLightfv(GL_LIGHT0+id,GL_LINEAR_ATTENUATION,@FLinearAttenuation);
end;

procedure TLightSource.SetQuadraticAttenuation(const AValue: glFloat);
begin
  FQuadraticAttenuation:=AValue;
  if IsTrueLight then glLightfv(GL_LIGHT0+id,GL_QUADRATIC_ATTENUATION,@FQuadraticAttenuation);
end;

procedure TLightSource.SetSpecular(v:vec4);
begin
     spec:=v;
     if IsTrueLight then glLightfv(GL_LIGHT0+id,GL_SPECULAR,spec);
end;

procedure TLightSource.SetIsTrueLight(v:boolean);
begin
     //only change when needed
     if v<>truelight then
      begin
       if v then
        begin
         id:=FOwner.RequestLightId();
         if id<>-1 then
          begin
           glEnable(GL_LIGHT0+id);
           FOwner.EnabledLights[id]:=true;
           glLightfv(GL_LIGHT0+id,GL_POSITION,pos);
           
           glLightfv(GL_LIGHT0+id,GL_AMBIENT,amb);
           glLightfv(GL_LIGHT0+id,GL_DIFFUSE,diff);
           glLightfv(GL_LIGHT0+id,GL_SPECULAR,spec);
           
           glLightfv(GL_LIGHT0+id,GL_CONSTANT_ATTENUATION,@FConstantAttenuation);
           glLightfv(GL_LIGHT0+id,GL_LINEAR_ATTENUATION,@FLinearAttenuation);
           glLightfv(GL_LIGHT0+id,GL_QUADRATIC_ATTENUATION,@FQuadraticAttenuation);
           
           glLightfv(GL_LIGHT0+id,GL_SPOT_CUTOFF,@FSpotCutoff);
           glLightfv(GL_LIGHT0+id,GL_SPOT_DIRECTION,FSpotDirection);
           glLightfv(GL_LIGHT0+id,GL_SPOT_EXPONENT,@FSpotExponent);
          end;
        end else
        begin
         glDisable(GL_LIGHT0+id);
         FOwner.EnabledLights[id]:=false;
         FOwner.FreeLightId(id);
         id:=-1;
        end;
       truelight:=v;
      end;
end;

procedure TLightSource.SetShadow(v:boolean);
begin
     shadow:=v;
end;

procedure TLightSource.SetPosition(v:vec4);
begin
     pos:=v;
     if IsTrueLight then glLightfv(GL_LIGHT0+id,GL_POSITION,pos);
end;

procedure TLightSource.SetEnabled(v:boolean);
begin
     IsTrueLight:=v;
     FEnabled:=v;
end;

procedure TLightSource.SetSpotCutoff(const AValue: glFloat);
begin
  FSpotCutoff:=AValue;
  if IsTrueLight then glLightfv(GL_LIGHT0+id,GL_SPOT_CUTOFF,@FSpotCutoff);
end;

procedure TLightSource.SetSpotDirection(const AValue: vec3);
begin
  FSpotDirection:=AValue;
  if IsTrueLight then glLightfv(GL_LIGHT0+id,GL_SPOT_DIRECTION,FSpotDirection);
end;

procedure TLightSource.SetSpotExponent(const AValue: glFloat);
begin
  FSpotExponent:=AValue;
  if IsTrueLight then glLightfv(GL_LIGHT0+id,GL_SPOT_EXPONENT,@FSpotExponent);
end;
