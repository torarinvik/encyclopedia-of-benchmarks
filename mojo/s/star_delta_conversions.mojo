from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("star_delta_conversions")
fn star_delta_conversions(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4 or (v[0]!=0 and v[0]!=1):return -1
    for i in range(1,4):if v[i]<1000 or v[i]>100000:return -1
    let x=Float64(v[1]);let y=Float64(v[2]);let z=Float64(v[3]);var out=InlineArray[Float64,3](fill=0.0)
    if v[0]==0:
        let p=x*y+y*z+z*x;out[0]=p/x;out[1]=p/y;out[2]=p/z
    else:
        let s=x+y+z;out[0]=y*z/s;out[1]=z*x/s;out[2]=x*y/s
    var h:UInt64=0xcbf29ce484222325
    for i in range(3):
        let q=Int64(out[i]+0.5);let u=bitcast[UInt64](q)
        for j in range(8):h=(h^((u>>UInt(8*j))&255))*0x100000001b3
    return bitcast[Int64](h)
