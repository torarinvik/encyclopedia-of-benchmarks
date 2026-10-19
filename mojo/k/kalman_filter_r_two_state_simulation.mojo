from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import isfinite
@export("kalman_filter_r_two_state_simulation")
fn kalman_filter_r_two_state_simulation(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>12:return -1
    for i in range(Int(n)):if not isfinite(a[i]) or a[i]< -1000.0 or a[i]>1000.0:return -1
    var state=InlineArray[Float64,2](fill=0.0);state[0]=a[0]
    var p=InlineArray[Float64,4](fill=0.0);p[0]=1.0;p[3]=1.0
    var stage=InlineArray[Float64,30](fill=0.0);var pred=InlineArray[Float64,2](fill=0.0);var pp=InlineArray[Float64,4](fill=0.0)
    for step in range(Int(n)):
        pred[0]=state[0];pred[1]=state[0]+state[1]
        var tmp=InlineArray[Float64,4](fill=0.0)
        tmp[0]=p[0];tmp[1]=p[1];tmp[2]=p[0]+p[2];tmp[3]=p[1]+p[3]
        pp[0]=tmp[0]+tmp[1];pp[1]=tmp[1];pp[2]=tmp[2]+tmp[3];pp[3]=tmp[3]
        pp[0]+=0.0001;pp[3]+=0.0001
        var hp0=pp[0];var hp1=pp[1];let innovation=hp0+0.1;let k0=pp[0]/innovation;let k1=pp[2]/innovation
        let residual=a[step]-(pred[0]+0.0*pred[1]);state[0]=pred[0]+k0*residual;state[1]=pred[1]+k1*residual
        stage[2*step]=state[0];stage[2*step+1]=state[1]
        let m00=1.0-k0;let m01=1.0;let m10=1.0-k1;let m11=1.0
        p[0]=m00*pp[0]+m01*pp[2];p[1]=m00*pp[1]+m01*pp[3];p[2]=m10*pp[0]+m11*pp[2];p[3]=m10*pp[1]+m11*pp[3]
    let required=2*Int(n)+6
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(required):return -2
    var at=0
    for i in range(2*Int(n)):o[at]=stage[i];at+=1
    o[at]=pred[0];o[at+1]=pred[1];o[at+2]=pp[0];o[at+3]=pp[2];o[at+4]=pp[1];o[at+5]=pp[3]
    return Int64(required)
