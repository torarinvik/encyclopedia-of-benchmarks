from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("euler_problem_6")
fn euler_problem_6(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1 or input[0]<1 or input[0]>100:return -1
    let n=input[0];let sum=n*(n+1)/2;let squares=n*(n+1)*(2*n+1)/6
    return sum*sum-squares
