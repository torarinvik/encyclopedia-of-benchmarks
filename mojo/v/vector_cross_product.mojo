from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("vector_cross_product")
fn vector_cross_product(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=6:return -1
    for i in range(6):
        if v[i]<-1000000 or v[i]>1000000:return -1
    let x=v[1]*v[5]-v[2]*v[4];let y=-(v[0]*v[5]-v[2]*v[3]);let z=v[0]*v[4]-v[1]*v[3]
    let mag=sqrt(Float64(x)*Float64(x)+Float64(y)*Float64(y)+Float64(z)*Float64(z))
    let micro=Int64(mag*1000000.0+0.5)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<32:return -2
    let vals=InlineArray[Int64,4](x,y,z,micro)
    for j in range(4):
        let u=UInt64(vals[j])
        for b in range(8):o[j*8+b]=UInt8((u>>(b*8))&255)
    return 32
