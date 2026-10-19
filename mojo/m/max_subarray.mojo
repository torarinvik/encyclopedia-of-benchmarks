from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

fn msa_range(v:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,end:Int)->Int64:
    if end-start==1:return v[start]
    let middle=start+(end-start)/2
    let left=msa_range(v,start,middle);let right=msa_range(v,middle,end)
    var running=v[middle-1];var suffix=running
    for rev in range(middle-1-start):
        let i=middle-2-rev;running+=v[i];if running>suffix:suffix=running
    running=v[middle];var prefix=running
    for i in range(middle+1,end):running+=v[i];if running>prefix:prefix=running
    let crossing=suffix+prefix;let best=left if left>right else right
    return crossing if crossing>best else best

@export("max_subarray")
fn max_subarray(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>1024:return -1
    for i in range(Int(n)):if v[i]< -2147483648 or v[i]>2147483647:return -1
    return msa_range(v,0,Int(n))
