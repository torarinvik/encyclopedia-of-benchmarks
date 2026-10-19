from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("powerset")
fn powerset(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>7 or v[0]<0 or v[0]>6 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0]);let subsets=1<<count;let need=2+subsets+8*count*(subsets//2)
    for i in range(count):if v[i+1]<-1000000 or v[i+1]>1000000:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(need):return -2
    out[0]=UInt8(subsets&255);out[1]=UInt8((subsets>>8)&255);var pos=2
    for mask in range(subsets):
        var size=0
        for i in range(count):if ((mask>>(count-1-i))&1)!=0:size+=1
        out[pos]=UInt8(size);pos+=1
        for i in range(count):
            if ((mask>>(count-1-i))&1)!=0:
                let bits=UInt64(v[i+1])
                for b in range(8):out[pos]=UInt8((bits>>(8*b))&255);pos+=1
    return Int64(need)
