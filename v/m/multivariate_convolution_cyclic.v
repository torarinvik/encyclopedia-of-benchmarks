module multivariate_convolution_cyclic
const max_k=3
const max_p=32
const max_input=70
const max_output=256
fn is_prime(p int) bool {if p<2{return false};for d in 2..p {if d*d>p{break};if p%d==0{return false}};return true}
fn store_le(mut output &u8,offset int,value i64){mut bits:=u64(value);for b in 0..8{unsafe{output[offset+b]=u8(bits&255)};bits>>=8}}
@[export: 'multivariate_convolution_cyclic']
pub fn multivariate_convolution_cyclic(input &i64,length usize,mut output &u8,capacity usize)i64{
 unsafe{
  if input==nil||length<2||length>max_input{return -1};p0:=input[0];k0:=input[1];if p0<2||p0>97||!is_prime(int(p0))||k0<0||k0>max_k{return -1};p:=int(p0);k:=int(k0);if length<usize(2+k){return -1}
  mut dims:=[max_k]int{};mut product:=1
  for axis in 0..k{d0:=input[2+axis];if d0<2||d0>max_p||(p-1)%int(d0)!=0||product>max_p/int(d0){return -1};dims[axis]=int(d0);product*=dims[axis]}
  start:=2+k;if length!=usize(start+2*product){return -1};for q in start..int(length){if input[q]<0||input[q]>=p0{return -1}}
  bytes:=8*product;if bytes>max_output{return -1};if output==nil||capacity<usize(bytes){return -2}
  mut a:=[]i64{len:max_p,init:0};mut b:=[]i64{len:max_p,init:0};mut result:=[]i64{len:max_p,init:0}
  for i in 0..product{a[i]=input[start+i];b[i]=input[start+product+i]}
  for i in 0..product{for j in 0..product{mut target:=0;mut stride:=1;for axis in 0..k{d:=dims[axis];sum:=((i/stride)%d+(j/stride)%d)%d;target+=sum*stride;stride*=d};result[target]=(result[target]+a[i]*b[j])%p0}}
  for i in 0..product{store_le(mut output,8*i,result[i])};return i64(bytes)
 }
}
