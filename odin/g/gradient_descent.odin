package gradient_descent
import "core:c"
INVALID :: f64(-1.0e300)
@(export)
gradient_descent :: proc "c" (v: [^]i64, length: c.size_t) -> f64 {
 if v==nil || length<5 || length>68 do return INVALID
 d:=v[0]; selected:=v[1]; rate:=v[2]; iterations:=v[3]
 if d<1 || d>64 || selected<0 || selected>=d || length!=c.size_t(4+d) || rate<1 || rate>500000 || iterations<0 || iterations>10000 do return INVALID
 x:=[64]f64{}
 for i:=c.size_t(0);i<c.size_t(d);i+=1 {if v[4+i]< -10 || v[4+i]>10 do return INVALID; x[i]=f64(v[4+i])}
 alpha:=f64(rate)/1_000_000.0
 for _ in 0..<iterations {g:=[64]f64{}; for i:=i64(0);i<d;i+=1 {g[i]=2.0*x[i]}; for i:=i64(0);i<d;i+=1 {x[i]-=alpha*g[i]}}
 return x[selected]
}
