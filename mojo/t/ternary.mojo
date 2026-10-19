from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import abs
fn ternary_run(op:Int,a:Float64,b:Float64,eps:Float64,depth:Int,budget:Int)->Float64:
    if depth>budget:return -1.0e300
    if abs(a-b)<=eps:
        let mid=(a+b)/2.0
        return -(mid-1.0)*(mid-1.0) if op==0 else (mid+1.0)*(mid+1.0)
    let m1=(2.0*a+b)/3.0;let m2=(a+2.0*b)/3.0
    let f1=-(m1-1.0)*(m1-1.0) if op==0 else (m1+1.0)*(m1+1.0)
    let f2=-(m2-1.0)*(m2-1.0) if op==0 else (m2+1.0)*(m2+1.0)
    if op==0:
        if f1>f2:return ternary_run(op,a,m2,eps,depth+1,budget)
        return ternary_run(op,m1,b,eps,depth+1,budget)
    if f1<f2:return ternary_run(op,a,m2,eps,depth+1,budget)
    return ternary_run(op,m1,b,eps,depth+1,budget)
@export("ternary")
fn ternary(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>6 or n!=5:return -1.0e300
    let op=a[0];let am=a[1];let bm=a[2];let em=a[3];let budget=a[4]
    if op<0 or op>1 or am< -1000000 or am>1000000 or bm< -1000000 or bm>1000000 or am>bm or em<1 or em>1000000 or budget<1 or budget>64:return -1.0e300
    return ternary_run(Int(op),Float64(am)/1000.0,Float64(bm)/1000.0,Float64(em)/1000000.0,1,Int(budget))
