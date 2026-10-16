package geofence
import "core:c"
import "core:math"
PI_VALUE :: 3.14159265358979323846264338327950288
@(export)
geofence :: proc "c" (a:[^]i64,n:c.size_t)->i64{
 if a==nil||n!=5 do return -1
 if a[0]<-90000000||a[0]>90000000||a[2]<-90000000||a[2]>90000000||a[1]<-180000000||a[1]>180000000||a[3]<-180000000||a[3]>180000000||a[4]<-1000000||a[4]>30000000000 do return -1
 f:=PI_VALUE/180000000.0;lat1:=f64(a[0])*f;lon1:=f64(a[1])*f;lat2:=f64(a[2])*f;lon2:=f64(a[3])*f
 dl:=lat2-lat1;dg:=lon2-lon1;s1:=math.sin(dl/2);s2:=math.sin(dg/2);h:=s1*s1+math.cos(lat1)*math.cos(lat2)*s2*s2
 if h<0 do h=0;if h>1 do h=1
 distance:=6_371_010.0*(2*math.atan2(math.sqrt(h),math.sqrt(1-h)))
 return i64(distance<=f64(a[4])/1000.0)
}
