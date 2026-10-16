package pythagoras
import "core:c"
import "core:math"
@(export)
pythagoras :: proc "c" (v: [^]i64, n: c.size_t) -> f64 {
 if v == nil || n != 6 do return -1.0e300
 for i:=0;i<6;i+=1 {if v[i]<-1000000 || v[i]>1000000 do return -1.0e300}
 dx:=f64(v[3]-v[0]);dy:=f64(v[4]-v[1]);dz:=f64(v[5]-v[2])
 return math.sqrt(dx*dx+dy*dy+dz*dz)
}
