module last_item_in_a_list
@[export: 'last_item_in_a_list']
pub fn last_item_in_a_list(v &i64,n usize)i64{if n>64{return -1};for i in 0..n{x:=unsafe{v[i]};if x<0||x>100000{return -1}};if n==0{return -1};return unsafe{v[n-1]}}
