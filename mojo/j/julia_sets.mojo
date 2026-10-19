from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray
fn jl_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Float32):
    let b=bitcast[UInt32](x)
    for i in range(4):o[p+i]=UInt8((b>>UInt32(8*i))&255)
@export("julia_sets")
fn julia_sets(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>68:return -1
    let it=v[0];let crv=v[1];let civ=v[2];let count=Int(v[3])
    if it<0 or it>8 or count<0 or count>32 or crv< -128 or crv>128 or civ< -128 or civ>128 or n!=c_size_t(4+2*count):return -1
    for i in range(2*count):if v[4+i]< -128 or v[4+i]>128:return -1
    let bytes=count*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    let cr=Float32(crv)/16.0;let ci=Float32(civ)/16.0;var stage=InlineArray[Float32,64](fill=0.0)
    for p in range(count):
        var re=Float32(v[4+2*p])/16.0;var im=Float32(v[5+2*p])/16.0
        for k in range(Int(it)):
            let rs=re*re;let isq=im*im;let ri=re*im;let ir=im*re
            let nr=(rs-isq)+cr;let ni=(ri+ir)+ci
            re=nr;im=ni
        stage[2*p]=re;stage[2*p+1]=im
    for i in range(2*count):jl_put(o,i*4,stage[i])
    return Int64(bytes)
