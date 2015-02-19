unit uIO64;

{$I config.inc}
{$mode objfpc}{$H+}
{$inline off}

interface

uses
  Classes, SysUtils, GL, GLu, GLext, uMath, uCamera, Math, DOM, IniFiles,
  XMLread, XMLwrite;
  
  
{$i uIO64.inc}

type TIO64=class;
     TMap=class;
     TTileset=class;

     { TResource }

     TResource=class(TObject)
      protected
       FOwner:TIO64;
       procedure doFree();virtual;abstract;
       procedure LoadFromFile(filename:ansistring);virtual;abstract;
       procedure Free();virtual;
      public
       Tag:integer;
       NumPointers:integer;
       constructor Create(AOwner:TIO64;AFileName:ansistring);virtual;
       procedure MarkUnused();
       property Owner:TIO64 read FOwner;
     end;
     
     { TTexture }

     TTexture=class(TResource)
      protected
       FFilename:ansistring;
       w,h:integer;
       procedure LoadFromBMP(filename:ansistring);
       procedure LoadFromDDS(filename:ansistring);
       class function LoadDDSTextureFile(filename:ansistring):pDDS_IMAGE_DATA;{inline;}
       procedure doFree();override;
       procedure LoadFromFile(filename:ansistring);override;
       procedure LoadNullImage();
      public
       Handle:GLuint;
       property Width:integer read w;
       property Height:integer read h;
       property Filename:ansistring read FFilename;
     end;
     
     { TModel }
     
     TModel=class(TResource)
      protected
       //these will be chopped out
       TimeBase:TTimeStamp;
       MaxTime:integer;
      
       Mesh:array of TMesh;
       Joint:array of TJoint;
       Material:array of TMaterial;
       procedure LoadFromMS3D(filename:ansistring);
       procedure doFree();override;
      public
       procedure Draw();
       procedure LoadFromFile(filename:ansistring);override;
     end;
     
     { TLensFlare }
     
     TLensFlare=class(TResource)
      protected
       SubFlares:array of TSubFlare;
       procedure doFree();override;
       procedure RenderLensFlare(dx,dy:glint;scale,posvec:glFloat);{inline;}
      public
       procedure Draw(dx,dy:integer);
       procedure LoadFromFile(filename:ansistring);override;
     end;

     { TLightSource }

     TLightSource=class(TObject)
      private
       FConstantAttenuation: glFloat;
       FEnabled:boolean;
       FLensFlare: ansistring;
       FLinearAttenuation: glFloat;
       FQuadraticAttenuation: glFloat;
       FSpotCutoff: glFloat;
       FSpotDirection: vec3;
       FSpotExponent: glFloat;
       FInternalFlare:TLensFlare;
       FOwner:TIO64;
       
       pos:vec4;
       amb,diff,spec:vec4;
       truelight,haze,shadow:boolean;
       id:integer;
       hit:boolean;
       rx,ry:glFloat;
       
       radialblur:TTexture;
       procedure SetAmbient(v:vec4);
       procedure SetConstantAttenuation(const AValue: glFloat);
       procedure SetDiffuse(v:vec4);
       procedure SetLensFlare(const AValue: ansistring);
       procedure SetLinearAttenuation(const AValue: glFloat);
       procedure SetQuadraticAttenuation(const AValue: glFloat);
       procedure SetSpecular(v:vec4);
       procedure SetIsTrueLight(v:boolean);
       procedure SetShadow(v:boolean);
       procedure SetPosition(v:vec4);
       procedure SetEnabled(v:boolean);
       procedure SetSpotCutoff(const AValue: glFloat);
       procedure SetSpotDirection(const AValue: vec3);
       procedure SetSpotExponent(const AValue: glFloat);
      public
       constructor Create(AOwner:TIO64);
       procedure LoadPropertiesFromFile(AFilename:ansistring);
       procedure SavePropertiesToFile(AFilename:ansistring);
       procedure Free();
       procedure Draw();
       procedure Loop();
       property Owner:TIO64 read FOwner;
       
       property Position:vec4 read pos write SetPosition;
       property Ambient:vec4 read amb write SetAmbient;
       property Diffuse:vec4 read diff write SetDiffuse;
       property Specular:vec4 read spec write SetSpecular;
       property SpotExponent:glFloat read FSpotExponent write SetSpotExponent;
       property SpotDirection:vec3 read FSpotDirection write SetSpotDirection;
       property SpotCutoff:glFloat read FSpotCutoff write SetSpotCutoff;
       property ConstantAttenuation:glFloat read FConstantAttenuation write SetConstantAttenuation;
       property LinearAttenuation:glFloat read FLinearAttenuation write SetLinearAttenuation;
       property QuadraticAttenuation:glFloat read FQuadraticAttenuation write SetQuadraticAttenuation;
       
       property isTrueLight:boolean read truelight write setIsTrueLight;
       property ShowHaze:boolean read haze write haze;
       property LensFlare:ansistring read FLensFlare write SetLensFlare;
       property Shadowing:boolean read shadow write SetShadow;
       property Enabled:boolean read FEnabled write setEnabled;
     end;

     { TSkyBox }

     TSkyBox=class(TResource)
      private
       FDrawDepth: glFloat;
       FrontFace,BackFace,LeftFace,RightFace,TopFace,BottomFace:TTexture;
       width,height,depth:integer;
       w,h,d:glFloat;
       SkyboxVertex:array[0..7] of vec3;
       procedure doFree();override;
       procedure SetDrawDepth(const AValue: glFloat);
      public
       procedure LoadFromFile(filename:ansistring);override;
       property DrawDepth:glFloat read FDrawDepth write SetDrawDepth;
       procedure Draw();
     end;
     
     TShader=class(TResource)
      private
       vsh,fsh,prg:glHandleARB;
       vertexsource,fragmentsource:^glCharARB;
       vlength,flength:gluint;
       cmp,lnk:boolean;
       sfn:ansistring;
       class procedure ReadShader(filename:shortstring;var l:gluInt;var d:ppchar);

       function Compile():boolean;
       function Link():boolean;
       procedure doFree();override;
       procedure FreeSource();
      public
       constructor Create(AOwner:TIO64;Afilename:ansistring);override;
       
       property Compiled:boolean read cmp;
       property Linked:boolean read lnk;
       property SourceFileName:ansistring read sfn;
     end;
     
     { TSegment }

     TSegment=class(TObject)
      private
       FHit:boolean;
       FOwner:TIO64;
       Query:GLuint;
       FSegmentSize:integer;
       //VisibilityVertexArray:array[0..3] of TPoint3D;
       MinX,MaxX,MinY,MaxY,MinZ,MaxZ:glFloat;
       VertexArray,NormalArray:array of TPoint3D;
       TexCoordArray:array of TPoint2D;
       function GetTexCoord(x, y: integer): TexCoordSet;{inline;}
       function GetVertex(x,y:integer):TPoint3D;{inline;}
       function GetNormal(x,y:integer):TPoint3D;{inline;}
       procedure SetTexCoord(x, y: integer; const AValue: TexCoordSet);{inline;}
       procedure SetVertex(sxp,syp:integer;v:TPoint3D);{inline;}
       procedure SetNormal(sxp,syp:integer;v:TPoint3D);{inline;}
      public
       property Owner:TIO64 read FOwner;
       procedure Loop();
       constructor Create(AOwner:TIO64;asegmentsize:integer);
       procedure Free();
       property Vertex[x,y:integer]:TPoint3D read GetVertex write SetVertex;
       property Normal[x,y:integer]:TPoint3D read GetNormal write SetNormal;
       property TexCoord[x,y:integer]:TexCoordSet read GetTexCoord write SetTexCoord;
       property Hit:boolean read FHit;
     end;

     
     { TMap }

     TMap=class(TObject)
      protected
       FOwner:TIO64;
       //size
       w,h:integer;//must be multiple of 64 and in the range 0-512
       //some basic properties
       FDrawGrid:boolean;
       //heightmap
       FHeightMap:array of array of glFloat;
       //texturemap
       FTileset: ansistring;
       InternalTileset:TTileset;
       FTexturemap:array of array of byte;
       ///segmentation
       FSegmentation:integer;
       FSegmentSize:integer;
       Segments:array of array of TSegment;
       NumHorizSegments,NumVertSegments:integer;

       procedure SetSegmentation(v:integer);
       
       function GetHeightmap(x,y:integer):glFloat;
       function GetTexturemap(x,y:integer):byte;

       function GetVertex(x,y:integer):TPoint3D;
       function GetNormal(x,y:integer):TPoint3D;

       procedure SetVertex(x,y:integer;v:TPoint3D);
       procedure SetNormal(x,y:integer;v:TPoint3D);

       property Vertex[x,y:integer]:TPoint3D read GetVertex write SetVertex;
       property Normal[x,y:integer]:TPoint3D read GetNormal write SetNormal;

       procedure SetHeightMap(x,y:integer;v:glFloat);
       procedure SetTextureMap(x,y:integer;v:byte);
      public
       Author,Title,Description:ansistring;
       
       constructor Create(AOwner:TIO64;AWidth,AHeight:integer;ATileset:ansistring);
       constructor Create(AOwner:TIO64;AFilename:ansistring);


       procedure SaveToFile(AFilename:ansistring);
       procedure Free();

       procedure Draw();
       function Pick(Ray:TRay):vec3;

       property Segmentation:integer read FSegmentation write SetSegmentation;
       
       property Heightmap[x,y:integer]:glFloat read GetHeightMap write SetHeightMap;
       property Texturemap[x,y:integer]:byte read GetTextureMap write SetTextureMap;
       property DrawGrid:boolean read FDrawGrid write FDrawGrid;
       
       property Width:integer read w;
       property Height:integer read h;
       property Tileset:ansistring read FTileset;
     end;

     TConfig=class(TObject)
      private
       FFilename:ansistring;
      public
       VSync,Log,Fullscreen:boolean;
       Segmentation:integer;
       Width,Height,TextureFilter,MaxLightSources,MaxShaders,DrawDistance,ColorDepth,x,y:integer;
       TextureCompression,ShowNormals,ShowWire,ViewComponentPalette,ViewViewport:boolean;
       MoveSensitivity,TiltSensitivity,WheelSensitivity:glFloat;
       SyncControlEnabled,DoNotCompileOnDemand,VBOsEnabled,QueriesEnabled:boolean;
       AegisDir:ansistring;
       font:ansistring;
       constructor Create(Afilename:ansistring);
       procedure Load();
       procedure Save();
       property FileName:ansistring read FFilename;
     end;
     
     { TIO64 }

     TIO64=class(TObject)
      private
       FCamera:TCamera;
       FConfig:TConfig;
       FonStateChange: CallbackProc;
       FSkyBox:TSkyBox;
       Resources:array of TResource;
       ResourceNames:array of ansistring;
       procedure SetonStateChange(const AValue: CallbackProc);
       Lights:array of TLightSource;
       EnabledLights:array of boolean;
       procedure SetOrtho();{inline;}
       procedure SetPerspective();{inline;}
      public
       constructor Create(AConfig:TConfig);
       procedure Free();
       MyQuery:gluint;
       LightOut:array[0..3] of glFloat;
       viewport:array[0..3] of glInt;
       
       procedure Filter(mips:boolean);
       
       //light manager
       function AddLightSource():TLightSource;
       procedure RemoveLightSource(id:integer);
       //skybox manager
       procedure LoadSkyBox(filename:ansistring);
       //resource manager
       function GetResource(filename:ansistring):TResource;
       procedure NotifyDestroyed(Tag:integer);
       //internal
       function RequestLightId():integer;
       procedure FreeLightId(id:integer);
       
       procedure DrawLensFlare();
       procedure Draw();
       
       property Camera:TCamera read FCamera;
       property Config:TConfig read FConfig;
       property SkyBox:TSkyBox read FSkybox;
       property onStateChange:CallbackProc read FonStateChange write SetonStateChange;
     end;
     
    { TBitmap24 }
     
    TBitmap24=class(TObject)
     protected
      data:array of TColor24b;
      FOwner:TIO64;
      w,h:integer;
      function GetPixel(x,y:integer):TColor32b;virtual;{inline;}
      procedure SetPixel(x,y:integer;v:TColor32b);virtual;{inline;}
     public
      property Width:integer read w;
      property Height:integer read h;
      property Pixels[x,y:integer]:TColor32b read GetPixel write SetPixel;
      procedure SaveToFile(filename:ansistring);
      procedure SaveToDDS(filename:ansistring);
      procedure SaveToBMP(filename:ansistring);
      procedure Alloc(aw,ah:integer);
      constructor Create(AOwner:TIO64);
      procedure Free();
    end;

    { TBitmap }

    TBitmap=class(TBitmap24)
     protected
      data2:array of TColor32b;
      function GetPixel(x,y:integer):TColor32b;override;{inline;}
      procedure SetPixel(x,y:integer;v:TColor32b);override;{inline;}
     public
      procedure LoadFromFile(filename:ansistring);
      procedure LoadAlphaChannel(filename:ansistring);
      procedure CopyFrom(src:TBitmap);
      procedure SaveToFile(filename:ansistring);
      procedure SaveToBMP(filename:ansistring);
      procedure SavetoDDS(filename:ansistring);
      procedure Alloc(aw,ah:integer);
      procedure Draw(x,y:integer;r:integer;dst:TBitmap24);
      procedure Free();
     end;
     
    { TLayer }
     
    TLayer=class(TObject)
     protected
      FOwner:TIO64;
     public
      property Owner:TIO64 read FOwner;
      name:ansistring;
      cmap,c2map,c3map:TBitmap;
      variations:array of TBitmap;
      procedure AddTexture(filename:ansistring);
      procedure Free();
      constructor Create(AOwner:TIO64);
    end;
    
    { TTileset }

    TTileset=class(TResource)
     private
      FName:ansistring;
      TexCoords:array[0..7] of array[0..7] of array[0..7] of array[0..7] of TexCoordSet;
      LayerCount:integer;
      Layers:array[0..7] of TLayer;
      FHandle:gluint;
     public
      property Handle:gluint read FHandle;
      property Name:ansistring read FName;

      procedure LoadFromFile(filename:ansistring);override;
      procedure doFree();override;
    end;
    
    { TAnimation }
    
    TAnimation=class(TResource)
     private
      Animations:array of TInternalAnimation;
      Timebase:TTimeStamp;
      FCurrentAnimation:integer;
      procedure doFree();override;
      procedure LoadFromFile(filename:ansistring);override;
     public
      procedure Apply(Model:TModel);
      procedure Start(id:integer);
      procedure Start(name:ansistring);
    end;

