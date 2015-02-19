{TShader}

constructor TShader.Create(AOwner:TIO64;Afilename:ansistring);
begin
 sfn:=Afilename;
 inherited Create(AOwner,AFilename);
end;

procedure TShader.doFree();
begin
 if Linked then glDeleteObjectARB(prg);
 if Compiled then
  begin
   glDeleteObjectARB(vsh);
   glDeleteObjectARB(fsh);
  end;
end;

function TShader.Compile():boolean;
var l:glsizei;
    v1,v2:GLint;
    buff:pchar;
    f:text;
begin
  if not Compiled then
   begin
    vsh := glCreateShaderObjectARB(GL_VERTEX_SHADER_ARB);
    fsh := glCreateShaderObjectARB(GL_FRAGMENT_SHADER_ARB);
    glShaderSourceARB(vsh, vlength, vertexsource, nil);
    glShaderSourceARB(fsh, flength, fragmentsource,nil);
    glCompileShaderARB(vsh);
    glCompileShaderARB(fsh);
   end;
  glGetObjectParameterivARB(vsh,GL_OBJECT_COMPILE_STATUS_ARB,@v1);
  glGetObjectParameterivARB(fsh,GL_OBJECT_COMPILE_STATUS_ARB,@v2);
  cmp:=(v1=GL_TRUE)and(v2=GL_TRUE);
  if FOwner.Config.Log then
   begin
    glGetObjectParameterivARB(vsh,GL_OBJECT_INFO_LOG_LENGTH_ARB,@v1);
    glGetObjectParameterivARB(fsh,GL_OBJECT_INFO_LOG_LENGTH_ARB,@v2);
    assign(f,FOwner.Config.AegisDir+'var\log\shader.log');
    if fileexists(FOwner.Config.AegisDir+'var\log\shader.log') then append(f)
                                           else rewrite(f);
    if v1<>0 then
     begin
      buff:=StrAlloc(v1);
      glGetInfoLogARB(prg,v1,@l,buff);
      writeln(f,'Messages encountered while compiling the vertex shader of "',SourceFileName,'": ');
      writeln(f,buff);
      StrDispose(buff);
     end;
    if v2<>0 then
     begin
      buff:=StrAlloc(v2);
      glGetInfoLogARB(prg,v2,@l,buff);
      writeln(f,'Messages encountered while compiling the fragment shader of "',SourceFileName,'": ');
      writeln(f,buff);
      StrDispose(buff);
     end;

    close(f);
   end;
  Result:=Compiled;
end;

function TShader.Link():boolean;
var l:GLsizei;
    buff:pchar;
    v1:GLint;
    f:text;
begin
  //attempt to link
  if not Linked then
   begin
    prg := glCreateProgramObjectARB();
    glAttachObjectARB(prg,vsh);
    glAttachObjectARB(prg,fsh);
    glLinkProgramARB(prg);
   end;
  //test for success
  glGetObjectParameterivARB(prg,GL_OBJECT_LINK_STATUS_ARB,@v1);
  lnk:=v1=GL_TRUE;
  //write log
  glGetObjectParameterivARB(prg,GL_OBJECT_INFO_LOG_LENGTH_ARB,@v1);
  if (FOwner.Config.Log)and(v1<>0) then
   begin
    assign(f,FOwner.Config.AegisDir+'var\log\shader.log');
    if fileexists(FOwner.Config.AegisDir+'var\log\shader.log') then append(f)
                                           else rewrite(f);

    buff:=StrAlloc(v1);
    glGetInfoLogARB(prg,v1,@l,buff);
    writeln(f,'Messages encountered while linking "',SourceFileName,'": ');
    writeln(f,buff);
    StrDispose(buff);

    close(f);
   end;
  //set result
  Result:=Linked;
end;

procedure TShader.ReadShader(filename:shortstring;var l:gluInt;var d:ppchar);
var f:text;
    i:integer;
    b:ansistring;
begin
  assign(f,filename);
  reset(f);
  l:=0;
  while not eof(f) do
   begin
    inc(l);
    ReAllocMem(d,sizeof(pchar)*l);
    readln(f,b);
    d[l-1]:=StrAlloc(length(b));
    for i:=1 to length(b) do d[l-1][i-1]:=b[i];
    d[l-1][i]:=#0;
   end;
  close(f);
end;

procedure TShader.FreeSource();
var i:integer;
begin
  for i:=0 to vlength-1 do StrDispose(vertexsource[i]);
  for i:=0 to flength-1 do StrDispose(fragmentsource[i]);
  freemem(vertexsource);
  freemem(fragmentsource);
end;
