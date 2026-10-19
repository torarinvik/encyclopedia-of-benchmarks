from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("uniform_crossover")
fn uniform_crossover(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>193:return -1
    let count=v[0]
    if count<1 or count>64 or n!=c_size_t(1+3*count):return -1
    for i in range(Int(count)):
        if v[1+i]!=0 and v[1+i]!=1:return -1
    for i in range(Int(2*count)):
        let gene=v[1+Int(count)+i]
        if gene < -2147483648 or gene > 2147483647:return -1
    let required=Int(count)*16
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(required):return -2
    for i in range(Int(count)):
        let a=v[1+i];let x=v[1+Int(count)+i];let y=v[1+2*Int(count)+i]
        let first=x if a==1 else y;let second=y if a==1 else x
        for b in range(8):o[i*8+b]=UInt8((first>>(b*8))&255);o[(Int(count)+i)*8+b]=UInt8((second>>(b*8))&255)
    return Int64(required)
