module is_arithmetic_series
const max_length=usize(64)
const bound=i64(1_000_000)
@[export: 'is_arithmetic_series']
pub fn is_arithmetic_series(values &i64,length usize) i64 {
 if length==0||length>max_length{return -1}
 for i in 0..length { x:=unsafe{values[i]}; if x < -bound||x>bound{return -1} }
 if length==1{return 1}
 d:=unsafe{values[1]-values[0]}
 for i in 1..length-1 { if unsafe{values[i+1]-values[i]}!=d{return 0} }
 return 1
}
