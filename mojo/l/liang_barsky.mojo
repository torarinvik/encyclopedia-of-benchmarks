from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn liang_round(x:Float64)->Int64:
    let z=x*1000.0
    return if z>=0.0:Int64(z+0.5) else:-Int64(-z+0.5)
@export("liang_barsky")
fn liang_barsky(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=8:return -1
    for i in range(8):
        if v[i]<-5 or v[i]>5:return -1
    let xmin=Float64(v[0]);let ymin=Float64(v[1]);let xmax=Float64(v[2]);let ymax=Float64(v[3]);let x0=Float64(v[4]);let y0=Float64(v[5]);let x1=Float64(v[6]);let y1=Float64(v[7])
    if xmin>=xmax or ymin>=ymax:return -1
    let dx=x1-x0;let dy=y1-y0
    var p=InlineArray[Float64,4](fill=0.0);p[0]= -dx;p[1]=dx;p[2]= -dy;p[3]=dy
    var q=InlineArray[Float64,4](fill=0.0);q[0]=x0-xmin;q[1]=xmax-x0;q[2]=y0-ymin;q[3]=ymax-y0
    var t0=0.0;var t1=1.0
    for i in range(4):
        if p[i]==0.0:
            if q[i]<0.0:return -1
        else:
            let t=q[i]/p[i]
            if p[i]<0.0:
                if t>t1:return -1
                if t>t0:t0=t
            else:
                if t<t0:return -1
                if t<t1:t1=t
    var z=InlineArray[Int64,4](fill=0);z[0]=liang_round(x0+t0*dx);z[1]=liang_round(y0+t0*dy);z[2]=liang_round(x0+t1*dx);z[3]=liang_round(y0+t1*dy)
    var result:Int64=0
    for i in range(4):result=result*10001+z[i]+5000
    return result
