package three_dimensional_moment_curve
import "core:c"

MAX_OUTPUT :: 1544
put_i64 :: proc(out:[^]u8,offset:int,value:i64){bits:=u64(value);for byte:=0;byte<8;byte+=1{out[offset+byte]=u8(bits&255);bits>>=8}}

@(export)
three_dimensional_moment_curve :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length!=1||input[0]<0||input[0]>64{return -1};n:=int(input[0]);bytes:=8*(1+3*n)
    if output==nil||capacity<c.size_t(bytes){return -2};staged:[MAX_OUTPUT]u8;put_i64(&staged[0],0,i64(n))
    for i:=1;i<=n;i+=1{x:=i64(i);offset:=8*(1+3*(i-1));put_i64(&staged[0],offset,x);put_i64(&staged[0],offset+8,x*x);put_i64(&staged[0],offset+16,x*x*x)}
    for i:=0;i<bytes;i+=1{output[i]=staged[i]};return i64(bytes)
}