implementation

procedure BuildCompressedMipmaps(target:glenum;iformat,width,height:glint;format,atype:glsizei;data:pointer);
var blah,aux,data2:pointer;
    Rw,Rh,ss:integer;
    level:integer=0;
begin
  Rw:=1 shl trunc(log2(width));
  Rh:=1 shl trunc(log2(height));
  if (format=GL_RGB)or(iformat=GL_BGR) then blah:=GetMemory(Rw*Rh*3)
                                       else blah:=GetMemory(Rw*Rh*4);
  data2:=blah;

  while (rw>0)and(rh>0) do
   begin
    if (width<>rw)or(height<>rh) then gluScaleImage(format,width,height,atype,data,rw,rh,atype,data2)
    else
     begin
      //good ol' flip flop
      aux:=data;
      data:=data2;
      data2:=aux;
     end;
    glTexImage2D(target,level,iformat,rw,rh,0,format,atype,data2);
    //increase level
    inc(level);
    //flip flopt
    aux:=data;
    data:=data2;
    data2:=aux;
    //update sizes
    width:=Rw;
    height:=Rh;
    Rw:=Rw div 2;
    Rh:=Rh div 2;
   end;
  FreeMemory(blah);
end;

{TResource}

constructor TResource.Create(AOwner:TIO64;AFileName:ansistring);
begin
  inherited Create();
  Tag:=-1;
  NumPointers:=1;
  FOwner:=AOwner;
  LoadFromFile(AFileName);
