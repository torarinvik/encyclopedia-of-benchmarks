package mean_squared_logarithmic_error
import "core:c"
import "core:math"
INVALID :: -1.0e300
SCALE :: 1_000_000.0
@(export)
mean_squared_logarithmic_error :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values==nil||length<1 do return INVALID
    n0:=values[0];if n0<1||n0>64 do return INVALID;n:=int(n0);if length!=1+2*n do return INVALID
    for i:=0;i<2*n;i+=1{x:=values[1+i];if x< -999999||x>1_000_000 do return INVALID}
    total:=0.0
    for i:=0;i<n;i+=1{t:=f64(values[1+i])/SCALE;p:=f64(values[1+n+i])/SCALE;d := math.log_f64(1.0+t)-math.log_f64(1.0+p); total += d*d}
    return total/f64(n)
}
