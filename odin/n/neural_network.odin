package neural_network
import "core:c"
import "core:math"
putd :: proc(o:[^]u8,p:int,x:f64){bits:=transmute(u64)x;for k:=0;k<8;k+=1{o[p+k]=u8(bits>>u64(k*8))}}
sig :: proc(x:f64)->f64{return 1.0/(1.0+math.exp(-x))}
@(export)
neural_network :: proc "c" (v:[^]i64,n:c.size_t,o:[^]u8,cap:c.size_t)->i64{if v==nil||n<7 do return -1;ni,nh,no:=v[0],v[1],v[2];if ni<1||ni>3||nh<1||nh>3||no<1||no>3||int(n)!=3+int(ni)+int(ni*nh)+int(nh*no) do return -1;for i:=3;i<int(n);i+=1{if v[i] < -1000||v[i]>1000 do return -1};if o==nil||cap<c.size_t(no*8) do return -2;xs:=3;w1:=xs+int(ni);w2:=w1+int(ni*nh);h:[3]f64;for j:=0;j<int(nh);j+=1{z:=0.0;for i:=0;i<int(ni);i+=1{z+=f64(v[xs+i])/1000.0*(f64(v[w1+i*int(nh)+j])/1000.0)};h[j]=sig(z)};for j:=0;j<int(no);j+=1{z:=0.0;for i:=0;i<int(nh);i+=1{z+=h[i]*(f64(v[w2+i*int(no)+j])/1000.0)};putd(o,j*8,sig(z))};return no*8}
