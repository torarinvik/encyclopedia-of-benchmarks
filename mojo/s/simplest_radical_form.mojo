from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("simplest_radical_form")
fn simplest_radical_form(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or a[0]<0 or a[0]>100000000:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    let original=a[0];var c:Int64=1;var r:Int64=1
    if original==0:r=0
    else:
        var rem=original;var f:Int64=2
        while f*f<=original:
            var count=0;while rem%f==0:rem/=f;count+=1
            for _ in range(count/2):c*=f
            if count%2==1:r*=f
            f+=1
        r*=rem
    let x=bitcast[UInt64](c);let y=bitcast[UInt64](r)
    for i in range(8):o[i]=UInt8((x>>UInt(8*i))&255);o[8+i]=UInt8((y>>UInt(8*i))&255)
    return 16
