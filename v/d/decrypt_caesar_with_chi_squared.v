module decrypt_caesar_with_chi_squared
import math
fn frequencies() [26]f64 { mut a := [26]f64{}; a[0]=0.08497;a[1]=0.01492;a[2]=0.02202;a[3]=0.04253;a[4]=0.11162;a[5]=0.02228;a[6]=0.02015;a[7]=0.06094;a[8]=0.07546;a[9]=0.00153;a[10]=0.01292;a[11]=0.04025;a[12]=0.02406;a[13]=0.06749;a[14]=0.07507;a[15]=0.01929;a[16]=0.00095;a[17]=0.07587;a[18]=0.06327;a[19]=0.09356;a[20]=0.02758;a[21]=0.00978;a[22]=0.02560;a[23]=0.00150;a[24]=0.01994;a[25]=0.00077;return a }
fn put_f64_le(mut output &u8, value f64) { mut bits := math.f64_bits(value);for b in 0..8 { unsafe { output[b] = u8(bits & 255) };bits >>= 8 } }
@[export: 'decrypt_caesar_with_chi_squared']
pub fn decrypt_caesar_with_chi_squared(input &i64,length usize,mut output &u8,capacity usize)i64 {
 if unsafe{input==nil} || length<1 || length>129{return -1};text_n:=unsafe{input[0]};if text_n<0 || text_n>128 || usize(text_n+1)!=length{return -1}
 for i in 0..int(text_n){v:=unsafe{input[i+1]};if v<0 || v>127{return -1}}
 if unsafe{output==nil} || capacity<8+usize(text_n){return -2}
 freq:=frequencies();mut best:=[128]u8{};mut candidate:=[128]u8{};mut best_score:=1e300;mut best_shift:=i64(0)
 for shift in 0..26 {mut counts:=[26]i64{};for i in 0..int(text_n){v:=unsafe{input[i+1]};mut d:=v;if v>=65 && v<=90{d=97+(v-65-i64(shift)+2600)%26}else if v>=97 && v<=122{d=97+(v-97-i64(shift)+2600)%26};candidate[i]=u8(d);if d>=97 && d<=122{counts[d-97]++}}
  mut score:=0.0;for j in 0..26{n:=counts[j];if n>0{expected:=freq[j]*f64(n);delta:=f64(n)-expected;score+=(delta*delta)/expected}}
  mut less:=score<best_score;if score==best_score{for i in 0..int(text_n){if candidate[i]<best[i]{less=true;break};if candidate[i]>best[i]{break}}}
  if less{best_score=score;best_shift=i64(shift);for i in 0..int(text_n){best[i]=candidate[i]}}
 }
 put_f64_le(mut output,best_score);for i in 0..int(text_n){unsafe{output[8+i]=best[i]}};return best_shift
}
