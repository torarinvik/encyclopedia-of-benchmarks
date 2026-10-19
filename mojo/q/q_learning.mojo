from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import isfinite
@export("q_learning")
fn q_learning(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<6 or n>11:return -1
    for i in range(Int(n)):if not isfinite(a[i]):return -1
    let done=a[0];let alpha=a[1];let gamma=a[2];let reward=a[3];let old=a[4];let count=a[5]
    if (done!=0.0 and done!=1.0) or alpha<0.0 or alpha>1.0 or gamma<0.0 or gamma>1.0 or reward< -100.0 or reward>100.0 or old< -100.0 or old>100.0 or count<0.0 or count>4.0 or Float64(Int64(count))!=count or n!=c_size_t(6+Int(count)):return -1
    var maxq:Float64=0.0
    if done==0.0 and count>0.0:
        maxq=a[6]
        for i in range(1,Int(count)):if a[6+i]>maxq:maxq=a[6+i]
    for i in range(Int(count)):if a[6+i]< -100.0 or a[6+i]>100.0:return -1
    let result=(1.0-alpha)*old+alpha*(reward+gamma*maxq)
    if not isfinite(result):return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    o[0]=result;return 1
