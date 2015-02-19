//spare me the typecasts
{$mode delphi}
unit glext;
interface
uses gl, {$ifdef mswindows}Windows{$else}DynLibs{$endif};
const LibName={$ifdef mswindows}'OpenGL32.dll'{$else}'libGL.so'{$endif};

//Generic Datatypes
type glHandleARB=Gluint;
     glCharARB=pchar;
     pglCharARB=^glCharARB;
const //Vertex Buffer Objects
      GL_ARRAY_BUFFER_ARB = $8892;
      GL_STATIC_DRAW_ARB = $88E4;
      //Shaders
      GL_VERTEX_SHADER_ARB = $8B31;
      GL_MAX_VERTEX_UNIFORM_COMPONENTS_ARB = $8B4A;
      GL_MAX_VARYING_FLOATS_ARB = $8B4B;
      GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS_ARB = $8B4C;
      GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS_ARB = $8B4D;
      GL_OBJECT_ACTIVE_ATTRIBUTES_ARB = $8B89;
      GL_OBJECT_ACTIVE_ATTRIBUTE_MAX_LENGTH_ARB = $8B8A;
      GL_OBJECT_COMPILE_STATUS_ARB = $8B81;
      GL_OBJECT_LINK_STATUS_ARB = $8B82;
      GL_OBJECT_VALIDATE_STATUS_ARB = $8B83;
      GL_OBJECT_INFO_LOG_LENGTH_ARB = $8B84;
      GL_FRAGMENT_SHADER_ARB = $8B30;
      GL_MAX_FRAGMENT_UNIFORM_COMPONENTS_ARB = $8B49;
      GL_FRAGMENT_SHADER_DERIVATIVE_HINT_ARB = $8B8B;
      //Generic Extensions
      GL_MAX_TEXTURE_UNITS_ARB = $84E2;
      GL_BGR = $80E0;
      GL_BGRA = $80E1;
      GL_CLAMP_TO_EDGE = $812F;
      //Texture Compression
      GL_COMPRESSED_RGB_S3TC_DXT1_EXT = $83F0;
      GL_COMPRESSED_RGBA_S3TC_DXT1_EXT = $83F1;
      GL_COMPRESSED_RGBA_S3TC_DXT3_EXT = $83F2;
      GL_COMPRESSED_RGBA_S3TC_DXT5_EXT = $83F3;
      //Occlusion Queries
      GL_SAMPLES_PASSED_ARB = $8914;
      GL_QUERY_COUNTER_BITS_ARB = $8864;
      GL_CURRENT_QUERY_ARB = $8865;
      GL_QUERY_RESULT_ARB = $8866;
      GL_QUERY_RESULT_AVAILABLE_ARB = $8867;


