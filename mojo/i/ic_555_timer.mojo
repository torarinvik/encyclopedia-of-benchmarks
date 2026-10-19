from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("ic_555_timer")
fn ic_555_timer(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=4:return -1.0e300
    let mode=input[0];let r1=input[1];let r2=input[2];let c=input[3]
    if (mode!=0 and mode!=1) or r1<1 or r1>1000000 or r2<1 or r2>1000000:return -1.0e300
    if (mode==0 and (c<1 or c>1000000)) or (mode==1 and (c<0 or c>1000000)):return -1.0e300
    if mode==0:return (1.44/((Float64(r1)+2.0*Float64(r2))*Float64(c)))*1000000.0
    return (Float64(r1+r2)/Float64(r1+2*r2))*100.0
