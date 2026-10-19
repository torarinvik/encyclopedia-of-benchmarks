from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("string_left_rotation")
fn string_left_rotation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>259:return -1
    let lv=v[0];let rot=v[1]
    if lv<0 or lv>256 or rot<0 or rot>lv or n!=c_size_t(lv+2):return -1
    let count=Int(lv);var units=InlineArray[UInt16,256](fill=0)
    for i in range(count):if v[2+i]<0 or v[2+i]>65535:return -1;units[i]=UInt16(v[2+i])
    let bytes=count*2
    if bytes==0:return 0
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):
        var source=Int(rot)+i
        if source>=count:source-=count
        let u=units[source];o[2*i]=UInt8(u&255);o[2*i+1]=UInt8((u>>8)&255)
    return Int64(bytes)