var //Vertex Buffer Objects
    glGenBuffersARB:procedure(n:glsizei;buffers:pgluint);stdcall;
    glBufferDataARB:procedure(target:glenum;size:gluint;Data:Pglvoid;usage:glenum);stdcall;
    glDeleteBuffersARB:procedure(n:glsizei;buffers:pgluint);stdcall;
    glBindBufferARB:procedure(target:glenum;buffer:gluint);stdcall;
    //VSync
    wglSwapIntervalEXT:procedure(n:gluint);stdcall;
    wglGetSwapIntervalEXT:function():gluint;stdcall;
    //Shaders
    glCreateShaderObjectARB:function(shadertype:glenum):glHandleARB;stdcall;
    glCreateProgramObjectARB:function():glHandleARB;stdcall;
    glShaderSourceARB:procedure(shader:GLhandleARB;number_strings:gluint;strings:pglCharARB;length:pglint);stdcall;
    glCompileShaderARB:procedure(shader:GlHandleARB);stdcall;
    glAttachObjectARB:procedure(programobject:glHandleARB;shader:glHandleARB);stdcall;
    glLinkProgramARB:procedure(programobject:glHandleARB);stdcall;
    glUseProgramObjectARB:procedure(programobject:glHandleARB);stdcall;
    glDeleteObjectARB:procedure(objecthandler:glHandleARB);stdcall;
    glGetInfoLogARB:procedure(objecthandler:glHandleARB;maxLenght:GLsizei;length:pglsizei;infoLog:glCharARB);stdcall;
    glGetObjectParameterivARB:procedure(objecthandler:GLhandleARB;pname:GLEnum;params:PGLint);
    glGetUniformLocationARB:function(tprogram:glHandleARB;name:glCharARB):glint;stdcall;
    glUniform1fARB:procedure(location:glint;val:glfloat);stdcall;
    glUniform1iARB:procedure(location:glint;val:glint);stdcall;
    glUniform2fARB:procedure(location:glint;val,val2:glfloat);stdcall;
    glUniform2iARB:procedure(location:glint;val,val2:glint);stdcall;
    glUniform3fARB:procedure(location:glint;val,val2,val3:glfloat);stdcall;
    glUniform3iARB:procedure(location:glint;val,val2,val3:glint);stdcall;
    glUniform4fARB:procedure(location:glint;val,val2,val3,val4:glfloat);stdcall;
    glUniform4iARB:procedure(location:glint;val,val2,val3,val4:glint);stdcall;
    glUniform1fvARB:procedure(location:glint;count:gluint;val:pglfloat);stdcall;
    glUniform1ivARB:procedure(location:glint;count:gluint;val:pglint);stdcall;
    glUniform2fvARB:procedure(location:glint;count:gluint;val,val2:pglfloat);stdcall;
    glUniform2ivARB:procedure(location:glint;count:gluint;val,val2:pglint);stdcall;
    glUniform3fvARB:procedure(location:glint;count:gluint;val,val2,val3:pglfloat);stdcall;
    glUniform3ivARB:procedure(location:glint;count:gluint;val,val2,val3:pglint);stdcall;
    glUniform4fvARB:procedure(location:glint;count:gluint;val,val2,val3,val4:pglfloat);stdcall;
    glUniform4ivARB:procedure(location:glint;count:gluint;val,val2,val3,val4:pglint);stdcall;
    glGetAttribLocationARB:function(tprogram:glHandleARB;name:glCharARB):glint;stdcall;
    glVertexAttrib1sARB:procedure(index:gluint; val:single);stdcall;
    glVertexAttrib1fARB:procedure(index:gluint; val:glfloat);stdcall;
    glVertexAttrib1dARB:procedure(index:gluint; val:gldouble);stdcall;
    glVertexAttrib2sARB:procedure(index:gluint; val,val2:single);stdcall;
    glVertexAttrib2fARB:procedure(index:gluint; val,val2:glfloat);stdcall;
    glVertexAttrib2dARB:procedure(index:gluint; val,val2:gldouble);stdcall;
    glVertexAttrib3sARB:procedure(index:gluint; val,val2,val3:single);stdcall;
    glVertexAttrib3fARB:procedure(index:gluint; val,val2,val3:glfloat);stdcall;
    glVertexAttrib3dARB:procedure(index:gluint; val,val2,val3:gldouble);stdcall;
    glVertexAttrib4sARB:procedure(index:gluint; val,val2,val3,val4:single);stdcall;
    glVertexAttrib4fARB:procedure(index:gluint; val,val2,val3,val4:glfloat);stdcall;
    glVertexAttrib4dARB:procedure(index:gluint; val,val2,val3,val4:gldouble);stdcall;
    glVertexAttrib1svARB:procedure(index:gluint; val:psingle);stdcall;
    glVertexAttrib1fvARB:procedure(index:gluint; val:pglfloat);stdcall;
    glVertexAttrib1dvARB:procedure(index:gluint; val:pgldouble);stdcall;
    glVertexAttrib2svARB:procedure(index:gluint; val,val2:psingle);stdcall;
    glVertexAttrib2fvARB:procedure(index:gluint; val,val2:pglfloat);stdcall;
    glVertexAttrib2dvARB:procedure(index:gluint; val,val2:pgldouble);stdcall;
    glVertexAttrib3svARB:procedure(index:gluint; val,val2,val3:psingle);stdcall;
    glVertexAttrib3fvARB:procedure(index:gluint; val,val2,val3:pglfloat);stdcall;
    glVertexAttrib3dvARB:procedure(index:gluint; val,val2,val3:pgldouble);stdcall;
    glVertexAttrib4svARB:procedure(index:gluint; val,val2,val3,val4:psingle);stdcall;
    glVertexAttrib4fvARB:procedure(index:gluint; val,val2,val3,val4:pglfloat);stdcall;
    glVertexAttrib4dvARB:procedure(index:gluint; val,val2,val3,val4:pgldouble);stdcall;
    //Texture Compression
    glCompressedTexImage2DARB: procedure(target: GLenum; level: GLint; internalformat: GLenum; width: GLsizei; height: GLsizei; border: GLint; imageSize: GLsizei; const data: PGLvoid); stdcall;
    glGetCompressedTexImageARB: procedure(target: GLenum; level: GLint; const data:pointer);stdcall;
    //Occlusion Queries
    glGenQueriesARB:procedure(n:glsizei;ids:pgluint);stdcall;
    glDeleteQueriesARB:Procedure(n:glsizei;ids:pgluint);stdcall;
    glIsQueryARB:function(id:gluint):glBoolean;stdcall;
    glBeginQueryARB:procedure(target:glEnum;id:gluint);stdcall;
    glEndQueryARB:procedure(target:glEnum);stdcall;
    glGetQueryivARB:procedure(target:glEnum;pname:glEnum;params:pglint);stdcall;
    glGetQueryObjectivARB:procedure(id:gluint;pname:glEnum;params:pglint);stdcall;
    glGetQueryObjectuivARB:procedure(id:gluint;pname:glEnum;params:pgluint);stdcall;


