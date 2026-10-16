const freq = [_]f64{ 0.08497,0.01492,0.02202,0.04253,0.11162,0.02228,0.02015,0.06094,0.07546,0.00153,0.01292,0.04025,0.02406,0.06749,0.07507,0.01929,0.00095,0.07587,0.06327,0.09356,0.02758,0.00978,0.02560,0.00150,0.01994,0.00077 };
fn putF64Le(output: [*c]u8, value: f64) void { const bits=@as(u64,@bitCast(value));for(0..8)|b|{output[b]=@truncate(bits>>@intCast(b*8));} }
export fn decrypt_caesar_with_chi_squared(input: [*c]const i64,length: usize,output: [*c]u8,capacity: usize) i64 {
 if(input==null or length<1 or length>129)return -1;const tn=input[0];if(tn<0 or tn>128 or length!=@as(usize,@intCast(tn))+1)return -1;
 const text_n:usize=@intCast(tn);for(0..text_n)|i|{if(input[i+1]<0 or input[i+1]>127)return -1;}
 if(output==null or capacity<8+text_n)return -2;
 var best:[128]u8=@splat(0);var candidate:[128]u8=@splat(0);var best_score:f64=1e300;var best_shift:i64=0;
 for(0..26)|shift_usize|{const shift:i64=@intCast(shift_usize);var counts:[26]i64=@splat(0);
  for(0..text_n)|i|{const v=input[i+1];var d=v;if(v>=65 and v<=90){d=97+@mod(v-65-shift+2600,26);}else if(v>=97 and v<=122){d=97+@mod(v-97-shift+2600,26);}candidate[i]=@intCast(d);if(d>=97 and d<=122)counts[@intCast(d-97)]+=1;}
  var score:f64=0;for(0..26)|j|{const n=counts[j];if(n>0){const expected=freq[j]*@as(f64,@floatFromInt(n));const delta=@as(f64,@floatFromInt(n))-expected;score+=(delta*delta)/expected;}}
  var less=score<best_score;if(score==best_score){for(0..text_n)|i|{if(candidate[i]<best[i]){less=true;break;}if(candidate[i]>best[i])break;}}
  if(less){best_score=score;best_shift=shift;for(0..text_n)|i|{best[i]=candidate[i];}}
 }
 putF64Le(output,best_score);for(0..text_n)|i|{output[8+i]=best[i];}return best_shift;
}
