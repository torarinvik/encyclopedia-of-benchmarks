from std.math import isfinite, sqrt

fn gl_pi(iter:Int)->Float64:
    var a=1.0;var b=sqrt(0.5);var t=0.25;var p=1.0
    for i in range(iter):
        let an=(a+b)/2.0;let bn=sqrt(a*b);let diff=a-an;let tn=t-p*diff*diff;let pn=2.0*p
        a=an;b=bn;t=tn;p=pn
    let s=a+b;return s*s/(4.0*t)

@export("gauss_legendre")
fn gauss_legendre(x:Float64) abi("C")->Float64:
    if not isfinite(x) or x<0.0 or x>8.0 or x!=Float64(Int64(x)):return -1.0e300
    return gl_pi(Int(x))
