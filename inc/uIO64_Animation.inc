{ TAnimation }

procedure TAnimation.doFree();
begin

end;

procedure TAnimation.LoadFromFile(filename: ansistring);
begin

end;

procedure TAnimation.Apply(Model:TModel);
begin
end;

procedure TAnimation.Start(id: integer);
begin
  FCurrentAnimation:=id;
end;

procedure TAnimation.Start(name: ansistring);
var i:integer;
begin
  for i:=0 to High(Animations) do
   if Animations[i].name=name then
    begin
     Start(i);
     exit();
    end;
end;
