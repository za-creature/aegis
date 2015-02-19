{TConfig}

constructor TConfig.Create(AFilename:ansistring);
begin
  FFilename:=AFilename;
  DoDirSeparators(FFilename);
end;

procedure TConfig.Save();
var f:TiniFile;
begin
  try
   f:=TiniFile.Create(filename);
   
   f.WriteInteger('Screen','Width',Width);
   f.WriteInteger('Screen','Height',Height);
   f.WriteInteger('Screen','ColorDepth',colordepth);
   f.WriteBool   ('Screen','Fullscreen',fullscreen);
   f.WriteBool   ('Screen','Vsync',vsync);

   f.WriteBool   ('Engine','CreateLog',Log);
   f.WriteBool   ('Engine','Texture-Compression',TextureCompression);
   f.WriteInteger('Engine','ShaderLimit',MaxShaders);
   f.WriteInteger('Engine','LightSourceLimit',MaxLightSources);
   f.WriteInteger('Engine','DrawDistance',DrawDistance);
   f.WriteInteger('Engine','TextureFilter',TextureFilter);
   f.WriteString ('Engine','Font',font);
   f.WriteInteger('Engine','Segmentation',Segmentation);

   f.WriteBool   ('Editor','Viewport-Visible',ViewViewport);
   f.WriteBool   ('Editor','CompPalette-Visible',ViewComponentPalette);
   f.WriteBool   ('Editor','Grid-Visible',ShowWire);
   f.WriteFloat  ('Editor','Move-Sensitivity',MoveSensitivity);
   f.WriteFloat  ('Editor','Tilt-Sensitivity',TiltSensitivity);
   f.WriteFloat  ('Editor','Wheel-Sensitivity',WheelSensitivity);

   f.UpdateFile();
   f.Destroy();
  except
   {$ifdef debug_l2}
   writeln('  Config: Could not save the configuration file');
   {$endif}
  end;
end;

procedure TConfig.Load();
var f:TiniFile;
begin
  try
   f:=TiniFile.Create(filename);
   Width:=                   f.ReadInteger('Screen','Width',640);
   Height:=                  f.ReadInteger('Screen','Height',480);
   colordepth:=              f.ReadInteger('Screen','ColorDepth',32);
   fullscreen:=              f.ReadBool   ('Screen','Fullscreen',true);
   vsync:=                   f.ReadBool   ('Screen','Vsync',true);
   maxshaders:=              f.ReadInteger('Engine','ShaderLimit',16);
   maxlightsources:=         f.ReadInteger('Engine','LightSourceLimit',8);
   log:=                     f.ReadBool   ('Engine','CreateLog',true);
   DrawDistance:=            f.ReadInteger('Engine','DrawDistance',1000);
   TextureFilter:=           f.ReadInteger('Engine','TextureFilter',0);
   Font:=                    f.ReadString ('Engine','Font','Arial');
   Segmentation:=            f.ReadInteger('Engine','Segmentation',2);
   TextureCompression:=      f.ReadBool   ('Engine','Texture-Compression',true);
   ViewViewport:=            f.ReadBool   ('Editor','Viewport-Visible',true);
   ViewComponentPalette:=    f.ReadBool   ('Editor','CompPalette-Visible',true);
   ShowWire:=                f.ReadBool   ('Editor','Grid-Visible',false);
   MoveSensitivity:=glFloat (f.ReadFloat  ('Editor','Move-Sensitivity',5));
   TiltSensitivity:=glFloat (f.ReadFloat  ('Editor','Tilt-Sensitivity',5));
   WheelSensitivity:=glFloat(f.ReadFloat  ('Editor','Wheel-Sensitivity',5));

   f.Destroy();
  except
   {$ifdef debug_l2}
   writeln('  Config: Could not load the configuration file');
   {$endif}
  end;
end;
