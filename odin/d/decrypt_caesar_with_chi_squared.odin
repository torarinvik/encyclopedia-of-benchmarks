package decrypt_caesar_with_chi_squared
import "core:c"
freq:[26]f64={0.08497,0.01492,0.02202,0.04253,0.11162,0.02228,0.02015,0.06094,0.07546,0.00153,0.01292,0.04025,0.02406,0.06749,0.07507,0.01929,0.00095,0.07587,0.06327,0.09356,0.02758,0.00978,0.02560,0.00150,0.01994,0.00077}
put_f64 :: proc "contextless" (out:[^]u8, value:f64) { bits:=transmute(u64)value; for i in 0..<8 { out[i]=u8((bits>>u64(i*8))&0xff) } }
@(export)
decrypt_caesar_with_chi_squared :: proc "c" (input:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64 {
 if input==nil||n<1||n>129||input[0]<0||input[0]>128||input[0]!=i64(n-1){return -1};text_n:=n-1;for i in 0..<text_n {if input[i+1]<0||input[i+1]>127{return -1}}
 if out==nil||cap<8+text_n{return -2}
 best:[128]u8;candidate:[128]u8;best_score:f64=1e300;best_shift:i64=0
 for shift:i64=0;shift<26;shift+=1 {
  counts:[26]i64
  for i in 0..<text_n {v:=input[i+1];d:=v;if v>=65&&v<=90 {d=97+(v-65-shift+2600)%26} else if v>=97&&v<=122 {d=97+(v-97-shift+2600)%26};candidate[i]=u8(d);if d>=97&&d<=122{counts[d-97]+=1}}
  score:f64=0;for j in 0..<26 {count:=counts[j];if count>0 {expected:=freq[j]*f64(count);delta:=f64(count)-expected;score+=(delta*delta)/expected}}
  less:=score<best_score;if score==best_score {for i in 0..<text_n {if candidate[i]<best[i]{less=true;break};if candidate[i]>best[i]{break}}}
  if less {best_score=score;best_shift=shift;for i in 0..<text_n{best[i]=candidate[i]}}
 }
 put_f64(out,best_score);for i in 0..<text_n{out[8+i]=best[i]};return best_shift
}
