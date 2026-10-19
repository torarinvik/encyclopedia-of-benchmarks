from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn sh_gcd(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0
    while b!=0:let r=a%b;a=b;b=r
    return a
@export("shors_algorithm")
fn shors_algorithm(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>18:return -1
    let m=a[0];let attempts=a[1];if m<2 or m>255 or attempts<1 or attempts>16 or n!=c_size_t(attempts+2):return -1
    for i in range(Int(attempts)):if a[i+2]<2 or a[i+2]>m:return -1
    for i in range(Int(attempts)):
        let g=a[i+2];let common=sh_gcd(g,m);if common!=1:return common
        var order:Int64=1;var power=g%m
        while power!=1 and order<m-1:power=(power*g)%m;order+=1
        if power!=1 or order%2==1:continue
        var hp:Int64=1;for _ in range(Int(order/2)):hp=(hp*g)%m
        let upper=hp+1;let lower=hp-1;if upper%m==0 or lower%m==0:continue
        let gu=sh_gcd(upper,m);if gu!=1:return gu
        return sh_gcd(lower,m)
    return -1
