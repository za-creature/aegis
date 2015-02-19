{TLayer}

constructor TLayer.Create(AOwner:TIO64);
begin
  inherited Create();
  FOwner:=AOwner;
end;

procedure TLayer.AddTexture(filename:ansistring);
begin
  setLength(variations,Length(variations)+1);
  variations[High(variations)]:=TBitmap.Create(FOwner);
  variations[High(variations)].LoadFromFile(filename);
end;

procedure TLayer.Free();
var i:integer;
begin
  for i:=0 to High(variations) do variations[i].Free();
  setLength(variations,0);
  if cmap<>nil then cmap.Free();
  if c2map<>nil then c2map.Free();
  if c3map<>nil then c3map.Free();
  inherited Free();
end;

{TBitmap24}

constructor TBitmap24.Create(AOwner:TIO64);
begin
  inherited Create();
  FOwner:=AOwner;
end;

procedure TBitmap24.Alloc(aw,ah:integer);
begin
 w:=aw;
 h:=ah;
 setLength(data,w*h);
end;

procedure TBitmap24.Free();
begin
 if self<>nil then setLength(data,0);
 inherited Free();
end;

function TBitmap24.GetPixel(x,y:integer):TColor32b;
begin
  Result.r:=data[y*w+x].r;
  Result.g:=data[y*w+x].g;
  Result.b:=data[y*w+x].b;
  Result.a:=255;
end;

procedure TBitmap24.SetPixel(x,y:integer;v:TColor32b);
begin
  data[y*w+x].r:=v.r;
  data[y*w+x].g:=v.g;
  data[y*w+x].b:=v.b;
end;

procedure TBitmap24.SaveToFile(filename:ansistring);
begin
  if ExtractFileExt(filename)='.dds' then SaveToDDS(filename)
                                     else SavetoBMP(filename);
end;

procedure TBitmap24.SaveToDDS(filename:ansistring);

var Handle:gluint;
    p,i,l,wi,he:integer;
    buff:pByte;
    ddsd:TDDSurfaceDesc2;
    pfile:integer;
    filecode:array [0..3] of char='DDS ';
