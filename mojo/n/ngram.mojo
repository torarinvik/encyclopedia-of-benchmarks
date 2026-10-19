from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("ngram")
fn ngram(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>258:return -1
    let width=a[0];let length=a[1]
    if width<1 or width>16 or length<0 or length>256 or n!=c_size_t(length+2):return -1
    for i in range(Int(length)):
        if a[i+2]<32 or a[i+2]>126:return -1
    var windows=0
    if width<=length:windows=Int(length-width+1)
    let bytes=windows*Int(width)+max(0,windows-1)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var p=0
    for i in range(windows):
        if i>0:o[p]=10;p+=1
        for j in range(Int(width)):o[p]=UInt8(a[i+j+2]);p+=1
    return Int64(bytes)
