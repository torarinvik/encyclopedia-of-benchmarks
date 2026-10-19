from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("integral_approximation")
fn integral_approximation(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=4:return -1.0e300
    let id=input[0];let lo0=input[1];let hi0=input[2];let delta=input[3]
    if id<0 or id>1 or lo0<0 or hi0>32 or lo0>=hi0 or delta<1 or delta>8:return -1.0e300
    let lo=Float64(lo0)/8.0;let hi=Float64(hi0)/8.0;let step=Float64(delta)/8.0
    let count=Int((hi-lo)/step)
    if count>32:return -1.0e300
    var total=0.0
    for i in range(count):
        let begin=lo+Float64(i)*step;let end=lo+Float64(i+1)*step
        let f0=begin*begin if id==0 else begin*begin*begin-begin*begin+378.0
        let f1=end*end if id==0 else end*end*end-end*end+378.0
        total+=step*(f0+f1)/2.0
    return total
