package integral_approximation
import "core:c"
sample :: proc(id:i64,x:f64)->f64 { if id==0 do return x*x; return x*x*x-x*x+378.0 }
@(export)
integral_approximation :: proc "c" (v:[^]i64,n:c.size_t)->f64 { if v==nil||n!=4 do return -1.0e300;id,li,ui,di:=v[0],v[1],v[2],v[3];if id<0||id>1||li<0||ui>32||li>=ui||di<1||di>8 do return -1.0e300;lo:=f64(li)/8.0;hi:=f64(ui)/8.0;d:=f64(di)/8.0;count:=int((hi-lo)/d);if count>32 do return -1.0e300;total:=f64(0);for i in 0..<count {begin:=lo+f64(i)*d;finish:=lo+f64(i+1)*d;total+=d*(sample(id,begin)+sample(id,finish))/2.0};return total }
