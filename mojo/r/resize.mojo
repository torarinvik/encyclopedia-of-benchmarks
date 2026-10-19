from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("resize")
fn resize(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>3077:return -1
    let sw=v[0];let sh=v[1];let dw=v[2];let dh=v[3]
    if sw<1 or sw>32 or sh<1 or sh>32 or dw<1 or dw>32 or dh<1 or dh>32 or Int(n)!=4+3*Int(sw)*Int(sh):return -1
    for i in range(4,Int(n)):if v[i]<0 or v[i]>255:return -1
    let needed=3*Int(dw)*Int(dh)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(needed):return -2
    let rx=Float64(sw)/Float64(dw);let ry=Float64(sh)/Float64(dh);var at=0
    for y in range(Int(dh)):
        let sy=Int(ry*Float64(y))
        for x in range(Int(dw)):
            let sx=Int(rx*Float64(x));let base=4+3*(sy*Int(sw)+sx)
            for c in range(3):o[at]=UInt8(v[base+c]);at+=1
    return Int64(at)