end;

procedure TResource.MarkUnused();
begin
  if self<>nil then
   begin
    dec(NumPointers);
    if (NumPointers=0)and(Tag<>-1) then
    FOwner.NotifyDestroyed(Tag);
   end;
end;

procedure TResource.Free();
begin
     if self<>nil then doFree();
     inherited Free();
end;

{$I uIO64_Timer.inc}
{$I uIO64_Config.inc}
{$I uIO64_Map.inc}
{$I uIO64_Model.inc}
{$I uIO64_Texture.inc}
{$I uIO64_Skybox.inc}
{$I uIO64_LightSource.inc}
{$I uIO64_Shader.inc}
{$I uIO64_LensFlare.inc}
{$I uIO64_Animation.inc}

{TIO64}

constructor TIO64.Create(AConfig:TConfig);
begin
  inherited Create();
  FConfig:=AConfig;
  {$ifdef debug_l2}
  writeln('  io64: Linking with OpenGL');
  {$endif}
  InitOpenGL();
  {$ifdef debug_l2}
  writeln('  io64: Configuring the OpenGL pipeline');
  {$endif}
  glShadeModel(GL_SMOOTH);
  glClearColor(0,0,0,0);
  glClearDepth(1);
  //Depth Test
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);
  glFrontFace(GL_CW);
  glCullFace(GL_BACK);
  glEnable(GL_CULL_FACE);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  //VBOs
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  //lightning
  glEnable(GL_LIGHTING);
  //alpha blending
  glDisable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA,GL_ONE);
  //line properties
  glDisable(GL_LINE_STIPPLE);
  glLineWidth(2);
  glLineStipple(4,$AAAA);
  //texture
  glEnable(GL_TEXTURE_2D);
  {$ifdef debug_l2}
  writeln('  io64: Initializing the Query System');
  {$endif}
  Config.QueriesEnabled:=glGenQueriesARB<>nil;
  Config.VBOsEnabled:=glGenBuffersARB<>nil;
  Config.SyncControlEnabled:=wglSwapIntervalEXT<>nil;
  if Config.QueriesEnabled then glGenQueriesARB(1,@myquery)
  else
   {$ifdef debug_l3}
   writeln('   io64: Could not load the GL_ARB_occlusion_query extension. This will be slow.');
   {$endif}
  {$ifdef debug_l2}
  writeln('  io64: Setting up the Feedback Buffer');
  {$endif}
  glFeedBackBuffer(3,GL_2D,LightOut);
  {$ifdef debug_l2}
  writeln('  io64: Creating the Camera');
  {$endif}
  FCamera:=TCamera.Create();
