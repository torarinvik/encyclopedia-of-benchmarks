from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List

@export("excess_3_code")
fn excess_3_code(value:Int64,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    var number=UInt64(value) if value>=0 else UInt64(0);var digits=List[Int](capacity=19)
    while True:
        digits.append(Int(number%10));number//=10
        if number==0:break
    let required=2+4*len(digits)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(required):return -2
    output[0]=48;output[1]=98;var pos=2
    for ix in range(len(digits)):
        let nibble=digits[len(digits)-1-ix]+3
        for shift in range(4):output[pos]=UInt8(48+((nibble>>(3-shift))&1));pos+=1
    return Int64(required)
