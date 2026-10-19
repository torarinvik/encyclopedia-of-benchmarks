from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sin, cos, sqrt, pow

fn butterworth_coefficients(kind:Int,frequency:Float64,samplerate:Float64,gain_db:Float64,q:Float64,index:Int)->Float64:
    let w0=6.283185307179586476925286766559*frequency/samplerate
    let sine=sin(w0);let cosine=cos(w0);let alpha=sine/(2.0*q)
    var a0=1.0+alpha;var a1= -2.0*cosine;var a2=1.0-alpha
    var b0:Float64=0.0;var b1:Float64=0.0;var b2:Float64=0.0
    if kind==0:b0=(1.0-cosine)/2.0;b1=1.0-cosine;b2=b0
    elif kind==1:b0=(1.0+cosine)/2.0;b1= -1.0-cosine;b2=b0
    elif kind==2:b0=sine/2.0;b1=0.0;b2= -b0
    elif kind==3:b0=1.0-alpha;b1= -2.0*cosine;b2=1.0+alpha;a0=b2;a1=b1;a2=b0
    elif kind==4:
        let big_a=pow(10.0,gain_db/40.0)
        b0=1.0+alpha*big_a;b1= -2.0*cosine;b2=1.0-alpha*big_a
        a0=1.0+alpha/big_a;a1= -2.0*cosine;a2=1.0-alpha/big_a
    elif kind==5 or kind==6:
        let big_a=pow(10.0,gain_db/40.0)
        let pmc=(big_a+1.0)-(big_a-1.0)*cosine;let ppmc=(big_a+1.0)+(big_a-1.0)*cosine
        let mpc=(big_a-1.0)-(big_a+1.0)*cosine;let pmpc=(big_a-1.0)+(big_a+1.0)*cosine
        let aa2=2.0*sqrt(big_a)*alpha
        if kind==5:
            b0=big_a*(pmc+aa2);b1=2.0*big_a*mpc;b2=big_a*(pmc-aa2)
            a0=ppmc+aa2;a1= -2.0*pmpc;a2=ppmc-aa2
        else:
            b0=big_a*(ppmc+aa2);b1= -2.0*big_a*pmpc;b2=big_a*(ppmc-aa2)
            a0=pmc+aa2;a1=2.0*mpc;a2=pmc-aa2
    elif kind==7:b0=1.0;b1= -2.0*cosine;b2=1.0
    else:b0=alpha;b1=0.0;b2= -alpha
    if index==0:return a0
    if index==1:return a1
    if index==2:return a2
    if index==3:return b0
    if index==4:return b1
    return b2

@export("butterworth_filter")
fn butterworth_filter(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=6:return -1.0e300
    let kind=values[0];let index=values[1];let frequency=values[2];let samplerate=values[3];let gain=values[4];let qmicro=values[5]
    if kind<0 or kind>8 or index<0 or index>5 or frequency<1 or frequency>95999 or samplerate<1 or samplerate>192000 or 2*frequency>=samplerate:return -1.0e300
    if qmicro!= -1 and (qmicro<1 or qmicro>10000000):return -1.0e300
    let needs_gain=kind>=4 and kind<=6
    if needs_gain:
        if gain< -60000 or gain>60000:return -1.0e300
    elif gain!=0:return -1.0e300
    let gain_db=Float64(gain)/1000.0 if needs_gain else 0.0
    let q=1.0/sqrt(2.0) if qmicro== -1 else Float64(qmicro)/1000000.0
    return butterworth_coefficients(Int(kind),Float64(frequency),Float64(samplerate),gain_db,q,Int(index))
