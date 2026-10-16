module welfords_variance
const max_length=64
const max_abs_value=i64(1_000_000)
const invalid_result=-1.0e300
@[export:'welfords_variance']
pub fn welfords_variance(values &i64,length usize) f64 {
 if unsafe{values==nil}||length<2||length>max_length{return invalid_result}
 mut mean:=0.0;mut m2:=0.0
 for i in 0..length{x:=unsafe{values[i]};if x < -max_abs_value||x>max_abs_value{return invalid_result};delta:=f64(x)-mean;mean+=delta/f64(i+1);m2+=delta*(f64(x)-mean)}
 return m2/f64(length-1)
}
