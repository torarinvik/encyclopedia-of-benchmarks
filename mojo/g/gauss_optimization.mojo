from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import abs, isfinite

fn go_obj(x:Float64,y:Float64,a:Float64,b:Float64)->Float64:
    let dx=x-a;let dy=y-b;return -(dx*dx+dy*dy)

@export("gauss_optimization")
fn gauss_optimization(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=7:return -1
    for i in range(7):if not isfinite(v[i]):return -1
    if (v[0]!=2.0 and v[0]!=3.0 and v[0]!=4.0) or v[1]<0.25 or v[1]>4.0 or v[2]<1.0e-6 or v[2]>2.0:return -1
    for i in range(3,7):if v[i]< -8.0 or v[i]>8.0:return -1
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<2:return -2
    let factor=v[0];var step=v[1];let epsilon=v[2];var x=v[3];var y=v[4];let tx=v[5];let ty=v[6];var error=1.0;var it=0
    while abs(error)>epsilon and it<256:
        let current=go_obj(x,y,tx,ty);var best=go_obj(x,y-step,tx,ty);var choice=0
        let q1=go_obj(x,y+step,tx,ty);if q1>best:best=q1;choice=1
        let q2=go_obj(x-step,y,tx,ty);if q2>best:best=q2;choice=2
        let q3=go_obj(x+step,y,tx,ty);if q3>best:best=q3;choice=3
        error=best-current
        if choice==0:y-=step
        elif choice==1:y+=step
        elif choice==2:x-=step
        else:x+=step
        step/=factor;it+=1
    if abs(error)>epsilon:return -1
    out[0]=x;out[1]=y;return 2
