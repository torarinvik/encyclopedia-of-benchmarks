package edn_lattice_synthesis
import "core:c"
put64 :: proc(out:[^]u8,pos:c.size_t,value:i64){u:=u64(value);for j:c.size_t=0;j<8;j+=1{out[pos+j]=u8(u>>(8*j))}}
@(export)
edn_lattice_synthesis :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{if v==nil||n<2||n>34 do return -1;order:=v[0];f:=v[1];if order<1||order>16||f< -65536||f>65535||n!=c.size_t(2+2*order) do return -1;q:=c.size_t(order);b:[16]i64; k:[16]i64;for i:c.size_t=0;i<q;i+=1{b[i]=v[2+i];k[i]=v[2+q+i];if b[i]< -1024||b[i]>1023||k[i]< -1024||k[i]>1023 do return -1};bytes:=8*(q+1);if out==nil||cap<bytes do return -2;f-=b[q-1]*k[q-1];z:=q;for z>1{z-=1;i:=z-1;f-=b[i]*k[i];b[i+1]=b[i]+((k[i]*(f>>16))>>16)};b[0]=f>>16;put64(out,0,f);for i:c.size_t=0;i<q;i+=1{put64(out,8*(i+1),b[i])};return i64(bytes)}
