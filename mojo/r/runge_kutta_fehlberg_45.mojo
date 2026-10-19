from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from math import sqrt
fn rkf(id:Int,x:Float64,y:Float64)->Float64:
    if id==0:return y
    if id==1:return x
    if id==2:return x+y
    if id==3:return (x-y)/2.0
    return 1.0+y*y
@export("runge_kutta_fehlberg_45")
fn runge_kutta_fehlberg_45(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=5:return -1.0e300
    let id=Int(v[0]);let ym=v[1];let xm=v[2];let hm=v[3];let em=v[4]
    if id<0 or id>4 or ym< -1000000 or ym>1000000 or xm< -1000000 or xm>1000000 or em< -1000000 or em>1000000 or hm<10000 or hm>250000 or em<=xm:return -1.0e300
    var y=Float64(ym)/1000000.0;var x=Float64(xm)/1000000.0;let h=Float64(hm)/1000000.0;let ending=Float64(em)/1000000.0
    if id==4 and (x<0.0 or y>0.0):return -1.0e300
    let steps=Int((ending-x)/h);if steps<1 or steps>64:return -1.0e300
    for _ in range(steps):
        let k1=h*rkf(id,x,y);let k2=h*rkf(id,x+h/4.0,y+k1/4.0);let k3=h*rkf(id,x+3.0/8.0*h,y+3.0/32.0*k1+9.0/32.0*k2)
        let k4=h*rkf(id,x+12.0/13.0*h,y+1932.0/2197.0*k1-7200.0/2197.0*k2+7296.0/2197.0*k3)
        let k5=h*rkf(id,x+h,y+439.0/216.0*k1-8.0*k2+3680.0/513.0*k3-845.0/4104.0*k4)
        let k6=h*rkf(id,x+h/2.0,y-8.0/27.0*k1+2.0*k2-3544.0/2565.0*k3+1859.0/4104.0*k4-11.0/40.0*k5)
        y=y+16.0/135.0*k1+6656.0/12825.0*k3+28561.0/56430.0*k4-9.0/50.0*k5+2.0/55.0*k6;x+=h
        if not k1.is_finite() or not k2.is_finite() or not k3.is_finite() or not k4.is_finite() or not k5.is_finite() or not k6.is_finite() or not y.is_finite() or not x.is_finite():return -1.0e300
    return y
