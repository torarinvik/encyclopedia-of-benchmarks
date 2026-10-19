from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn round_even(x:Float64)->Int:
    let lower=Int(x);let frac=x-Float64(lower)
    if frac<0.5:return lower
    if frac>0.5:return lower+1
    return if lower%2==0:lower else:lower+1
@export("rgb_cmyk_conversion")
fn rgb_cmyk_conversion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    for i in range(3):if v[i]<0 or v[i]>255:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<4:return -2
    let r=Float64(v[0])/255.0;let g=Float64(v[1])/255.0;let b=Float64(v[2])/255.0
    let maxc=if r>g:if r>b:r else:b else:if g>b:g else:b
    let key=1.0-maxc
    if key==1.0:o[0]=0;o[1]=0;o[2]=0;o[3]=100;return 4
    let den=1.0-key
    o[0]=UInt8(round_even(100.0*(1.0-r-key)/den));o[1]=UInt8(round_even(100.0*(1.0-g-key)/den));o[2]=UInt8(round_even(100.0*(1.0-b-key)/den));o[3]=UInt8(round_even(100.0*key))
    return 4
