from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import abs
fn ts_value(mode:Int, x:Float32)->Float32:
    if mode==0:return x*x-2.0*x+3.0
    return -x*x-2.0*x+3.0
@export("ternary_search_min_max_recursive")
fn ternary_search_min_max_recursive(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1.0e300
    let mode=a[0];let start=a[1];let end=a[2];let precision=a[3]
    let center=1000 if mode==0 else -1000
    if mode<0 or mode>1 or start< -100000 or end>100000 or start>=center or end<=center or precision<1 or precision>8:return -1.0e300
    var lo=Float32(start)/1000.0;var hi=Float32(end)/1000.0;let eps=Float32(precision)/1000.0
    for _ in range(32):
        if abs(hi-lo)<eps:break
        let d=(hi-lo)/3.0;let m1=lo+d;let m2=hi-d;let f1=ts_value(Int(mode),m1);let f2=ts_value(Int(mode),m2)
        if mode==0:
            if f1<f2:hi=m2
            elif f1>f2:lo=m1
            else:lo=m1;hi=m2
        else:
            if f1<f2:lo=m1
            elif f1>f2:hi=m2
            else:lo=m1;hi=m2
    return Float64(ts_value(Int(mode),lo))
