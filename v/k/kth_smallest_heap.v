module kth_smallest_heap
@[export: 'kth_smallest_heap']
pub fn kth_smallest_heap(v &i64,n usize)i64{if n<2||n>65{return -1};k:=unsafe{v[0]};if k<1||k>=i64(n){return -1};mut h:=[]i64{};for i in 0..k{z:=unsafe{v[i+1]};if z< -100000||z>100000{return -1};h<<z};h.sort(a>b);for i in k+1..n{z:=unsafe{v[i]};if z< -100000||z>100000{return -1};if z<=h[0]{h[0]=z;h.sort(a>b)}};return h[0]}
