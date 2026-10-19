from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import floor, pow
@export("geometric_mean")
fn geometric_mean(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>6:return -1.0e300
    var product:Int64=1
    for i in range(Int(n)):
        if v[i]< -100 or v[i]>100:return -1.0e300
        product*=v[i]
    if product<0 and n%2==0:return -1.0e300
    var root=pow(Float64(if product<0 then -product else product),1.0/Float64(n));let rounded=floor(root+0.5);var rp:Int64=1
    for i in range(Int(n)):rp*=Int64(rounded)
    if (product>=0 and rp==product) or (product<0 and n%2==1 and -rp==product):root=rounded
    if product<0:root= -root
    return root