procedure InitOpenGL;
procedure DoneOpenGL;

implementation

{$ifndef mswindows}
var LibHandle:HModule;
{$endif}

procedure Init();
begin
     {$ifndef mswindows}
     LibHandle:=LoadLibrary(LibName);
     {$endif}
end;

procedure Done();
begin
     {$ifndef mswindows}
     UnloadLibrary(LibHandle);
     {$endif}
end;

function GetProcedureAddress(filename:pchar):pointer;
begin
     {$ifdef mswindows}
     Result:=wglGetProcAddress(filename);
     {$else}
     Result:=DynLibs.GetProcedureAddress(LibHandle,filename);
     {$endif}
end;

procedure InitOpenGL;
begin
 Init();

 //Vertex Buffer Objects
 glGenBuffersARB:=GetProcedureAddress('glGenBuffersARB');
 glDeleteBuffersARB:=GetProcedureAddress('glDeleteBuffersARB');
 glBufferDataARB:=GetProcedureAddress('glBufferDataARB');
 glBindBufferARB:=GetProcedureAddress('glBindBufferARB');
 //VSync
 wglSwapIntervalEXT:=GetProcedureAddress('wglSwapIntervalEXT');
 wglGetSwapIntervalEXT:=GetProcedureAddress('wglGetSwapIntervalEXT');
 //Shaders
 glCreateShaderObjectARB:=GetProcedureAddress('glCreateShaderObjectARB');
 glCreateProgramObjectARB:=GetProcedureAddress('glCreateProgramObjectARB');
 glShaderSourceARB:=GetProcedureAddress('glShaderSourceARB');
 glCompileShaderARB:=GetProcedureAddress('glCompileShaderARB');
 glAttachObjectARB:=GetProcedureAddress('glAttachObjectARB');
 glLinkProgramARB:=GetProcedureAddress('glLinkProgramARB');
 glUseProgramObjectARB:=GetProcedureAddress('glUseProgramObjectARB');
 glDeleteObjectARB:=GetProcedureAddress('glDeleteObjectARB');
 glGetInfoLogARB:=GetProcedureAddress('glGetInfoLogARB');
 glGetObjectParameterivARB:=GetProcedureAddress('glGetObjectParameterivARB');
 glGetUniformLocationARB:=GetProcedureAddress('glGetUniformLocationARB');
 glUniform1fARB:=GetProcedureAddress('glUniform1fARB');
 glUniform1iARB:=GetProcedureAddress('glUniform1iARB');
 glUniform2fARB:=GetProcedureAddress('glUniform2fARB');
 glUniform2iARB:=GetProcedureAddress('glUniform2iARB');
 glUniform3fARB:=GetProcedureAddress('glUniform3fARB');
 glUniform3iARB:=GetProcedureAddress('glUniform3iARB');
 glUniform4fARB:=GetProcedureAddress('glUniform4fARB');
 glUniform4iARB:=GetProcedureAddress('glUniform4iARB');
 glUniform1fvARB:=GetProcedureAddress('glUniform1fvARB');
 glUniform1ivARB:=GetProcedureAddress('glUniform1ivARB');
 glUniform2fvARB:=GetProcedureAddress('glUniform2fvARB');
 glUniform2ivARB:=GetProcedureAddress('glUniform2ivARB');
 glUniform3fvARB:=GetProcedureAddress('glUniform3fvARB');
 glUniform3ivARB:=GetProcedureAddress('glUniform3ivARB');
 glUniform4fvARB:=GetProcedureAddress('glUniform4fvARB');
 glUniform4ivARB:=GetProcedureAddress('glUniform4ivARB');
 glGetAttribLocationARB:=GetProcedureAddress('glGetAttribLocationARB');
 glVertexAttrib1sARB:=GetProcedureAddress('glVertexAttrib1sARB');
 glVertexAttrib1fARB:=GetProcedureAddress('glVertexAttrib1fARB');
 glVertexAttrib1dARB:=GetProcedureAddress('glVertexAttrib1dARB');
 glVertexAttrib2sARB:=GetProcedureAddress('glVertexAttrib2sARB');
 glVertexAttrib2fARB:=GetProcedureAddress('glVertexAttrib2fARB');
 glVertexAttrib2dARB:=GetProcedureAddress('glVertexAttrib2dARB');
 glVertexAttrib3sARB:=GetProcedureAddress('glVertexAttrib3sARB');
 glVertexAttrib3fARB:=GetProcedureAddress('glVertexAttrib3fARB');
 glVertexAttrib3dARB:=GetProcedureAddress('glVertexAttrib3dARB');
 glVertexAttrib4sARB:=GetProcedureAddress('glVertexAttrib4sARB');
 glVertexAttrib4fARB:=GetProcedureAddress('glVertexAttrib4fARB');
 glVertexAttrib4dARB:=GetProcedureAddress('glVertexAttrib4dARB');
 glVertexAttrib1svARB:=GetProcedureAddress('glVertexAttrib1svARB');
 glVertexAttrib1fvARB:=GetProcedureAddress('glVertexAttrib1fvARB');
 glVertexAttrib1dvARB:=GetProcedureAddress('glVertexAttrib1dvARB');
 glVertexAttrib2svARB:=GetProcedureAddress('glVertexAttrib2svARB');
 glVertexAttrib2fvARB:=GetProcedureAddress('glVertexAttrib2fvARB');
 glVertexAttrib2dvARB:=GetProcedureAddress('glVertexAttrib2dvARB');
 glVertexAttrib3svARB:=GetProcedureAddress('glVertexAttrib3svARB');
 glVertexAttrib3fvARB:=GetProcedureAddress('glVertexAttrib3fvARB');
 glVertexAttrib3dvARB:=GetProcedureAddress('glVertexAttrib3dvARB');
 glVertexAttrib4svARB:=GetProcedureAddress('glVertexAttrib4svARB');
 glVertexAttrib4fvARB:=GetProcedureAddress('glVertexAttrib4fvARB');
 glVertexAttrib4dvARB:=GetProcedureAddress('glVertexAttrib4dvARB');
 //Texture Compression
 glCompressedTexImage2DARB:=GetProcedureAddress('glCompressedTexImage2DARB');
 glGetCompressedTexImageARB:=GetProcedureAddress('glGetCompressedTexImageARB');
 //Occlusion Queries
 glGenQueriesARB:=GetProcedureAddress('glGenQueriesARB');
 glDeleteQueriesARB:=GetProcedureAddress('glDeleteQueriesARB');
 glIsQueryARB:=GetProcedureAddress('glIsQueryARB');
 glBeginQueryARB:=GetProcedureAddress('glBeginQueryARB');
 glEndQueryARB:=GetProcedureAddress('glEndQueryARB');
 glGetQueryivARB:=GetProcedureAddress('glGetQueryivARB');
 glGetQueryObjectivARB:=GetProcedureAddress('glGetQueryObjectivARB');
 glGetQueryObjectuivARB:=GetProcedureAddress('glGetQueryObjectuivARB');
