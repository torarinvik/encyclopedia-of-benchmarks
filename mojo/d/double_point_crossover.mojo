from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn crossover_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>UInt(b*8))&255)
@export("double_point_crossover")
fn double_point_crossover(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<7 or length>131:return -1
    let nv=input[0];let j1=input[1];let j2=input[2]
    if nv<2 or nv>64 or length!=c_size_t(3+2*nv) or j1<1 or j1>=j2 or j2>nv:return -1
    let n=Int(nv)
    for i in range(2*n):if input[3+i]< -2147483648 or input[3+i]>2147483647:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(16*n):return -2
    for i in range(n):
        let c1=input[3+i] if i<Int(j1) or i>=Int(j2) else input[3+n+i]
        let c2=input[3+n+i] if i<Int(j1) or i>=Int(j2) else input[3+i]
        crossover_put(out,i*8,c1);crossover_put(out,(n+i)*8,c2)
    return Int64(16*n)