begin
  //header
  if FileExists(filename) then pFile:=FileOpen(filename,fmOpenWrite)
                          else pFile:=FileCreate(filename);
  if pFile=0 then exit;
  FileTruncate(pFile,0);
  filewrite(pFile,filecode,4);

  FillChar(ddsd,sizeof(ddsd),#0);
  ddsd.ddpfPixelFormat.dwFourCC:=FOURCC_DXT1;
  ddsd.dwWidth:=w;
  ddsd.dwHeight:=h;

  wi:=w;
  he:=h;
  l:=0;
  while (wi>0)and(he>0) do
   begin
    wi:=wi div 2;
    he:=he div 2;
    inc(l);
   end;

  ddsd.dwMipMapCount:=l;

  filewrite( pFile, ddsd, sizeof(ddsd));

  //compress the texture

  glGenTextures( 1, @Handle);
  glBindTexture( GL_TEXTURE_2D, Handle );

  BuildCompressedMipMaps(GL_TEXTURE_2D,GL_COMPRESSED_RGB_S3TC_DXT1_EXT,w,h,GL_BGR,GL_UNSIGNED_BYTE,@data[0]);

  //retrieve compressed image data
  getmem(buff,((w+3) div 4)*((h+3) div 4)*8);

  wi:=w;
  he:=h;
  l:=0;

  while (wi>0)and(he>0) do
   begin
    p:=((wi+3) div 4)*((he+3) div 4)*8;
    glGetCompressedTexImageARB(GL_TEXTURE_2D,l,buff);
    FileWrite( pFile, buff^, p);
    wi:=wi div 2;
    he:=he div 2;
    l+=1;
   end;
  freemem(buff);
  fileclose(pFile);
  
  glDeleteTextures(1, @Handle);
end;

procedure TBitmap24.SaveToBMP(filename:ansistring);
var f:integer;
    i,y,size:integer;
    p:dword;
    a:word;
begin
  size:=54+w*h*4;
  if fileexists(filename) then f:=fileopen(filename,fmOpenWrite)
                          else f:=filecreate(filename);
  filetruncate(f,0);
  filewrite(f,19778,2);//BM
  filewrite(f,size,4);//FILE SIZE
  p:=0;
  filewrite(f,p,4);//ALWAYS 0
  p:=54;
  filewrite(f,p,4);//HEADER SIZE
  p:=40;
  filewrite(f,p,4);//INFO HEADER SIZE
  filewrite(f,w,4);//w
  filewrite(f,h,4);//h
  a:=1;
  filewrite(f,a,2);//PLANES
  a:=24;
  filewrite(f,a,2);//BPP
  p:=0;
  filewrite(f,p,4);//NO COMPRESSION
  filewrite(f,p,4);//NO COMPRESSION
  filewrite(f,1,4);//HORIZONTAL DPI
  filewrite(f,1,4);//VERTICAL DPI
  filewrite(f,p,4);//NUMBER OF COLORS
  filewrite(f,p,4);//IMPORTANT COLORS
  p:=0;
  for y:=h-1 downto 0 do
   begin
    i := y*w;
    filewrite(f,data[i],3*w);
   end;
	fileclose(f);
end;

{TBitmap}

procedure TBitmap.Alloc(aw,ah:integer);
begin
 w:=aw;
 h:=ah;
 setLength(data2,w*h);
end;

procedure TBitmap.Free();
begin
 if self<>nil then
  begin
   setLength(data2,0);
   inherited Free();
  end;
end;

procedure TBitmap.CopyFrom(src:TBitmap);
var x,y:integer;
begin
  Alloc(src.Width,src.Height);
  for x:=0 to w-1 do
   for y:=0 to h-1 do
    Pixels[x,y]:=src.Pixels[x,y];
end;

procedure TBitmap.Draw(x,y:integer;r:integer;dst:TBitmap24);

  function Blend(dst,src:TColor32b):TColor32b;{inline;}
  begin
    Result.r:=byte(src.r+dst.a*(dst.r-src.r)div 256);
    Result.g:=byte(src.g+dst.a*(dst.g-src.g)div 256);
    Result.b:=byte(src.b+dst.a*(dst.b-src.b)div 256);
  end;

var a,b,ax,ay:integer;
    c1,c2:TColor32b;
begin
  if r=0 then
   begin
    for ax:=0 to w-1 do
     for ay:=0 to h-1 do
      dst.Pixels[x+ax,y+ay]:=Blend(Pixels[ax,ay],dst.Pixels[x+ax,y+ay]);
   end   else
  if r=1 then
   begin
    for ax:=0 to w-1 do
     for ay:=0 to h-1 do
      dst.Pixels[x+h-1-ay,y+ax]:=Blend(Pixels[ax,ay],dst.Pixels[x+h-1-ay,y+ax]);
   end   else
  if r=2 then
   begin
    for ax:=0 to w-1 do
     for ay:=0 to h-1 do
      dst.Pixels[x+w-1-ax,y+h-1-ay]:=Blend(Pixels[ax,ay],dst.Pixels[x+w-1-ax,y+h-1-ay]);
   end   else
   begin
    for ax:=0 to w-1 do
     for ay:=0 to h-1 do
      dst.Pixels[x+ay,y+h-1-ax]:=Blend(Pixels[ax,ay],dst.Pixels[x+ay,y+h-1-ax]);
   end;
end;

procedure TBitmap.SaveToFile(filename:ansistring);
begin
     if ExtractFileExt(filename)='.dds' then SaveToDDS(filename)
                                        else SaveToBMP(filename);
end;

procedure TBitmap.SaveToDDS(filename:ansistring);

var Handle:gluint;
    p,i,l,wi,he:integer;
    buff:pByte;
    ddsd:TDDSurfaceDesc2;
    pfile:integer;
    filecode:array [0..3] of char='DDS ';
begin
  //header
  if FileExists(filename) then pFile:=FileOpen(filename,fmOpenWrite)
                          else pFile:=FileCreate(filename);
  if pFile=0 then exit;
  FileTruncate(pFile,0);
  filewrite(pFile,filecode,4);

  FillChar(ddsd,sizeof(ddsd),#0);
  ddsd.ddpfPixelFormat.dwFourCC:=FOURCC_DXT5;
  ddsd.dwWidth:=w;
  ddsd.dwHeight:=h;

  wi:=w;
  he:=h;
  l:=0;
  while (wi>0)and(he>0) do
   begin
    wi:=wi div 2;
    he:=he div 2;
    inc(l);
   end;

  ddsd.dwMipMapCount:=l;

  filewrite( pFile, ddsd, sizeof(ddsd));

  //compress the texture

  glEnable(GL_TEXTURE_2D);
  glGenTextures( 1, @Handle);
  glBindTexture( GL_TEXTURE_2D, Handle );

  BuildCompressedMipMaps(GL_TEXTURE_2D,GL_COMPRESSED_RGBA_S3TC_DXT5_EXT,w,h,GL_BGR,GL_UNSIGNED_BYTE,@data2[0]);

  //retrieve compressed image data
  getmem(buff,((w+3) div 4)*((h+3) div 4)*16);

  wi:=w;
  he:=h;
  l:=0;

  while (wi>0)and(he>0) do
   begin
    p:=((wi+3) div 4)*((he+3) div 4)*16;
    glGetCompressedTexImageARB(GL_TEXTURE_2D,l,buff);
    FileWrite( pFile, buff^, p);
    wi:=wi div 2;
    he:=he div 2;
    l+=1;
   end;
  freemem(buff);
  fileclose(pFile);
  glDeleteTextures(1, @Handle);
end;

procedure TBitmap.SaveToBMP(filename:ansistring);
var f:integer;
    i,y,size:integer;
    p:dword;
    a:word;
begin
  size:=54+w*h*4;
  if fileexists(filename) then f:=fileopen(filename,fmOpenWrite)
                          else f:=filecreate(filename);
  filetruncate(f,0);
  filewrite(f,19778,2);//BM
  filewrite(f,size,4);//FILE SIZE
  p:=0;
  filewrite(f,p,4);//ALWAYS 0
  p:=54;
  filewrite(f,p,4);//HEADER SIZE
  p:=40;
  filewrite(f,p,4);//INFO HEADER SIZE
  filewrite(f,w,4);//w
  filewrite(f,h,4);//h
  a:=1;
  filewrite(f,a,2);//PLANES
  a:=32;
  filewrite(f,a,2);//BPP
  p:=0;
  filewrite(f,p,4);//NO COMPRESSION
  filewrite(f,p,4);//NO COMPRESSION
  filewrite(f,1,4);//HORIZONTAL DPI
  filewrite(f,1,4);//VERTICAL DPI
  filewrite(f,p,4);//NUMBER OF COLORS
  filewrite(f,p,4);//IMPORTANT COLORS
  p:=0;
  for y:=h-1 downto 0 do
   begin
    i := y*w;
    filewrite(f,data2[i],4*w);
   end;
  fileclose(f);
end;

procedure TBitmap.LoadAlphaChannel(filename:ansistring);
var t:TBitmap;
    c,tmp:TColor32b;
    x,y:integer;
begin
  if not FileExists(filename) then filename:=FOwner.Config.AegisDir+'media\texture\'+filename;
  doDirSeparators(filename);

  t:=TBitmap.Create(FOwner);
  t.LoadFromFile(filename);
  for x:=0 to w-1 do
   for y:=0 to h-1 do
    begin
     tmp:=Pixels[x,y];
     c:=t.Pixels[x,y];
     tmp.a:=byte((c.r+c.g+c.b) div 3);
     Pixels[x,y]:=tmp;
    end;
  t.Free();
end;

procedure TBitmap.LoadFromFile(filename:ansistring);
var b:word;
    x,y,i,size,f:integer;
    hasalpha:boolean=false;
begin
  if not FileExists(filename) then filename:=FOwner.Config.AegisDir+'media\texture\'+filename;
  doDirSeparators(filename);

  f:=fileopen(filename,fmOpenRead);
  fileread(f,b,2);
  if b<>19778 then
   begin
    fileclose(f);
    exit;
   end;
  fileread(f,size,4);//FILE SIZE 0
  fileread(f,b,2);//ALWAYS 0
  fileread(f,b,2);//ALWAYS 0
  fileread(f,size,4);//HEADER SIZE
  fileread(f,size,4);//INFO HEADER SIZE
  fileread(f,w,4);//WIDTH
  fileread(f,h,4);//HEIGHT
  fileread(f,b,2);//PLANES
  fileread(f,b,2);//BPP
  if (b<>24)and(b<>32) then
   begin
    fileclose(f);
    exit;
   end;

  setLength(data2,w*h);
  hasalpha:=b=32;
  fileread(f,size,4);//NO COMPRESSION
  fileread(f,size,4);//NO COMPRESSION
  fileread(f,size,4);//HORIZONTAL DPI
  fileread(f,size,4);//VERTICAL DPI
  fileread(f,size,4);//NUMBER OF COLORS
  fileread(f,size,4);//IMPORTANT COLORS

  if hasalpha then
   for y:=h-1 downto 0 do
    begin
     i := y*w;
     fileread(f,data2[i],4*w);
    end       else
   for y:=h-1 downto 0 do
    begin
     i := y*w;
     for x:=0 to w-1 do
      begin
       fileread(f,data2[i+x],3);
       data2[i+x].a:=255;
      end;
    end;
  fileclose(f);
end;

function TBitmap.GetPixel(x,y:integer):TColor32b;{inline;}
begin
  Result:=data2[y*w+x];
end;

procedure TBitmap.SetPixel(x,y:integer;v:TColor32b);{inline;}
begin
  data2[y*w+x]:=v;
end;

{TTileSet}

procedure TTileSet.LoadFromFile(filename:ansistring);

  procedure AddLayer(elem:TDOMNode);
  var i:integer;
      ac:string='';
      a2c:string='';
      a3c:string='';
      c:TDOMNodeList;
  begin

    Layers[LayerCount]:=TLayer.Create(FOwner);
    if elem.Attributes.GetNamedItem('name')<>nil then Layers[LayerCount].Name:=elem.Attributes.GetNamedItem('name').NodeValue
                                                 else Layers[LayerCount].Name:='Unnamed Layer';
    c:=elem.ChildNodes;

    with c do
     for i:=0 to Count-1 do
      begin
       if Item[i].NodeName='texture' then
        Layers[LayerCount].AddTexture(Item[i].Attributes.GetNamedItem('src').NodeValue)
       else if Item[i].NodeName='texture_c' then
        begin
         if Layers[LayerCount].cmap<>nil then Layers[LayerCount].cmap.Free();
         Layers[LayerCount].cmap:=TBitmap.Create(FOwner);
         Layers[LayerCount].cmap.LoadFromFile(Item[i].Attributes.GetNamedItem('src').NodeValue);
        end
       else if Item[i].NodeName='texture_2c' then
        begin
         if Layers[LayerCount].c2map<>nil then Layers[LayerCount].c2map.Free();
         Layers[LayerCount].c2map:=TBitmap.Create(FOwner);
         Layers[LayerCount].c2map.LoadFromFile(Item[i].Attributes.GetNamedItem('src').NodeValue);
        end
       else if Item[i].NodeName='texture_3c' then
        begin
         if Layers[LayerCount].c3map<>nil then Layers[LayerCount].c3map.Free();
         Layers[LayerCount].c3map:=TBitmap.Create(FOwner);
         Layers[LayerCount].c3map.LoadFromFile(Item[i].Attributes.GetNamedItem('src').NodeValue);
        end
       else if Item[i].NodeName='alpha_c' then ac:=Item[i].Attributes.GetNamedItem('src').NodeValue
       else if Item[i].NodeName='alpha_2c' then a2c:=Item[i].Attributes.GetNamedItem('src').NodeValue
       else if Item[i].NodeName='alpha_3c' then a3c:=Item[i].Attributes.GetNamedItem('src').NodeValue;
      end;
    //create missing textures
    if Layers[LayerCount].cmap=nil then
     begin
      Layers[LayerCount].cmap:=TBitmap.Create(FOwner);
      Layers[LayerCount].cmap.CopyFrom(Layers[LayerCount].Variations[0]);
      if FileExists(ac) then Layers[LayerCount].cmap.LoadAlphaChannel(ac)
                        else Layers[LayerCount].cmap.LoadAlphaChannel('default_c.bmp');
     end;
    if Layers[LayerCount].c2map=nil then
     begin
      Layers[LayerCount].c2map:=TBitmap.Create(FOwner);
      Layers[LayerCount].c2map.CopyFrom(Layers[LayerCount].Variations[0]);
      if FileExists(a2c) then Layers[LayerCount].c2map.LoadAlphaChannel(ac)
                         else Layers[LayerCount].c2map.LoadAlphaChannel('default_2c.bmp');
     end;
    if Layers[LayerCount].c3map=nil then
     begin
      Layers[LayerCount].c3map:=TBitmap.Create(FOwner);
      Layers[LayerCount].c3map.CopyFrom(Layers[LayerCount].Variations[0]);
      if FileExists(a3c) then Layers[LayerCount].c3map.LoadAlphaChannel(ac)
                         else Layers[LayerCount].c3map.LoadAlphaChannel('default_3c.bmp');
     end;

    c.Free();

    inc(LayerCount);
  end;

var a:array[0..3] of integer;

  function Valid():boolean;
  begin
    if ((a[0]=a[2])and(a[0]<>a[1])and(a[0]<>a[3]))or((a[1]=a[3])and(a[1]<>a[0])and(a[1]<>a[2]))then exit(false);
    if (a[0]>=LayerCount)or(a[1]>=LayerCount)or(a[2]>=LayerCount)or(a[3]>=LayerCount) then exit(false);
    result:=true;
  end;

  function Check():integer;
  var i,j:integer;
      min,d:ansistring;
  begin
    min:=char(48+a[0])+char(48+a[1])+char(48+a[2])+char(48+a[3]);
    Result:=0;
    for i:=1 to 3 do
     begin
      d:='';
      for j:=0 to 3 do d+=min[(j+i) mod 4+1];
      if d<min then
       begin
        min:=d;
        Result:=i;
       end;
     end;
  end;

  function Rotate(t:TexCoordSet;c:integer):TexCoordSet;
  var i:integer;
  begin
   for i:=0 to 3 do
    Result[(i+c) mod 4]:=t[i];
  end;

  function Rotate(t:l4v;c:integer):l4v;
  var i:integer;
  begin
   for i:=0 to 3 do
    Result[i]:=t[(i+c) mod 4];
  end;
  
  procedure LoadAndMoveToVideoMem(filename:ansistring);
  var pDDSImageData:pDDS_IMAGE_DATA;
      i,nSize,nOffset,nHeight,nwidth,nNumMipMaps,nBlockSize:integer;
  begin
    if not(FileExists(filename))then filename:=FOwner.Config.AegisDir+'media\texture\'+filename;
    doDirSeparators(filename);

    pDDSImageData:=TTexture.LoadDDSTextureFile(filename);

    if pDDSImageData<>nil then
     begin
      nHeight     := pDDSImageData^.height;
      nWidth      := pDDSImageData^.width;
      nNumMipMaps := pDDSImageData^.numMipMaps;

      if (pDDSImageData^.format=GL_COMPRESSED_RGBA_S3TC_DXT1_EXT)or
         (pDDSImageData^.format=GL_COMPRESSED_RGB_S3TC_DXT1_EXT) then nBlockSize := 8
                                                                 else nBlockSize := 16;

      glBindTexture( GL_TEXTURE_2D, FHandle );
      FOwner.Filter(false);

      nOffset := 0;

      //load only the wanted LOD; in this case 0
      //for i:=0 to nNumMipMaps-1 do
      i:=0;
       begin
        if nWidth  = 0 then nWidth  := 1;
        if nHeight = 0 then nHeight := 1;

        nSize := ((nWidth+3) div 4) * ((nHeight+3) div 4) * nBlockSize;
        glCompressedTexImage2DARB( GL_TEXTURE_2D,i,pDDSImageData^.format,nWidth,nHeight,0,nSize,pDDSImageData^.pixels[i]);
        nOffset += nSize;

        // half size;
        nWidth  := nWidth  div 2;
        nHeight := nHeight div 2;
       end;
      for i:=0 to nNumMipMaps-1 do
       if pDDSImageData^.pixels[i]<>nil then freemem(pDDSImageData^.Pixels[i]);
      if pDDSImageData^.pixels<>nil then freemem(pDDSImageData^.pixels);
      freemem(pDDSImageData);
     end;
  end;

var f:TXMLDocument;
    yafx,yafy,ii,min,i,j,k,l,c:integer;
    cx,cy:integer;
    count:integer=0;
    d:l4v;
    e:TDOMNodeList;
    src2,src,cd:ansistring;
    compiled:boolean=false;
    Data:TBitmap24;
    tmp:TDOMNode;
begin
  glGenTextures(1,@FHandle);

  cd:=GetCurrentDir();

  SetCurrentDir(ExtractFileDir(filename));
  try
   ReadXMLFile(f,filename);
  except
  end;
  //read all layer tags

  if f.DocumentElement.Attributes.GetNamedItem('name')<>nil then FName:=f.DocumentElement.Attributes.GetNamedItem('name').NodeValue
                                                            else FName:='Unnamed Tileset';
                                                            
  if (f.DocumentElement.Attributes.GetNamedItem('compiled')<>nil)and
     (f.DocumentElement.Attributes.GetNamedItem('compiled').NodeValue='true') then
   begin
    src:=f.DocumentElement.Attributes.GetNamedItem('src').NodeValue;
    src2:=FOwner.Config.AegisDir+'media\texture\'+src;
    doDirSeparators(src);
    doDirSeparators(src2);
    compiled:=(FileExists(src))or(FileExists(src2));
   end;

  
  if compiled then LoadAndMoveToVideoMem(src)
  else
   begin
    Data:=TBitmap24.Create(FOwner);
    Data.Alloc(4096,4096);
   end;

  e:=f.DocumentElement.ChildNodes;
  with e do
   for i:=0 to Count-1 do
    if Item[i].NodeName='layer' then AddLayer(Item[i]);

  e.Free();

  //build texcoordmap and texturemap

  cx:=4;
  cy:=4;
  for i:=0 to 7 do
   begin
    a[0]:=i;
    for j:=0 to 7 do
     begin
      a[1]:=j;
      for k:=0 to 7 do
       begin
        a[2]:=k;
        for l:=0 to 7 do
         begin
          a[3]:=l;
          if Valid() then
           begin
            c:=Check();
            if c=0 then
             begin
              //add new coords
              TexCoords[a[0]][a[1]][a[2]][a[3]][0].x:=glFloat(cx/4096);
              TexCoords[a[0]][a[1]][a[2]][a[3]][0].y:=glFloat(cy/4096);

              TexCoords[a[0]][a[1]][a[2]][a[3]][1].x:=glFloat((cx+128)/4096);
              TexCoords[a[0]][a[1]][a[2]][a[3]][1].y:=glFloat(cy/4096);

              TexCoords[a[0]][a[1]][a[2]][a[3]][2].x:=glFloat((cx+128)/4096);
              TexCoords[a[0]][a[1]][a[2]][a[3]][2].y:=glFloat((cy+128)/4096);

              TexCoords[a[0]][a[1]][a[2]][a[3]][3].x:=glFloat(cx/4096);
              TexCoords[a[0]][a[1]][a[2]][a[3]][3].y:=glFloat((cy+128)/4096);
              
              if not compiled then
               begin
                d:=a;
                min:=high(min);
                for ii:=0 to 3 do
                 if d[ii]<min then min:=d[ii];
                for ii:=0 to 3 do
                 if d[ii]=min then d[ii]:=high(d[ii]);//should be max
                Layers[min].Variations[0].Draw(cx,cy,0,Data);

                min:=high(min);
                for ii:=0 to 3 do
                 if d[ii]<min then min:=d[ii];

                //layer paint
                while min<high(min) do
                 begin
                  //asume three corners
                  if (d[3]=min) and (d[0]=min) and (d[1]=min) then Layers[min].c3map.Draw(cx,cy,0,Data) else
                  if (d[0]=min) and (d[1]=min) and (d[2]=min) then Layers[min].c3map.Draw(cx,cy,1,Data) else
                  if (d[1]=min) and (d[2]=min) and (d[3]=min) then Layers[min].c3map.Draw(cx,cy,2,Data) else
                  if (d[2]=min) and (d[3]=min) and (d[0]=min) then Layers[min].c3map.Draw(cx,cy,3,Data) else
                  //asume half
                  if (d[3]=min) and (d[0]=min) then Layers[min].c2map.Draw(cx,cy,0,Data) else
                  if (d[0]=min) and (d[1]=min) then Layers[min].c2map.Draw(cx,cy,1,Data) else
                  if (d[1]=min) and (d[2]=min) then Layers[min].c2map.Draw(cx,cy,2,Data) else
                  if (d[2]=min) and (d[3]=min) then Layers[min].c2map.Draw(cx,cy,3,Data) else
                  //must be corner
                  if d[0]=min then Layers[min].cmap.Draw(cx,cy,0,Data) else
                  if d[1]=min then Layers[min].cmap.Draw(cx,cy,1,Data) else
                  if d[2]=min then Layers[min].cmap.Draw(cx,cy,2,Data) else
                  if d[3]=min then Layers[min].cmap.Draw(cx,cy,3,Data);

                  for ii:=0 to 3 do
                   if d[ii]=min then d[ii]:=high(d[ii]);//should be max
                  min:=high(min);
                  for ii:=0 to 3 do
                   if d[ii]<min then min:=d[ii];
                 end;
                //edge paint
                for yafx:=1 to 4 do
                 for yafy:=cy to cy+127 do
                  begin
                   Data.Pixels[cx-yafx,yafy]:=Data.Pixels[cx,yafy];
                   Data.Pixels[cx+127+yafx,yafy]:=Data.Pixels[cx+127,yafy];
                  end;
                for yafy:=1 to 4 do
                 for yafx:=cx to cx+127 do
                  begin
                   Data.Pixels[yafx,cy-yafy]:=Data.Pixels[yafx,cy];
                   Data.Pixels[yafx,cy+127+yafy]:=Data.Pixels[yafx,cy+127];
                  end;
                //corner paint
                for yafx:=1 to 4 do
                 for yafy:=1 to 4 do
                  begin
                   Data.Pixels[cx-yafx,cy-yafy]:=Data.Pixels[cx,cy];
                   Data.Pixels[cx+127+yafx,cy-yafy]:=Data.Pixels[cx+127,cy];
                   Data.Pixels[cx-yafx,cy+127+yafy]:=Data.Pixels[cx,cy+127];
                   Data.Pixels[cx+127+yafx,cy+127+yafy]:=Data.Pixels[cx+127,cy+127];
                  end;
               end;
              inc(cx,136);
              if cx=4084 then
               begin
                inc(cy,136);
                cx:=4;
               end;
              inc(count);
             end   else
             begin
              //rotate coords
              d:=Rotate(a,c);
              TexCoords[a[0]][a[1]][a[2]][a[3]]:=Rotate(TexCoords[d[0]][d[1]][d[2]][d[3]],c);
             end;
           end;
          if FOwner.onStateChange<>nil then FOwner.onStateChange(count div 10);
         end;
       end;
     end;
   end;

  //add variations
  for i:=0 to LayerCount-1 do
   for j:=1 to High(Layers[i].Variations) do
    begin
     Layers[i].Variations[j].Draw(cx,cy,0,Data);
     inc(cx,136);
     if cx=4084 then
      begin
       inc(cy,136);
       cx:=4;
      end;
    end;

  if not compiled then
   begin
    glBindTexture(GL_TEXTURE_2D,FHandle);
    FOwner.Filter(false);
    //no mipmaps for us
    glTexImage2D(GL_TEXTURE_2D,0,GL_COMPRESSED_RGB_S3TC_DXT1_EXT,Data.Width,Data.Height,0,GL_BGR,GL_UNSIGNED_BYTE,@Data.data[0]);
    if not FOwner.Config.DoNotCompileOnDemand then
     begin
      //compile
      f.DocumentElement.SetAttribute('compiled','true');
      f.DocumentElement.SetAttribute('src',ExtractFileName(filename)+'.dds');

      Data.SaveToFile(ExtractFileName(filename)+'.dds');

      WriteXMLFile(f,filename);
     end;
    Data.Free();
    Data:=nil;
   end;

  //release aux data
  
  f.Free();
  
  for i:=0 to LayerCount-1 do
   layers[i].Free();
  LayerCount:=0;
  
  
  SetCurrentDir(cd);
end;

procedure TTileSet.doFree();
begin
  glDeleteTextures(1,@FHandle);
end;

{TSegment}

constructor TSegment.Create(AOwner:TIO64;asegmentsize:integer);
begin
  inherited Create();
  FOwner:=AOwner;
  if FOwner.Config.QueriesEnabled then glGenQueriesARB(1,@Query);
  FSegmentSize:=asegmentsize;
  setLength(VertexArray,6*asegmentsize*asegmentsize);
  setLength(NormalArray,6*asegmentsize*asegmentsize);
  setLength(TexCoordArray,6*asegmentsize*asegmentsize);
end;

procedure TSegment.Free();
begin
  if self<>nil then
   begin
    setLength(VertexArray,0);
    setLength(NormalArray,0);
    setLength(TexCoordArray,0);
    if FOwner.Config.QueriesEnabled then glDeleteQueriesARB(1,@Query);
   end;
  inherited Free();
end;

function TSegment.GetVertex(x,y:integer):TPoint3D;{inline;}
var dp:integer;
begin
  if (x<FSegmentSize)and(y<FSegmentSize) then dp:=6*(FSegmentSize*y+x)
                                         else
  if (x=FSegmentSize)and(y<FSegmentSize) then dp:=6*(FSegmentSize*y+x-1)+1
                                         else
  if (x<FSegmentSize)and(y=FSegmentSize) then dp:=6*(FSegmentSize*(y-1)+x)+2
                                         else dp:=6*(FSegmentSize*(y-1)+x-1)+5;
  Result:=VertexArray[dp];
(*   dp:=4*y*(FSegmentSize+1)+8*(x div 2)+3*(x mod 2);
   if dp<length(VertexArray)then Result:=VertexArray[dp]
                            else
    if x mod 2=0 then
     if x<>0 then Result:=VertexArray[dp-4*(FSegmentSize+1)-1]
             else Result:=VertexArray[dp-4*(FSegmentSize+1)+2]
                 else Result:=VertexArray[dp-4*(FSegmentSize+1)+1];*)
end;

function TSegment.GetTexCoord(x, y: integer): TexCoordSet;{inline;}
var dp:integer;
begin
  dp:=6*(FSegmentSize*y+x);
  Result[0] := TexCoordArray[dp];
  Result[1] := TexCoordArray[dp+1];
  Result[2] := TexCoordArray[dp+5];
  Result[3] := TexCoordArray[dp+2];
end;

function TSegment.GetNormal(x,y:integer):TPoint3D;{inline;}
var dp:integer;
begin
  if (x<FSegmentSize)and(y<FSegmentSize) then dp:=6*(FSegmentSize*y+x)
                                         else
  if (x=FSegmentSize)and(y<FSegmentSize) then dp:=6*(FSegmentSize*y+x-1)+1
                                         else
  if (x<FSegmentSize)and(y=FSegmentSize) then dp:=6*(FSegmentSize*(y-1)+x)+2
                                         else dp:=6*(FSegmentSize*(y-1)+x-1)+5;
  Result:=NormalArray[dp];
  (*   dp:=4*y*(FSegmentSize+1)+8*(x div 2)+3*(x mod 2);
   if dp<length(VertexArray)then Result:=NormalArray[dp]
                            else
    if x mod 2=0 then
     if x<>0 then Result:=NormalArray[dp-4*(FSegmentSize+1)-1]
             else Result:=NormalArray[dp-4*(FSegmentSize+1)+2]
                 else Result:=NormalArray[dp-4*(FSegmentSize+1)+1];*)
end;

procedure TSegment.SetTexCoord(x, y: integer; const AValue: TexCoordSet);{inline;}
var dp:integer;
begin
  dp:=6*(FSegmentSize*y+x);
  TexCoordArray[dp]   := AValue[0];
  TexCoordArray[dp+1] := AValue[1];
  TexCoordArray[dp+2] := AValue[3];
  TexCoordArray[dp+3] := AValue[3];
  TexCoordArray[dp+4] := AValue[1];
  TexCoordArray[dp+5] := AValue[2];
end;

procedure TSegment.SetVertex(sxp,syp:integer;v:TPoint3D);{inline;}

  procedure SubTryToSet(dp:integer);{inline;}
  begin
   if (dp>=0)and(dp<length(VertexArray))then VertexArray[dp]:=v;
  end;

var dp:integer;//data pointer;
begin
  //bounding box
  if v.x<MinX then MinX:=v.x;
  if v.x>MaxX then MaxX:=v.x;

  if v.y<MinY then MinY:=v.y;
  if v.y>MaxY then MaxY:=v.y;

  if v.z<MinZ then MinZ:=v.z;
  if v.z>MaxZ then MaxZ:=v.z;

  dp:=6*(FSegmentSize*syp+sxp);
  
  if sxp<FSegmentSize then SubTryToSet(dp);
  if sxp>0 then
   begin
    SubTryToSet(dp-2);
    SubTryToSet(dp-5);
   end;
  if syp>0 then
   begin
    dp-=6*FSegmentSize;
    if sxp<FSegmentSize then
     begin
      SubTryToSet(dp+2);
      SubTryToSet(dp+3);
     end;
    if sxp>0 then SubTryToSet(dp-1);
   end;

{  dp:=4*syp*(FSegmentSize+1)+8*(sxp div 2)+3*(sxp mod 2);
  //primary
  SubTryToSet(dp);
  if sxp mod 2=0 then
   begin
    //primary degenerate
    SubTryToSet(dp+1);
    if sxp<>0 then
     begin
      //secondary
      SubTryToSet(dp-4*(FSegmentSize+1)-1);
      //secondary degenerate
      SubTryToSet(dp-4*(FSegmentSize+1)+2);
      //secondary degenerate (2)
      if sxp=FSegmentSize then SubTryToSet(dp-4*(FSegmentSize+1)+3);
              //other secondary
     end      else SubTryToSet(dp-4*(FSegmentSize+1)+2);
   end           else
   begin
    //primary degenerate
    SubTryToSet(dp+3);
    //secondary
    SubTryToSet(dp-4*(FSegmentSize+1)+1);
    //secondary degenerate
    SubTryToSet(dp-4*(FSegmentSize+1)+2);
   end;}
end;

procedure TSegment.SetNormal(sxp,syp:integer;v:TPoint3D);{inline;}

  procedure SubTryToSet(dp:integer);{inline;}
  begin
   if (dp>=0)and(dp<length(NormalArray))then NormalArray[dp]:=v;
  end;

var dp:integer;//data pointer;
begin
  dp:=6*(FSegmentSize*syp+sxp);

  if sxp<FSegmentSize then SubTryToSet(dp);
  if sxp>0 then
   begin
    SubTryToSet(dp-2);
    SubTryToSet(dp-5);
   end;
  if syp>0 then
   begin
    dp-=6*FSegmentSize;
    if sxp<FSegmentSize then
     begin
      SubTryToSet(dp+2);
      SubTryToSet(dp+3);
     end;
    if sxp>0 then SubTryToSet(dp-1);
   end;

{  dp:=4*syp*(FSegmentSize+1)+8*(sxp div 2)+3*(sxp mod 2);
  //primary
  SubTryToSet(dp);
  if sxp mod 2=0 then
   begin
    //primary degenerate
    SubTryToSet(dp+1);
    if sxp<>0 then
     begin
      //secondary
      SubTryToSet(dp-4*(FSegmentSize+1)-1);
      //secondary degenerate
      SubTryToSet(dp-4*(FSegmentSize+1)+2);
      //secondary degenerate (2)
      if sxp=FSegmentSize then SubTryToSet(dp-4*(FSegmentSize+1)+3);
              //other secondary
     end      else SubTryToSet(dp-4*(FSegmentSize+1)+2);
   end           else
   begin
    //primary degenerate
    SubTryToSet(dp+3);
    //secondary
    SubTryToSet(dp-4*(FSegmentSize+1)+1);
    //secondary degenerate
    SubTryToSet(dp-4*(FSegmentSize+1)+2);
   end;}
end;

procedure TSegment.Loop();{inline;}
var SampleCount:integer;
begin
  if FOwner.Config.QueriesEnabled then
   begin
    glBeginQueryARB(GL_SAMPLES_PASSED_ARB,Query);

     glBegin(GL_QUADS);
      glVertex3f(MinX,MinY,MinZ);
      glVertex3f(MinX,MaxY,MinZ);
      glVertex3f(MaxX,MaxY,MinZ);
      glVertex3f(MaxX,MinY,MinZ);
      
      glVertex3f(MaxX,MinY,MinZ);
      glVertex3f(MaxX,MaxY,MinZ);
      glVertex3f(MaxX,MaxY,MaxZ);
      glVertex3f(MaxX,MinY,MaxZ);
      
      glVertex3f(MinX,MaxY,MinZ);
      glVertex3f(MinX,MaxY,MaxZ);
      glVertex3f(MaxX,MaxY,MaxZ);
      glVertex3f(MaxX,MaxY,MinZ);
      
      glVertex3f(MinX,MinY,MaxZ);
      glVertex3f(MinX,MaxY,MaxZ);
      glVertex3f(MinX,MaxY,MinZ);
      glVertex3f(MinX,MinY,MinZ);
      
      glVertex3f(MinX,MinY,MaxZ);
      glVertex3f(MinX,MinY,MinZ);
      glVertex3f(MaxX,MinY,MinZ);
      glVertex3f(MaxX,MinY,MaxZ);
      
      glVertex3f(MaxX,MinY,MaxZ);
      glVertex3f(MaxX,MaxY,MaxZ);
      glVertex3f(MinX,MaxY,MaxZ);
      glVertex3f(MinZ,MinY,MaxZ);
     glEnd();

     {glVertexPointer(3,GL_FLOAT,0,@VisibilityVertexArray[0]);
     glDrawArrays(GL_TRIANGLE_STRIP,0,4);}

    glEndQueryARB(GL_SAMPLES_PASSED_ARB);

    glGetQueryObjectuivARB(Query, GL_QUERY_RESULT_ARB, @SampleCount);
    FHit:=SampleCount>0;
   end                            else FHit:=true;
end;

{TMap}

constructor TMap.Create(AOwner:TIO64;AFilename:ansistring);
var f:TXMLDocument;
    c:TDOMNodeList;
    x,y,tm,hm,i:integer;
    cd,HeightmapName,TexturemapName:ansistring;
    tmpf:glFloat;
    tmpb:byte;
begin
     cd:=GetCurrentDir();
     SetCurrentDir(ExtractFilePath(AFilename));
     inherited Create();
     FOwner:=AOwner;
     try
      ReadXMLFile(f,AFilename);
     except
     end;
     
     c:=f.DocumentElement.ChildNodes;
     
     w:=StrToInt(f.DocumentElement.Attributes.GetNamedItem('width').NodeValue);
     h:=StrToInt(f.DocumentElement.Attributes.GetNamedItem('height').NodeValue);
     
     Author:=f.DocumentElement.Attributes.GetNamedItem('author').NodeValue;
     Title:=f.DocumentElement.Attributes.GetNamedItem('title').NodeValue;
     Description:=f.DocumentElement.Attributes.GetNamedItem('description').NodeValue;
     
     
     for i:=0 to c.Count-1 do
      begin
       if c.Item[i].NodeName='tileset' then
        FTileset:=c.Item[i].Attributes.GetNamedItem('src').NodeValue;
       if c.Item[i].NodeName='heightmap' then
        HeightmapName:=c.Item[i].Attributes.GetNamedItem('src').NodeValue;
       if c.Item[i].NodeName='texturemap' then
        TexturemapName:=c.Item[i].Attributes.GetNamedItem('src').NodeValue;
      end;
     
     c.Free();
     
     f.Free();

     InternalTileset:=AOwner.GetResource(FTileset) as TTileset;

     setLength(FHeightmap,w+1,h+1);
     setLength(FTexturemap,w+1,h+1);

     FSegmentation:=FOwner.Config.Segmentation;
     FSegmentSize:=IntSeg[FSegmentation];
     NumHorizSegments:=Width div IntSeg[FSegmentation];
     NumVertSegments:=Height div IntSeg[FSegmentation];
     SetLength(Segments,NumHorizSegments,NumVertSegments);

     for x:=0 to NumHorizSegments-1 do
      for y:=0 to NumVertSegments-1 do
       Segments[x][y]:=TSegment.Create(FOwner,IntSeg[FSegmentation]);

     hm:=FileOpen(HeightmapName,fmOpenRead);
     tm:=FileOpen(TexturemapName,fmOpenRead);
     
     for x:=0 to Width do
      for y:=0 to Height do
       begin
        FileRead(hm,tmpf,SizeOf(tmpf));
        FileRead(tm,tmpb,SizeOf(tmpb));
        Heightmap[x,y]:=tmpf;
        Texturemap[x,y]:=tmpb;
       end;
       
     FileClose(hm);
     FileClose(tm);
     
     SetCurrentDir(cd);
end;

procedure TMap.SaveToFile(AFilename:ansistring);
var f:TXMLDocument;
    c:TDOMNodeList;
    x,y,tm,hm,i:integer;
    HeightmapName,TexturemapName:ansistring;
    tmpf:glFloat;
    tmpb:byte;
    p:TDOMElement;
    cd:ansistring;
    
function RipExtension(AFilename:ansistring):ansistring;
var i:integer;
begin
  i:=length(AFilename);
  while (i>0)and(AFilename[i]<>'.') do dec(i);
  dec(i);
  if i>0 then Result:=Copy(AFilename,1,i)
         else Result:=AFilename;
end;

begin
     cd:=GetCurrentDir();
     SetCurrentDir(ExtractFilePath(AFilename));
     AFilename:=RipExtension(AFilename);
     f:=TXMLDocument.Create();
     
     f.AppendChild(f.CreateElement('map'));

     f.DocumentElement.SetAttribute('version','1.0');
     
     f.DocumentElement.SetAttribute('width',IntToStr(w));
     f.DocumentElement.SetAttribute('height',IntToStr(h));

     f.DocumentElement.SetAttribute('author',Author);
     f.DocumentElement.SetAttribute('title',Title);
     f.DocumentElement.SetAttribute('description',Description);
     
     HeightmapName:=ExtractFileName(AFilename+'.heightmap');
     TexturemapName:=ExtractFileName(AFilename+'.texturemap');

     p:=f.CreateElement('tileset');
     p.SetAttribute('src',FTileset);
     f.DocumentElement.AppendChild(p);

     p:=f.CreateElement('heightmap');
     p.SetAttribute('src',HeightmapName);
     f.DocumentElement.AppendChild(p);

     p:=f.CreateElement('texturemap');
     p.SetAttribute('src',TexturemapName);
     f.DocumentElement.AppendChild(p);
     
     WriteXMLFile(f,AFilename+'.map');
     
     f.Free();

     if FileExists(HeightmapName) then hm:=FileOpen(HeightmapName,fmOpenWrite)
                                  else hm:=FileCreate(HeightmapName);
     if FileExists(TexturemapName) then tm:=FileOpen(TexturemapName,fmOpenWrite)
                                   else tm:=FileCreate(TextureMapName);

     for x:=0 to Width do
      for y:=0 to Height do
       begin
        tmpf:=Heightmap[x,y];
        tmpb:=Texturemap[x,y];
        FileWrite(hm,tmpf,SizeOf(tmpf));
        FileWrite(tm,tmpb,SizeOf(tmpb));
       end;

     FileClose(hm);
     FileClose(tm);
     
     SetCurrentDir(cd);
end;

constructor TMap.Create(AOwner:TIO64;AWidth,AHeight:integer;ATileset:ansistring);
var x,y:integer;
begin
     inherited Create();
     FOwner:=AOwner;
     FTileset:=ATileset;
     InternalTileset:=AOwner.GetResource(FTileset) as TTileset;

     w:=AWidth;
     h:=AHeight;

     setLength(FHeightmap,w+1,h+1);
     setLength(FTexturemap,w+1,h+1);

     FSegmentation:=FOwner.Config.Segmentation;
     FSegmentSize:=IntSeg[FSegmentation];
     NumHorizSegments:=Width div IntSeg[FSegmentation];
     NumVertSegments:=Height div IntSeg[FSegmentation];
     SetLength(Segments,NumHorizSegments,NumVertSegments);

     for x:=0 to NumHorizSegments-1 do
      for y:=0 to NumVertSegments-1 do
       Segments[x][y]:=TSegment.Create(FOwner,IntSeg[FSegmentation]);

     for x:=0 to Width do
      for y:=0 to Height do
       begin
        Heightmap[x,y]:=0;
        Texturemap[x,y]:=0;
       end;
end;

function TMap.GetVertex(x, y: integer): TPoint3D;
begin
  Result.x:=glFloat(x-(Width+1)/2);
  Result.y:=glFloat(FHeightmap[x,y]);
  Result.z:=glFloat(y-(Height+1)/2);
end;

procedure TMap.Free();
var x,y:integer;
begin
  if self<>nil then
   begin
    InternalTileset.MarkUnused();
    for x:=0 to NumHorizSegments-1 do
     for y:=0 to NumVertSegments-1 do
      Segments[x][y].Free();

    setLength(Segments,0,0);
    setLength(FTexturemap,0,0);
    setLength(FHeightmap,0,0);
   end;
  inherited Free();
end;

procedure TMap.SetSegmentation(v:integer);
var a:array of array of glFloat;
    b:array of array of byte;
    i,j,x,y:integer;
begin
     if (v<0)or(v>4) then exit;//invalid value
     if (Width>0)and(Height>0) then
      begin
       setLength(a,Width+1,Height+1);
       setLength(b,Width+1,Height+1);
       for x:=0 to Width do
        for y:=0 to Height do
         begin
          a[x][y]:=Heightmap[x,y];
          b[x][y]:=Texturemap[x,y];
         end;
      end;

     for x:=0 to NumHorizSegments-1 do
      for y:=0 to NumVertSegments-1 do
       Segments[x][y].Free();

     FSegmentation:=v;
     FSegmentSize:=IntSeg[FSegmentation];
     NumHorizSegments:=Width div IntSeg[FSegmentation];
     NumVertSegments:=Height div IntSeg[FSegmentation];
     SetLength(Segments,NumHorizSegments,NumVertSegments);

     for x:=0 to NumHorizSegments-1 do
      for y:=0 to NumVertSegments-1 do
       Segments[x][y]:=TSegment.Create(FOwner,IntSeg[FSegmentation]);


     if (Width>0)and(Height>0)then
      begin
       for x:=0 to Width do
        for y:=0 to Height do
         begin
          Heightmap[x,y]:=a[x][y];
          Texturemap[x,y]:=b[x][y];
         end;
       setLength(a,0,0);
       setLength(b,0,0);
      end;
end;

function TMap.GetHeightmap(x, y: integer): glFloat;
begin
  Result:=FHeightmap[x][y];
end;

function TMap.GetTexturemap(x, y: integer): byte;
begin
  Result:=FTexturemap[x][y];
end;

procedure TMap.SetVertex(x,y:integer;v:TPoint3D);

  procedure TryToUpdate(sx,sy,sxp,syp:integer);
  begin
    if (sx>=0)and(sy>=0)and(sx<NumHorizSegments)and(sy<NumVertSegments)then Segments[sx][sy].Vertex[sxp,syp]:=v;
  end;

var sx,sy,sxp,syp:word;
begin
  DivMod(x,word(IntSeg[FSegmentation]),sx,sxp);
  DivMod(y,word(IntSeg[FSegmentation]),sy,syp);
  if (sxp=0)and(syp=0) then
   begin
    TryToUpdate(sx  ,sy  ,0                    ,0);
    TryToUpdate(sx-1,sy  ,IntSeg[FSegmentation],0);
    TryToUpdate(sx  ,sy-1,0                    ,IntSeg[FSegmentation]);
    TryToUpdate(sx-1,sy-1,IntSeg[FSegmentation],IntSeg[FSegmentation]);
   end                      else
  if sxp=0 then
   begin
    TryToUpdate(sx  ,sy,0                    ,syp);
    TryToUpdate(sx-1,sy,IntSeg[FSegmentation],syp);
   end                      else
  if syp=0 then
   begin
    TryToUpdate(sx,sy  ,sxp,0);
    TryToUpdate(sx,sy-1,sxp,IntSeg[FSegmentation]);
   end                      else TryToUpdate(sx,sy,sxp,syp);
end;

function TMap.GetNormal(x,y:integer):TPoint3D;
var sx,sy,sxp,syp:word;
begin
  if x<w then DivMod(x,word(IntSeg[FSegmentation]),sx,sxp)
         else
   begin
    sx:=word(NumHorizSegments-1);
    sxp:=word(IntSeg[FSegmentation]);
   end;
  if y<h then DivMod(y,word(IntSeg[FSegmentation]),sy,syp)
         else
   begin
    sy:=word(NumVertSegments-1);
    syp:=word(IntSeg[FSegmentation]);
   end;

   Result:=Segments[sx][sy].Normal[sxp,syp];
end;

procedure TMap.SetNormal(x,y:integer;v:TPoint3D);

  procedure TryToUpdate(sx,sy,sxp,syp:integer);
  begin
    if (sx>=0)and(sy>=0)and(sx<NumHorizSegments)and(sy<NumVertSegments)then Segments[sx][sy].Normal[sxp,syp]:=v;
  end;

var sx,sy,sxp,syp:word;
begin
  DivMod(x,word(IntSeg[FSegmentation]),sx,sxp);
  DivMod(y,word(IntSeg[FSegmentation]),sy,syp);
  if (sxp=0)and(syp=0) then
   begin
    TryToUpdate(sx  ,sy  ,0                    ,0);
    TryToUpdate(sx-1,sy  ,IntSeg[FSegmentation],0);
    TryToUpdate(sx  ,sy-1,0                    ,IntSeg[FSegmentation]);
    TryToUpdate(sx-1,sy-1,IntSeg[FSegmentation],IntSeg[FSegmentation]);
   end                      else
  if sxp=0 then
   begin
    TryToUpdate(sx  ,sy,0                    ,syp);
    TryToUpdate(sx-1,sy,IntSeg[FSegmentation],syp);
   end                      else
  if syp=0 then
   begin
    TryToUpdate(sx,sy  ,sxp,0);
    TryToUpdate(sx,sy-1,sxp,IntSeg[FSegmentation]);
   end                      else TryToUpdate(sx,sy,sxp,syp);
end;

operator =(a,b:TPoint3D):boolean;
begin
     result:= (a.x=b.x) and (a.y=b.y) and (a.z=b.z);
end;

procedure TMap.Draw();
var rx,ry,x,y:integer;
    sx,sy:glFloat;
    i:integer;
begin
  if self<>nil then
   begin
    if FOwner.Config.VBOsEnabled then
     glBindBufferARB(GL_ARRAY_BUFFER_ARB,0);//we're drawing from Vertex Arrays for now

    //check for visibility

    glColor4f(0,0,0,0);

    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);

    glDisable(GL_LIGHTING);
    glDisable(GL_TEXTURE_2D);

    glDepthMask(GL_FALSE);
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);

    for x:=0 to NumHorizSegments-1 do
     for y:=0 to NumVertSegments-1 do
     Segments[x][y].Loop();

    glDepthMask(GL_TRUE);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);

    glEnable(GL_LIGHTING);
    glEnable(GL_TEXTURE_2D);

    glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    glColor4f(1,1,1,1);

    //draw visible segments
    
    glBindTexture(GL_TEXTURE_2D,InternalTileset.Handle);

    for x:=0 to NumHorizSegments-1 do
     for y:=0 to NumVertSegments-1 do
      if Segments[x][y].Hit then
       begin
        glVertexPointer(3,GL_FLOAT,0,@Segments[x][y].VertexArray[0]);
        glNormalPointer(GL_FLOAT,0,  @Segments[x][y].NormalArray[0]);
        glTexCoordPointer(2,GL_FLOAT,0,  @Segments[x][y].TexCoordArray[0]);

        glDrawArrays(GL_TRIANGLES,0,length(Segments[x][y].VertexArray));
       end;

    if DrawGrid then
     begin
      sx:=glFloat((Width+1)/-2);
      sy:=glFloat((Height+1)/-2);

      glDisable(GL_LIGHTING);
      glDisable(GL_TEXTURE_2D);
      glColor4f(1,1,1,1);

      for rx:=0 to NumHorizSegments-1 do
       for ry:=0 to NumVertSegments-1 do
        if Segments[rx][ry].hit then
         begin
          for x:=rx*IntSeg[FSegmentation] to (rx+1)*IntSeg[FSegmentation] do
           begin
            glBegin(GL_LINE_STRIP);
            for y:=ry*IntSeg[FSegmentation] to (ry+1)*IntSeg[FSegmentation] do
             glVertex3f(sx+x,Heightmap[x,y],sy+y);
            glEnd();
           end;
          for y:=ry*IntSeg[FSegmentation] to (ry+1)*IntSeg[FSegmentation] do
           begin
            glBegin(GL_LINE_STRIP);
            for x:=rx*IntSeg[FSegmentation] to (rx+1)*IntSeg[FSegmentation] do
             glVertex3f(sx+x,Heightmap[x,y],sy+y);
            glEnd();
           end;
         end;

      glEnable(GL_LIGHTING);
      glEnable(GL_TEXTURE_2D);
     end;
   end;
