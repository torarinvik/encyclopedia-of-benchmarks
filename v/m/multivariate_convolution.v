module multivariate_convolution
const max_k = 3
const max_p = 32
const max_input = 69
const max_output = 256
const mod = i64(998244353)
fn store_le(mut output &u8, offset int, value i64) { mut bits:=u64(value); for b in 0..8 { unsafe { output[offset+b]=u8(bits&255) }; bits>>=8 } }
@[export: 'multivariate_convolution']
pub fn multivariate_convolution(input &i64,length usize,mut output &u8,capacity usize) i64 {
 unsafe {
  if input==nil||length<1||length>max_input{return -1};k0:=input[0];if k0<0||k0>max_k{return -1};k:=int(k0);if length<usize(1+k){return -1}
  mut dims:=[max_k]int{};mut p:=1
  for axis in 0..k {d0:=input[1+axis];if d0<2||d0>max_p||p>max_p/int(d0){return -1};dims[axis]=int(d0);p*=dims[axis]}
  start:=1+k;if length!=usize(start+2*p){return -1};for q in start..int(length){if input[q]<0||input[q]>=mod{return -1}}
  bytes:=8*p;if bytes>max_output{return -1};if output==nil||capacity<usize(bytes){return -2}
  mut a:=[]i64{len:max_p,init:0};mut b:=[]i64{len:max_p,init:0};mut result:=[]i64{len:max_p,init:0}
  for i in 0..p{a[i]=input[start+i];b[i]=input[start+p+i]}
  for i in 0..p{for j in 0..p{mut target:=0;mut stride:=1;mut valid:=true;for axis in 0..k{d:=dims[axis];sum:=(i/stride)%d+(j/stride)%d;if sum>=d{valid=false;break};target+=sum*stride;stride*=d};if valid{result[target]=(result[target]+a[i]*b[j])%mod}}}
  for i in 0..p{store_le(mut output,8*i,result[i])};return i64(bytes)
 }
}
