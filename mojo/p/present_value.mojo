from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import floor
@export("present_value")
fn present_value(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>10 or v[0]<1 or v[0]>8 or (v[1]!=0 and v[1]!=1000000) or n!=c_size_t(v[0]+2):return -1.0e300
    let count=Int(v[0]);var sum=0.0
    for i in range(count):
        let raw=v[i+2]
        if raw< -1000000 or raw>1000000 or raw%125!=0:return -1.0e300
        let cash=Float64(raw)/1000.0
        sum+=cash/(1.0+Float64(v[1])/1000000.0)**Float64(i)
    let scaled=sum*100.0;let low=Int64(floor(scaled));let frac=scaled-Float64(low)
    var cents=low
    if frac>0.5 or (frac==0.5 and low%2!=0):cents+=1
    return Float64(cents)/100.0
