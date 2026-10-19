from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import sqrt
@export("realtime_stats")
fn realtime_stats(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>36:return -1.0e300
    let variant=v[0];let stat=v[1];let count=v[2]
    if variant<0 or variant>2 or stat<0 or stat>2 or count<2 or count>32 or n!=c_size_t(3+count):return -1.0e300
    for i in range(Int(count)):if v[3+i]<-64 or v[3+i]>64:return -1.0e300
    if variant<2:
        var mu:Float32=0.0;var variance:Float32=0.0
        if variant==0:
            let anchor=Float32(v[3])/16.0;var ex:Float32=0.0;var ex2:Float32=0.0
            for i in range(Int(count)):
                let x=Float32(v[3+i])/16.0;let tmp=x-anchor;ex+=tmp;ex2+=tmp*tmp
            mu=anchor+ex/Float32(count);variance=(ex2-(ex*ex)/Float32(count))/Float32(count-1)
        else:
            var m:Float32=0.0;var seen=0
            for i in range(Int(count)):
                let x=Float32(v[3+i])/16.0;seen+=1;let delta=x-mu;mu+=delta/Float32(seen);let delta2=x-mu;m+=delta*delta2
            variance=m/Float32(count)
        if stat==0:return Float64(mu)
        if stat==1:return Float64(variance)
        return Float64(sqrt(variance))
    var mu64:Float64=0.0;var m64:Float64=0.0;var seen64=0
    for i in range(Int(count)):
        let x=Float64(Float32(v[3+i])/16.0);seen64+=1;let delta=x-mu64;mu64+=delta/Float64(seen64);let delta2=x-mu64;m64+=delta*delta2
    let variance64=m64/Float64(count)
    if stat==0:return mu64
    if stat==1:return variance64
    return sqrt(variance64)
