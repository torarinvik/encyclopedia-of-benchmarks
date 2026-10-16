const max_count = 64
const modulus = i64(1000000007)
const base = i64(2000000003)
@[export: 'partition_linked_list']
pub fn partition_linked_list(v &i64, n usize) i64 {
 unsafe {
  if v == nil || n < 2 || n > 66 || v[0] < 0 || v[0] > max_count || n != usize(v[0] + 2) || v[1] < -2147483648 || v[1] > 2147483647 { return -1 }
  count:=int(v[0]); mut less:=[max_count]i64{}; mut ge:=[max_count]i64{}; mut l:=0; mut g:=0
  for i in 0..count { x:=v[i+2]; if x < -2147483648 || x > 2147483647 { return -1 }; if x<v[1] { less[l]=x;l++ } else { ge[g]=x;g++ } }
  mut h:=i64(0); for i in 0..l { h=(h*base+less[i]+2147483648)%modulus }; for i in 0..g { h=(h*base+ge[i]+2147483648)%modulus }; return h
 }
}
