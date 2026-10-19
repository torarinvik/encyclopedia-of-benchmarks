from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("segmented_sieve")
fn segmented_sieve(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or a[0]<2 or a[0]>10000:return -1
    let limit=Int(a[0]);var root=1;while (root+1)*(root+1)<=limit:root+=1
    var mark=InlineArray[Bool,10001]();for i in range(2,limit+1):mark[i]=True
    for p in range(2,root+1):if mark[p]:for j in range(p*p,limit+1,p):mark[j]=False
    var count=0;for i in range(2,limit+1):if mark[i]:count+=1
    let bytes=count*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var pos=0
    for i in range(2,limit+1):
        if mark[i]:
            let z=bitcast[UInt64](Int64(i));for b in range(8):o[pos+b]=UInt8((z>>UInt(8*b))&255);pos+=8
    return Int64(bytes)
