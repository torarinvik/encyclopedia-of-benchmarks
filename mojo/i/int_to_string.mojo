from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("int_to_string")
fn int_to_string(packed:Int64,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if packed<0:return -1
    let value=packed//15;let base=packed%15+2
    if value>65535:return -1
    var digits=InlineArray[UInt8,16](fill=0);var n=0;var x=value
    while True:
        let digit=Int(x%base)
        digits[n]=UInt8(48+digit if digit<10 else 87+digit);n+=1;x//=base
        if x==0:break
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(n+1):return -2
    for i in range(n):output[i]=digits[n-1-i]
    output[n]=0
    return Int64(n+1)
