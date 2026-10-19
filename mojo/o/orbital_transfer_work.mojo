from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn otw_store(o:UnsafePointer[UInt8,MutAnyOrigin],x:Float64):
    let b=bitcast[UInt64](x)
    for j in range(8):o[j]=UInt8((b>>(8*j))&255)
@export("orbital_transfer_work")
fn orbital_transfer_work(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1
    if v[0]<-1000000000 or v[0]>1000000000 or v[1]<-1000000 or v[1]>1000000 or v[2]<1 or v[2]>1000000000 or v[3]<1 or v[3]>1000000000:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    let work=(6.67430e-11*Float64(v[0])*Float64(v[1])/2.0)*(1.0/Float64(v[2])-1.0/Float64(v[3]))
    otw_store(o,work);return 8
