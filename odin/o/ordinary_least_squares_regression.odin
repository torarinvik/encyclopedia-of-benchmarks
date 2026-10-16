package ordinary_least_squares_regression
import "core:c"
put_double :: proc(outp: [^]u8, offset: int, value: f64) { bits:=transmute(u64)value; for b:=0;b<8;b+=1 { outp[offset+b]=u8(bits>>u64(8*b)) } }
@(export)
ordinary_least_squares_regression :: proc "c" (v:[^]i64,n:c.size_t,outp:[^]u8,cap:c.size_t)->i64 {
 if v==nil||n<5||v[0]<2||v[0]>32||n!=c.size_t(1+2*v[0]) do return -1
 count:=int(v[0]);xs:[32]f64;ys:[32]f64;xm,ym:f64=0,0
 for i:=0;i<count;i+=1 { x,y:=v[1+2*i],v[2+2*i];if x < -10000||x>10000||y < -10000||y>10000 do return -1;xs[i]=f64(x);ys[i]=f64(y);xm+=xs[i];ym+=ys[i] }
 xm/=f64(count);ym/=f64(count);num,den:f64=0,0
 for i:=0;i<count;i+=1 { dx:=xs[i]-xm;num+=dx*(ys[i]-ym);den+=dx*dx }
 if den==0 do return -1;slope:=num/den;intercept:=ym-slope*xm
 if outp==nil||cap<16 do return -2;put_double(outp,0,intercept);put_double(outp,8,slope);return 16
}
