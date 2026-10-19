from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("percentage")
fn percentage(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3 or v[0]<1 or v[0]>100000 or v[1]<1 or v[1]>100000 or v[2]<1 or v[2]>4:return -1
    var scale:Int64=1
    for _ in range(Int(v[2])):scale*=10
    let product=v[0]*v[1]*scale
    if product<100:return -1
    return product/100
