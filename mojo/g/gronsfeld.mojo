from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("gronsfeld")
fn gronsfeld(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>321:return -1
    var sep=0
    while sep<Int(n) and v[sep]!=0:sep+=1
    if sep==Int(n):return -1
    let textlen=sep;let keylen=Int(n)-sep-1
    if textlen>256 or keylen<1 or keylen>64:return -1
    for i in range(textlen):if v[i]<1 or v[i]>127:return -1
    for i in range(keylen):if v[sep+1+i]<48 or v[sep+1+i]>57:return -1
    if cap<c_size_t(textlen) or (textlen>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var keyidx=0
    for i in range(textlen):
        let x=v[i];var mapped=x
        if x>=65 and x<=90:
            let shift=v[sep+1+keyidx%keylen]-48;mapped=65+(x-65+shift)%26;keyidx+=1
        elif x>=97 and x<=122:
            let shift=v[sep+1+keyidx%keylen]-48;mapped=97+(x-97+shift)%26;keyidx+=1
        out[i]=UInt8(mapped)
    return Int64(textlen)