end;

function TMap.Pick(Ray:TRay):vec3;
var i,l,x,y:integer;
    p,min:glFloat;
    res:vec3;
    hit:boolean;
    sx,sy:glFloat;
    c:array of TPoint3D;
begin
  sx:=glFloat((w+1)/-2);
  sy:=glFloat((h+1)/-2);
  Result[0]:=-1234567;
  Result[1]:=-1234567;
  Result[2]:=-1234567;
  min:=1000000000;

   for x:=0 to NumHorizSegments-1 do
    for y:=0 to NumVertSegments-1 do
     if Segments[x][y].Hit then
      begin
       i:=0;
       c:=Segments[x][y].VertexArray;
       l:=length(c);
       while i<l do
        begin
         hit:=RayHitsTriangleDist(Ray.Origin,Ray.Direction,vec3(c[i]),vec3(c[i+1]),vec3(c[i+2]),res,p);
         inc(i,3);

         if (hit)and(p<min) then
          begin
           min:=p;
           Result:=res;
          end;
        end;
      end;
end;

procedure TMap.SetHeightmap(x,y:integer;v:glFloat);

  function CalcNormal(x,y:integer):vec3;{inline;}

  var divident:integer=6;

    function GetH(vx,vy:integer):glFloat;{inline;}
    begin
     if (vx<0)or(vx>w)or(vy<0)or(vy>h)then
      begin
       dec(divident);
       exit(0);
      end;
     Result:=Heightmap[vx,vy];
    end;

  begin
    Result:=(
    //1
    uMath.Normal(vector(0,GetH(x,y),0),vector(-1,GetH(x-1,y),0),vector(0,GetH(x,y-1),-1))+
    //2
    uMath.Normal(vector(0,GetH(x,y),0),vector(0,GetH(x,y-1),-1),vector(1,GetH(x+1,y-1),-1))+
    //3
    uMath.Normal(vector(0,GetH(x,y),0),vector(1,GetH(x+1,y-1),-1),vector(1,GetH(x+1,y),0))+
    //4
    uMath.Normal(vector(0,GetH(x,y),0),vector(1,GetH(x+1,y),0),vector(0,GetH(x,y+1),1))+
    //5
    uMath.Normal(vector(0,GetH(x,y),0),vector(0,GetH(x,y+1),1),vector(-1,GetH(x-1,y+1),1))+
    //6
    uMath.Normal(vector(0,GetH(x,y),0),vector(-1,GetH(x-1,y+1),1),vector(-1,GetH(x-1,y),0))
    )*glFloat(1/divident);
    ;
  end;

