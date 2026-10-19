from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn ncr_inverse(a:Int64,m:Int64)->Int64:
    var oldr=a;var r=m;var olds:Int64=1;var s:Int64=0
    while r!=0:
        let q=oldr//r;let tr=r;r=oldr-q*r;oldr=tr;let ts=s;s=olds-q*s;olds=ts
    return (olds+m)%m if oldr==1 else -1
@export("ncr_modulo_p")
fn ncr_modulo_p(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -9223372036854775808
    let size=a[0];let p=a[1];let nn=a[2];let r=a[3]
    if size<0 or size>64 or p<2 or p>1009 or nn<0 or nn>size or r<0 or r>64:return -9223372036854775808
    var fac=InlineArray[Int64,65]();fac[0]=1
    for i in range(1,Int(size)+1):fac[i]=(fac[i-1]*Int64(i))%p
    if r>nn:return 0
    if r==1:return nn%p
    if r==0 or r==nn:return 1
    let den=(fac[Int(r)]*fac[Int(nn-r)])%p;let inv=ncr_inverse(den,p)
    if inv<0:return -1
    return (fac[Int(nn)]*inv)%p
