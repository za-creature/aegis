{TTexture}

function TTexture.LoadDDSTextureFile(filename:ansistring):pDDS_IMAGE_DATA;
var ddsd:TDDSurfaceDesc2;
    pfile:integer;
    filecode:array [0..3] of char;
    pData:pDDS_IMAGE_DATA;
    nSize,nWidth,nHeight,nBlockSize,i:integer;
begin
  try
   pFile:=fileOpen(filename,fmOpenRead);
   if (pFile=-1)or(pFile=0) then raise Exception.Create('Could not open file');
   fileread(pFile,filecode,4);
   if filecode<>'DDS ' then exit(nil);
   fileread( pFile, ddsd, sizeof(ddsd));
  
   getmem(pData,sizeof(DDS_IMAGE_DATA));
   fillchar(pData^,sizeof(DDS_IMAGE_DATA),0);

   case ddsd.ddpfPixelFormat.dwFourCC of
    FOURCC_DXT1:
     begin
      // DXT1's compression ratio is 8:1
      pData^.format := GL_COMPRESSED_RGBA_S3TC_DXT1_EXT;
      nBlockSize:=8;
     end;
    FOURCC_DXT3:
     begin
      // DXT3's compression ratio is 4:1
      pData^.format := GL_COMPRESSED_RGBA_S3TC_DXT3_EXT;
      nBlockSize:=16;
     end;
    FOURCC_DXT5:
     begin
      // DXT5's compression ratio is 4:1
      pData^.format := GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;
      nBlockSize:=16;
     end
   end;

   getmem(pData^.pixels,sizeof(pByte)*ddsd.dwMipMapCount);

   nWidth:=ddsd.dwWidth;
   nHeight:=ddsd.dwHeight;

   for i:=0 to ddsd.dwMipMapCount-1 do
    begin
     if nWidth  = 0 then nWidth  := 1;
     if nHeight = 0 then nHeight := 1;
     //get size
     nSize := ((nWidth+3) div 4) * ((nHeight+3) div 4) * nBlockSize;
     getmem(pData^.Pixels[i],nSize);
     fileread(pFile,pData^.pixels[i]^,nSize);
     //half
     nWidth:=nWidth div 2;
     nHeight:=nHeight div 2;
    end;

   fileclose( pFile );

   pData^.width      := ddsd.dwWidth;
   pData^.height     := ddsd.dwHeight;
   pData^.numMipMaps := ddsd.dwMipMapCount;


   if ddsd.ddpfPixelFormat.dwFourCC = FOURCC_DXT1 then pData^.components := 3
                                                  else pData^.components := 4;

   Result:=pData;
  except
   if pData<>nil then
    begin
     for i:=0 to pData^.NumMipMaps-1 do
      if pData^.pixels[i]<>nil then freemem(pData^.Pixels[i]);
     if pData^.pixels<>nil then freemem(pData^.pixels);
    end;
    
   Result:=nil;
  end;
end;

procedure TTexture.LoadFromBMP(filename:ansistring);
var b:word;
    l,wi,he,y,i,size,f:integer;
    hasalpha:boolean=false;
    data:pByte=nil;
begin
  try
   Handle:=High(Handle);
   f:=fileopen(filename,fmOpenRead);
   if (f=0)or(f=-1)then raise Exception.Create('An IO Exception has Occured');
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

   getmem(data,w*h*(b div 8));
   
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
      i := 4*(y*w);
      fileread(f,data[i],4*w);
     end       else
    for y:=h-1 downto 0 do
     begin
      i := 3*(y*w);

      fileread(f,data[i],3*w);
     end;
    fileclose(f);

   glGenTextures( 1, @Handle);
   glBindTexture(GL_TEXTURE_2D, Handle);
   FOwner.Filter(true);
   if FOwner.Config.TextureCompression then
    begin
     if hasalpha then BuildCompressedMipmaps(GL_TEXTURE_2D,GL_COMPRESSED_RGBA_S3TC_DXT5_EXT,w,h,GL_BGRA,GL_UNSIGNED_BYTE,data)
                 else BuildCompressedMipmaps(GL_TEXTURE_2D,GL_COMPRESSED_RGB_S3TC_DXT1_EXT ,w,h,GL_BGR ,GL_UNSIGNED_BYTE,data);
    end
   else
    begin
     if hasalpha then gluBuild2DMipmaps(GL_TEXTURE_2D,GL_RGBA,w,h,GL_BGRA,GL_UNSIGNED_BYTE,data)
                 else gluBuild2DMipmaps(GL_TEXTURE_2D,GL_RGB ,w,h,GL_BGR ,GL_UNSIGNED_BYTE,data);
    end;
   freemem(data);
  except
   //release resources
   if data<>nil then freemem(data);
   if Handle<>High(Handle) then glDeleteTextures(1,@Handle);
   raise Exception.Create('Unable to load BMP image');
  end;
end;

procedure TTexture.LoadFromDDS(filename:ansistring);
var pDDSImageData:pDDS_IMAGE_DATA;
    i,nSize,nOffset,nHeight,nwidth,nNumMipMaps,nBlockSize:integer;
begin
  pDDSImageData:=LoadDDSTexturefile(filename);

  if pDDSImageData<>nil then
   begin
    nHeight     := pDDSImageData^.height;
    nWidth      := pDDSImageData^.width;
    nNumMipMaps := pDDSImageData^.numMipMaps;

    if (pDDSImageData^.format=GL_COMPRESSED_RGBA_S3TC_DXT1_EXT)or
       (pDDSImageData^.format=GL_COMPRESSED_RGB_S3TC_DXT1_EXT )then nBlockSize:=8
                                                               else nBlockSize:=16;

    glGenTextures( 1, @Handle);
    glBindTexture( GL_TEXTURE_2D, Handle );
    FOwner.Filter(true);

    nOffset := 0;

    //load
    for i:=0 to nNumMipMaps-1 do
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
   end
  else raise Exception.Create('Unable to load DDS image');
end;

procedure TTexture.LoadNullImage();

const t:array[0..1] of TColor32b=((t:$00ff00ff),(t:$00ffffff));

var data:array of TColor32b;
    i,j:byte;
begin
  setLength(data,64*64);

  for i:=0 to 63 do
   for j:=0 to 63 do
    data[i*64+j]:=t[(i+j) mod 2];

  glGenTextures(1,@Handle);
  glBindTexture(GL_TEXTURE_2D,Handle);

  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST );
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST );

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

  glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,64,64,0,GL_RGBA,GL_UNSIGNED_BYTE,@data[0]);

  setLength(data,0);
end;

procedure TTexture.LoadFromFile(filename:ansistring);
var ext:Ansistring;
begin
  try
    ext:=ExtractFileExt(filename);
    if(ext='.bmp') then LoadFromBMP(filename)
                   else LoadFromDDS(filename);
  except
    LoadNullImage();
  end;
end;

procedure TTexture.doFree();
begin
  if Handle<>0 then glDeleteTextures(1,@Handle);
end;
