from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import cos, sin
@export("transformations_2d")
fn transformations_2d(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1.0e300
    let op=a[0];let param=a[1];let comp=a[2]
    if op<0 or op>3 or comp<0 or comp>3:return -1.0e300
    var m=InlineArray[Float64,4]()
    if op==0:
        if param< -1000000 or param>1000000:return -1.0e300
        let f=Float64(param)/1000000.0;m[0]=f*1.0;m[1]=f*0.0;m[2]=f*0.0;m[3]=f*1.0
    else:
        if param< -6283185 or param>6283185:return -1.0e300
        let angle=Float64(param)/1000000.0;let c=cos(angle);let s=sin(angle)
        if op==1:m[0]=c;m[1]= -s;m[2]=s;m[3]=c
        else:
            let cs=c*s
            if op==2:m[0]=c*c;m[1]=cs;m[2]=cs;m[3]=s*s
            else:m[0]=2.0*c-1.0;m[1]=2.0*cs;m[2]=2.0*cs;m[3]=2.0*s-1.0
    return m[Int(comp)]
