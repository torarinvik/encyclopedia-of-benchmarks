from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("integer_to_roman")
fn integer_to_roman(value:Int64,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if value<1 or value>3999:return -1
    var result=InlineArray[UInt8,16](fill=0);var n=0
    var thousands=value//1000
    while thousands>0:result[n]=77;n+=1;thousands-=1
    var remainder=value%1000
    for pos in range(3):
        let divisor=Int64(100 if pos==0 else 10 if pos==1 else 1)
        let digit=(value//divisor)%10
        let one=UInt8(67 if pos==0 else 88 if pos==1 else 73)
        let five=UInt8(68 if pos==0 else 76 if pos==1 else 86)
        let ten=UInt8(77 if pos==0 else 67 if pos==1 else 88)
        if digit==9:result[n]=one;n+=1;result[n]=ten;n+=1
        elif digit>=5:
            result[n]=five;n+=1
            for _ in range(Int(digit-5)):result[n]=one;n+=1
        elif digit==4:result[n]=one;n+=1;result[n]=five;n+=1
        else:
            for _ in range(Int(digit)):result[n]=one;n+=1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(n):return -2
    for i in range(n):output[i]=result[i]
    return Int64(n)
