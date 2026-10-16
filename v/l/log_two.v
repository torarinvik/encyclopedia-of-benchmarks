module log_two
@[export: 'log_two']
pub fn log_two(v &i64,n usize)i64{if n!=1{return -1};mut x:=unsafe{v[0]};if x<0||x>2147483647{return -1};mut r:=i64(0);for x>>1!=0{x=x>>1;r++};return r}
