from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import floor
@export("hsv_to_rgb_conversion")
fn hsv_to_rgb_conversion(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3 or a[0]<0 or a[0]>360000 or a[1]<0 or a[1]>255000000 or a[2]<0 or a[2]>255000000:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<3:return -2
    let h=Float64(a[0])/1000.0;let s=Float64(a[1])/255000000.0;let v=Float64(a[2])/255000000.0
    let c=v*s;let x=c*(1.0-abs((h/60.0)%2.0-1.0));let m=v-c;var r=0.0;var g=0.0;var b=0.0
    if h<60.0:r=c;g=x
    elif h<120.0:r=x;g=c
    elif h<180.0:g=c;b=x
    elif h<240.0:g=x;b=c
    elif h<300.0:r=x;b=c
    else:r=c;b=x
    o[0]=UInt8(floor(255.0*(r+m)+0.5));o[1]=UInt8(floor(255.0*(g+m)+0.5));o[2]=UInt8(floor(255.0*(b+m)+0.5));return 3
