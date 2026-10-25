package edn_vec_mpy1
import "core:c"
put64 :: proc(out:[^]u8,pos:c.size_t,value:i64){u:=u64(value);for j:c.size_t=0;j<8;j+=1{out[pos+j]=u8(u>>(8*j))}}
@(export)
edn_vec_mpy1 :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{if v==nil||n<4||n>130 do return -1;count:=v[0];if count<1||count>64||n!=c.size_t(2+2*count) do return -1;q:=c.size_t(count);scale:=v[n-1];if scale< -1024||scale>1023 do return -1;y:[64]i64;x:[64]i64;for i:c.size_t=0;i<q;i+=1{y[i]=v[1+i];x[i]=v[1+q+i];if y[i]< -1024||y[i]>1023||x[i]< -1024||x[i]>1023 do return -1};bytes:=8*q;if out==nil||cap<bytes do return -2;for i:c.size_t=0;i<q;i+=1{y[i]+=(scale*x[i])>>15};for i:c.size_t=0;i<q;i+=1{put64(out,8*i,y[i])};return i64(bytes)}