end;

procedure TIO64.Free();
var i:integer;
begin
  if Camera<>nil then
   begin
    {$ifdef debug_l2}
    writeln(' io64: Releasing Camera');
    {$endif}
    FCamera.Free();
    FCamera:=nil;
   end;
  if Config.QueriesEnabled then
   begin
    {$ifdef debug_l2}
    writeln('  io64: Uninitializing the Query System');
    {$endif}
    glDeleteQueriesARB(1,@myquery)
   end;
  if Skybox<>nil then
   begin
    {$ifdef debug_l2}
    writeln(' io64: Releasing Skybox');
    {$endif}
    FSkybox.MarkUnused();
    FSkybox:=nil;
   end;
  if length(Lights)<>0 then
   begin
    {$ifdef debug_l2}
    writeln(' io64: Releasing Lights');
    {$endif}
    for i:=0 to length(Lights)-1 do RemoveLightSource(i);
   end;
  if length(Resources)<>0 then
   begin
    {$ifdef debug_l2}
    writeln(' io64: Releasing Resources');
    {$endif}
    i:=0;
    while i<length(Resources) do
     begin
      if Resources[i]<>nil then
       begin
        Resources[i].NumPointers:=1;
        Resources[i].MarkUnused();
       end;
      inc(i);
     end;
   end;
  {$ifdef debug_l2}
  writeln('  io64: Unlinking OpenGL');
  {$endif}
  DoneOpenGL();
  inherited Free();
