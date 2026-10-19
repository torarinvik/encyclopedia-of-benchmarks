from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("iso10126_d2_padding")
fn iso10126_d2_padding(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                       output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>67:return -1
    let mode=input[0]
    if mode==0:
        if length<3:return -1
        let off=input[1];let n=input[2]
        if n<1 or n>64 or off<0 or off>=n or length!=c_size_t(3+off+(n-off-1)):return -1
        for i in range(3,Int(length)):
            if input[i]<0 or input[i]>255:return -1
        for i in range(3+Int(off),Int(length)):
            if input[i]>=255:return -1
        let bytes=Int(n)+1
        if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
        let count=UInt8(n-off);output[0]=count;var at=1
        for i in range(Int(off)):output[at]=UInt8(input[3+i]);at+=1
        for i in range(3+Int(off),Int(length)):output[at]=UInt8(input[i]);at+=1
        output[at]=count
        return Int64(bytes)
    if (mode!=1 and mode!=2) or length<3:return -1
    let n=input[1]
    if n<1 or n>64 or length!=c_size_t(2+n):return -1
    for i in range(2,Int(length)):
        if input[i]<0 or input[i]>255:return -1
    let count=input[Int(length)-1]
    if count<1 or count>n:return -1
    let bytes=Int(n-count) if mode==1 else 1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    if mode==1:
        for i in range(bytes):output[i]=UInt8(input[2+i])
    else:output[0]=UInt8(count)
    return Int64(bytes)
