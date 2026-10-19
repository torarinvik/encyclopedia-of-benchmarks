from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("shorten_vector")
fn shorten_vector(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n<2 or n>66 or a==UnsafePointer[Int64,ImmutAnyOrigin]():return -1
    let count=a[0];let by=a[1];if count<0 or count>64 or by<0 or by>count or n!=c_size_t(count+2):return -1
    for i in range(Int(count)):if a[i+2]< -1000000 or a[i+2]>1000000:return -1
    var keep=InlineArray[Bool,64]();let start=Int(count-by)
    for i in range(Int(count)):
        var remove=False
        for j in range(start,Int(count)):if a[i+2]==a[j+2]:remove=True
        keep[i]=not remove
    var size=0;for i in range(Int(count)):if keep[i]:size+=1
    let bytes=size*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var p=0
    for i in range(Int(count)):
        if keep[i]:let z=bitcast[UInt64](a[i+2]);for b in range(8):o[p*8+b]=UInt8((z>>UInt(8*b))&255);p+=1
    return Int64(bytes)
