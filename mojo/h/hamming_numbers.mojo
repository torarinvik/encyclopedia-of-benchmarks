from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("hamming_numbers")
fn hamming_numbers(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1 or input[0]<1 or input[0]>32:return -1
    let n=Int(input[0]);let bytes=n*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    var values=InlineArray[UInt64,32](fill=0);values[0]=1
    var i2=0;var i3=0;var i5=0
    for index in range(1,n):
        let c2=values[i2]*2;let c3=values[i3]*3;let c5=values[i5]*5
        var next=min(c2,c3);next=min(next,c5);values[index]=next
        if c2==next:i2+=1
        if c3==next:i3+=1
        if c5==next:i5+=1
    for index in range(n):
        for b in range(8):out[index*8+b]=UInt8((values[index]>>UInt(8*b))&255)
    return Int64(n)
