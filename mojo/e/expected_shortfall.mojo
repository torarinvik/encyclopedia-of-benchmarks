from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("expected_shortfall")
fn expected_shortfall(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>67:return -1.0e300
    let confidence=input[0];let count=input[1]
    if confidence<1 or confidence>=1000000 or count<1 or count>64 or length!=c_size_t(count+2):return -1.0e300
    var sorted=List[Float64](capacity=64)
    for i in range(Int(count)):
        let v=input[2+i]
        if v< -1000000000 or v>1000000000:return -1.0e300
        let value=Float64(v)/1000000.0;var pos=len(sorted);sorted.append(value)
        while pos>0 and sorted[pos-1]>value:sorted[pos]=sorted[pos-1];pos-=1
        sorted[pos]=value
    let q=1.0-Float64(confidence)/1000000.0;let position=Float64(count-1)*q;let lower=Int(position);let fraction=position-Float64(lower)
    let threshold=sorted[lower] if lower==Int(count-1) else sorted[lower]*(1.0-fraction)+sorted[lower+1]*fraction
    var sum:Float64=0.0;var tail=0
    for i in range(Int(count)):
        if sorted[i]<=threshold:sum+=sorted[i];tail+=1
    return -sum/Float64(tail)
