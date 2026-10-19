from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn ome_store(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Float64):
    let b=bitcast[UInt64](x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("ode_midpoint_euler")
fn ode_midpoint_euler(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1
    if v[0]<1 or v[0]>8 or v[1]<1 or v[1]>4 or v[2]<-10 or v[2]>10 or v[3]<-10 or v[3]>10:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    let dt=Float64(v[1])/4.0;let half=0.5*dt;var u=Float64(v[2]);var w=Float64(v[3])
    for _ in range(Int(v[0])):
        let mu=u+half*w;let mv=w-half*u;let nu=u+dt*mv;let nw=w-dt*mu;u=nu;w=nw
    ome_store(o,0,u);ome_store(o,8,w);return 16
