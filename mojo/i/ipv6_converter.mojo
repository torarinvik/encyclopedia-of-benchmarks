from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("ipv6_converter")
fn ipv6_converter(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                  output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2:return -1
    let op=input[0];let n=input[1]
    if (op==0 and n!=4) or (op==1 and n!=16) or (op!=0 and op!=1) or length!=c_size_t(2+n):return -1
    for i in range(Int(n)):
        if input[2+i]<0 or input[2+i]>255:return -1
    if op==1:
        for i in range(10):
            if input[2+i]!=0:return -1
        if input[12]!=255 or input[13]!=255:return -1
    let needed=16 if op==0 else 4
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(needed):return -2
    if op==0:
        for i in range(10):output[i]=0
        output[10]=255;output[11]=255
        for i in range(4):output[12+i]=UInt8(input[2+i])
    else:
        for i in range(4):output[i]=UInt8(input[14+i])
    return Int64(needed)
