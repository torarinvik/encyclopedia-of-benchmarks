from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("n_body_simulation")
fn n_body_simulation(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>26:return -1
    let nb=a[0];let steps=a[1];let dtm=a[2];let gm=a[3];let tf=a[4];let sm=a[5]
    if nb<2 or nb>4 or steps<0 or steps>4 or dtm<1 or dtm>1000 or gm<0 or gm>1000 or tf<1 or tf>10 or sm<1 or sm>3000 or n!=c_size_t(6+5*nb):return -1
    var x=InlineArray[Float64,4]();var y=InlineArray[Float64,4]();var vx=InlineArray[Float64,4]();var vy=InlineArray[Float64,4]();var mass=InlineArray[Float64,4]()
    for i in range(Int(nb)):
        let xx=a[6+5*i];let yy=a[7+5*i];let vxx=a[8+5*i];let vyy=a[9+5*i];let m=a[10+5*i]
        if xx< -1000 or xx>1000 or yy< -1000 or yy>1000 or vxx< -100 or vxx>100 or vyy< -100 or vyy>100 or m<1 or m>1000:return -1
        x[i]=Float64(xx);y[i]=Float64(yy);vx[i]=Float64(vxx);vy[i]=Float64(vyy);mass[i]=Float64(m)
    let dt=(Float64(dtm)/1000.0)*Float64(tf);let g=Float64(gm)/1000.0;let soft=Float64(sm)/1000.0
    for _ in range(Int(steps)):
        for i in range(Int(nb)):
            var fx:Float64=0.0;var fy:Float64=0.0
            for j in range(Int(nb)):
                if i!=j:
                    let dx=x[j]-x[i];let dy=y[j]-y[i];let dist=sqrt(dx*dx+dy*dy+soft);let cube=dist*dist*dist
                    fx+=g*mass[j]*dx/cube;fy+=g*mass[j]*dy/cube
            vx[i]+=fx*dt;vy[i]+=fy*dt
        for i in range(Int(nb)):x[i]+=vx[i]*dt;y[i]+=vy[i]*dt
    let bytes=Int(nb)*32
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(nb)):
        let bits0=bitcast[UInt64](x[i]);let bits1=bitcast[UInt64](y[i]);let bits2=bitcast[UInt64](vx[i]);let bits3=bitcast[UInt64](vy[i])
        for b in range(8):o[(4*i)*8+b]=UInt8((bits0>>(8*b))&255);o[(4*i+1)*8+b]=UInt8((bits1>>(8*b))&255);o[(4*i+2)*8+b]=UInt8((bits2>>(8*b))&255);o[(4*i+3)*8+b]=UInt8((bits3>>(8*b))&255)
    return bytes
