module intensity_based_segmentation
@[export: 'intensity_based_segmentation']
pub fn intensity_based_segmentation(v &i64,n usize)i64{if n<2||n>12{return -1};k:=unsafe{v[0]};if k<0||k>4||n<=usize(k)+1||n>usize(k)+8{return -1};for j in 1..n{x:=unsafe{v[j]};if x<0||x>255{return -1}};mut out:=i64(0);mut place:=i64(1);for p in usize(k)+1..n{mut label:=i64(0);for i in 0..usize(k){if unsafe{v[p]}>unsafe{v[i+1]}{label=i64(i+1)}};out+=label*place;place*=5};return out}
