fn putF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits:u64=@bitCast(value);
    for(0..8)|b| output[offset+b]=@truncate(bits>>@intCast(8*b));
}
export fn solve_quadratic_equation(values:?[*]const i64,length:usize,output:?[*]u8,capacity:usize)i64 {
    if(values==null||length!=2)return -1;
    const p_i=values.?[0];const q_i=values.?[1];
    if(p_i < -1_000_000||p_i>1_000_000||q_i < -1_000_000||q_i>1_000_000)return -1;
    const p:f64=@floatFromInt(p_i);const q:f64=@floatFromInt(q_i);const root=@sqrt(p*p/4.0-q);
    if(std.math.isNan(root))return 0;
    const x1=-p/2.0-root;const x2=-p/2.0+root;
    if(x1==x2){if(output==null||capacity<8)return -2;putF64Le(output.?,0,x1);return 1;}
    if(output==null||capacity<16)return -2;
    const out=output.?[0..16];putF64Le(out.ptr,0,x1);putF64Le(out.ptr,8,x2);return 2;
}
const std=@import("std");
