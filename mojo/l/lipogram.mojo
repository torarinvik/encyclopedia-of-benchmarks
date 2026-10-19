from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("lipogram")
fn lipogram(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1026 or v[0]<0 or v[0]>1024 or n!=c_size_t(v[0]+2):return -1
    let want=v[Int(n)-1]
    if want<0 or want>67108863:return -1
    var seen=UInt32(0)
    for i in range(Int(v[0])):
        var c=v[i+1]
        if c>=65 and c<=90:c+=32
        if c>=97 and c<=122:seen|=UInt32(1)<<Int(c-97)
        elif c!=9 and c!=10 and c!=11 and c!=12 and c!=13 and c!=32:return -1
    let alphabet=UInt32(67108863)
    return Int64((alphabet&(~seen))==UInt32(want))
