from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import exp, isfinite
fn nn_sigmoid(x:Float64)->Float64:return 1.0/(1.0+exp(-x))
@export("neural_network")
fn neural_network(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<7 or n>24:return -1
    let ni=a[0];let nh=a[1];let no=a[2]
    if ni<1 or ni>3 or nh<1 or nh>3 or no<1 or no>3 or n!=c_size_t(3+ni+ni*nh+nh*no):return -1
    for i in range(3,Int(n)):if a[i]< -1000 or a[i]>1000:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(no*8):return -2
    let w1=3+Int(ni);let w2=w1+Int(ni*nh);var h=InlineArray[Float64,3]();var output=InlineArray[Float64,3]()
    for j in range(Int(nh)):
        var z:Float64=0.0
        for i in range(Int(ni)):z+=(Float64(a[3+i])/1000.0)*(Float64(a[w1+i*Int(nh)+j])/1000.0)
        h[j]=nn_sigmoid(z)
    for j in range(Int(no)):
        var z:Float64=0.0
        for i in range(Int(nh)):z+=h[i]*(Float64(a[w2+i*Int(no)+j])/1000.0)
        output[j]=nn_sigmoid(z)
    for i in range(Int(no)):let bits=bitcast[UInt64](output[i]);for b in range(8):o[i*8+b]=UInt8((bits>>(8*b))&255)
    return no*8
