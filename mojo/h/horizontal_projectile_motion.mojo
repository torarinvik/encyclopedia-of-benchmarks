from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sin, sqrt, floor
fn hpm_round(x:Float64)->Float64:
    let scaled=x*100.0;let lo=floor(scaled);let frac=scaled-lo
    var r=lo
    if frac>0.5 or (frac==0.5 and Int64(lo)%2!=0):r=lo+1.0
    return r/100.0
@export("horizontal_projectile_motion")
fn horizontal_projectile_motion(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or a[0]<0 or a[0]>100000 or a[1]<1000 or a[1]>90000:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<24:return -2
    let pi=3.141592653589793;let v=Float64(a[0])/1000.0;let angle=Float64(a[1])/1000.0*pi/180.0;let g=9.80665
    var values=InlineArray[Float64,3](fill=0);values[0]=hpm_round(v*v*sin(2.0*angle)/g);let sn=sin(angle);values[1]=hpm_round(v*v*sn*sn/(2.0*g));values[2]=hpm_round(2.0*v*sn/g)
    for i in range(3):let u=bitcast[UInt64](values[i]);for b in range(8):o[i*8+b]=UInt8((u>>UInt(8*b))&255)
    return 24
