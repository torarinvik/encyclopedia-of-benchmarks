package scaled_exponential_linear_unit
import "core:c"
import "core:math"
@(export)
scaled_exponential_linear_unit :: proc "c" (v: [^]i64,n: c.size_t,out: [^]u8,cap: c.size_t)->i64 {
 if v==nil||n<3||n>259||v[0]<0||v[0]>256||n!=c.size_t(v[0]+3)||v[1]<-10000000||v[1]>10000000||v[2]<-10000000||v[2]>10000000 do return -1
 count:=int(v[0]);for i in 0..<count{if v[i+3]<-20000000||v[i+3]>20000000 do return -1};bytes:=count*8;if out==nil||cap<c.size_t(bytes) do return -2
 alpha:=f64(v[1])/1e6;lambda:=f64(v[2])/1e6
 for i in 0..<count{x:=f64(v[i+3])/1e6;inner:=x;if x<=0{inner=alpha*(math.exp(x)-1)};y:=lambda*inner;q:=i64(math.floor(y*1e9+0.5));bits:=transmute(u64)q;for b in 0..<8{out[i*8+b]=u8(bits>>(8*b))}}
 return i64(bytes)
}
