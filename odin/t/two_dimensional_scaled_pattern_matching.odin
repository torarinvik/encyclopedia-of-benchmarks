// Clean-room fixed-rational-scale geometric 2D pattern matching profile.
package two_dimensional_scaled_pattern_matching
import "core:c"
const MAX_INPUT :: 186
const MAX_FIELDS :: 289
put :: proc "contextless" (out: [^]u8, at: int, value: i64) { bits:=u64(value);for b:=0;b<8;b+=1{out[at+b]=u8(bits&255);bits>>=8} }
@(export)
two_dimensional_scaled_pattern_matching :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64 {
 if v==nil||n<6||n>MAX_INPUT do return -1
 h0,w0,ph0,pw0,p,q:=v[0],v[1],v[2],v[3],v[4],v[5]
 if h0<1||h0>12||w0<1||w0>12||ph0<1||ph0>6||pw0<1||pw0>6||q<1||q>8||p<q||p>2*q do return -1
 h,w,ph,pw:=int(h0),int(w0),int(ph0),int(pw0);if n!=c.size_t(6+h*w+ph*pw) do return -1
 for i:=0;i<h*w+ph*pw;i+=1{if v[6+i]<0||v[6+i]>255 do return -1}
 fields:[MAX_FIELDS]i64;count:=1
 for r:=0;r<h;r+=1{for col:=0;col<w;col+=1{
  if p*i64(ph)>q*i64(h-r)||p*i64(pw)>q*i64(w-col){continue}
  matched:=true
  for y:=0;y<h-r&&matched;y+=1{if (2*i64(y)+1)*q>=2*p*i64(ph){continue};py:=int(((2*i64(y)+1)*q)/(2*p));for x:=0;x<w-col;x+=1{if (2*i64(x)+1)*q>=2*p*i64(pw){continue};px:=int(((2*i64(x)+1)*q)/(2*p));if v[6+(r+y)*w+col+x]!=v[6+h*w+py*pw+px]{matched=false;break}}}
  if matched{fields[count]=i64(r);fields[count+1]=i64(col);count+=2}
 }}
 fields[0]=i64((count-1)/2);bytes:=8*count;if out==nil||cap<c.size_t(bytes) do return -2;for i:=0;i<count;i+=1{put(&out[0],8*i,fields[i])};return i64(bytes)
}
