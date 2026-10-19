from std.ffi import c_size_t
from std.memory import UnsafePointer
fn gcd_factor(a0: Int64,b0: Int64)->Int64:
    var a=a0;var b=b0
    while b!=0:let r=a%b;a=b;b=r
    return a
fn next_factor(x: Int64,n: Int64)->Int64:return (x*x+1)%n
@export("pollards_rho_factorizing")
fn pollards_rho_factorizing(n:Int64) abi("C")->Int64:
    if n<2 or n>46340:return -1
    var x=Int64(2);var y=Int64(2);var d=Int64(1)
    while d==1:
        x=next_factor(x,n);y=next_factor(next_factor(y,n),n)
        d=gcd_factor(if x>=y:x-y else:y-x,n)
    return d