end;

//Internal Use

procedure TIO64.SetonStateChange(const AValue: CallbackProc);
begin
  FonStateChange:=AValue;
end;

procedure TIO64.SetOrtho();
begin
  glPushMatrix();
   glPushAttrib(GL_TRANSFORM_BIT);
   glGetIntegerv(GL_VIEWPORT, ViewPort);
   glMatrixMode(GL_PROJECTION);
   glPushMatrix();
    glLoadIdentity();
    gluOrtho2D(ViewPort[0],ViewPort[2],ViewPort[1],ViewPort[3]);
    glPopAttrib();

    glDisable(GL_DEPTH_TEST);
    glDisable(GL_LIGHTING);
    glEnable(GL_BLEND);
    //glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_COLOR);
    glBlendfunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
   
    glLoadIdentity();
end;

procedure TIO64.SetPerspective();
begin
    glDisable(GL_BLEND);
    glEnable(GL_LIGHTING);
    glEnable(GL_DEPTH_TEST);

    glPushAttrib(GL_TRANSFORM_BIT);
    glMatrixMode(GL_PROJECTION);
   glPopMatrix();
   glPopAttrib();
  glPopMatrix();
end;

//Texture Filtering

procedure TIO64.Filter(mips:boolean);
begin
  if Config.TextureFilter=0 then
   begin
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST );
    if mips then glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST_MIPMAP_NEAREST )
            else glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST );
   end
  else if Config.TextureFilter=1 then
   begin
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR );
    if mips then glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST_MIPMAP_NEAREST )
            else glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST );
   end
  else if Config.TextureFilter=2 then
   begin
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR );
    if mips then glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST_MIPMAP_LINEAR )
            else glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR );
   end
  else
   begin
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR );
    if mips then glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR )
            else glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR );
   end;

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
end;

