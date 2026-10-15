module arithmetic_mean
const max_length=usize(64)
const bound=i64(1_000_000)
@[export: 'arithmetic_mean']
pub fn arithmetic_mean(values &i64,length usize) f64 {
 if length==0||length>max_length{return -1.0e300}
 mut total:=i64(0)
 for i in 0..length { x:=unsafe{values[i]}; if x < -bound||x>bound{return -1.0e300}; total+=x }
 return f64(total)/f64(length)
}
