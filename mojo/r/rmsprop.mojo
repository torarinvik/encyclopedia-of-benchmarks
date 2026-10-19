from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from math import sqrt
@export("rmsprop")
fn rmsprop(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<5 or n>102:return -1
    let nv=v[0];let modev=v[1]
    if not nv.is_finite() or nv!=Float64(Int(nv)) or nv<0.0 or nv>32.0 or (modev!=0.0 and modev!=1.0):return -1
    let count=Int(nv);let mode=Int(modev);if Int(n)!=5+2*count+if mode==1:count else:0:return -1
    let lr=v[2];let rho=v[3];let eps=v[4]
    if not lr.is_finite() or lr<1e-6 or lr>1.0 or not rho.is_finite() or rho<0.0 or rho>0.99 or not eps.is_finite() or eps<1e-8 or eps>1.0:return -1
    var params=InlineArray[Float64,32](fill=0.0);var grads=InlineArray[Float64,32](fill=0.0);var avg=InlineArray[Float64,32](fill=0.0)
    for i in range(count):
        params[i]=v[5+i];grads[i]=v[5+count+i]
        if not params[i].is_finite() or params[i]< -100.0 or params[i]>100.0 or not grads[i].is_finite() or grads[i]< -100.0 or grads[i]>100.0:return -1
    if mode==1:
        for i in range(count):avg[i]=v[5+2*count+i];if not avg[i].is_finite() or avg[i]<0.0 or avg[i]>10000.0:return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(2*count):return -2
    for i in range(count):
        let g=grads[i];let updated=rho*avg[i]+(1.0-rho)*(g*g);avg[i]=updated;params[i]=params[i]-(lr/sqrt(updated+eps))*g
    for i in range(count):o[i]=params[i];o[count+i]=avg[i]
    return Int64(2*count)
