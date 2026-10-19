from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("wave_string")
fn wave_string(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>513:return -1
    let size=a[0]
    if size<0 or size>512 or n!=c_size_t(size+1):return -1
    var letters=0
    for i in range(Int(size)):
        if a[i+1]<32 or a[i+1]>126:return -1
        if (a[i+1]>=65 and a[i+1]<=90) or (a[i+1]>=97 and a[i+1]<=122):letters+=1
    let required=letters*(Int(size)+2)
    if cap<c_size_t(required) or (required>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var outpos=0
    for changed in range(Int(size)):
        let c=a[changed+1]
        if not ((c>=65 and c<=90) or (c>=97 and c<=122)):continue
        o[outpos]=UInt8(size&255);o[outpos+1]=UInt8((size>>8)&255);outpos+=2
        for j in range(Int(size)):
            var b=UInt8(a[j+1])
            if j==changed and b>=97 and b<=122:b-=32
            o[outpos]=b;outpos+=1
    return Int64(letters)
