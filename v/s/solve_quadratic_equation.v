import math
fn put_f64_le(mut output &u8,offset int,value f64){bits:=math.bits_from_f64(value);for b in 0..8{unsafe{output[offset+b]=u8(bits&255)};bits>>=8}}
@[export:'solve_quadratic_equation']
pub fn solve_quadratic_equation(values &i64,length usize,mut output &u8,capacity usize)i64 {
    if unsafe{values==nil}||length!=2{return -1}
    unsafe{
        pi,qi:=values[0],values[1];if pi < -1_000_000||pi>1_000_000||qi < -1_000_000||qi>1_000_000{return -1}
        p,q:=f64(pi),f64(qi);root:=math.sqrt(p*p/4.0-q);if root!=root{return 0}
        x1,x2:=-p/2.0-root,-p/2.0+root
        if x1==x2{if output==nil||capacity<8{return -2};put_f64_le(mut output,0,x1);return 1}
        if output==nil||capacity<16{return -2};put_f64_le(mut output,0,x1);put_f64_le(mut output,8,x2);return 2
    }
}
