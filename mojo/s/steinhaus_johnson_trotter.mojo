from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("steinhaus_johnson_trotter")
fn steinhaus_johnson_trotter(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n==0 or n>6:return -1
    let count=Int(n);var fact=1
    for i in range(2,count+1):fact*=i
    let bytes=fact*count*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var a=InlineArray[Int32,6](fill=0);var inv=InlineArray[Int,6](fill=0);var pos=0
    for i in range(count):a[i]=v[i]
    for _ in range(fact):
        for i in range(count):let bits=bitcast[UInt32](a[i]);for b in range(4):o[pos]=UInt8((bits>>UInt(8*b))&255);pos+=1
        var idx=1
        while idx<count:
            if inv[idx]<idx:
                let swap=if idx%2==0 then 0 else inv[idx];let t=a[swap];a[swap]=a[idx];a[idx]=t;inv[idx]+=1;idx=1
            else:inv[idx]=0;idx+=1
    return Int64(bytes)
