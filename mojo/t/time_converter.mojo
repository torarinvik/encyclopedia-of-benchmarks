from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("time_converter")
fn time_converter(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1.0e300
    let t=a[0];let f=a[1];let to=a[2]
    if t<0 or t>1000000000 or f<0 or f>6 or to<0 or to>6:return -1.0e300
    var seconds:Float64=1.0;var dest:Float64=1.0
    if f==1:seconds=60.0
    elif f==2:seconds=3600.0
    elif f==3:seconds=86400.0
    elif f==4:seconds=604800.0
    elif f==5:seconds=2629800.0
    elif f==6:seconds=31557600.0
    if to==1:dest=60.0
    elif to==2:dest=3600.0
    elif to==3:dest=86400.0
    elif to==4:dest=604800.0
    elif to==5:dest=2629800.0
    elif to==6:dest=31557600.0
    let value=(Float64(t)/1000000.0*seconds)/dest
    return Float64(Int64(value*1000.0+0.5))/1000.0
