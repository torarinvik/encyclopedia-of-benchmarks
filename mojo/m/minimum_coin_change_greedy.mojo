from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mccg_i32(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):out[p+b]=UInt8((u>>(8*b))&255)
@export("minimum_coin_change_greedy")
fn minimum_coin_change_greedy(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>34 or v[0] < -4096 or v[0]>4096 or v[1]<0 or v[1]>32 or Int(n)!=2+Int(v[1]):return -1
    let target=v[0];let count=Int(v[1]);var prev:Int64=0
    for i in range(count):if v[i+2]<1 or v[i+2]>4096 or v[i+2]<=prev:return -1;prev=v[i+2]
    var coins=InlineArray[Int64,4096](fill=0);var used=0;var rem=target
    if rem>0:
        for ii in range(count):
            let i=count-1-ii;let coin=v[i+2];let take=Int(rem/coin)
            for _ in range(take):coins[used]=coin;used+=1
            rem%=coin
    let bytes=4+used*4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    mccg_i32(out,0,Int32(used))
    for i in range(used):mccg_i32(out,4+4*i,Int32(coins[i]))
    return Int64(bytes)
