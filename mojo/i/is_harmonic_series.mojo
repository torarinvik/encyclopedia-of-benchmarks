from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("is_harmonic_series")
fn is_harmonic_series(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>33:return -1.0e300
    let n=input[0]
    if n<1 or n>32 or length!=c_size_t(n+1):return -1.0e300
    var recip=InlineArray[Float64,32](fill=0.0)
    for i in range(Int(n)):
        let value=bitcast[Float64](input[i+1])
        if value==0.0:return -1.0e300
        recip[i]=1.0/value
    if n==1:return 1.0
    let d=recip[1]-recip[0]
    for i in range(2,Int(n)):
        if recip[i]-recip[i-1]!=d:return 0.0
    return 1.0
