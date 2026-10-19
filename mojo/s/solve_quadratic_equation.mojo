from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt

fn sqe_write(output:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):output[offset+b]=UInt8((bits>>UInt(8*b))&255)

@export("solve_quadratic_equation")
fn solve_quadratic_equation(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2:return -1
    if values[0]< -1000000 or values[0]>1000000 or values[1]< -1000000 or values[1]>1000000:return -1
    let p=Float64(values[0]);let q=Float64(values[1]);let radicand=p*p/4.0-q
    if radicand<0:return 0
    let root=sqrt(radicand);let x1= -p/2.0-root;let x2= -p/2.0+root
    if x1==x2:
        if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<8:return -2
        sqe_write(output,0,x1);return 1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<16:return -2
    sqe_write(output,0,x1);sqe_write(output,8,x2);return 2
