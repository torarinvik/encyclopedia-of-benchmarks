from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("length_of_last_word")
fn length_of_last_word(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129:return -1
    if v[0]<0 or v[0]>128 or n!=c_size_t(v[0]+1):return -1
    var i=Int(v[0])
    while i>0 and v[i]==32:i-=1
    var count:Int64=0
    while i>0 and v[i]!=32:
        if v[i]<0 or v[i]>255:return -1
        count+=1;i-=1
    for j in range(1,Int(n)):
        if v[j]<0 or v[j]>255:return -1
    return count
