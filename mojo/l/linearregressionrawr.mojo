from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import isfinite
@export("linearregressionrawr")
fn linearregressionrawr(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>66:return -1
    for i in range(Int(n)):
        if not isfinite(v[i]):return -1
    let m=v[0]
    if m<2 or m>32 or Float64(Int(m))!=m or n!=c_size_t(1+2*Int(m)):return -1
    var sx:Int64=0;var sy:Int64=0;var sxy:Int64=0;var sxx:Int64=0;var first:Int64=0;var same=True
    for i in range(Int(m)):
        let x=v[1+i];let y=v[1+Int(m)+i]
        if x < -4 or x>4 or Float64(Int(x))!=x or y < -16 or y>16 or Float64(Int(y))!=y:return -1
        let xi=Int64(x);let yi=Int64(y)
        if i==0:first=xi
        elif xi!=first:same=False
        sx+=xi;sy+=yi;sxy+=xi*yi;sxx+=xi*xi
    if sx!=0 or same or sxx==0:return -1
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<2:return -2
    out[0]=Float64(sy)/Float64(m);out[1]=Float64(sxy)/Float64(sxx);return 2
