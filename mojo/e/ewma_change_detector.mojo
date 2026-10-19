from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("ewma_change_detector")
fn ewma_change_detector(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>16:return -1
    let count=input[0]
    if count<0 or count>15 or length!=c_size_t(count+1):return -1
    var exponent=0;var numerator:Int64=0;var packed:Int64=0
    for i in range(Int(count)):
        let sample=input[i+1]
        if sample< -8 or sample>8:return -1
        exponent+=1;numerator+=sample*(Int64(1)<<(exponent-1))
        var signal=0
        if 3*numerator*numerator>((Int64(1)<<(2*exponent))-1):
            signal=1 if numerator>0 else 2;exponent=0;numerator=0
        packed=packed*4+signal
    return packed
