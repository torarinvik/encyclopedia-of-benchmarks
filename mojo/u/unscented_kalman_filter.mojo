from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64=-1.0e300
fn make_sigma(x:Float64,y:Float64,p00:Float64,p01:Float64,p11:Float64)->(Bool,InlineArray[Float64,10]):
    var pts=InlineArray[Float64,10](fill=0.0)
    let l00=sqrt(2.0*p00)
    if not (l00>0.0):return(False,pts)
    let l10=(2.0*p01)/l00;let rem=2.0*p11-l10*l10
    if not (rem>0.0):return(False,pts)
    let l11=sqrt(rem)
    pts[0]=x;pts[1]=y;pts[2]=x+l00;pts[3]=y+l10;pts[4]=x;pts[5]=y+l11;pts[6]=x-l00;pts[7]=y-l10;pts[8]=x;pts[9]=y-l11
    return(True,pts)
@export("unscented_kalman_filter")
fn unscented_kalman_filter(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<10 or n>17:return BAD
    let steps=v[0]
    if steps<1 or steps>8 or n!=c_size_t(9+steps):return BAD
    if v[1]<-1000 or v[1]>1000 or v[2]<-1000 or v[2]>1000:return BAD
    if v[3]<500 or v[3]>1000 or v[4]<-100 or v[4]>100 or v[5]<500 or v[5]>1000:return BAD
    if v[6]<10 or v[6]>50 or v[7]<10 or v[7]>50 or v[8]<10 or v[8]>100:return BAD
    for i in range(Int(steps)):if v[9+i]<-2000 or v[9+i]>2000:return BAD
    var x=Float64(v[1])/1000.0;var y=Float64(v[2])/1000.0
    var p00=Float64(v[3])/1000.0;var p01=Float64(v[4])/1000.0;var p11=Float64(v[5])/1000.0
    let q0=Float64(v[6])/1000.0;let q1=Float64(v[7])/1000.0;let noise=Float64(v[8])/1000.0
    for t in range(Int(steps)):
        var (ok,sigma)=make_sigma(x,y,p00,p01,p11)
        if not ok:return BAD
        var prop=InlineArray[Float64,10](fill=0.0)
        for i in range(5):
            let sx=sigma[2*i];let sy=sigma[2*i+1]
            prop[2*i]=sx+0.1*sy;prop[2*i+1]=sy+0.05*sx*sx
        var mx=Float64(0);var my=Float64(0)
        for i in range(1,5):mx+=0.25*prop[2*i];my+=0.25*prop[2*i+1]
        let dx0=prop[0]-mx;let dy0=prop[1]-my
        var np00=2.0*dx0*dx0;var np01=2.0*dx0*dy0;var np11=2.0*dy0*dy0
        for i in range(1,5):
            let dx=prop[2*i]-mx;let dy=prop[2*i+1]-my
            np00+=0.25*dx*dx;np01+=0.25*dx*dy;np11+=0.25*dy*dy
        x=mx;y=my;p00=np00+q0;p01=0.5*(np01+np01);p11=np11+q1
        (ok,sigma)=make_sigma(x,y,p00,p01,p11)
        if not ok:return BAD
        var mapped=InlineArray[Float64,5](fill=0.0)
        for i in range(5):mapped[i]=0.05*sigma[2*i]*sigma[2*i]+sigma[2*i+1]
        var expected=Float64(0)
        for i in range(1,5):expected+=0.25*mapped[i]
        var innovation=noise;var cross0=Float64(0);var cross1=Float64(0)
        for i in range(5):
            let weight=2.0 if i==0 else 0.25
            let dx=sigma[2*i]-x;let dy=sigma[2*i+1]-y;let dz=mapped[i]-expected
            innovation+=weight*dz*dz;cross0+=weight*dx*dz;cross1+=weight*dy*dz
        if not (innovation>0.0) or not isfinite(innovation):return BAD
        let k0=cross0/innovation;let k1=cross1/innovation
        let residual=Float64(v[9+t])/1000.0-expected
        x+=k0*residual;y+=k1*residual
        let u0=k0*innovation;let u1=k1*innovation;let old=p01
        p00-=u0*k0;p01=old-0.5*(u0*k1+u1*k0);p11-=u1*k1
    if not isfinite(x):return BAD
    return x
