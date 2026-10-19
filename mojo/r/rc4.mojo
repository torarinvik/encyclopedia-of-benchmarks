from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("rc4")
fn rc4(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>515 or v[0]<1 or v[0]>256 or v[1]<0 or v[1]>256:return -1
    let kl=Int(v[0]);let pl=Int(v[1]);if n!=c_size_t(2+kl+pl):return -1
    for i in range(kl+pl):if v[2+i]<0 or v[2+i]>255:return -1
    if pl==0:return 0
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(pl):return -2
    var s=InlineArray[Int64,256](fill=0)
    for i in range(256):s[i]=Int64(i)
    var j=0
    for i in range(256):
        j=(j+Int(s[i])+Int(v[2+(i%kl)]))&255;let t=s[i];s[i]=s[j];s[j]=t
    var i=0;j=0
    for pos in range(pl):
        i=(i+1)&255;j=(j+Int(s[i]))&255;let t=s[i];s[i]=s[j];s[j]=t
        let stream=(Int(s[i])+Int(s[j]))&255;o[pos]=UInt8(Int(v[2+kl+pos])^Int(s[stream]))
    return Int64(pl)
