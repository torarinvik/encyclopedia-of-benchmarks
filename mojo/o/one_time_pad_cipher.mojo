from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("one_time_pad_cipher")
fn one_time_pad_cipher(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>2050:return -1
    let mode=v[0];let count=v[1]
    if (mode!=0 and mode!=1) or count<0 or count>1024 or n!=c_size_t(2+2*count):return -1
    if cap<c_size_t(count) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var staged=InlineArray[UInt8,1024](fill=UInt8(0))
    for i in range(Int(count)):
        let a=v[2+i];let b=v[2+Int(count)+i]
        if a<0 or a>255 or b<0 or b>255:return -1
        staged[i]=UInt8(a^b)
    for i in range(Int(count)):o[i]=staged[i]
    return count
