from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("nesterov_accelerated_sgd")
fn nesterov_accelerated_sgd(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>76:return -1
    let width=a[0];let steps=a[1];let lm=a[2];let mm=a[3]
    if width<1 or width>8 or steps<1 or steps>8 or lm<0 or lm>1000 or mm<0 or mm>1000 or n!=c_size_t(4+width*(steps+1)):return -1
    for i in range(4,Int(n)):if a[i]< -10000 or a[i]>10000:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(width*8):return -2
    let w=Int(width);var params=InlineArray[Float64,8]();var vel=InlineArray[Float64,8]()
    for i in range(w):params[i]=Float64(a[4+i])/1000.0
    let lr=Float64(lm)/1000.0;let momentum=Float64(mm)/1000.0
    for t in range(Int(steps)):
        for i in range(w):let prev=vel[i];let grad=Float64(a[4+w+t*w+i])/1000.0;vel[i]=momentum*vel[i]-lr*grad;params[i]=params[i]-momentum*prev+(1.0+momentum)*vel[i]
    for i in range(w):let bits=bitcast[UInt64](params[i]);for b in range(8):o[8*i+b]=UInt8((bits>>(8*b))&255)
    return w*8
