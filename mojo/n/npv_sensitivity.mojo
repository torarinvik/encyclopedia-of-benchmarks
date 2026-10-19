from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import pow
@export("npv_sensitivity")
fn npv_sensitivity(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>98:return -1
    let count=a[0];let rates=a[1]
    if count<0 or count>64 or rates<0 or rates>32 or n!=c_size_t(2+count+rates):return -1
    for i in range(Int(count)):if a[2+i]< -1000000 or a[2+i]>1000000:return -1
    for i in range(Int(rates)):if a[2+Int(count)+i]<0 or a[2+Int(count)+i]>1000:return -1
    var values=InlineArray[Float64,32]();var p=0
    for r in range(Int(rates)):
        let rate=Float64(a[2+Int(count)+r])/10000.0;var total:Float64=0.0
        for t in range(Int(count)):total+=Float64(a[2+t])/pow(1.0+rate,Float64(t))
        values[r]=total
    let bytes=Int(rates)*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(rates)):
        let bits=bitcast[UInt64](values[i])
        for b in range(8):o[p]=UInt8((bits>>UInt(8*b))&255);p+=1
    return Int64(bytes)
