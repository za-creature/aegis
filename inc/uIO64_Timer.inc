procedure TimeStamp(var ts:TTimeStamp);{inline;}
begin
  ts:=DateTimeToTimeStamp(Now);
end;

function TimePassed(ts:TTimeStamp):integer;{inline;}
var s:TTimeStamp;
begin
  s:=DateTimeToTimeStamp(Now);;
  TimePassed:=s.time-ts.time;
  if TimePassed<0 then TimePassed+=86400000;
end;
