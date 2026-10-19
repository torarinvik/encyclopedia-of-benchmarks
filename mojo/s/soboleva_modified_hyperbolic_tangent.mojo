from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import exp, isfinite

@export("soboleva_modified_hyperbolic_tangent")
fn soboleva_modified_hyperbolic_tangent(input:UnsafePointer[Float64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[Float64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Float64,ImmutAnyOrigin]() or length<6 or length>38:return -1
    for i in range(Int(length)):if !isfinite(input[i]):return -1
    let count_value=input[0]
    if count_value<1 or count_value>32 or count_value!=Float64(Int(count_value)) or length!=c_size_t(5+Int(count_value)):return -1
    let count=Int(count_value);let a=input[1];let b=input[2];let c=input[3];let d=input[4]
    if a< -2 or a>2 or b< -2 or b>2 or c< -2 or c>2 or d< -2 or d>2:return -1
    for i in range(count):if input[5+i]< -20 or input[5+i]>20:return -1
    if output==UnsafePointer[Float64,MutAnyOrigin]() or capacity<c_size_t(count):return -2
    for i in range(count):
        let x=input[5+i];let ax=a*x;let neg_b_x=(-b)*x;let cx=c*x;let neg_d_x=(-d)*x
        let numerator=exp(ax)-exp(neg_b_x);let denominator=exp(cx)+exp(neg_d_x)
        output[i]=numerator/denominator
    return Int64(count)
