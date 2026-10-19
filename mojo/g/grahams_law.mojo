from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import floor, isfinite, pow, sqrt
fn gl_decode(v:UnsafePointer[Int64,ImmutAnyOrigin],i:Int)->Float64:
    let x=bitcast[Float64](bitcast[UInt64](v[i]))
    if not isfinite(x) or x<1.0e-6 or x>1.0e6:return 0.0
    return x
fn gl_round6(x:Float64)->Float64:
    if x<0.0 or x>1.0e6:return -1.0e300
    let scaled=x*1000000.0;let low=floor(scaled);let fraction=scaled-low
    if fraction>=0.499 and fraction<=0.501:return -1.0e300
    return (low+ (1.0 if fraction>0.5 else 0.0))/1000000.0
@export("grahams_law")
fn grahams_law(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>4 or v[0]<0 or v[0]>4:return -1.0e300
    let op=Int(v[0]);if (op==0 and n!=3) or (op!=0 and n!=4):return -1.0e300
    let a=gl_decode(v,1);let b=gl_decode(v,2);if a==0.0 or b==0.0:return -1.0e300
    var result=0.0
    if op==0:result=sqrt(b/a)
    else:
        let c=gl_decode(v,3);if c==0.0:return -1.0e300
        if op==1:result=a*sqrt(c/b)
        elif op==2:result=a/sqrt(c/b)
        elif op==3:result=a/pow(b/c,2.0)
        else:result=pow(b/c,2.0)/a
    if not isfinite(result):return -1.0e300
    return gl_round6(result)
