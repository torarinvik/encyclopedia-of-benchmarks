from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("mirror_of_matrix")
fn mirror_of_matrix(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>259 or v[0]<1 or v[0]>16 or v[1]<1 or v[1]>16 or Int(n)!=2+Int(v[0]*v[1]):return -1
    let rows=Int(v[0]);let cols=Int(v[1])
    for i in range(rows*cols):if v[2+i] < -2147483648 or v[2+i]>2147483647:return -1
    let bytes=rows*cols*4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for r in range(rows):
        for c in range(cols):
            let bits=UInt32(Int32(v[2+r*cols+(cols-1-c)]));let p=(r*cols+c)*4
            for b in range(4):out[p+b]=UInt8((bits>>(8*b))&255)
    return Int64(bytes)
