module geofence
import math
const pi_value=3.14159265358979323846264338327950288
@[export: 'geofence']
pub fn geofence(a &i64,n usize)i64{
 if isnil(a)||n!=5{return -1}
 unsafe {
  if a[0]< -90000000||a[0]>90000000||a[2]< -90000000||a[2]>90000000||a[1]< -180000000||a[1]>180000000||a[3]< -180000000||a[3]>180000000||a[4]< -1000000||a[4]>30000000000{return -1}
  f:=pi_value/180000000.0;lat1:=f64(a[0])*f;lon1:=f64(a[1])*f;lat2:=f64(a[2])*f;lon2:=f64(a[3])*f
  dl:=lat2-lat1;dg:=lon2-lon1;s1:=math.sin(dl/2);s2:=math.sin(dg/2);mut h:=s1*s1+math.cos(lat1)*math.cos(lat2)*s2*s2
  if h<0{h=0};if h>1{h=1}
  distance:=6371010.0*(2*math.atan2(math.sqrt(h),math.sqrt(1-h)))
  return i64(distance<=f64(a[4])/1000.0)
 }
}
