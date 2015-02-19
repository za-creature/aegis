const
  FOURCC_DXT1 = DWORD(Byte('D') or (Byte('X') shl 8) or (Byte('T') shl 16) or (Byte('1') shl 24));
  FOURCC_DXT2 = DWORD(Byte('D') or (Byte('X') shl 8) or (Byte('T') shl 16) or (Byte('2') shl 24));
  FOURCC_DXT3 = DWORD(Byte('D') or (Byte('X') shl 8) or (Byte('T') shl 16) or (Byte('3') shl 24));
  FOURCC_DXT4 = DWORD(Byte('D') or (Byte('X') shl 8) or (Byte('T') shl 16) or (Byte('4') shl 24));
  FOURCC_DXT5 = DWORD(Byte('D') or (Byte('X') shl 8) or (Byte('T') shl 16) or (Byte('5') shl 24));
  IntSeg:array[0..4] of integer=(4,8,16,32,64);

type

 //DDS Loading

  TDDSCaps2 = packed record
    dwCaps: DWORD;         // capabilities of surface wanted
    dwCaps2 : DWORD;
    dwCaps3 : DWORD;
    dwCaps4 : DWORD;
  end;

  TDDPixelFormat = packed record
    dwSize: DWORD;                 // size of structure
    dwFlags: DWORD;                // pixel format flags
    dwFourCC: DWORD;               // (FOURCC code)
    case Integer of
      1:
       (
        dwRGBBitCount : DWORD;          // how many bits per pixel
        dwRBitMask : DWORD;             // mask for red bit
        dwGBitMask : DWORD;             // mask for green bits
        dwBBitMask : DWORD;             // mask for blue bits
        dwRGBAlphaBitMask : DWORD;      // mask for alpha channel
       );
      2:
       (
        dwYUVBitCount : DWORD;          // how many bits per pixel
        dwYBitMask : DWORD;             // mask for Y bits
        dwUBitMask : DWORD;             // mask for U bits
        dwVBitMask : DWORD;             // mask for V bits
        dwYUVAlphaBitMask : DWORD;      // mask for alpha channel
       );
      3:
       (
        dwZBufferBitDepth : DWORD;      // how many total bits/pixel in z buffer (including any stencil bits)
        dwStencilBitDepth : DWORD;      // how many stencil bits (note: dwZBufferBitDepth-dwStencilBitDepth is total Z-only bits)
        dwZBitMask : DWORD;             // mask for Z bits
        dwStencilBitMask : DWORD;       // mask for stencil bits
        dwLuminanceAlphaBitMask : DWORD; // mask for alpha channel
       );
      4:
       (
        dwAlphaBitDepth : DWORD;        // how many bits for alpha channels
        dwLuminanceBitMask : DWORD;     // mask for luminance bits
        dwBumpDvBitMask : DWORD;        // mask for bump map V delta bits
        dwBumpLuminanceBitMask : DWORD; // mask for luminance in bump map
        dwRGBZBitMask : DWORD;          // mask for Z channel
       );
      5:
       (
        dwLuminanceBitCount : DWORD;   // how many bits per pixel
        dwBumpDuBitMask : DWORD;       // mask for bump map U delta bits
        Fill1, Fill2    : DWORD;
        dwYUVZBitMask   : DWORD;       // mask for Z channel
       );
      6:
       (
        dwBumpBitCount  : DWORD;       // how many bits per "buxel", total
       );
  end;
  TDDColorKey = packed record
    dwColorSpaceLowValue: DWORD;   // low boundary of color space that is to
                                   // be treated as Color Key, inclusive
    dwColorSpaceHighValue: DWORD;  // high boundary of color space that is
                                   // to be treated as Color Key, inclusive
  end;

  TDDSurfaceDesc2 = packed record
    dwSize: DWORD;                      // size of the TDDSurfaceDesc structure
    dwFlags: DWORD;                     // determines what fields are valid
    dwHeight: DWORD;                    // height of surface to be created
    dwWidth: DWORD;                     // width of input surface
    case Integer of
    0:
     (
      lPitch : Longint;                  // distance to start of next line (return value only)
     );
    1:
     (
      dwLinearSize : DWORD;              // Formless late-allocated optimized surface size
      dwBackBufferCount: DWORD;          // number of back buffers requested
      case Integer of
      0:
       (
        dwMipMapCount: DWORD;            // number of mip-map levels requested
        dwAlphaBitDepth: DWORD;          // depth of alpha buffer requested
        dwReserved: DWORD;               // reserved
        lpSurface: DWORD;                // pointer to the associated surface memory
                                         //
                                         // 07 october 2006 19:02 PM: Fuck you microsoft with your
                                         // crappy pointers that fuck everything up on 64 bit systems
                                         // Thanks
                                         //
        ddckCKDestOverlay: TDDColorKey;  // color key for destination overlay use
        ddckCKDestBlt: TDDColorKey;      // color key for destination blt use
        ddckCKSrcOverlay: TDDColorKey;   // color key for source overlay use
        ddckCKSrcBlt: TDDColorKey;       // color key for source blt use
        ddpfPixelFormat: TDDPixelFormat; // pixel format description of the surface
        ddsCaps: TDDSCaps2;              // direct draw surface capabilities
        dwTextureStage: DWORD;           // stage in multitexture cascade
       );
      1:
       (
        dwRefreshRate: DWORD;            // refresh rate (used when display mode is described)
       );
     );
  end;

  DDS_IMAGE_DATA=record
   width,height:glsizei;
   Components:glint;
   format:Glenum;
   numMipMaps:integer;
   pixels:^pByte;
  end;
  
  pDDS_IMAGE_DATA=^DDS_IMAGE_DATA;
  
  //Some Generic Datatypes

  TPoint3D=record
   x,y,z:glFloat;
  end;
  TPoint2D=record
   x,y:glFloat;
  end;
  VertexBuffer=array of TPoint3D;
  NormalBuffer=array of TPoint3D;
  TexCoordBuffer=array of TPoint2D;
  IndexBuffer=array of byte;
  TexCoordSet=array[0..3] of TPoint2D;
  l4v=array[0..3] of longint;


  //Models
  TTexture=class;

  TVertex=record
   BoneID:byte;
   Location:array[0..2] of Single;
  end;
  PVertex=^TVertex;
  
  TTriangle=record
   normals:array[0..2] of array[0..2] of Single;
   Texcoords:array[0..1] of array[0..2] of Single;
   Indices:array[0..2] of word;
  end;
  PTriangle=^TTriangle;

  TMesh=record
   MaterialIndex:byte;
   NumTriangles:integer;
   TriangleIndices:array of Word;
   
   VertexArray:VertexBuffer;
   NormalArray:NormalBuffer;
   TexCoordArray:TexCoordBuffer;
   BoneIndexArray:IndexBuffer;
  end;
  PMesh=^TMesh;

  TMaterial=record
   Ambient, Diffuse, Specular, Emissive:array[0..3] of glFloat;
   Shininess:glFloat;
   TexID:TTexture;
   Texture:array[0..127] of char;
  end;
  PMaterial=^TMaterial;

  MS3DHeader = packed record
   m_ID: array [0..9] of char;
   m_version: integer;
  end;

  MS3DVertex = packed record
   m_flags: byte;
   m_vertex: array [0..2] of single;
   m_boneID: byte;
   m_refCount: byte;
  end;

  MS3DTriangle = packed record
   m_flags: word;
   m_vertexIndices: array [0..2] of word;
   m_vertexNormals: array [0..2,0..2] of single;
   m_s, m_t: array [0..2] of single;
   m_smoothingGroup: byte;
   m_groupIndex: byte;
  end;

  MS3DMaterial = packed record
   m_name: array [0..31] of char;
   m_ambient: array [0..3] of single;
   m_diffuse: array [0..3] of single;
   m_specular: array [0..3] of single;
   m_emissive: array [0..3] of single;
   m_shininess: single;
   m_transparency: single;
   m_mode: byte;
   m_texture: array [0..127] of char;
   m_alphamap: array [0..127] of char;
  end;

  MS3DJoint = packed record
   flags : byte;
   name : array[0..31] of char;
   parentName : array[0..31] of char;
   rotation : array[0..2] of single;
   position : array[0..2] of single;
   numKeyFramesRot : word;
   numKeyFramesTrans : word;
  end;
  
  TKeyFrame=record
   time:single;
   data:vec3;
  end;
  
  PJoint=^TJoint;
  
  TJoint=record //puff, puff, pass
   Parent:integer;
   FinalMatrix,AbsoluteMatrix,RelativeMatrix:mat4;
   KeyFramesRotation,KeyFramesTranslation:array of TKeyFrame;
  end;
  
  ppgluShort=^pgluShort;
  ppgluByte=^pgluByte;
  pVec3=^vec3;
  pPoint3D=^Tpoint3D;
  ppPoint3D=^pPoint3D;
  ppglFloat=^pglFloat;

  Tinput=record
   Keys:array[0..255] of boolean;
   Buttons:array[0..2] of boolean;
   MouseX,MouseY:integer;
   Drag:boolean;
   DragEnd,DragStart:record x,y:integer end;
  end;
  PInput=^TInput;
  TColor24b=packed record
   case Integer of
   0:
    (
     r,g,b:byte;
    );
   1:
    (
     data:array[0..2] of byte;
    );
  end;
  
  TColor32b=packed record
   case Integer of
   0:
    (
     r,g,b,a:byte;
    );
   1:
    (
     data:array[0..3] of byte;
    );
   2:
    (
     t:dword;
    )
  end;
  CallbackProc=procedure(status:integer) of object;

  TSubFlare=record
   scale,pos,r,g,b:glFloat;
   texture:TTexture;
  end;
  
  TInternalAnimation=record
   StartFrameRot,EndFrameRot:integer;
   StartFrameTrans,EndFrameTrans:integer;
   speed:single;
   name:ansistring;
  end;
  
