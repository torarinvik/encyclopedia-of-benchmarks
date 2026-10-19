from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn gcd_py(a0: Int64,b0: Int64)->Int64:
    var a=a0;var b=b0
    while b!=0:let r=a%b;a=b;b=r
    return a
fn adv_py(x: Int64,s: Int64,n: Int64)->Int64:return (x*x+s)%n
@export("pollard_rho_python")
fn pollard_rho_python(v: UnsafePointer[Int64,ImmutAnyOrigin], n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=5:return -1
    let m=v[0];var seed=v[1];var step=v[2];let attempts=v[3];let limit=v[4]
    if m<2 or m>1000000 or seed<0 or seed>=m or step<0 or step>1000 or attempts<1 or attempts>8 or limit<1 or limit>64:return -1
    if m>2 and m%2==0:return 2
    for _ in range(Int(attempts)):
        var t=seed;var h=seed
        for _ in range(Int(limit)):
            t=adv_py(t,step,m);h=adv_py(adv_py(h,step,m),step,m)
            let d=gcd_py(if h>=t:h-t else:t-h,m)
            if d==1:continue
            if d<m:return d
            break
        seed=h;step+=1
    return 0
