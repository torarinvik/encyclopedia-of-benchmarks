from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List

fn decimal_put(output:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):output[offset+b]=UInt8((bits>>UInt(8*b))&255)

@export("decimal_expansion")
fn decimal_expansion(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1
    let numerator=values[0];let denominator=values[1];let base=values[2]
    if numerator<0 or denominator<1 or denominator>256 or numerator>denominator or base<2 or base>10:return -1
    var digits=List[UInt8](capacity=255);var first=List[Int](length=256,fill=-1)
    var cycle:Int64=-1;var remainder=Int(numerator)
    while remainder!=0 and numerator!=denominator:
        if first[remainder]>=0:
            cycle=Int64(first[remainder]);break
        first[remainder]=len(digits)
        let scaled=remainder*Int(base)
        digits.append(UInt8(scaled/Int(denominator)))
        remainder=scaled%Int(denominator)
    let required=24+len(digits)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(required):return -2
    var integer_part:Int64=0
    if numerator==denominator:integer_part=1
    decimal_put(output,0,integer_part);decimal_put(output,8,Int64(len(digits)));decimal_put(output,16,cycle)
    for i in range(len(digits)):output[24+i]=digits[i]
    return Int64(required)
