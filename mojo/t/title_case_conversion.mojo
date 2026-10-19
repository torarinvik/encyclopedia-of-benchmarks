from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("title_case_conversion")
fn title_case_conversion(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -1
    let size=a[0]
    if size<0 or size>256 or n!=c_size_t(size+1):return -1
    for i in range(Int(size)):
        let x=a[i+1]
        if not ((x>=65 and x<=90) or (x>=97 and x<=122) or x==32):return -1
        if x==32 and (i==0 or i+1==Int(size) or a[i]==32):return -1
    if cap<c_size_t(size+1) or o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    var beginning=True
    for i in range(Int(size)):
        var x=a[i+1]
        if x==32:beginning=True
        elif beginning:
            if x>=97 and x<=122:x-=32
            beginning=False
        elif x>=65 and x<=90:x+=32
        o[i]=UInt8(x)
    o[Int(size)]=0
    return size
