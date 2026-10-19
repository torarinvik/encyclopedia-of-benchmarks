from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn rs_next(mut state:UInt64,bits:Int)->UInt32:
    state=(state*UInt64(0x5DEECE66D)+11)&UInt64(0xffffffffffff)
    return UInt32(state>>(48-bits))
fn rs_bounded(mut state:UInt64,bound:UInt32)->UInt32:
    if (bound&(bound-1))==0:return UInt32((UInt64(bound)*UInt64(rs_next(state,31)))>>31)
    while True:
        let bits=rs_next(state,31);let value=bits%bound
        if UInt64(bits)-UInt64(value)+UInt64(bound-1)<=2147483647:return value
fn rs_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("random_scheduling")
fn random_scheduling(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>35 or v[1]<0 or v[1]>32 or n!=c_size_t(2+v[1]):return -1
    let count=Int(v[1]);var tasks=InlineArray[Int64,32](fill=0)
    for i in range(count):if v[i+2]< -2147483648 or v[i+2]>2147483647:return -1;tasks[i]=v[i+2]
    var state=(bitcast[UInt64](v[0])^UInt64(0x5DEECE66D))&UInt64(0xffffffffffff)
    for rem in range(count-1):
        let size=count-rem;let selected=Int(rs_bounded(state,UInt32(size)));let tmp=tasks[size-1];tasks[size-1]=tasks[selected];tasks[selected]=tmp
    let bytes=count*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):rs_put(o,i*8,tasks[i])
    return Int64(bytes)
