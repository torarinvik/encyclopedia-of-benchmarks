module windowed_median
import math
fn put_f64_le(mut output &u8, offset int, value f64) { mut bits:=math.bits_from_f64(value);for b in 0..8{unsafe{output[offset+b]=u8(bits&255)};bits>>=8} }
@[export: 'windowed_median']
pub fn windowed_median(input &i64,length usize,mut output &u8,capacity usize) i64 {
 if unsafe{input==nil}||length<3{return -1};wv:=input[0];nv:=input[1];if wv<1||wv>64||nv<1||nv>128{return -1};w:=int(wv);n:=int(nv);if length!=usize(n+2){return -1}
 unsafe{for i in 0..n{if input[2+i]<-1000000||input[2+i]>1000000{return -1}};if capacity<n*8||output==nil{return -2}
 mut sorted:=[64]i64{};mut active:=0
 for i in 0..n{if i>=w{old:=input[2+i-w];mut p:=0;for p<active&&sorted[p]!=old{p++};if p==active{return -1};for j:=p+1;j<active;j++{sorted[j-1]=sorted[j]};active--}
  value:=input[2+i];mut p:=0;for p<active&&sorted[p]<value{p++};mut j:=active;for j>p{sorted[j]=sorted[j-1];j--};sorted[p]=value;active++
  mut median:=f32(0);if active%2==1{median=f32(sorted[active/2])}else{median=0.5*f32(sorted[active/2-1])+0.5*f32(sorted[active/2])};put_f64_le(mut output,i*8,f64(median))}
 return i64(n*8)}
}
