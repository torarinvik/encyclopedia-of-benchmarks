from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
fn radix_key(x:Int64)->UInt64:
    let sign=UInt64(1)<<63
    if x<0:return sign-1-UInt64(-(x+1))
    return sign+UInt64(x)
@export("radix_sort")
fn radix_sort(v:UnsafePointer[Int64,MutAnyOrigin],scratch:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if n<2 or v==UnsafePointer[Int64,MutAnyOrigin]() or scratch==UnsafePointer[Int64,MutAnyOrigin]():return
    for pass in range(8):
        for b in range(256):scratch[b]=0
        for i in range(Int(n)):
            let bucket=Int((radix_key(v[i])>>(pass*8))&255);scratch[bucket]+=1
        var next=0
        for b in range(256):let count=scratch[b];scratch[b]=next;next+=count
        for i in range(Int(n)):
            let bucket=Int((radix_key(v[i])>>(pass*8))&255);let dest=Int(scratch[bucket]);scratch[bucket]+=1;scratch[256+dest]=v[i]
        for i in range(Int(n)):v[i]=scratch[256+i]
