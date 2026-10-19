from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn gcd_j(a0: Int64, b0: Int64) -> Int64:
    var a=a0; var b=b0
    while b != 0: let r=a%b; a=b; b=r
    return a
fn rem_j(x: Int64, n: Int64) -> Int64:
    return if x < 0: -((-x)%n) else: x%n
fn step_j(x: Int64,n: Int64) -> Int64: return rem_j(x*x-1,n)
@export("pollard_rho_java")
fn pollard_rho_java(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<2 or v[0]>46340 or v[1]<1 or v[1]>4096:return -1
    let m=v[0];var x=2;var y=2
    for _ in range(Int(v[1])):
        x=step_j(x,m);y=step_j(step_j(y,m),m)
        let d=gcd_j(if x>=y:x-y else:y-x,m)
        if d!=1:return if d==m:0 else:d
    return -2
