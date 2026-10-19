from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("max_consecutive_ones_iii")
fn max_consecutive_ones_iii(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>1026 or v[0]<1 or v[0]>1024 or n!=c_size_t(v[0]+2):return -2
    let count=Int(v[0]);let k=v[1]
    if k<0 or k>count:return -2
    for i in range(count):if v[i+2]!=0 and v[i+2]!=1:return -2
    var left=0;var zeros=0;var best=0
    for right in range(count):
        if v[right+2]==0:zeros+=1
        while zeros>k:
            if v[left+2]==0:zeros-=1
            left+=1
        if right-left+1>best:best=right-left+1
    return Int64(best)
