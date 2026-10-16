package nesterov_accelerated_sgd
import "core:c"
put_double :: proc(outp:[^]u8,off:int,x:f64){bits:=transmute(u64)x;for k:=0;k<8;k+=1{outp[off+k]=u8(bits>>u64(8*k))}}
@(export)
nesterov_accelerated_sgd :: proc "c" (v:[^]i64,n:c.size_t,outp:[^]u8,cap:c.size_t)->i64 {
 if v==nil||n<4 do return -1;wi,si,lm,mm:=v[0],v[1],v[2],v[3];if wi<1||wi>8||si<1||si>8||lm<0||lm>1000||mm<0||mm>1000||n!=c.size_t(4+wi*(si+1)) do return -1
 w,s:=int(wi),int(si);for i:=4;i<int(n);i+=1{if v[i] < -10000||v[i]>10000 do return -1};if outp==nil||cap<c.size_t(w*8) do return -2
 p:[8]f64;vel:[8]f64;lr,m:=f64(lm)/1000.0,f64(mm)/1000.0;for i:=0;i<w;i+=1{p[i]=f64(v[4+i])/1000.0}
 for t:=0;t<s;t+=1{for i:=0;i<w;i+=1{prev:=vel[i];g:=f64(v[4+w+t*w+i])/1000.0;vel[i]=m*vel[i]-lr*g;p[i]=p[i]-m*prev+(1.0+m)*vel[i]}}
 for i:=0;i<w;i+=1{put_double(outp,i*8,p[i])};return i64(w*8)
}
