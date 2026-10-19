from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn euler_julia_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("euler_method_julia")
fn euler_method_julia(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1
    let initial=input[0];let count=input[1];let power=input[2]
    if initial< -8 or initial>8 or count<1 or count>16 or power<1 or power>4:return -1
    let n=Int(count);let bytes=n*16
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    let h=1.0/Float64(Int64(1)<<Int(power));var states=List[Float64](capacity=n);var times=List[Float64](capacity=n)
    states.append(Float64(initial));times.append(0.0)
    for i in range(1,n):
        let t=Float64(i-1)*h;let next=states[i-1]+h*(states[i-1]+t)
        states.append(next);times.append(Float64(i)*h)
    for i in range(n):euler_julia_put(out,8*i,states[i])
    for i in range(n):euler_julia_put(out,8*(n+i),times[i])
    return Int64(bytes)
