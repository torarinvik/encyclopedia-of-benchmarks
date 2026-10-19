from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minimum_coin_change_combinations")
fn minimum_coin_change_combinations(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>34 or v[0] < -64 or v[0]>64 or v[1]<0 or v[1]>32 or Int(n)!=2+Int(v[1]):return -1
    let target=Int(v[0]);let coins=Int(v[1]);var prev:Int64=0
    for i in range(coins):if v[i+2]<1 or v[i+2]>64 or v[i+2]<=prev:return -1;prev=v[i+2]
    if target<0:return 0
    var ways=InlineArray[Int64,65](fill=0);ways[0]=1
    for i in range(coins):
        let c=Int(v[i+2])
        for amount in range(c,target+1):ways[amount]+=ways[amount-c]
    return ways[target]
