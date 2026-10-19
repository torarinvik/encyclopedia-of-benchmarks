from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("valid_anagram")
fn valid_anagram(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>2050:return -1
    let a=v[0];let b=v[1]
    if a<0 or a>1024 or b<0 or b>1024 or n!=c_size_t(2+a+b):return -1
    var ca=InlineArray[Int,26](fill=0);var cb=InlineArray[Int,26](fill=0)
    for i in range(Int(a)):
        if v[2+i]<97 or v[2+i]>122:return -1
        ca[Int(v[2+i]-97)]+=1
    for i in range(Int(b)):
        if v[2+Int(a)+i]<97 or v[2+Int(a)+i]>122:return -1
        cb[Int(v[2+Int(a)+i]-97)]+=1
    for i in range(26):if ca[i]!=cb[i]:return 0
    return 1
