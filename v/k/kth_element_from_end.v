module kth_element_from_end
@[export: 'kth_element_from_end']
pub fn kth_element_from_end(v &i64,n usize)i64{if n<1||n>65{return -1};k:=unsafe{v[0]};if k<=0||k>=i64(n){return -1};for i in 1..n{z:=unsafe{v[i]};if z<0||z>100000{return -1}};return unsafe{v[usize(i64(n)-k)]}}
