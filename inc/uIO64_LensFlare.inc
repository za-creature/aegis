{ TLensFlare }

procedure TLensFlare.doFree();
var i:integer;
begin
  for i:=0 to High(SubFlares) do
   SubFlares[i].texture.MarkUnused();
  setLength(SubFlares,0);
end;

procedure TLensFlare.RenderLensFlare(dx, dy: glint; scale, posvec: glFloat);{ inline;}
var bx,by:glFloat;
begin
   bx:=glFloat(FOwner.ViewPort[2])/2-posvec*(dx-glFloat(FOwner.ViewPort[2])/2);
   by:=glFloat(FOwner.ViewPort[3])/2-posvec*(dy-glFloat(FOwner.ViewPort[3])/2);
   
   glBegin(GL_QUADS);
    gltexcoord2f(0,0);
    glVertex3f(bx-scale,by+scale,0);
    gltexcoord2f(1,0);
    glVertex3f(bx+scale,by+scale,0);
    gltexcoord2f(1,1);
    glVertex3f(bx+scale,by-scale,0);
    gltexcoord2f(0,1);
    glVertex3f(bx-scale,by-scale,0);
   glEnd();
end;

procedure TLensFlare.Draw(dx, dy: integer);
var i:integer;
begin
  for i:=0 to High(SubFlares) do
   with SubFlares[i] do
    begin
     glColor3f(r,g,b);
     glBindTexture(GL_TEXTURE_2D,texture.Handle);
     RenderLensFlare(dx,dy,scale,pos);
    end;
end;

procedure TLensFlare.LoadFromFile(filename: ansistring);
var f:TXMLDocument;
    c:TDOMNodeList;
    src,cd:ansistring;
    flare_count,i:integer;
begin
  cd:=GetCurrentDir();
  SetCurrentDir(ExtractFilePath(filename));

  try
   ReadXMLFile(f,filename);
  except
  end;
  
  c:=f.DocumentElement.ChildNodes;
  
  flare_count:=0;
  for i:=0 to c.Count-1 do
   if c.Item[i].NodeName='flare' then inc(flare_count);
  setLength(SubFlares,flare_count);
  
  flare_count:=0;
  for i:=0 to c.Count-1 do
   if c.Item[i].NodeName='flare' then
    begin
     SubFlares[flare_count].texture:=FOwner.GetResource(
     c.Item[i].Attributes.getNamedItem('src').NodeValue) as TTexture;

     SubFlares[flare_count].scale:=glFloat(StrToFloat(c.Item[i].Attributes.getNamedItem('scale').NodeValue));
     SubFlares[flare_count].pos:=glFloat(StrToFloat(c.Item[i].Attributes.getNamedItem('position').NodeValue));
     SubFlares[flare_count].r:=glFloat(StrToFloat(c.Item[i].Attributes.getNamedItem('r').NodeValue));
     SubFlares[flare_count].g:=glFloat(StrToFloat(c.Item[i].Attributes.getNamedItem('g').NodeValue));
     SubFlares[flare_count].b:=glFloat(StrToFloat(c.Item[i].Attributes.getNamedItem('b').NodeValue));
     
     inc(flare_count);
    end;

  c.Free();
  f.Free();
  
  SetCurrentDir(cd);
end;
