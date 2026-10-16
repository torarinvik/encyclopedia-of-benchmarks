package solve_quadratic_equation
import "core:c"
import "core:math"
put_f64_le :: proc "contextless" (out:[^]u8,offset:c.size_t,value:f64){bits:=transmute(u64)value;for b:=0;b<8;b+=1{out[offset+c.size_t(b)]=u8(bits>>u64(8*b))}}
@(export)
solve_quadratic_equation :: proc "c" (values:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if values==nil||length!=2 do return -1
    pi,qi:=values[0],values[1];if pi < -1_000_000||pi>1_000_000||qi < -1_000_000||qi>1_000_000 do return -1
    p,q:=f64(pi),f64(qi);root:=math.sqrt(p*p/4.0-q);if math.is_nan(root) do return 0
    x1,x2:=-p/2.0-root,-p/2.0+root
    if x1==x2 {if output==nil||capacity<8 do return -2;put_f64_le(output,0,x1);return 1}
    if output==nil||capacity<16 do return -2
    put_f64_le(output,0,x1);put_f64_le(output,8,x2);return 2
}
