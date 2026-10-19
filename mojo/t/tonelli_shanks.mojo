from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn ts_modpow(base0:Int64,exponent0:Int64,modulus:Int64)->Int64:
    var base=base0%modulus;var exponent=exponent0;var result:Int64=1
    while exponent>0:
        if (exponent&1)!=0:result=(result*base)%modulus
        base=(base*base)%modulus;exponent=exponent>>1
    return result
fn ts_legendre(a:Int64,p:Int64)->Int:
    let x=ts_modpow(a%p,(p-1)/2,p)
    if x==p-1:return -1
    return Int(x)
@export("tonelli_shanks")
fn tonelli_shanks(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let residue=a[0];let p=a[1]
    if p<=2 or (p&1)==0 or p>1000003 or residue<0 or residue>=p:return -1
    var d:Int64=3
    while d*d<=p:
        if p%d==0:return -1
        d+=2
    if residue==0:return 0
    if ts_legendre(residue,p)!=1:return -1
    if p%4==3:
        let root=ts_modpow(residue,(p+1)/4,p)
        return min(root,p-root)
    var q=p-1;var s:Int64=0
    while (q&1)==0:q/=2;s+=1
    var z:Int64=2
    while ts_legendre(z,p)!= -1:z+=1
    var c=ts_modpow(z,q,p);var r=ts_modpow(residue,(q+1)/2,p);var t=ts_modpow(residue,q,p);var rem=s
    while t!=1:
        var test=t;var least:Int64=0
        for i in range(1,Int(rem)):
            test=ts_modpow(test,2,p)
            if test==1:least=Int64(i);break
        if least==0:return -1
        let b=ts_modpow(c,Int64(1)<<(rem-least-1),p)
        r=(r*b)%p;c=(b*b)%p;t=(t*c)%p;rem=least
    return min(r,p-r)