//Resource Manager

function TIO64.GetResource(filename:ansistring):TResource;
var ext:ansistring;
    i:integer;
    found:boolean=false;
begin
  ext:=LowerCase(ExtractFileExt(filename));
  
  doDirSeparators(filename);
  //expand filename
  
  if(ext='.bmp')or(ext='.dds')or(ext='.tga')then
   if not fileexists(filename) then filename:=Config.AegisDir+'media\texture\'+filename
                               else filename:=ExpandFileName(filename);
  if(ext='.skybox')then
   if not fileexists(filename) then filename:=Config.AegisDir+'media\skybox\'+filename
                               else filename:=ExpandFileName(filename);
  if(ext='.ms3d') then
   if not fileexists(filename) then filename:=Config.AegisDir+'media\model\'+filename
                               else filename:=ExpandFileName(filename);
  if(ext='.tileset') then
   if not fileexists(filename) then filename:=Config.AegisDir+'media\tileset\'+filename
                               else filename:=ExpandFileName(filename);
  if(ext='.flare') then
   if not fileexists(filename) then filename:=Config.AegisDir+'media\lensflare\'+filename
                               else filename:=ExpandFileName(filename);
                               
  DoDirSeparators(filename);


  for i:=0 to length(ResourceNames)-1 do
   if ResourceNames[i]=filename then
    begin
     {$ifdef debug_l3}
     writeln('  Resource Manager: "',filename,'" already exists. Returning copy');
     {$endif}
     inc(Resources[i].NumPointers);
     Exit(Resources[i]);
    end;

  {$ifdef debug_l3}
  writeln('  Resource Manager: "',filename,'" not found. Loading');
  {$endif}

  for i:=0 to length(ResourceNames)-1 do
   if Resources[i]=nil then
    begin
     found:=true;
     break;
    end;
    
  if not found then
   begin
    i:=length(ResourceNames);
    {$ifdef debug_l3}
    writeln('  Resource Manager: Resizing data segment to ',i+1);
    {$endif}
    setLength(ResourceNames,i+1);
    setLength(Resources,i+1);
    Resources[i]:=TResource(-1);
   end;
   
  if(ext='.bmp')or(ext='.dds')or(ext='.tga')then Result:=TTexture.Create(self,filename);
  if(ext='.skybox')then Result:=TSkyBox.Create(self,filename);
  if(ext='.ms3d') then Result:=TModel.Create(self,filename);
  if(ext='.tileset') then Result:=TTileSet.Create(self,filename);
  if(ext='.flare') then Result:=TLensFlare.Create(self,filename);

  Result.Tag:=i;
  ResourceNames[i]:=filename;
  Resources[i]:=Result;
