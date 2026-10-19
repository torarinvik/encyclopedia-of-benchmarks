from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("quadratic_roots")
fn quadratic_roots(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    if a[0]==0 or a[0]< -1000000 or a[0]>1000000 or a[1]< -1000000 or a[1]>1000000 or a[2]< -1000000 or a[2]>1000000:return -1
    let disc=a[1]*a[1]-4*a[0]*a[2]
    if disc<0:return 0
    let count=1 if disc==0 else 2
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -2
    let den=2.0*Float64(a[0]);let root=sqrt(Float64(disc));let x0=(-Float64(a[1])+root)/den;o[0]=0
    let bits0=bitcast[UInt64](x0)
    for b in range(8):o[b]=UInt8((bits0>>UInt(8*b))&255)
    if count==2:
        let x1=(-Float64(a[1])-root)/den;let bits1=bitcast[UInt64](x1)
        for b in range(8):o[8+b]=UInt8((bits1>>UInt(8*b))&255)
    return count
