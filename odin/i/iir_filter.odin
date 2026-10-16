package iir_filter
import "core:c"
put64 :: proc(out:[^]u8,slot:int,x:f64){bits:=transmute(u64)x;for k:=0;k<8;k+=1{out[slot*8+k]=u8(bits>>(8*k))}}
@(export)
iir_filter :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||n<7||n>26 do return -1;order:=v[0];samples:=v[1]
 if order<1||order>3||samples<1||samples>16||n!=c.size_t(4+2*order+samples)do return -1
 a:[4]f64;b:[4]f64;xh:[3]f64;yh:[3]f64
 for i:=0;i<4;i+=1{a[i]=0;b[i]=0};for i:=0;i<3;i+=1{xh[i]=0;yh[i]=0}
 for i:=0;i<int(order)+1;i+=1{av:=v[2+i];bv:=v[3+int(order)+i];if av < -500||av>2000||bv < -500||bv>500 do return -1;a[i]=f64(av)/1000.0;b[i]=f64(bv)/1000.0}
 if a[0]<0.5 do return -1
 for i:=0;i<int(samples);i+=1{x:=v[4+2*int(order)+i];if x < -1000||x>1000 do return -1}
 bytes:=c.size_t(samples)*8;if out==nil||cap<bytes do return -2
 for s:=0;s<int(samples);s+=1{x:=f64(v[4+2*int(order)+s])/1000.0;y:=f64(0);for i:=1;i<=int(order);i+=1{y+=b[i]*xh[i-1]-a[i]*yh[i-1]};y=(y+b[0]*x)/a[0];i:=int(order);for i>1{i-=1;xh[i]=xh[i-1];yh[i]=yh[i-1]};xh[0]=x;yh[0]=y;put64(out,s,y)}
 return i64(bytes)
}
