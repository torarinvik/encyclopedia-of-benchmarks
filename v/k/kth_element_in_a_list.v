module kth_element_in_a_list
@[export: 'kth_element_in_a_list']
pub fn kth_element_in_a_list(v &i64,n usize)i64{if n<3||n>34{return -1};k:=unsafe{v[0]};pos:=unsafe{v[1]};if k<1||k>16||n!=usize(k+2)||pos<1||pos>k{return -1};for i in 0..int(k){x:=unsafe{v[i+2]};if x < -10000||x>10000{return -1}};return unsafe{v[pos+1]}}
