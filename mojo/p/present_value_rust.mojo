from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import floor, ceil
@export("present_value_rust")
fn present_value_rust(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>10 or v[0]<1 or v[0]>8 or (v[1]!=0 and v[1]!=1000000) or n!=c_size_t(v[0]+2):return -1.0e300
    let count=Int(v[0]);var sum=0.0
    for i in range(count):
        let raw=v[i+2]
        if raw< -1000000 or raw>1000000 or raw%125!=0:return -1.0e300
        sum+=(Float64(raw)/1000.0)/(1.0+Float64(v[1])/1000000.0)**Float64(i)
    let x=sum*100.0
    return floor(x+0.5)/100.0 if x>=0 else ceil(x-0.5)/100.0
