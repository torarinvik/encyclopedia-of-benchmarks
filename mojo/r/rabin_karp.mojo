from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("rabin_karp")
fn rabin_karp(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>512:return -1
    let tn=v[0];let pn=v[1]
    if tn<0 or tn>255 or pn<0 or pn>255 or n!=c_size_t(2+tn+pn):return -1
    for i in range(Int(tn+pn)):if v[2+i]<0 or v[2+i]>127:return -1
    if pn==0:return 1
    if pn>tn:return 0
    var ph:Int64=0;var rh:Int64=0;var power:Int64=1
    for i in range(Int(pn)):
        ph=(ph*256+v[2+Int(tn)+i])%1000003;rh=(rh*256+v[2+i])%1000003
        if i+1<Int(pn):power=(power*256)%1000003
    for start in range(Int(tn-pn+1)):
        if rh==ph:
            var off=0
            while off<Int(pn) and v[2+start+off]==v[2+Int(tn)+off]:off+=1
            if off==Int(pn):return 1
        if start<Int(tn-pn):
            var r=(rh-(v[2+start]*power)%1000003)%1000003
            if r<0:r+=1000003
            rh=(r*256+v[2+start+Int(pn)])%1000003
    return 0
