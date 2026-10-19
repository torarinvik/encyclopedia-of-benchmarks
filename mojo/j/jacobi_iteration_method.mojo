from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray
fn ji_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Float64):
    let b=bitcast[UInt64](x)
    for i in range(8):o[p+i]=UInt8((b>>UInt64(8*i))&255)
@export("jacobi_iteration_method")
fn jacobi_iteration_method(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>26:return -1
    let d=Int(v[0]);let it=Int(v[1]);if d<2 or d>4 or it<1 or it>8 or n!=c_size_t(2+d*d+2*d):return -1
    let rhs=2+d*d;let ini=rhs+d;var a=InlineArray[Float64,16](fill=0.0);var b=InlineArray[Float64,4](fill=0.0);var x=InlineArray[Float64,4](fill=0.0);var y=InlineArray[Float64,4](fill=0.0)
    for i in range(d):
        var off=0.0
        for j in range(d):
            let z=v[2+i*d+j];if z<0 or z>4000:return -1;a[i*4+j]=Float64(z)/1000.0
            if i!=j:off+=a[i*4+j]
        if a[i*4+i]<=off or v[rhs+i]< -2000 or v[rhs+i]>2000 or v[ini+i]< -2000 or v[ini+i]>2000:return -1
        b[i]=Float64(v[rhs+i])/1000.0;x[i]=Float64(v[ini+i])/1000.0
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(d*8):return -2
    for k in range(it):
        for i in range(d):
            var s=0.0
            for j in range(d):if i!=j:s+= -a[i*4+j]*x[j]
            y[i]=(s+b[i])/a[i*4+i]
        for i in range(d):x[i]=y[i]
    for i in range(d):ji_put(o,i*8,x[i])
    return Int64(d*8)
