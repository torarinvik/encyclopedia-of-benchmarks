from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import atan2,cos,fabs,isfinite,sin,sqrt
comptime RADAR_PI=3.14159265358979323846
comptime RADAR_A=6378137.0
comptime RADAR_B=6356752.314245
fn radar_ecef(lat:Float64,lon:Float64,alt:Float64)->InlineArray[Float64,3]:
    let a2=RADAR_A*RADAR_A;let b2=RADAR_B*RADAR_B;let e2=1.0-b2/a2;let lr=lat*RADAR_PI/180.0;let orad=lon*RADAR_PI/180.0
    let sl=sin(lr);let cl=cos(lr);let nr=RADAR_A/sqrt(1.0-e2*sl*sl)
    var result=InlineArray[Float64,3](fill=0.0);result[0]=(nr+alt)*cl*cos(orad);result[1]=(nr+alt)*cl*sin(orad);result[2]=(nr*(1.0-e2)+alt)*sl;return result
fn radar_geo(x:Float64,y:Float64,z:Float64)->InlineArray[Float64,3]:
    let a2=RADAR_A*RADAR_A;let b2=RADAR_B*RADAR_B;let e2=1.0-b2/a2;let ep=(a2-b2)/b2;let p=sqrt(x*x+y*y);var result=InlineArray[Float64,3](fill=0.0)
    if p==0.0:result[1]=if z>0.0:90.0 else: -90.0;result[2]=fabs(z)-RADAR_B;return result
    let theta=atan2(z*RADAR_A,p*RADAR_B);let st=sin(theta);let ct=cos(theta);let lon=atan2(y,x)
    let lat=atan2(z+ep*RADAR_B*st*st*st,p-e2*RADAR_A*ct*ct*ct);let sl=sin(lat);let nr=RADAR_A/sqrt(1.0-e2*sl*sl)
    result[0]=lat*180.0/RADAR_PI;result[1]=lon*180.0/RADAR_PI;result[2]=p/cos(lat)-nr;return result
@export("radar_target_calculation")
fn radar_target_calculation(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=6:return -1
    for i in range(6):if not isfinite(v[i]):return -1
    if v[0]<-80 or v[0]>80 or v[1]<-180 or v[1]>180 or v[2]<-1000 or v[2]>10000 or v[3]<-360 or v[3]>360 or v[4]<0 or v[4]>200000 or v[5]<-30 or v[5]>30:return -1
    let az=v[3]*RADAR_PI/180.0;let el=v[5]*RADAR_PI/180.0;let east=v[4]*cos(el)*sin(az);let north=v[4]*cos(el)*cos(az);let up=v[4]*sin(el)
    let radar=radar_ecef(v[0],v[1],v[2]);let lat=v[0]*RADAR_PI/180.0;let lon=v[1]*RADAR_PI/180.0
    let dx= -sin(lon)*east-sin(lat)*cos(lon)*north+cos(lat)*cos(lon)*up
    let dy=cos(lon)*east-sin(lat)*sin(lon)*north+cos(lat)*sin(lon)*up
    let dz=cos(lat)*north+sin(lat)*up;let target=radar_geo(radar[0]+dx,radar[1]+dy,radar[2]+dz)
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<3:return -2
    for i in range(3):o[i]=target[i]
    return 3
