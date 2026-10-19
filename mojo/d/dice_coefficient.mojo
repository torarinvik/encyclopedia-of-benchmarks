from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
from std.math import floor
@export("dice_coefficient")
fn dice_coefficient(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2:return -1.0e300
    let av=input[0];let bv=input[1]
    if av<0 or av>128 or bv<0 or bv>128 or length!=c_size_t(2+av+bv):return -1.0e300
    let a=Int(av);let b=Int(bv)
    for i in range(a+b):if input[2+i]<32 or input[2+i]>126:return -1.0e300
    var equal=a==b
    for i in range(a):if equal and input[2+i]!=input[2+a+i]:equal=false
    if equal:return 1.0
    if a<2 or b<2:return 0.0
    var present=List[Int](length=95*95,fill=0)
    for i in range(a-1):present[Int(input[2+i]-32)*95+Int(input[2+i+1]-32)]=1
    var common=0
    for i in range(b-1):
        let k=Int(input[2+a+i]-32)*95+Int(input[2+a+i+1]-32)
        if present[k]!=0:common+=1
    let denominator=Float64(a-1+b-1);let score=(2.0*Float64(common))/denominator
    return floor(score*100.0)/100.0
