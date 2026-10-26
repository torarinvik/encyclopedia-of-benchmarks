// Clean-room fixed-rational-scale geometric 2D pattern matching profile.
module two_dimensional_scaled_pattern_matching
const max_input=186;const max_fields=289
fn put(mut out &u8,at int,value i64){mut bits:=u64(value);for b in 0..8{unsafe{out[at+b]=u8(bits&255)};bits>>=8}}
@[export:'two_dimensional_scaled_pattern_matching']
pub fn two_dimensional_scaled_pattern_matching(v &i64,n usize,mut out &u8,cap usize)i64{unsafe{
 if v==nil||n<6||n>max_input{return -1};h0,w0,ph0,pw0,p,q:=v[0],v[1],v[2],v[3],v[4],v[5]
 if h0<1||h0>12||w0<1||w0>12||ph0<1||ph0>6||pw0<1||pw0>6||q<1||q>8||p<q||p>2*q{return -1};h,w,ph,pw:=int(h0),int(w0),int(ph0),int(pw0);if n!=usize(6+h*w+ph*pw){return -1}
 for i in 0..h*w+ph*pw{if v[6+i]<0||v[6+i]>255{return -1}};mut fields:=[max_fields]i64{};mut count:=1
 for r in 0..h{for c in 0..w{if p*i64(ph)>q*i64(h-r)||p*i64(pw)>q*i64(w-c){continue};mut matched:=true
  for y in 0..h-r{if (2*i64(y)+1)*q>=2*p*i64(ph){continue};py:=int(((2*i64(y)+1)*q)/(2*p));for x in 0..w-c{if (2*i64(x)+1)*q>=2*p*i64(pw){continue};px:=int(((2*i64(x)+1)*q)/(2*p));if v[6+(r+y)*w+c+x]!=v[6+h*w+py*pw+px]{matched=false;break}};if !matched{break}}
  if matched{fields[count]=i64(r);fields[count+1]=i64(c);count+=2}
 }};fields[0]=i64((count-1)/2);bytes:=8*count;if out==nil||cap<usize(bytes){return -2};for i in 0..count{put(mut out,8*i,fields[i])};return i64(bytes)
}}
