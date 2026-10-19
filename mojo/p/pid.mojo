from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("pid")
fn pid(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<5 or n>64:return -1
    let count=Int(n)-4;let kp=v[0];let ki=v[1];let kd=v[2];let dt64=v[3]
    if not is_finite(kp) or kp < -1.0 or kp>1.0 or not is_finite(ki) or ki < -1.0 or ki>1.0 or not is_finite(kd) or kd < -1.0 or kd>1.0 or not is_finite(dt64) or (dt64!=0.0 and (dt64<0.01 or dt64>1.0)):return -1
    var errors=InlineArray[Float32,60](fill=0.0)
    for i in range(count):if not is_finite(v[4+i]) or v[4+i] < -1.0 or v[4+i]>1.0:return -1;errors[i]=Float32(v[4+i])
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    let fkp=Float32(kp);let fki=Float32(ki);let fkd=Float32(kd);let dt=Float32(dt64);var integral:Float32=0.0;var last:Float32=0.0
    for i in range(count):
        let error=errors[i];let proportional=error*fkp;var step=error*dt;step*=fki;integral+=step;var derivative:Float32=0.0
        if dt!=0.0:let difference=error-last;let rate=difference/dt;derivative=rate*fkd
        last=error;let partial=proportional+integral;let result=partial+derivative;o[i]=Float64(result)
    return Int64(count)
