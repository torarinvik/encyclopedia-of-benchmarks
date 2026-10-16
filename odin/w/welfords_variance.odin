package welfords_variance
import "core:c"
MAX_LENGTH :: 64
MAX_ABS_VALUE :: i64(1_000_000)
INVALID_RESULT :: f64 = -1.0e300
@(export)
welfords_variance :: proc "c" (values:[^]i64,length:c.size_t)->f64 {
 if values==nil||length<2||length>MAX_LENGTH do return INVALID_RESULT
 mean:=f64(0);m2:=f64(0)
 for i:=c.size_t(0);i<length;i+=1{x:=values[i];if x < -MAX_ABS_VALUE||x>MAX_ABS_VALUE do return INVALID_RESULT;delta:=f64(x)-mean;mean+=delta/f64(i+1);m2+=delta*(f64(x)-mean)}
 return m2/f64(length-1)
}
