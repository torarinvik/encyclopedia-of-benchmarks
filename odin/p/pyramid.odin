package pyramid

import "core:math"

@(export)
pyramid :: proc "c" (v: [^]i64, n: u64) -> f64 {
 if v==nil||n!=3||v[0]<0||v[0]>1||v[1]<1||v[1]>10_000_000||v[2]<1||v[2]>10_000_000 do return -1e300
 b:=f64(v[1])/1000.0;h:=f64(v[2])/1000.0;area:=math.pow(b,2.0)
 if v[0]==0 do return (area*h)/3.0
 return area+((b*4.0)/2.0)*math.sqrt(math.pow(b/2.0,2.0)+math.pow(h,2.0))
}
