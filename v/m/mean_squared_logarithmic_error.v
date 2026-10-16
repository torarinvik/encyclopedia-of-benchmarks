module mean_squared_logarithmic_error
import math
const invalid = -1.0e300
const scale = 1_000_000.0
@[export: 'mean_squared_logarithmic_error']
pub fn mean_squared_logarithmic_error(values &i64, length usize) f64 {
    if values==nil||length<1{return invalid};n0:=values[0];if n0<1||n0>64{return invalid};n:=int(n0);if length!=1+2*n{return invalid}
    for i in 0..2*n{x:=values[1+i];if x< -999999||x>1_000_000{return invalid}}
    mut total:=0.0
    for i in 0..n{t:=f64(values[1+i])/scale;p:=f64(values[1+n+i])/scale;d := math.log(1.0+t)-math.log(1.0+p); total+=d*d}
    return total/f64(n)
}
