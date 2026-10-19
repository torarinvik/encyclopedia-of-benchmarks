from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from math import sqrt
fn rkf(id:Int,x:Float64,y:Float64)->Float64:
    if id==0:return y
    if id==1:return x
    if id==2:return x+y
    if id==3:return (x-y)/2.0
    return 1.0+y*y
@export("runge_kutta_gills")
fn runge_kutta_gills(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=5:return -1.0e300
    let id=Int(v[0]);let ym=v[1];let xm=v[2];let hm=v[3];let em=v[4]
    if id<0 or id>4 or ym< -1000000 or ym>1000000 or xm< -1000000 or xm>1000000 or em< -1000000 or em>1000000 or hm<10000 or hm>250000 or em<=xm:return -1.0e300
    var y=Float64(ym)/1000000.0;var x=Float64(xm)/1000000.0;let h=Float64(hm)/1000000.0;let ending=Float64(em)/1000000.0
    if id==4 and (x<0.0 or y>0.0):return -1.0e300
    let steps=Int((ending-x)/h);if steps<1 or steps>64:return -1.0e300
    let root2=sqrt(2.0)
    for _ in range(steps):
        let k1=h*rkf(id,x,y);let k2=h*rkf(id,x+h/2.0,y+k1/2.0)
        let k3=h*rkf(id,x+h/2.0,y+(-0.5+1.0/root2)*k1+(1.0-1.0/root2)*k2)
        let k4=h*rkf(id,x+h,y-(1.0/root2)*k2+(1.0+1.0/root2)*k3)
        y=y+(k1+(2.0-root2)*k2+(2.0+root2)*k3+k4)/6.0;x+=h
        if not k1.is_finite() or not k2.is_finite() or not k3.is_finite() or not k4.is_finite() or not y.is_finite() or not x.is_finite():return -1.0e300
    return y