begin
  //keep in interval
  if v<0 then v:=0;
  //update geometry
  Vertex[x,y]:=TPoint3D(Vector(glFloat(x-(Width+1)/2),v,glFloat(y-(Height+1)/2)));
  FHeightMap[x,y]:=v;
  //recalculate normals
  //1
  if x>0 then Normal[x-1,y]:=TPoint3D(CalcNormal(x-1,y));
  //2
  if y>0 then Normal[x,y-1]:=TPoint3D(CalcNormal(x,y-1));
  //3
  if (y>0)and(x<Width-1)then Normal[x+1,y-1]:=TPoint3D(CalcNormal(x+1,y-1));
  //4
  if x<Width-1 then Normal[x+1,y]:=TPoint3D(CalcNormal(x+1,y));
  //5
  if y<Height-1 then Normal[x,y+1]:=TPoint3D(CalcNormal(x,y+1));
  //6
  if (x>0)and(y<Height-1)then Normal[x-1,y+1]:=TPoint3D(CalcNormal(x-1,y+1));
  //self
  Normal[x,y]:=TPoint3D(CalcNormal(x,y));
end;

procedure TMap.SetTextureMap(x, y: integer; v: byte);
begin
  FTextureMap[x][y]:=v;
  //solve dependencies
  if (x>0) and (y>0) and (FTextureMap[x-1][y-1]=FTextureMap[x][y]) and
  (FTextureMap[x-1][y]<>FTextureMap[x][y]) and
  (FTextureMap[x][y-1]<>FTextureMap[x][y]) then SetTextureMap(x-1,y,v);
  
  if (x<Width) and (y>0) and (FTextureMap[x+1][y-1]=FTextureMap[x][y]) and
  (FTextureMap[x+1][y]<>FTextureMap[x][y]) and
  (FTextureMap[x][y-1]<>FTextureMap[x][y]) then SetTextureMap(x,y-1,v);
  
  if (x<Width) and (y<Height) and (FTextureMap[x+1][y+1]=FTextureMap[x][y]) and
  (FTextureMap[x+1][y]<>FTextureMap[x][y]) and
  (FTextureMap[x][y+1]<>FTextureMap[x][y]) then SetTextureMap(x+1,y,v);
  
  if (x>0) and (y<Height) and (FTextureMap[x-1][y+1]=FTextureMap[x][y]) and
  (FTextureMap[x-1][y]<>FTextureMap[x][y]) and
  (FTextureMap[x][y+1]<>FTextureMap[x][y]) then SetTextureMap(x,y+1,v);
  

  if (x>0) and (y>0)and
     (FTextureMap[x][y-1]=FTextureMap[x-1][y])and
     (FTextureMap[x][y-1]<>FTextureMap[x][y])and
     (FTextureMap[x][y-1]<>FTextureMap[x-1][y-1])then SetTextureMap(x-1,y,v);
  if (x<Width) and (y>0)and
     (FTextureMap[x][y-1]=FTextureMap[x+1][y])and
     (FTextureMap[x][y-1]<>FTextureMap[x][y])and
     (FTextureMap[x][y-1]<>FTextureMap[x+1][y-1])then SetTextureMap(x,y-1,v);
  if (x<Width) and (y<Height)and
     (FTextureMap[x+1][y]=FTextureMap[x][y+1])and
     (FTextureMap[x+1][y]<>FTextureMap[x][y])and
     (FTextureMap[x+1][y]<>FTextureMap[x+1][y+1])then SetTextureMap(x+1,y,v);
  if (x>0) and (y<Height)and
     (FTextureMap[x][y+1]=FTextureMap[x-1][y])and
     (FTextureMap[x][y+1]<>FTextureMap[x][y])and
     (FTextureMap[x][y+1]<>FTextureMap[x-1][y+1])then SetTextureMap(x,y+1,v);

  //update texturemap
  
  if (x<Width)and(y<Height) then
   begin
    Segments[x div FSegmentSize]
            [y div FSegmentSize].TexCoord[x mod FSegmentSize,y mod FSegmentSize]:=
    InternalTileset.TexCoords[FTextureMap[x  ][y  ]]
                             [FTextureMap[x+1][y  ]]
                             [FTextureMap[x+1][y+1]]
                             [FTextureMap[x  ][y+1]];
   end;

  if (x>0)and(y<Height) then
   begin
    Segments[(x-1) div FSegmentSize]
            [y     div FSegmentSize].TexCoord[(x-1) mod FSegmentSize,y mod FSegmentSize]:=
    InternalTileset.TexCoords[FTextureMap[x-1][y  ]]
                             [FTextureMap[x  ][y  ]]
                             [FTextureMap[x  ][y+1]]
                             [FTextureMap[x-1][y+1]];
   end;

  if(x>0)and(y>0)then
   begin
    Segments[(x-1) div FSegmentSize]
            [(y-1) div FSegmentSize].TexCoord[(x-1) mod FSegmentSize,(y-1) mod FSegmentSize]:=
    InternalTileset.TexCoords[FTextureMap[x-1][y-1]]
                             [FTextureMap[x  ][y-1]]
                             [FTextureMap[x  ][y  ]]
                             [FTextureMap[x-1][y  ]];
   end;

  if (y>0)and(x<Width) then
   begin
    Segments[ x    div FSegmentSize]
            [(y-1) div FSegmentSize].TexCoord[x mod FSegmentSize,(y-1) mod FSegmentSize]:=
    InternalTileset.TexCoords[FTextureMap[x  ][y-1]]
                             [FTextureMap[x+1][y-1]]
                             [FTextureMap[x+1][y  ]]
                             [FTextureMap[x  ][y  ]];
   end;
end;

