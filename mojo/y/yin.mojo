from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64=-1.0e300
@export("yin")
fn yin(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<7 or n>261:return BAD
    let countv=v[0];let rate=v[1];let minhz=v[2];let maxhz=v[3];let thresholdv=v[4]
    if countv<2 or countv>256 or n!=c_size_t(countv+5) or rate<1 or rate>192000 or minhz<1 or maxhz<=minhz or maxhz>rate/2 or thresholdv<1 or thresholdv>999999:return BAD
    let count=Int(countv);let minlag=Int(rate/maxhz);let maxlag=Int(rate/minhz)
    if minlag<1 or minlag>maxlag or maxlag>64 or maxlag>=count:return BAD
    for i in range(count):if v[5+i]< -32768 or v[5+i]>32767:return BAD
    var cmndf=InlineArray[Float64,65](fill=0.0);cmndf[0]=1.0;var cumulative=Float64(0)
    for lag in range(1,maxlag+1):
        var difference=Float64(0)
        for i in range(count-lag):let delta=Float64(v[5+i])-Float64(v[5+i+lag]);difference+=delta*delta
        cumulative+=difference
        let denom=1.0e-10 if cumulative==0.0 else cumulative
        cmndf[lag]=Float64(lag)*difference/denom
    let threshold=Float64(thresholdv)/1000000.0;var lag=minlag
    while lag<=maxlag:
        if cmndf[lag]<threshold:
            while lag<maxlag and cmndf[lag+1]<cmndf[lag]:lag+=1
            let x0=max(0,lag-1);let x2=min(maxlag,lag+1)
            let s0=cmndf[x0];let s1=cmndf[lag];let s2=cmndf[x2]
            let denominator=s0-2.0*s1+s2
            let refined=Float64(lag) if denominator==0.0 else Float64(lag)+(s0-s2)/(2.0*denominator)
            if not (refined>0.0) or not isfinite(refined):return BAD
            return Float64(rate)/refined
        lag+=1
    return BAD