end;

procedure DoneOpenGL;
begin
 //Vertex Buffer Objects
 glGenBuffersARB:=nil;
 glDeleteBuffersARB:=nil;
 glBufferDataARB:=nil;
 glBindBufferARB:=nil;
 //VSync
 wglSwapIntervalEXT:=nil;
 wglGetSwapIntervalEXT:=nil;
 //Shaders
 glCreateShaderObjectARB:=nil;
 glCreateProgramObjectARB:=nil;
 glShaderSourceARB:=nil;
 glCompileShaderARB:=nil;
 glAttachObjectARB:=nil;
 glLinkProgramARB:=nil;
 glUseProgramObjectARB:=nil;
 glDeleteObjectARB:=nil;
 glGetInfoLogARB:=nil;
 glGetObjectParameterivARB:=nil;
 glGetUniformLocationARB:=nil;
 glUniform1fARB:=nil;
 glUniform1iARB:=nil;
 glUniform2fARB:=nil;
 glUniform2iARB:=nil;
 glUniform3fARB:=nil;
 glUniform3iARB:=nil;
 glUniform4fARB:=nil;
 glUniform4iARB:=nil;
 glUniform1fvARB:=nil;
 glUniform1ivARB:=nil;
 glUniform2fvARB:=nil;
 glUniform2ivARB:=nil;
 glUniform3fvARB:=nil;
 glUniform3ivARB:=nil;
 glUniform4fvARB:=nil;
 glUniform4ivARB:=nil;
 glGetAttribLocationARB:=nil;
 glVertexAttrib1sARB:=nil;
 glVertexAttrib1fARB:=nil;
 glVertexAttrib1dARB:=nil;
 glVertexAttrib2sARB:=nil;
 glVertexAttrib2fARB:=nil;
 glVertexAttrib2dARB:=nil;
 glVertexAttrib3sARB:=nil;
 glVertexAttrib3fARB:=nil;
 glVertexAttrib3dARB:=nil;
 glVertexAttrib4sARB:=nil;
 glVertexAttrib4fARB:=nil;
 glVertexAttrib4dARB:=nil;
 glVertexAttrib1svARB:=nil;
 glVertexAttrib1fvARB:=nil;
 glVertexAttrib1dvARB:=nil;
 glVertexAttrib2svARB:=nil;
 glVertexAttrib2fvARB:=nil;
 glVertexAttrib2dvARB:=nil;
 glVertexAttrib3svARB:=nil;
 glVertexAttrib3fvARB:=nil;
 glVertexAttrib3dvARB:=nil;
 glVertexAttrib4svARB:=nil;
 glVertexAttrib4fvARB:=nil;
 glVertexAttrib4dvARB:=nil;
 //Texture Compression
 glCompressedTexImage2DARB:=nil;
 glGetCompressedTexImageARB:=nil;
 //Occlusion Queries
 glGenQueriesARB:=nil;
 glDeleteQueriesARB:=nil;
 glIsQueryARB:=nil;
 glBeginQueryARB:=nil;
 glEndQueryARB:=nil;
 glGetQueryivARB:=nil;
 glGetQueryObjectivARB:=nil;
 glGetQueryObjectuivARB:=nil;
 
 Done();
end;

end.
