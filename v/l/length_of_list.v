module length_of_list
@[export: 'length_of_list']
pub fn length_of_list(v &i64,n usize)i64{if n>64{return -1};for i in 0..n{x:=unsafe{v[i]};if x<0||x>100000{return -1}};return i64(n)}
