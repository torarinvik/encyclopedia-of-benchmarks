from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("next_smaller_element")
fn next_smaller_element(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return -1
    let count=a[0]
    if count<0 or count>1024 or n!=c_size_t(count+1):return -1
    var vals=InlineArray[Int64,1024]();var stack=InlineArray[Int64,1024]();var result=InlineArray[Int64,1024]();var top=0
    for i in range(Int(count)):
        let x=a[i+1]
        if x< -2147483648 or x>2147483647:return -1
        vals[i]=x
    for i in range(Int(count)):
        while top>0 and stack[top-1]>=vals[i]:top-=1
        result[i]=stack[top-1] if top>0 else -1
        stack[top]=vals[i];top+=1
    let bytes=Int(count)*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(count)):
        let bits=bitcast[UInt64](result[i])
        for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
