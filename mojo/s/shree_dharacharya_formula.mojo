from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("shree_dharacharya_formula")
fn shree_dharacharya_formula(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    for i in range(3):if a[i]< -1000000 or a[i]>1000000:return -1
    if a[0]==0:return -1
    let aa=Float64(a[0]);let bb=Float64(a[1]);let cc=Float64(a[2]);let disc=bb*bb-4.0*aa*cc;if disc<0:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    let root=sqrt(disc);let den=2.0*aa;let x=(-bb+root)/den;let y=(-bb-root)/den;let u=bitcast[UInt64](x);let v=bitcast[UInt64](y)
    for j in range(8):o[j]=UInt8((u>>UInt(8*j))&255);o[8+j]=UInt8((v>>UInt(8*j))&255)
    return 16
