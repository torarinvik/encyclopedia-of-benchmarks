module local_binary_pattern
@[export: 'local_binary_pattern']
pub fn local_binary_pattern(v &i64,n usize)i64{if n!=9{return -1};for i in 0..9{x:=unsafe{v[i]};if x<0||x>255{return -1}};ix:=[8]usize{2,5,1,8,7,6,3,0};mut out:=i64(0);for i in 0..8{if unsafe{v[ix[i]]}>=unsafe{v[4]}{out|=i64(1)<<i}};return out}
