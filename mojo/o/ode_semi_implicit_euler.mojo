from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn osie_store(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Float64):
    let b=bitcast[UInt64](x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("ode_semi_implicit_euler")
fn ode_semi_implicit_euler(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1
    if v[0]<1 or v[0]>8 or v[1]<1 or v[1]>4 or v[2]<-10 or v[2]>10 or v[3]<-10 or v[3]>10:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    let dt=Float64(v[1])/4.0;var u=Float64(v[2]);var w=Float64(v[3])
    for _ in range(Int(v[0])):let old_u=u;let old_v=w;u=old_u+dt*old_v;w=old_v-dt*u
    osie_store(o,0,u);osie_store(o,8,w);return 16
