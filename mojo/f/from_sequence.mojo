from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("from_sequence")
fn from_sequence(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                 output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>129:return -1
    let n=input[0]
    if n<1 or n>128 or length!=c_size_t(n+1):return -1
    var staged=InlineArray[UInt8,3589](fill=0);var pos=0
    for i in range(Int(n)):
        let value=input[i+1]
        var magnitude:UInt64
        if value<0:magnitude=UInt64(-(value+1))+1
        else:magnitude=UInt64(value)
        var digits=InlineArray[UInt8,20](fill=0);var nd=0
        while magnitude>0:digits[nd]=UInt8(48+magnitude%10);nd+=1;magnitude/=10
        staged[pos]=60;pos+=1
        if value<0:staged[pos]=45;pos+=1
        while nd>0:nd-=1;staged[pos]=digits[nd];pos+=1
        staged[pos]=62;pos+=1
        staged[pos]=32;staged[pos+1]=45;staged[pos+2]=45;staged[pos+3]=45;staged[pos+4]=62;staged[pos+5]=32;pos+=6
    staged[pos]=60;staged[pos+1]=69;staged[pos+2]=78;staged[pos+3]=68;staged[pos+4]=62;pos+=5
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(pos):return -2
    for i in range(pos):output[i]=staged[i]
    return Int64(pos)
