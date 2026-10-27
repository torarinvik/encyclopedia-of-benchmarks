const std=@import("std");
const max_n:usize=8;const max_input:usize=76;

fn put64(output:[*]u8,offset:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|output[offset+b]=@truncate(bits>>@intCast(8*b));}

export fn distributed_coupon_collection_replay(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null or length<4 or length>max_input)return -1;
    const input=input_opt.?;const n64=input[0];const c64=input[1];const copies=input[2];const steps64=input[3];
    if(n64<2 or n64>8 or c64<1 or c64>8 or copies<1 or copies>n64 or steps64<1 or steps64>8 or length!=4+@as(usize,@intCast(n64))+@as(usize,@intCast(n64*steps64)))return -1;
    const n:usize=@intCast(n64);const coupons:usize=@intCast(c64);const steps:usize=@intCast(steps64);const full=(@as(u64,1)<<@intCast(coupons))-1;
    var bins:[max_n]u64=@splat(0);
    for(0..n)|b|{const raw=input[4+b];if(raw<0 or (@as(u64,@intCast(raw))&~full)!=0)return -1;bins[b]=@intCast(raw);}
    for(0..coupons)|coupon|{var count:usize=0;for(0..n)|b|{if((bins[b]>>@intCast(coupon))&1!=0)count+=1;}if(count<@as(usize,@intCast(copies)))return -1;}
    const tape_at=4+n;for(0..n*steps)|i|{if(input[tape_at+i]!=0 and input[tape_at+i]!=1)return -1;}
    if(output_opt==null or capacity<16)return -2;
    var collected:u64=0;var singleton_steps:i64=0;
    for(0..steps)|step|{var opened_count:usize=0;var opened_bin:usize=0;for(0..n)|bin|{if(input[tape_at+step*n+bin]==1){opened_count+=1;opened_bin=bin;}}if(opened_count==1){singleton_steps+=1;collected|=bins[opened_bin];}}
    const output=output_opt.?;var staged:[16]u8=@splat(0);put64(&staged,0,@bitCast(collected));put64(&staged,8,singleton_steps);for(0..16)|b|output[b]=staged[b];return 16;
}
