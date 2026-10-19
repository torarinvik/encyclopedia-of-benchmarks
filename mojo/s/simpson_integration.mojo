from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from math import exp
@export("simpson_integration")
fn simpson_integration(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1.0e300
    let k=a[0];let am=a[1];let bm=a[2]
    if k<2 or k>128 or k%2!=0 or am< -10000000 or am>10000000 or bm< -10000000 or bm>10000000 or am>bm:return -1.0e300
    let x0=Float64(am)/1000000.0;let b=Float64(bm)/1000000.0
    if x0==b:return 0.0
    let h=(b-x0)/Float64(k);var x=x0;var total=0.0
    for i in range(Int(k)+1):
        let sample=exp(-x)*(4.0-x*x)
        if i==0 or i==Int(k):total+=sample
        elif i%2==1:total+=4.0*sample
        else:total+=2.0*sample
        x+=h
    return (h/3.0)*total
