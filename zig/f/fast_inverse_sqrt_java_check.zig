const std=@import("std");
pub export fn fast_inverse_sqrt_java_check(input:[*c]const i64,length:usize)i64{
    if(input==null or length!=2)return -1;
    if(input[0]==0){
        if(input[1]<0x00800000 or input[1]>0x7f7fffff)return -1;
        const bits:u32=@intCast(input[1]);const number:f32=@bitCast(bits);const xhalf:f32=0.5*number;
        const seed:u32=0x5f3759df-(bits>>1);var x:f32=@bitCast(seed);x=x*(1.5-xhalf*x*x);
        const expected:f32=1.0/@as(f32,@floatCast(@sqrt(@as(f64,number))));return if(x==expected)1 else 0;
    }
    if(input[0]==1){
        if(input[1]<0x0010000000000000 or input[1]>0x7fefffffffffffff)return -1;
        const bits:u64=@intCast(input[1]);const number:f64=@bitCast(bits);const xhalf:f64=0.5*number;
        const seed:u64=0x5fe6ec85e7de30da-(bits>>1);var x:f64=@bitCast(seed);
        for(0..4)|_|{x=x*(1.5-xhalf*x*x);}x*=number;return if(x==1.0/@sqrt(number))1 else 0;
    }
    return -1;
}
