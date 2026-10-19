from std.ffi import c_size_t
from std.math import atan2, cos, isfinite, sin, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("vector2")
fn vector2(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=6:return -1
    for i in range(6):if not isfinite(v[i]):return -1
    if v[0]<0.0 or v[0]>10.0 or v[0]!=Float64(Int(v[0])):return -1
    for i in range(1,5):if v[i]< -1000.0 or v[i]>1000.0:return -1
    let op=Int(v[0]);let ax=v[1];let ay=v[2];let bx=v[3];let by=v[4];let scalar=v[5]
    if op==1:
        if scalar<0.0 or scalar>2000.0:return -1
    elif op==6:
        if bx!=0.0 or by!=0.0 or scalar< -1000.0 or scalar>1000.0:return -1
    elif op==9:
        if bx!=0.0 or by!=0.0 or scalar< -6.283185307179586 or scalar>6.283185307179586:return -1
    elif scalar!=0.0:return -1
    if (op==2 or op==3) and (bx!=0.0 or by!=0.0):return -1
    var result=InlineArray[Float64,2](fill=0.0);var size=1
    if op==0:result[0]=1.0 if ax==bx and ay==by else 0.0
    elif op==1:result[0]=1.0 if abs(ax-bx)<scalar and abs(ay-by)<scalar else 0.0
    elif op==2:result[0]=sqrt(ax*ax+ay*ay)
    elif op==3:
        let mag=sqrt(ax*ax+ay*ay)
        if mag==0.0:return -1
        size=2;result[0]=ax/mag;result[1]=ay/mag
    elif op==4:size=2;result[0]=ax+bx;result[1]=ay+by
    elif op==5:size=2;result[0]=ax-bx;result[1]=ay-by
    elif op==6:size=2;result[0]=ax*scalar;result[1]=ay*scalar
    elif op==7:
        let dx=bx-ax;let dy=by-ay;result[0]=sqrt(dx*dx+dy*dy)
    elif op==8:result[0]=ax*bx+ay*by
    elif op==9:
        let c=cos(scalar);let s=sin(scalar);size=2;result[0]=c*ax-s*ay;result[1]=s*ax+c*ay
    else:result[0]=atan2(by,bx)-atan2(ay,ax)
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(size):return -2
    for i in range(size):o[i]=result[i]
    return Int64(size)
