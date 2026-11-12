const MaxK: usize = 3;
const MaxP: usize = 32;
const MaxInput: usize = 69;
const MaxOutput: usize = 256;
const Mod: i64 = 998_244_353;
fn storeLe(output: [*]u8, offset: usize, value: i64) void { const bits: u64 = @bitCast(value); for (0..8) |b| output[offset+b] = @truncate(bits >> @intCast(8*b)); }
export fn multivariate_convolution(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if(input_opt==null or length<1 or length>MaxInput)return -1;const input=input_opt.?;const k0=input[0];if(k0<0 or k0>3)return -1;const k:usize=@intCast(k0);if(length<1+k)return -1;
    var dims:[MaxK]usize=@splat(0);var p:usize=1;for(0..k)|axis|{const d0=input[1+axis];if(d0<2 or d0>32)return -1;const d:usize=@intCast(d0);if(p>MaxP/d)return -1;dims[axis]=d;p*=d;}
    const start=1+k;if(length!=start+2*p)return -1;for(input[start..length])|x|{if(x<0 or x>=Mod)return -1;}
    const bytes=8*p;if(bytes>MaxOutput)return -1;if(output_opt==null or capacity<bytes)return -2;var a:[MaxP]i64=@splat(0);var b:[MaxP]i64=@splat(0);var result:[MaxP]i64=@splat(0);
    for(0..p)|i|{a[i]=input[start+i];b[i]=input[start+p+i];}
    for(0..p)|i|{for(0..p)|j|{var target:usize=0;var stride:usize=1;var valid=true;for(0..k)|axis|{const d=dims[axis];const sum=(i/stride)%d+(j/stride)%d;if(sum>=d){valid=false;break;}target+=sum*stride;stride*=d;}if(valid)result[target]=(result[target]+a[i]*b[j])%Mod;}}
    const output=output_opt.?;for(0..p)|i|storeLe(output,8*i,result[i]);return @intCast(bytes);
}