end;

procedure TIO64.NotifyDestroyed(Tag:integer);
var i:integer;
    c:TResource;
begin
  {$ifdef debug_l3}
  writeln('  Resource Manager: Releasing "'+ResourceNames[Tag]+'"');
  {$endif}
  c:=Resources[Tag];
  Resources[Tag]:=nil;
  ResourceNames[Tag]:='';
  
  c.Free();
  i:=High(Resources);
  
  while (i>=0)and(Resources[i]=nil) do dec(i);
  if i+1<>length(Resources) then
   begin
    {$ifdef debug_l3}
    writeln('  Resource Manager: Resizing data segment to ',i+1);
    {$endif}
    setLength(Resources,i+1);
    setLength(ResourceNames,i+1);
   end;
end;

//Lightsource Manager

function TIO64.AddLightSource():TLightSource;

  function GetFreeLightID():integer;
  var i:integer;
  begin
    for i:=0 to length(Lights)-1 do
     if Lights[i]=nil then exit(i);
    i:=length(Lights);
    {$ifdef debug_l3}
    writeln('  Lightsource Manager: Resizing data segment to ',i+1);
    {$endif}
    SetLength(Lights,i+1);
    Result:=i;
  end;

var newid:integer;
begin
  newid:=GetFreeLightID();
  {$ifdef debug_l3}
  writeln('  Lightsource Manager: Creating "',newid,'"');
  {$endif}
  Lights[newid]:=TLightSource.Create(self);
  Result:=Lights[newid];
end;

procedure TIO64.RemoveLightSource(id:integer);
var i:integer;
begin
  {$ifdef debug_l3}
  writeln('  Lightsource Manager: Releasing "',id,'"');
  {$endif}
  Lights[id].Free();
  Lights[id]:=nil;
  //attempt to free any unused pointers
  i:=length(Lights)-1;
  while (i>=0)and(Lights[i]=nil) do dec(i);
  if i+1<>length(Lights) then
   begin
    {$ifdef debug_l3}
    writeln('  Lightsource Manager: Resizing data segment to ',i+1);
    {$endif}
    setLength(Lights,i+1);
   end;
end;

function TIO64.RequestLightId():integer;
var i:integer;
begin
  for i:=0 to length(EnabledLights)-1 do
   if not EnabledLights[i] then
    begin
     EnabledLights[i]:=true;
     exit(i);
    end;
  i:=Length(EnabledLights);
  setLength(EnabledLights,i+1);
  EnabledLights[i]:=true;
  Result:=i;
end;

procedure TIO64.FreeLightId(id:integer);
begin
  if (id>=0)and(id<length(EnabledLights))then
   EnabledLights[id]:=false;
  id:=length(EnabledLights)-1;
  while (id>=0)and not(EnabledLights[id]) do dec(id);
  setLength(EnabledLights,id+1);
end;

//Drawing

procedure TIO64.Draw();
var i:integer;
begin
  //switch to camera
  glLoadMatrixf(@Camera.ModelviewMatrix);
  glTranslatef(-Camera.Position[0],-camera.Position[1],-camera.Position[2]);
  //setup lights
   for i:=0 to length(Lights)-1 do
    if Lights[i].IsTrueLight then glLightfv(GL_LIGHT0+Lights[i].id,GL_POSITION,lights[i].Position);
  //skybox
  if Skybox<>nil then Skybox.Draw()
                 else glClear(GL_COLOR_BUFFER_BIT);
end;

//Skybox Manager
procedure TIO64.LoadSkyBox(filename:ansistring);
begin
  FSkyBox.MarkUnused;
  FSkyBox:=GetResource(filename) as TSkyBox;
end;

procedure TIO64.DrawLensFlare();
var i:integer;
begin
  //do a bunch of occlusion queries
  glDepthMask(GL_FALSE);
  glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
  for i:=0 to High(Lights) do Lights[i].Loop();
  SetOrtho();
  glDepthMask(GL_TRUE);
  glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
  for i:=0 to High(Lights) do Lights[i].Draw();
  SetPerspective();
end;

end.


