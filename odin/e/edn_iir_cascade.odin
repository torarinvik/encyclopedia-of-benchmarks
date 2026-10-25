package edn_iir_cascade
import "core:c"
put64 :: proc(out:[^]u8,pos:c.size_t,value:i64){u:=u64(value);for j:c.size_t=0;j<8;j+=1{out[pos+j]=u8(u>>(8*j))}}
@(export)
edn_iir_cascade :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{if v==nil||n<2||n>50 do return -1;count:=v[0];x:=v[1];if count<1||count>8||x< -1024||x>1023||n!=c.size_t(2+6*count) do return -1;q:=c.size_t(count);c:[32]i64;s:[16]i64;for i:c.size_t=0;i<4*q;i+=1{c[i]=v[2+i];if c[i]< -1024||c[i]>1023 do return -1};for i:c.size_t=0;i<2*q;i+=1{s[i]=v[2+4*q+i];if s[i]< -1024||s[i]>1023 do return -1};bytes:=8*(1+2*q);if out==nil||cap<bytes do return -2;for i:c.size_t=0;i<q;i+=1{t:=x+((c[4*i+2]*s[2*i]+c[4*i+3]*s[2*i+1])>>15);x=t+((c[4*i]*s[2*i]+c[4*i+1]*s[2*i+1])>>15);s[2*i+1]=s[2*i];s[2*i]=t};put64(out,0,x);for i:c.size_t=0;i<2*q;i+=1{put64(out,8*(i+1),s[i])};return i64(bytes)}
