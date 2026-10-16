package orbital_transfer_work
import "core:c"
put_double :: proc(outp:[^]u8,x:f64){bits:=transmute(u64)x;for k:=0;k<8;k+=1{outp[k]=u8(bits>>u64(8*k))}}
@(export)
orbital_transfer_work :: proc "c" (v:[^]i64,n:c.size_t,outp:[^]u8,cap:c.size_t)->i64{if v==nil||n!=4 do return -1;a,b,r1,r2:=v[0],v[1],v[2],v[3];if a < -1000000000||a>1000000000||b < -1000000||b>1000000||r1<1||r1>1000000000||r2<1||r2>1000000000 do return -1;if outp==nil||cap<8 do return -2;work:=(6.67430e-11*f64(a)*f64(b)/2.0)*(1.0/f64(r1)-1.0/f64(r2));put_double(outp,work);return 8}
