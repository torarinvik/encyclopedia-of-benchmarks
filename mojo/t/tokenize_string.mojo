from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("tokenize_string")
fn tokenize_string(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130 or a[0]<0 or a[0]>128 or n!=c_size_t(a[0]+2):return -1
    let sep=a[1]
    if sep!=44 and sep!=46 and sep!=58:return -1
    var count=0
    for i in range(Int(a[0])):
        let x=a[i+2]
        if x<32 or x>126:return -1
        if x==sep:count+=1
    if count>18:return -1
    let outn=Int(a[0])+2
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(outn):return -2
    o[0]=UInt8(count+1)
    for i in range(Int(a[0])):o[i+1]=UInt8(0 if a[i+2]==sep else a[i+2])
    o[outn-1]=0
    return Int64(outn)
