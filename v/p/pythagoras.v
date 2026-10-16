module pythagoras
import math
@[export: 'pythagoras']
pub fn pythagoras(v &i64,n usize) f64 {
 unsafe {
  if v==nil || n!=6 {return -1.0e300}
  for i in 0..6 {if v[i]<-1000000 || v[i]>1000000{return -1.0e300}}
  dx:=f64(v[3]-v[0]);dy:=f64(v[4]-v[1]);dz:=f64(v[5]-v[2])
  return math.sqrt(dx*dx+dy*dy+dz*dz)
 }
}
