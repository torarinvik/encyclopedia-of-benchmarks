const std = @import("std");
fn add32(a:f32,b:f32) f32 { return a+b; }
fn sub32(a:f32,b:f32) f32 { return a-b; }
fn mul32(a:f32,b:f32) f32 { return a*b; }

export fn versabench_beamformer(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    if(input_opt==null or length!=48)return -1;const input=input_opt.?;var v=[_]f32{0}**48;
    for(0..48)|i|{const x=input[i];if(!std.math.isFinite(x) or x < -128.0 or x > 128.0)return -1;v[i]=@floatCast(x);}
    var real:f32=0;var imag:f32=0;
    for(0..12)|c|{const b=4*c;const rr=sub32(mul32(v[b],v[b+2]),mul32(v[b+1],v[b+3]));const ii=add32(mul32(v[b],v[b+3]),mul32(v[b+1],v[b+2]));real=add32(real,rr);imag=add32(imag,ii);}
    const output=output_opt orelse return -2;if(capacity<2)return -2;output[0]=@floatCast(real);output[1]=@floatCast(imag);return 2;
}
