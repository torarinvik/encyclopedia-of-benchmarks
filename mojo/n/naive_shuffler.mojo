from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("naive_shuffler")
fn naive_shuffler(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>258 or a[0]<0 or a[0]>2147483645 or a[1]<0 or a[1]>256 or n!=c_size_t(2+a[1]):return -1
    let count=Int(a[1]);var vals=InlineArray[Int64,256]()
    for i in range(count):if a[2+i]<0 or a[2+i]>255:return -1;vals[i]=a[2+i]
    var state=a[0]+1
    if count>0:
        for i in range(count):
            let period:Int64=2147483646;let bound=Int64(count);let limit=period-period%bound
            var sample:Int64=0
            while True:
                state=(state*48271)%2147483647
                sample=state-1
                if sample<limit:break
            let j=Int(sample%bound);let t=vals[i];vals[i]=vals[j];vals[j]=t
    if cap<c_size_t(count) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(count):o[i]=UInt8(vals[i])
    return count
