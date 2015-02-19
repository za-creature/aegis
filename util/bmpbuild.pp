{$mode objfpc} 
uses sysutils; 

type TBitmap=class(TOBject)
        protected
         data:pDword;
         w,h:integer;
        public
         property width:integer read w;
         property height:integer read h;
         procedure Alloc(wd,ht:integer);
         Function GetPixel(X,Y: Integer): dword;
         procedure SetPixel(x,y:integer;value:dword);
         procedure LoadFromFile(filename:ansistring);
         procedure SaveToFile(filename:ansistring);
         procedure Draw(x,y:integer;target:TBitmap);
end;

function gw(w:integer):integer;
begin
 if w mod 4<>0 then gw:=4*(w div 4+1)
               else gw:=w;
end;

procedure TBitmap.Alloc(wd,ht:integer);
begin
        if data<>nil then freemem(data);
        w:=wd;
        h:=ht;
        getmem(data,w*h*4);
        fillDword(data[0],w*h,0); 
end;

function TBitmap.GetPixel(X,Y: Integer): dword;
begin
     if (x<w)and(y<h)then Result:=data[y*w+x]
                     else Result:=0;      
end;
 
procedure TBitmap.SetPixel(x,y:integer;value:dword);
begin
     Data[y*w+x]:=value; 
end; 


procedure TBitmap.Draw(x,y:integer;target:TBitmap);
var tx,ty:integer;
begin
        for tx:=0 to width-1 do
         for ty:=0 to height-1 do 
          target.SetPixel(x+tx,y+ty,GetPixel(tx,ty));
end;

procedure TBitmap.LoadFromFile(filename:ansistring);
var b:word;
    x,y,size,f:integer;
    tmp:array[0..11] of char;
begin
        if data<>nil then FreeMem(data);
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
        fileread(f,w,4);//w
        fileread(f,h,4);//h
        getmem(data,w*h*4);
        fileread(f,b,2);//PLANES
        fileread(f,b,2);//BPP
        if b<>24 then 
         begin
          fileclose(f);
          exit;
         end;
        fileread(f,size,4);//NO COMPRESSION
        fileread(f,size,4);//NO COMPRESSION
        fileread(f,size,4);//HORIZONTAL DPI
        fileread(f,size,4);//VERTICAL DPI
        fileread(f,size,4);//NUMBER OF COLORS
        fileread(f,size,4);//IMPORTANT COLORS
        for y:=h-1 downto 0 do
         begin
          for x:=0 to w-1 do
           begin 
            data[y*w+x]:=$ffffffff; 
            fileread(f,data[y*w+x],3);
           end; 
          if w mod 4<>0 then fileread(f,tmp,w mod 4);
         end;
	fileclose(f);

end;


procedure TBitmap.SaveToFile(filename:ansistring);
var f:integer;
    i,y,size:integer;
    p:dword;
    a:word;
begin
        size:=54+gw(w)*h*3;
        if fileexists(filename) then f:=fileopen(filename,fmOpenWrite)
                                else f:=filecreate(filename);
        filewrite(f,19778,2);//BM
        filewrite(f,size,4);//FILE SIZE 0
        p:=0;
        filewrite(f,p,4);//ALWAYS 0
        //filewrite(f,0,2);//ALWAYS 0
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
           filewrite(f,data[i],4*w);
          end;
	fileclose(f);
end;

{procedure TTexture.LoadFromBMP(filename:ansistring);
var b:word;
    y,i,size,f:integer;
    hasalpha:boolean=false;
    data:pByte;
begin
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
  if (b<>24)or(b<>32) then
   begin
    fileclose(f);
    exit;
   end;
  hasalpha:=b=32;
  getmem(data,w*h*(b div 8));
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

  glGenTextures(1, @Handle);
  glBindTexture(GL_TEXTURE_2D, Handle);
  FOwner.Filter();
  if hasalpha then gluBuild2DMipmaps(GL_TEXTURE_2D, 4, w, h, GL_BGRA, GL_UNSIGNED_BYTE, data)
              else gluBuild2DMipmaps(GL_TEXTURE_2D, 3, w, h, GL_BGRA, GL_UNSIGNED_BYTE, data);

  freemem(data);
end;} 

var outmap,colormap,alphamap:TBitmap; 
    x,y:integer; 
    p:dword; 
    a:byte; 
begin
     if paramcount<>3 then
      begin
       writeln('Usage: bmpbuild colormap alphamap output'); 
       readln; 
       exit; 
      end; 
     colormap:=TBitmap.Create();
     alphamap:=TBItmap.Create();
     outmap:=TBitmap.Create(); 
     
     colormap.LoadFromFile(paramstr(1));
     alphamap.LoadFromFile(paramstr(2)); 
     outmap.Alloc(colormap.width,colormap.height); 
     
     for x:=0 to colormap.width-1 do
      for y:=0 to colormap.height-1 do
       begin 
        p:=alphamap.GetPixel(x,y); 
        a:=(pByte(@p)[0]+pByte(@p)[1]+pByte(@p)[2]) div 3; 
        p:=colormap.GetPixel(x,y);
        pByte(@p)[3]:=a; 
        outmap.SetPixel(x,y,p); 
       end; 
     
     
     outmap.SaveToFile(paramstr(3)); 
     
     outmap.Free(); 
     colormap.Free();
     alphamap.Free(); 
end. 
