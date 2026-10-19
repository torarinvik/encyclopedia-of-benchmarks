from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn gcd_r(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0;if a<0:a= -a;if b<0:b= -b
    while b!=0:let r=a%b;a=b;b=r
    return a
fn powmod_fac(base:Int64,ex:Int64,m:Int64)->Int64:
    var result:Int64=1;var power=base%m;var e=ex
    while e>0:if e&1!=0:result=(result*power)%m;power=(power*power)%m;e/=2
    return result
@export("rsa_factorization")
fn rsa_factorization(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>21:return -1
    let d=v[0];let e=v[1];let m=v[2];let attempts=v[3]
    if d<1 or d>1000000 or e<1 or e>1000000 or m<3 or m>65535 or m%2==0 or attempts<1 or attempts>16 or Int(n)!=4+Int(attempts):return -1
    let k=d*e-1;if k<=0 or k&1!=0:return -1
    for i in range(Int(attempts)):if v[4+i]<2 or v[4+i]>m-1:return -1
    for i in range(Int(attempts)):
        var t=k
        while t&1==0:
            t/=2;let x=powmod_fac(v[4+i],t,m);let factor=gcd_r(x-1,m)
            if x>1 and factor>1:
                let other=m/factor;let low=if factor<other:factor else:other;let high=if factor<other:other else:factor
                return low*65536+high
    return -1
