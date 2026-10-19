from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import exp, floor
fn selu_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:Int64):
    let z=bitcast[UInt64](v)
    for b in range(8):o[p+b]=UInt8((z>>UInt(8*b))&255)
@export("scaled_exponential_linear_unit")
fn scaled_exponential_linear_unit(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>259:return -1
    let count=a[0]
    if count<0 or count>256 or n!=c_size_t(count+3) or a[1]< -10000000 or a[1]>10000000 or a[2]< -10000000 or a[2]>10000000:return -1
    for i in range(Int(count)):if a[i+3]< -20000000 or a[i+3]>20000000:return -1
    let bytes=Int(count)*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    let alpha=Float64(a[1])/1e6;let lambda=Float64(a[2])/1e6
    var res=InlineArray[Int64,256]()
    for i in range(Int(count)):
        let x=Float64(a[i+3])/1e6;let y=lambda*(x if x>0 else alpha*(exp(x)-1.0));res[i]=Int64(floor(y*1e9+0.5))
    for i in range(Int(count)):selu_put(o,i*8,res[i])
    return Int64(bytes)
