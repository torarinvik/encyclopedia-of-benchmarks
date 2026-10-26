// Clean-room fixed-rational-scale geometric 2D pattern matching profile.
const FIELDS:usize=289;const INPUT:usize=186;
fn put(out:[*]u8,at:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|i|out[at+i]=@truncate(bits>>@intCast(8*i));}
export fn two_dimensional_scaled_pattern_matching(v:[*c]const i64,n:usize,out_opt:?[*]u8,cap:usize)i64{
 if(v==null||n<6||n>INPUT)return -1;const h0=v[0];const w0=v[1];const ph0=v[2];const pw0=v[3];const p=v[4];const q=v[5];if(h0<1||h0>12||w0<1||w0>12||ph0<1||ph0>6||pw0<1||pw0>6||q<1||q>8||p<q||p>2*q)return -1;
 const h:usize=@intCast(h0);const w:usize=@intCast(w0);const ph:usize=@intCast(ph0);const pw:usize=@intCast(pw0);if(n!=6+h*w+ph*pw)return -1;for(0..h*w+ph*pw)|i|if(v[6+i]<0||v[6+i]>255)return -1;
 var fields:[FIELDS]i64=@splat(0);var count:usize=1;for(0..h)|r|{for(0..w)|c|{if(p*ph0>q*@as(i64,@intCast(h-r))||p*pw0>q*@as(i64,@intCast(w-c)))continue;var matched=true;
  for(0..h-r)|y|{if((2*@as(i64,@intCast(y))+1)*q>=2*p*ph0)continue;const py:usize=@intCast(((2*@as(i64,@intCast(y))+1)*q)/(2*p));for(0..w-c)|x|{if((2*@as(i64,@intCast(x))+1)*q>=2*p*pw0)continue;const px:usize=@intCast(((2*@as(i64,@intCast(x))+1)*q)/(2*p));if(v[6+(r+y)*w+c+x]!=v[6+h*w+py*pw+px]){matched=false;break}}if(!matched)break}
  if(matched){fields[count]=@intCast(r);fields[count+1]=@intCast(c);count+=2}
 }}fields[0]=@intCast((count-1)/2);const bytes=8*count;if(out_opt==null||cap<bytes)return -2;const out=out_opt.?;var staged:[FIELDS*8]u8=@splat(0);for(0..count)|i|put(&staged,8*i,fields[i]);@memcpy(out[0..bytes],staged[0..bytes]);return @intCast(bytes)
}
