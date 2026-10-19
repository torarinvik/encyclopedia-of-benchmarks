from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn damped_put_f64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):output[offset+b]=UInt8((bits>>UInt(8*b))&255)

@export("damped_oscillator")
fn damped_oscillator(input: UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=5:return -1
    if input[0]<1 or input[0]>1024 or input[1]<0 or input[1]>1024 or input[2]<-1024 or input[2]>1024 or input[3]<-1024 or input[3]>1024 or input[4]<1 or input[4]>1024:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<16:return -2
    let omega=Float64(input[0])/1024.0
    let gamma=Float64(input[1])/1024.0
    let x=Float64(input[2])/1024.0
    let v=Float64(input[3])/1024.0
    let dt=Float64(input[4])/1024.0
    let acceleration=-2.0*gamma*v-omega*omega*x
    let next_x=x+dt*v
    let next_v=v+dt*acceleration
    damped_put_f64(output,0,next_x);damped_put_f64(output,8,next_v)
    return 16
