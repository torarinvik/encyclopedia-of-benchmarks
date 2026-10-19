from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import floor
fn mi_store(out:UnsafePointer[UInt8,MutAnyOrigin],x:Int64):
    let u=UInt64(x)
    for i in range(8):out[i]=UInt8((u>>(i*8))&255)
@export("midpoint_integration")
fn midpoint_integration(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1
    let f=v[0];let steps=v[1];let aa=v[2];let bb=v[3]
    if f<0 or f>2 or steps<1 or steps>256 or aa < -1000000 or aa>1000000 or bb<aa or bb>1000000:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    let lo=Float64(aa)/1000000.0;let hi=Float64(bb)/1000000.0;let h=(hi-lo)/Float64(steps);var sum=0.0
    for i in range(Int(steps)):
        let x=lo+Float64(i)*h+h/2.0
        if f==0:sum+=1.0
        elif f==1:sum+=x
        else:sum+=x*x
    let rounded=Int64(floor(h*sum*1000000000.0+0.5));mi_store(out,rounded);return 8
