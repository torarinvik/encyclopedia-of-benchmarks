package distributed_coupon_collection_replay

import "core:c"

MAX_N :: 8
MAX_INPUT :: 76

put64 :: proc(output:[^]u8,offset:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{output[offset+b]=u8(bits&255);bits>>=8}}

@(export)
distributed_coupon_collection_replay :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
    if input==nil||length<4||length>MAX_INPUT do return -1
    n64,c64,copies,steps64:=input[0],input[1],input[2],input[3]
    if n64<2||n64>8||c64<1||c64>8||copies<1||copies>n64||steps64<1||steps64>8||length!=c.size_t(4+n64+n64*steps64) do return -1
    n,coupons,steps:=int(n64),int(c64),int(steps64);full:=(u64(1)<<coupons)-1
    bins:[MAX_N]u64
    for b:=0;b<n;b+=1{raw:=input[4+b];if raw<0||(u64(raw)&~full)!=0 do return -1;bins[b]=u64(raw)}
    for coupon:=0;coupon<coupons;coupon+=1{count:=0;for b:=0;b<n;b+=1{if ((bins[b]>>coupon)&1)!=0{count+=1}};if count<int(copies) do return -1}
    tape_at:=4+n
    for i:=0;i<n*steps;i+=1{if input[tape_at+i]!=0&&input[tape_at+i]!=1 do return -1}
    if output==nil||capacity<16 do return -2
    collected:u64=0;singleton_steps:i64=0
    for step:=0;step<steps;step+=1{open_count:=0;opened_bin:=0;for bin:=0;bin<n;bin+=1{if input[tape_at+step*n+bin]==1{open_count+=1;opened_bin=bin}};if open_count==1{singleton_steps+=1;collected|=bins[opened_bin]}}
    staged:[16]u8;put64(&staged[0],0,i64(collected));put64(&staged[0],8,singleton_steps);for b:=0;b<16;b+=1{output[b]=staged[b]}return 16
}
