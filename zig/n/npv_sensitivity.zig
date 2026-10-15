/// Evaluate net present value for each supplied discount rate.
const std=@import("std");
fn putF64Le(out:[*]u8,offset:usize,value:f64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[offset+b]=@truncate(bits>>@intCast(8*b));}
pub export fn npv_sensitivity(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<2)return -1;const n64=input[0];const rates64=input[1];if(n64<0 or n64>64 or rates64<0 or rates64>32)return -1;
    const n:usize=@intCast(n64);const rates:usize=@intCast(rates64);if(length!=2+n+rates)return -1;
    const flows=input[2..][0..n];const rateValues=input[2+n..][0..rates];for(flows)|v|{if(v < -1_000_000 or v>1_000_000)return -1;}for(rateValues)|v|{if(v<0 or v>1000)return -1;}
    if(capacity<rates*8 or(rates>0 and output==null))return -2;if(rates==0)return 0;
    for(rateValues,0..)|rateBp,r|{const rate=@as(f64,@floatFromInt(rateBp))/10000.0;var total:f64=0.0;for(flows,0..)|flow,t|{const term=@as(f64,@floatFromInt(flow))/std.math.pow(f64,1.0+rate,@floatFromInt(t));total=total+term;}putF64Le(output,r*8,total);}
    return @intCast(rates*8);
}
