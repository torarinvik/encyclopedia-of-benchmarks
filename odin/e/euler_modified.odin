package euler_modified
import "core:c"
put64 :: proc(out:[^]u8,i:int,x:f64){b:=transmute(u64)x;for k:=0;k<8;k+=1{out[i*8+k]=u8(b>>(8*k))}}
@(export)
euler_modified :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||n!=2 do return -1;steps:=v[0];y0:=v[1];if steps<1||steps>8||y0<1||y0>4 do return -1
 bytes:=c.size_t(steps+1)*8;if out==nil||cap<bytes do return -2
 h:=f64(0.25);x:=f64(0);y:=f64(y0);put64(out,0,y)
 for i:=0;i<int(steps);i+=1{f0:=-2.0*x*y*y;predictor:=y+h*f0;f1:=-2.0*(x+h)*predictor*predictor;y=y+(h/2.0)*(f0+f1);x+=h;put64(out,i+1,y)}
 return i64(bytes)
}
