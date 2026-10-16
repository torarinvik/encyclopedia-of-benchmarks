package gram_schmidt
import "core:c"
put_f64 :: proc(out:[^]u8,at:int,x:f64){u:=transmute(u64)x;for i:=0;i<8;i+=1{out[at+i]=u8(u>>(8*i))}}
@(export)
gram_schmidt :: proc "c"(v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{if v==nil||n<2||n>18 do return -1;r,d:=v[0],v[1];if r<1||r>4||d<r||d>4||n!=2+c.size_t(r*d) do return -1;a:[4][4]f64{};q:[4][4]f64{};for i:=i64(0);i<r;i+=1{for j:=i64(0);j<d;j+=1{z:=v[2+i*d+j];if z < -1000||z>1000||(j<i&&z!=0)||(j==i&&(z<100||z>1000)) do return -1;a[i][j]=f64(z)/1000}};bytes:=c.size_t(r*d*8);if out==nil||cap<bytes do return -2;for k:=i64(0);k<r;k+=1{p:[4]f64{};for i:=i64(0);i<k;i+=1{dot,norm:=f64(0),f64(0);for j:=i64(0);j<d;j+=1{dot+=a[k][j]*q[i][j];norm+=q[i][j]*q[i][j]};f:=dot/norm;for j:=i64(0);j<d;j+=1{p[j]+=q[i][j]*f}};for j:=i64(0);j<d;j+=1{q[k][j]=a[k][j]-p[j]}};for i:=i64(0);i<r;i+=1{for j:=i64(0);j<d;j+=1{put_f64(out,int(i*d+j)*8,q[i][j])}};return i64(bytes)}
