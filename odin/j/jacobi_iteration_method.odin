package jacobi_iteration_method
import "core:c"
put :: proc(o:[^]u8,p:int,x:f64){bits:=transmute(u64)x;for k:=0;k<8;k+=1{o[p+k]=u8(bits>>(8*k))}}
@(export)
jacobi_iteration_method :: proc "c"(v:[^]i64,n:c.size_t,o:[^]u8,cap:c.size_t)->i64{if v==nil||n<2||n>26 do return -1;d,it:=v[0],v[1];if d<2||d>4||it<1||it>8||n!=c.size_t(2+d*d+2*d) do return -1;a:[4][4]f64{};b,x,y:[4]f64{};rhs:=2+d*d;ini:=rhs+d;for i:=i64(0);i<d;i+=1{off:=f64(0);for j:=i64(0);j<d;j+=1{z:=v[2+i*d+j];if z<0||z>4000 do return -1;a[i][j]=f64(z)/1000;if i!=j{off+=a[i][j]}};if a[i][i]<=off do return -1;if v[rhs+i] < -2000||v[rhs+i]>2000||v[ini+i] < -2000||v[ini+i]>2000 do return -1;b[i]=f64(v[rhs+i])/1000;x[i]=f64(v[ini+i])/1000};bytes:=c.size_t(d*8);if o==nil||cap<bytes do return -2;for _:=i64(0);_<it;_+=1{for i:=i64(0);i<d;i+=1{sum:=f64(0);for j:=i64(0);j<d;j+=1{if i!=j{sum+= -a[i][j]*x[j]}};y[i]=(sum+b[i])/a[i][i]};x=y};for i:=i64(0);i<d;i+=1{put(o,int(i)*8,x[i])};return i64(bytes)}
