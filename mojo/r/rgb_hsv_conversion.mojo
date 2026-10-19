from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from math import min,max
fn put_f64(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Float64):
    let b=bitcast[UInt64](x);for i in range(8):o[at+i]=UInt8((b>>(8*i))&UInt64(255))
@export("rgb_hsv_conversion")
fn rgb_hsv_conversion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    for i in range(3):if v[i]<0 or v[i]>255:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<24:return -2
    let r=Float64(v[0])/255.0;let g=Float64(v[1])/255.0;let b=Float64(v[2])/255.0
    let value=max(r,max(g,b));let chroma=value-min(r,min(g,b));let sat=if value==0.0:0.0 else:chroma/value
    var hue:Float64=0.0
    if chroma!=0.0:
        if value==r:hue=60.0*((g-b)/chroma)
        elif value==g:hue=60.0*(2.0+(b-r)/chroma)
        else:hue=60.0*(4.0+(r-g)/chroma)
    hue+=360.0;if hue>=360.0:hue-=360.0
    put_f64(o,0,hue);put_f64(o,8,sat);put_f64(o,16,value);return 24
